#!/usr/bin/env python3
"""Regression tests for tools/state.py — deterministic project-state reader.

state.py is the read-side aggregator (active-mode + git tree state +
bootstrap presence + second-brain reachability). It backs the root_state MCP
tool, /audit step 6, and is imported by tools.cycle. Its docstring named a
test file that was never written ("Test file: tests/test-state.py (when
authored)") and the claimed transitive coverage via tools.cycle tests does not
exist (there are no cycle tests) — so it had zero real coverage.

Isolation: state.py resolves its paths from module globals (ACTIVE_MODE_PATH,
ROOT, BOOTSTRAP_PATH) derived from the repo root. These tests run IN-PROCESS
and repoint those globals at temp dirs per case, incl. a real throwaway git
repo for the git-state branch — so the reader is exercised against controlled
filesystem state, never the live repo.

Emits the canonical `Result: N/M passed` line consumed by tools.run-tests.
Exit 0 iff all pass.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import tools.state as st  # noqa: E402

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, cond: bool, detail: str = "") -> None:
    if cond:
        PASSED.append(label)
        print(f"  PASS {label}")
    else:
        FAILED.append((label, detail))
        print(f"  FAIL {label}" + (f" — {detail}" if detail else ""))


def tmpdir() -> Path:
    return Path(tempfile.mkdtemp(prefix="state-test-"))


def test_read_active_mode() -> None:
    d = tmpdir()
    st.ACTIVE_MODE_PATH = d / "active-mode"
    check("active-mode absent → (none)", st.read_active_mode() == "(none)")
    st.ACTIVE_MODE_PATH.write_text("   \n")
    check("active-mode empty/whitespace → (none)", st.read_active_mode() == "(none)")
    st.ACTIVE_MODE_PATH.write_text("dual-expert\n")
    check("active-mode set → value (stripped)", st.read_active_mode() == "dual-expert")


def test_git_state_not_init() -> None:
    d = tmpdir()  # plain dir, no .git
    st.ROOT = d
    state, n = st.read_git_state()
    check("non-git dir → not-init, 0", state == "not-init" and n == 0)


def test_git_state_clean_and_uncommitted() -> None:
    d = tmpdir()
    subprocess.run(["git", "init", "-q", str(d)], check=True,
                   capture_output=True, text=True)
    st.ROOT = d
    state, n = st.read_git_state()
    check("fresh git repo (no files) → clean, 0", state == "clean" and n == 0)
    (d / "newfile.txt").write_text("hi")
    state2, n2 = st.read_git_state()
    check("untracked file → uncommitted, count≥1", state2 == "uncommitted" and n2 >= 1)


def test_read_state_shape() -> None:
    d = tmpdir()
    st.ACTIVE_MODE_PATH = d / "active-mode"
    st.ROOT = d
    st.BOOTSTRAP_PATH = d / "BOOTSTRAP.md"
    s = st.read_state()
    expected_keys = {"active-mode", "git-state", "git-uncommitted",
                     "bootstrap-exists", "second-brain-reachable"}
    check("read_state has exactly the 5 documented fields", set(s) == expected_keys)
    check("bootstrap-exists is False when absent", s["bootstrap-exists"] is False)
    (d / "BOOTSTRAP.md").write_text("# hi")
    check("bootstrap-exists is True when present", st.read_state()["bootstrap-exists"] is True)
    check("git-uncommitted is an int", isinstance(s["git-uncommitted"], int))


def _cli(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, "-m", "tools.state", *args],
        capture_output=True, text=True, cwd=str(REPO_ROOT),
        env={"HOME": os.environ.get("HOME", ""), "PATH": os.environ.get("PATH", "")},
    )


def test_cli_field_and_json() -> None:
    # These run against the real repo state but only assert structural behavior.
    r = _cli("--field", "bogus-field")
    check("--field unknown → exit 1", r.returncode == 1)
    check("--field unknown names it 'unknown field'", "unknown field" in r.stderr)
    r2 = _cli("--field", "active-mode")
    check("--field active-mode → exit 0", r2.returncode == 0)
    r3 = _cli("--json")
    import json as _json
    ok = r3.returncode == 0
    try:
        parsed = _json.loads(r3.stdout)
        ok = ok and {"active-mode", "git-state", "git-uncommitted",
                     "bootstrap-exists", "second-brain-reachable"} <= set(parsed)
    except Exception:
        ok = False
    check("--json emits valid JSON with all documented keys", ok)


def main() -> int:
    print("=== tools.state regression tests ===")
    for t in (
        test_read_active_mode, test_git_state_not_init,
        test_git_state_clean_and_uncommitted, test_read_state_shape,
        test_cli_field_and_json,
    ):
        t()
    total = len(PASSED) + len(FAILED)
    print()
    print(f"Result: {len(PASSED)}/{total} passed")
    for label, detail in FAILED:
        print(f"  - {label}: {detail}")
    return 0 if not FAILED else 1


if __name__ == "__main__":
    sys.exit(main())
