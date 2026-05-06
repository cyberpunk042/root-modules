#!/usr/bin/env python3
# Stop hook — emit end-of-cycle status stamp via additionalContext.
#
# Operator-authored I/O enhancement mode (per directive 2026-05-05,
# wiki/log/2026-05-05-input-output-enhancement-mode-context-stamp-trail-status.md):
# "context status at input and a trail or stamp and status at the end".
#
# This hook fires on Claude Code's Stop event (end of agent turn) and invokes
# tools.cycle --status-block --diff-fence to produce the colored ```diff-fenced
# block. The output is injected via additionalContext so it renders naturally
# at the end of the agent's response.
#
# Self-gates via BOOTSTRAP.md + CLAUDE_PROJECT_DIR so this fires only for
# /root sessions (not /opt second-brain or other sister-project sessions).

import json
import os
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path.home()


def _trace(tag: str, extra: str = "") -> None:
    try:
        from datetime import datetime as _dt
        with open("/tmp/hook-fire-trace.log", "a") as f:
            f.write(
                f"[{_dt.now().isoformat()}] hook=end-of-cycle-stamp.sh "
                f"path={tag} "
                f"cwd={os.getcwd()} "
                f"home={os.environ.get('HOME', '')} "
                f"claude_proj={os.environ.get('CLAUDE_PROJECT_DIR', '<unset>')} "
                f"{extra}\n"
            )
    except Exception:
        pass


def _resolve_python() -> str:
    """Find a python with tools.* importable (project venv preferred)."""
    sb_venv = Path("/opt/devops-solutions-information-hub/.venv/bin/python")
    if sb_venv.exists():
        return str(sb_venv)
    return "python3"


def main() -> None:
    _trace("entered")

    # Parse stdin to determine event type
    raw = ""
    try:
        raw = sys.stdin.read()
    except Exception:
        pass

    event = ""
    session_id = "default"
    try:
        payload = json.loads(raw) if raw else {}
        event = payload.get("hook_event_name", payload.get("hookEventName", ""))
        session_id = (payload.get("session_id", "default") or "default")[:32]
    except Exception:
        pass

    # Self-gate: only fire for /root sessions
    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        _trace("exit-bootstrap-missing")
        sys.exit(0)

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    home_str = str(PROJECT_ROOT).rstrip("/")
    if project_dir:
        # Positive evidence: must be /root or under /root
        if not (project_dir.rstrip("/") == home_str or project_dir.startswith(home_str + "/")):
            _trace(f"exit-suppress-on-mismatch:{project_dir}")
            sys.exit(0)
    # If unset → fail-OPEN (fire), per operator priority: visibility > cross-fire-prevention

    # SB-115 redesign: read persistent stamp config (slash-command-driven via
    # tools/stamp.py). Replaces failed prompt-marker mechanism (SB-114 v1).
    # Schema: {"layout": "horizontal"|"vertical", "enabled": "on"|"off"|"auto"}
    stamp_cfg = {"layout": "vertical", "enabled": "auto"}
    cfg_file = PROJECT_ROOT / ".claude" / "stamp-config.json"
    if cfg_file.exists():
        try:
            loaded = json.loads(cfg_file.read_text())
            if isinstance(loaded, dict):
                stamp_cfg.update(loaded)
        except Exception:
            pass

    # enabled=off → suppress
    if stamp_cfg.get("enabled") == "off":
        _trace("exit-config-off")
        sys.exit(0)

    # enabled=auto → mode-conditional (SB-114 sub-req c)
    if stamp_cfg.get("enabled") == "auto":
        active_mode = ""
        try:
            mode_file = PROJECT_ROOT / ".claude" / "active-mode"
            if mode_file.exists():
                active_mode = mode_file.read_text().strip()
        except Exception:
            pass
        if not active_mode:
            _trace("exit-auto-no-mode")
            sys.exit(0)

    # enabled=on falls through to render unconditionally

    # Layout determines cycle.py flag
    render_mode = stamp_cfg.get("layout", "vertical")

    # Invoke tools.cycle with mode-appropriate flag.
    # vertical = --ansi-fence (default, stacked sections)
    # horizontal = --ansi-horizontal (compact, single-line-per-section)
    py = _resolve_python()
    flag = "--ansi-horizontal" if render_mode == "horizontal" else "--ansi-fence"
    try:
        result = subprocess.run(
            [py, "-m", "tools.cycle", flag],
            cwd=str(PROJECT_ROOT),
            capture_output=True,
            text=True,
            timeout=8,
        )
        stamp = (result.stdout or "").strip()
    except Exception as exc:
        _trace("exit-tool-error", f"err={exc!r}")
        sys.exit(0)

    if not stamp:
        _trace("exit-empty-stamp")
        sys.exit(0)

    # systemMessage is the only valid display channel for Stop hook per
    # Claude Code official docs (hookSpecificOutput.additionalContext NOT
    # supported for Stop event, hookSpecificOutput hookEventName-only also
    # rejected by schema validator).
    print(json.dumps({"systemMessage": stamp}))
    _trace("fired-systemMessage", f"stamp_len={len(stamp)}")
    sys.exit(0)


if __name__ == "__main__":
    main()
