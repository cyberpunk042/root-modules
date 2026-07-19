#!/usr/bin/env python3
"""tools.run-tests — unified runner for all $HOME hook + tool regression tests.

Per SB-131 chain-operation pattern + operator directive 2026-05-06:
"use the tools and harness and ecosystem better" + chain-batched operations.

Replaces the manual "python3 .claude/hooks/tests/test-X.py" sequence with a
single invocation that aggregates pass/fail + reports per-file totals.

Run:
    python3 -m tools.run-tests          # all suites
    python3 -m tools.run-tests --json   # JSON output for programmatic consumers

Test discovery:
    .claude/hooks/tests/test-*.py    — hook regression tests (5 files)
    tools/tests/test-*.py            — tool regression tests (2 files)

Exit code 0 if all PASS; 1 on any FAIL.

Composes-with:
- Slash commands: /audit (composition surface for "verify everything green"); /cycle
  Architect mode (test-pass evidence is the verified-edit gate per Hard Rule 14)
- Hooks: not directly consumed by hooks; hooks use their own per-test files in
  .claude/hooks/tests/
- Sister tools: this is the canonical aggregator across all 13 test files (215/234
  aggregate as of 2026-05-06 evening; 3 partial-fail surfaced for operator-decision)

Idempotency invariant: pure read-only orchestration; runs each test as subprocess;
parses Result line; aggregates pass/fail. No filesystem mutation.

Action vocabulary (Hard Rule 14): emits `verified-edit` action type when used as the
canonical verifier per Architect-mode `/cycle` step 7 — pass output IS the verification
evidence required per work-mode.md status-claim discipline (P4 — Declarations
Aspirational Until Verified).

This is THE canonical verifier for the `verified-edit` M-E001-1 action type per
wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md. Any code-edit
status claim should inline this tool's exit code + per-suite breakdown.

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path.home()
HOOK_TESTS_DIR = PROJECT_ROOT / ".claude" / "hooks" / "tests"
TOOL_TESTS_DIR = PROJECT_ROOT / "tools" / "tests"

RESULT_RE = re.compile(r"^Result:\s*(\d+)/(\d+)", re.MULTILINE)


def discover_tests() -> list[Path]:
    """Find all test-*.py files in hook + tool test directories."""
    files: list[Path] = []
    for d in (HOOK_TESTS_DIR, TOOL_TESTS_DIR):
        if d.exists():
            files.extend(sorted(d.glob("test-*.py")))
    return files


def run_one(path: Path) -> dict:
    """Run a single test file. Returns dict with name + pass + total + ok + duration."""
    import time
    start = time.time()
    r = subprocess.run(
        [sys.executable, str(path)],
        capture_output=True, text=True,
        cwd=str(PROJECT_ROOT),
        timeout=60,
    )
    duration = time.time() - start
    out = r.stdout + r.stderr
    m = RESULT_RE.search(out)
    if m:
        passed, total = int(m.group(1)), int(m.group(2))
    else:
        passed, total = 0, 0
    return {
        "name": path.name,
        "passed": passed,
        "total": total,
        "ok": r.returncode == 0,
        "duration_sec": round(duration, 2),
        "rc": r.returncode,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run all root-modules regression tests")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    tests = discover_tests()
    if not tests:
        print("No test files found.", file=sys.stderr)
        return 1

    results: list = []
    total_passed = 0
    total_total = 0
    all_ok = True

    for t in tests:
        r = run_one(t)
        results.append(r)
        total_passed += r["passed"]
        total_total += r["total"]
        if not r["ok"]:
            all_ok = False

    if args.json:
        print(json.dumps({
            "results": results,
            "aggregate": {
                "passed": total_passed,
                "total": total_total,
                "all_ok": all_ok,
            }
        }, indent=2))
        return 0 if all_ok else 1

    # Pretty output
    print(f"=== root-modules regression test run ===")
    print()
    for r in results:
        marker = "✓" if r["ok"] else "✗"
        print(f"  {marker} {r['name']:40s}  {r['passed']:3d}/{r['total']:3d}  ({r['duration_sec']}s)")
    print()
    print(f"AGGREGATE: {total_passed}/{total_total} {'PASS' if all_ok else 'FAIL'} across {len(tests)} files")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
