"""tools.state — read project state (active mode + git + paths) without invoking an LLM.

Per operator directive 2026-05-05: tools = deterministic non-model invocations
that empower / interact with / exploit the system. Commands compose tools; tools
do the work.

Usage:
    python3 -m tools.state                    # human-readable summary
    python3 -m tools.state --json             # JSON output for command composition
    python3 -m tools.state --field active-mode  # single field

Fields:
    active-mode       <project>/.claude/active-mode (or "(none)")
    git-state         project git tree state (init / clean / uncommitted)
    git-uncommitted   count of uncommitted files (0 if clean / not init)
    bootstrap-exists  <project>/BOOTSTRAP.md presence (sanity check)
    second-brain      <second-brain-root>/ reachability (env-var-resolved)

Composes-with:
- Slash commands: /orient (calls indirectly via /cycle), /audit (step 6)
- Hooks: mode-enforcement.sh reads active-mode via this module's logic equivalent
- MCP: root_state tool at tools.mcp_server wraps read_state() for structured returns
- Other tools: tools.cycle imports read_state() to surface in cycle JSON

Idempotency invariant: read-only; no state mutation; re-run = same output if filesystem unchanged.

Action vocabulary (Hard Rule 14): emits `read-only-audit` action type (state queries; no mutation).

Test file: tests/test-state.py (when authored; currently exercised transitively via tools.cycle tests).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

from tools._paths import PROJECT_ROOT, SECOND_BRAIN_ROOT

ACTIVE_MODE_PATH = PROJECT_ROOT / ".claude" / "active-mode"
ROOT = PROJECT_ROOT
BOOTSTRAP_PATH = PROJECT_ROOT / "BOOTSTRAP.md"


def read_active_mode() -> str:
    if not ACTIVE_MODE_PATH.exists():
        return "(none)"
    content = ACTIVE_MODE_PATH.read_text().strip()
    return content if content else "(none)"


def read_git_state() -> tuple[str, int]:
    if not (ROOT / ".git").exists():
        return "not-init", 0
    try:
        result = subprocess.run(
            ["git", "-C", str(ROOT), "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (subprocess.SubprocessError, OSError):
        return "error", 0
    if result.returncode != 0:
        return "error", 0
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        return "clean", 0
    return "uncommitted", len(lines)


def read_state() -> dict:
    git_state, git_uncommitted = read_git_state()
    return {
        "active-mode": read_active_mode(),
        "git-state": git_state,
        "git-uncommitted": git_uncommitted,
        "bootstrap-exists": BOOTSTRAP_PATH.exists(),
        "second-brain-reachable": (SECOND_BRAIN_ROOT / "wiki" / "spine" / "references" / "adoption-guide.md").exists(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Read project state for root-modules")
    parser.add_argument("--json", action="store_true", help="output as JSON")
    parser.add_argument("--field", type=str, help="output a single field")
    args = parser.parse_args()

    state = read_state()

    if args.field:
        if args.field not in state:
            print(f"unknown field: {args.field}. available: {', '.join(state)}", file=sys.stderr)
            return 1
        print(state[args.field])
        return 0

    if args.json:
        print(json.dumps(state, indent=2))
        return 0

    print("=== root-modules state ===")
    for key, value in state.items():
        print(f"  {key:<24}  {value}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
