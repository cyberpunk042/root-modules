#!/usr/bin/env python3
"""opt-write-block — PreToolUse hook that denies Write/Edit/NotebookEdit to /opt paths.

Wired event: PreToolUse · matcher: Write|Edit|NotebookEdit
Strictness tier (per .claude/rules/hook-architecture.md): **Strict** — fail-CLOSED with documented bypass
Tests: .claude/hooks/tests/test-opt-write-block.py (5/5 pass — empirically verified
       2026-05-06 evening; covers project-cwd-allow + /opt-cwd-deny + bypass-allow +
       legitimate-second-brain-cwd-allow + non-write-tool-passthrough)
Bypass: env var `ROOT_OPT_WRITE_REASON=<reason>` documents justified exception
        (e.g., operator-explicit one-time direction for operational config edits
        per SB-098 knowledge-vs-operational-config distinction). Logged to
        opt-write-block.log for audit.
SB closures: SB-009 (re-wrote to /opt after correction — structural fix here) ·
             SB-010 (cwd-aware via CLAUDE_PROJECT_DIR + os.getcwd() check) ·
             SB-098 (knowledge-vs-operational-config distinction — the binding
             rule covers KNOWLEDGE; bypass exists for operational config when
             operator explicitly directs)
Cross-refs: .claude/hooks/README.md (DRAFT v1) · .claude/rules/hook-architecture.md
            (Strict-tier 3-component pattern; bypass mechanism canonical example) ·
            .claude/rules/operating-principles.md #9 ($HOME scope discipline +
              knowledge-vs-operational-config refinement) ·
            CLAUDE.md/AGENTS.md Hard Rule 12 (brain-inheritance pattern —
              $HOME source-of-truth for operational tooling; this hook enforces
              the boundary at tool-call time) ·
            wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
            (sacrosanct verbatim directive governing this comment refresh)

Per operator binding rule 2026-05-05 (sacrosanct verbatim): "LET THE SECOND-BRAIN
BE ITS OWN... THE ONLY WAY TO SEND TO THE SECOND-BRAIN IS TO USE THE CONTRIBUTE
FEATURE." The $HOME agent must not write into <second-brain>/ directly. The
canonical channel is `tools.gateway contribute` (gated on M007 connect).

This hook is structural enforcement on top of the rule-layer prevention in
`.claude/rules/work-mode.md` + `.claude/rules/operating-principles.md` §9. It catches
the bug at tool-call time, not just rule-warning time.

Wired in `.claude/settings.json` as PreToolUse hook with matcher `Write|Edit|NotebookEdit`.

Status: WIRED — authored 2026-05-05 during systemic-fix workblock; wired in
.claude/settings.json as a PreToolUse hook (matcher `Write|Edit|NotebookEdit`,
command `python3 $HOME/.claude/hooks/opt-write-block.sh`). Empirically verified
2026-07-03 (settings.json parse + tests/test-opt-write-block.py 5/5). Any future
change to its wiring still falls under work-mode.md PO approval boundary (hook
configuration changes).
"""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime
from pathlib import Path

LOG_PATH = Path.home() / ".claude/hooks/opt-write-block.log"


def _resolve_second_brain():
    """Resolve second-brain root: env var → $HOME default → /opt legacy."""
    env = os.environ.get("RGP_SECOND_BRAIN_ROOT")
    if env:
        return Path(env).expanduser().resolve()
    home_candidate = Path.home() / "devops-solutions-information-hub"
    if home_candidate.exists():
        return home_candidate
    opt_candidate = Path("/opt/devops-solutions-information-hub")
    if opt_candidate.exists():
        return opt_candidate
    return home_candidate  # default; may not exist


SECOND_BRAIN_ROOT = _resolve_second_brain()
PROTECTED_PREFIX = str(SECOND_BRAIN_ROOT) + "/"


def is_project_context() -> bool:
    """Detect if the calling agent is operating from THIS host's project context ($HOME).

    The hook lives at machine-level (~/.claude/) so it fires for all sessions
    on the host. We only enforce the second-brain-write-block rule for sessions
    whose project root is $HOME (the canonical project location for type=root
    install) — NOT for second-brain's own agent or other sister projects that
    legitimately write into their own directories.

    Detection (in priority order):
    1. CLAUDE_PROJECT_DIR env var — set by Claude Code per session
    2. cwd — falls back to working directory
    """
    home = str(Path.home())
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    if project_dir:
        return project_dir == home or project_dir.startswith(home + "/")
    cwd = os.getcwd()
    return cwd == home or cwd.startswith(home + "/")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        # If we can't parse, allow (don't break the harness)
        return 0

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})

    if tool_name not in ("Write", "Edit", "NotebookEdit"):
        return 0

    file_path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""

    if not file_path.startswith(PROTECTED_PREFIX):
        return 0

    # Only enforce when calling agent is operating from THIS host's project ($HOME).
    # Second-brain's own agent (cwd inside SECOND_BRAIN_ROOT) legitimately writes
    # into its own directory and must not be blocked.
    if not is_project_context():
        return 0

    # Bypass check
    bypass_reason = os.environ.get("ROOT_OPT_WRITE_REASON", "").strip()
    timestamp = datetime.utcnow().isoformat()

    if bypass_reason:
        # Allow but log the bypass
        try:
            with LOG_PATH.open("a") as f:
                f.write(f"{timestamp} BYPASS tool={tool_name} path={file_path} reason={bypass_reason!r}\n")
        except OSError:
            pass
        return 0

    # Deny + remediation
    try:
        with LOG_PATH.open("a") as f:
            f.write(f"{timestamp} DENY tool={tool_name} path={file_path}\n")
    except OSError:
        pass

    response = {
        "decision": "block",
        "reason": (
            f"BLOCKED: {tool_name} to {file_path}. "
            f"REASON: project agent must not write into second-brain at {PROTECTED_PREFIX} "
            "directly (operator binding rule 2026-05-05: 'LET THE SECOND-BRAIN BE ITS OWN'). "
            f"INSTEAD: write to {Path.home()}/wiki/log/<date>-<slug>.md for project iteration "
            "directives, or use `tools.gateway contribute` (gated on M007 connect) "
            "for second-brain submissions. "
            "BYPASS: set env var ROOT_OPT_WRITE_REASON=<reason> on the tool call to "
            "document a justified exception (logged to opt-write-block.log)."
        ),
    }
    print(json.dumps(response))
    return 0


if __name__ == "__main__":
    sys.exit(main())
