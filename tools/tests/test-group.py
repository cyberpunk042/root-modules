#!/usr/bin/env python3
"""Regression tests for tools/group.py — the chain/group/tree composition
primitive (E003 multi-group Layer A).

Closes the explicitly-planned-but-never-authored test gap noted in
tools/group.py line ~108 ("Test file: tools/tests/test-group.py (when
authored)"). group.py is pure functions (no I/O, no env coupling), so
these tests are fully deterministic — the strongest kind of verified-edit
substrate per Hard Rule 14.

First test under tools/tests/ — tools.run-tests already discovers this
path (tools/tests/test-*.py) but it was empty until now, so the
deterministic tool layer had zero regression coverage.

Emits the canonical `Result: N/M passed` line that tools.run-tests'
RESULT_RE consumes (see the test-t015 aggregate-undercount fix, same PR).

Exit 0 iff all pass; 1 otherwise.
"""
from __future__ import annotations

import sys
from pathlib import Path

# tools/ is the package parent of this file's grandparent (tools/tests/ -> tools/ -> <repo>).
REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from tools.group import GroupError, chain, group, tree  # noqa: E402

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, cond: bool, detail: str = "") -> None:
    (PASSED if cond else FAILED).append(label if cond else (label, detail))  # type: ignore[arg-type]
    print(f"  {'PASS' if cond else 'FAIL'} {label}" + (f" — {detail}" if not cond else ""))


# --- chain: sequential composition, prev-return feeds next ------------------
def test_chain() -> None:
    check("chain three steps feed forward", chain(lambda: 1, lambda x: x + 10, lambda x: x * 2) == 22)
    check("chain empty returns initial (None)", chain() is None)
    check("chain empty returns provided initial", chain(initial=9) == 9)
    check("chain single step no-arg", chain(lambda: 42) == 42)
    check("chain first step receives non-None initial", chain(lambda x: x + 1, initial=5) == 6)

    # Failure stops the chain: the second step raises, third must never run.
    ran = {"third": False}

    def boom(_):
        raise ValueError("stop here")

    def third(_):
        ran["third"] = True
        return "reached"

    stopped = False
    try:
        chain(lambda: 1, boom, third)
    except ValueError:
        stopped = True
    check("chain stops at first exception (propagates)", stopped)
    check("chain does NOT run steps after a failure", ran["third"] is False)


# --- group: parallel composition, all run regardless of failures ------------
def test_group() -> None:
    check("group returns results in input order", group(lambda: "a", lambda: "b", lambda: "c") == ["a", "b", "c"])
    check("group empty returns empty list", group() == [])

    # All callables run even though one fails; GroupError aggregates.
    ran = {"after": False}

    def ok_first():
        return 1

    def fails():
        raise ZeroDivisionError("div0")

    def ok_after():
        ran["after"] = True
        return 3

    raised = None
    try:
        group(ok_first, fails, ok_after)
    except GroupError as e:
        raised = e
    check("group raises GroupError on any failure", isinstance(raised, GroupError))
    check("group runs ALL callables despite a failure (not short-circuit)", ran["after"] is True)
    if raised is not None:
        check("GroupError.errors records the failing index", [i for i, _ in raised.errors] == [1])
        check("GroupError.results places the exception in the failed slot",
              isinstance(raised.results[1], ZeroDivisionError))
        check("GroupError.results keeps successful results", raised.results[0] == 1 and raised.results[2] == 3)
    else:
        check("GroupError.errors records the failing index", False, "no GroupError raised")
        check("GroupError.results places the exception in the failed slot", False, "no GroupError raised")
        check("GroupError.results keeps successful results", False, "no GroupError raised")


# --- tree: root → branches(seed) → merge ------------------------------------
def test_tree() -> None:
    r = tree(
        root=lambda: 5,
        branches=[lambda s: s + 1, lambda s: s * 2, lambda s: s - 3],
        merge=lambda parts: sum(parts),
    )
    check("tree root→branches→merge composes (5→[6,10,2]→18)", r == 18)

    # Each branch receives the SAME seed (no seed mutation across branches).
    seeds_seen = []

    def record(s):
        seeds_seen.append(s)
        return s

    tree(root=lambda: 7, branches=[record, record, record], merge=lambda parts: parts)
    check("tree passes identical seed to every branch", seeds_seen == [7, 7, 7])

    # merge receives branch results in branch order.
    ordered = tree(root=lambda: 0, branches=[lambda s: "x", lambda s: "y"], merge=lambda parts: parts)
    check("tree merge receives branch results in order", ordered == ["x", "y"])


def main() -> int:
    print("=== tools.group regression tests ===")
    test_chain()
    test_group()
    test_tree()
    total = len(PASSED) + len(FAILED)
    print()
    print(f"Result: {len(PASSED)}/{total} passed")
    if FAILED:
        for item in FAILED:
            label, detail = item if isinstance(item, tuple) else (item, "")
            print(f"  - {label}: {detail}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
