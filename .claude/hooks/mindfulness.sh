#!/usr/bin/env python3
# mindfulness.sh — UserPromptSubmit hook injecting mindfulness baseline.
#
# Operator directive 2026-05-06: *"about those crazy act... it probably just
# need another hook / sub-hook in reality where we remind of the basis of
# mindful that naturally dont lead to pendulum and extrapolation and
# hallucination moves..."*
#
# Engineering scope (closes the recurring rule-only-fix gap from SB-113):
#
#   1. PROACTIVE MINDFULNESS LAYER — fires on every UserPromptSubmit, not just
#      under-pressure (output-discipline-guard.sh covers under-pressure).
#      Steady-baseline grounding to prevent the bug-class BEFORE it triggers.
#
#   2. COMPOUND COMPOSITION — runs alongside mode-enforcement + context-warning
#      + output-discipline-guard. Each emits its own additionalContext field.
#      Compounds, doesn't replace (per operator's compound-not-collide directive).
#
#   3. PATTERNS ADDRESSED (per recurring SBs): SB-082/093 pendulum (one-notch-
#      rule), SB-090 family premise-construction (confirm-don't-construct),
#      SB-095 hallucinated artifacts (flag-as-agent-draft), SB-099 abdication-
#      as-freeze (forward-not-stop).
#
#   4. TIGHT REMINDER — short (≤400 chars). Banner not lecture. Grounds without
#      crowding mode-enforcement banner or other UserPromptSubmit hooks.
#
#   5. CONTEXT-AWARE — silent when no active-mode (consistent with mode-
#      enforcement; mindfulness is mode-bound discipline, not always-on).
#
#   6. NON-DEROUTE — never deroutes the agent. Just adds anchor.

from __future__ import annotations

import json
import os
import sys
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path.home()
ACTIVE_MODE_FILE = PROJECT_ROOT / ".claude" / "active-mode"

REMINDER = (
    "MINDFULNESS [DRAFT v2 per SB-129; binary MUST/MUST-NOT format per "
    "<second-brain> context-engineering-standards; 6 clauses, prose=25%/tables=60%/hooks=100% compliance]: "
    "(1) one-notch — MUST adjust ONE dimension on operator correction; MUST NOT swing fully opposite (SB-082/093). "
    "(2) premise — MUST treat operator's literal words as premise; MUST confirm before constructing inferences (SB-090). "
    "(3) artifacts — MUST flag agent-drafts at every reference; MUST NOT treat agent-authored as operator-known (SB-095). "
    "(4) forward — MUST fix-and-continue when corrected; MUST NOT \"standing by\" without specific subject (SB-099). "
    "(5) priority — MUST address top priority FIRST per cycle; MUST NOT short-circuit to easier lower-priority items (SB-128). "
    "(6) substance — MUST produce real work per cron-fire (SB closure / verified edit / drift-fix-with-empirical / explicit-standby-with-named-reason); MUST NOT emit thin \"standby\" output (SB-128). "
    "(7) not-blocked-when-unblocked — MUST verify empirically (`tools.blockers --check` + impediment file) before claiming pseudo-block; MUST chain/batch operations when multiple files reflect ONE coherent change (SB-131)."
)


def is_project_context() -> bool:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    home = str(PROJECT_ROOT)
    if project_dir:
        return project_dir == home or project_dir.startswith(home + "/")
    cwd = os.getcwd()
    return cwd == home or cwd.startswith(home + "/")


def _trace(tag: str) -> None:
    try:
        with open("/tmp/hook-fire-trace.log", "a") as f:
            f.write(
                f"[{datetime.now().isoformat()}] hook=mindfulness.sh "
                f"path={tag} cwd={os.getcwd()}\n"
            )
    except Exception:
        pass


def main() -> None:
    _trace("entered")

    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        _trace("exit-bootstrap-missing")
        sys.exit(0)
    if not is_project_context():
        _trace("exit-not-project-context")
        sys.exit(0)

    try:
        sys.stdin.read()
    except Exception:
        pass

    if not ACTIVE_MODE_FILE.exists():
        _trace("exit-no-active-mode")
        sys.exit(0)

    try:
        if not ACTIVE_MODE_FILE.read_text().strip():
            _trace("exit-empty-active-mode")
            sys.exit(0)
    except Exception:
        _trace("exit-mode-read-error")
        sys.exit(0)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": REMINDER,
        }
    }
    print(json.dumps(output))
    _trace("fired")
    sys.exit(0)


if __name__ == "__main__":
    main()
