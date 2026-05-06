#!/usr/bin/env python3
# stamp-control.sh — UserPromptSubmit hook for SB-114 per-prompt stamp control.
#
# Detects markers in operator's prompt and writes flag file consumed by
# end-of-cycle-stamp.sh on Stop event.
#
# Markers:
#   !nostamp           → suppress stamp for this turn (override)
#   !stamp             → opt-in to show stamp this turn (overrides default-hide
#                        when no mode active)
#   !stamp=horizontal  → opt-in + render horizontal layout
#   !stamp=vertical    → opt-in + render vertical layout (the ansi-fence default)
#
# Flag file: /tmp/stamp-flags/<session-id>.json (session-scoped to avoid
# cross-session interference; deleted by Stop hook after read).
#
# Self-gates via BOOTSTRAP.md presence + CLAUDE_PROJECT_DIR or cwd match.

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path.home()
FLAG_DIR = Path("/tmp/stamp-flags")


def is_project_context() -> bool:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    home = str(PROJECT_ROOT)
    if project_dir:
        return project_dir == home or project_dir.startswith(home + "/")
    cwd = os.getcwd()
    return cwd == home or cwd.startswith(home + "/")


def main() -> None:
    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        sys.exit(0)
    if not is_project_context():
        sys.exit(0)

    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    prompt = payload.get("prompt", "") or payload.get("user_prompt", "")
    if not isinstance(prompt, str):
        sys.exit(0)

    session_id = (payload.get("session_id", "default") or "default")[:32]

    flags: dict = {}

    # !nostamp — suppress this turn (highest priority)
    if re.search(r"!nostamp\b", prompt):
        flags["suppress"] = True

    # !stamp=<mode> — opt-in + specific mode
    m = re.search(r"!stamp=(horizontal|vertical)\b", prompt)
    if m:
        flags["mode"] = m.group(1)
        flags["opt_in"] = True

    # !stamp (without =) — opt-in only
    elif re.search(r"!stamp\b(?!=)", prompt):
        flags["opt_in"] = True

    if not flags:
        sys.exit(0)  # silent if no markers

    try:
        FLAG_DIR.mkdir(parents=True, exist_ok=True)
        (FLAG_DIR / f"{session_id}.json").write_text(json.dumps(flags))
    except Exception:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
