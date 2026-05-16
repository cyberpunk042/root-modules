#!/usr/bin/env python3
# ============================================================================
# ARCHIVED — UNWIRED 2026-05-06 — superseded by SB-115 redesign
# ----------------------------------------------------------------------------
# Replaced by: /stamp-{horizontal,vertical,on,off,auto,status} slash commands
# + persistent config at $HOME/.claude/stamp-config.json + tools/stamp.py
# + end-of-cycle-stamp.sh (reads config on Stop event).
#
# Kept for reference per operator directive 2026-05-06:
# "label them as archive if they are not usefull anymore. dont necessarily
#  delete them. they remind me of something."
#
# Reason for archival: original prompt-marker mechanism (`!stamp=horizontal` etc.)
#            DID NOT WORK in real session per operator-empirical 2026-05-06
#            (synthetic test passed; real-session marker not picked up — SB-091
#            recurrence: synthetic-test-claimed-as-verified). SB-115 redesign
#            replaced with slash-command + persistent JSON config (operator-
#            empirically verified working).
# Cross-refs: .claude/hooks/README.md (DRAFT v1 — WIRED-vs-ARCHIVE labels) ·
#             .claude/hooks/end-of-cycle-stamp.sh (active successor) ·
#             tools/stamp.py (config persistence layer) ·
#             .claude/commands/stamp-*.md (6 slash commands — operator UX) ·
#             tools/tests/test-stamp.py (23/23 regression tests for the active path) ·
#             wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
#
# Original purpose preserved below for historical reference.
# ============================================================================
#
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
