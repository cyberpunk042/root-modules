#!/usr/bin/env python3
"""uninstall.sh safety-contract test — scaffold-stage semantics that MUST hold.

uninstall.sh is the reverse-operation companion to install.sh. It is currently
at `0.0.1-scaffold` (per its own header, line 16: "CURRENT STAGE: scaffold —
operations are STUBS"). The per-op REMOVAL logic is NOT implemented — each
op_* function only emits `would:` lines under --dry-run or a `STUB: ... not
implemented` warning under a real run. It does NOT delete anything yet.

Therefore this test deliberately does NOT assert "uninstall reverses install"
(that behavior does not exist yet — asserting it would be a false green). What
IS implemented and IS load-bearing even in scaffold stage is the SAFETY
CONTRACT — the guards that prevent an accidental irreversible action and the
flag-surface argument contract. Those are what this locks:

  1. `--purge` without `--yes` ABORTS (exit 3) — the single most important
     safety guard: it prevents an irreversible outright-delete from running
     without explicit confirmation. This MUST hold at every stage.
  2. `--dry-run` makes NO state changes (a marker file in the target survives).
  3. `--purge --yes --dry-run` — the purge guard passes but --dry-run still
     touches nothing (marker survives). Confirms the dangerous combo is inert
     under dry-run.
  4. A REAL (non-dry) invocation against an isolated --dest is a NO-OP on files
     because the removal ops are stubs — it emits the honest `STUB: ... not
     implemented` warning and leaves the marker intact. This is the scaffold
     honesty assertion: the script says it isn't done and proves it by not
     deleting.
  5. Argument contract: --version prints the version (exit 0); --help shows the
     EXIT CODES section (exit 0); an unknown flag exits 1; an unknown profile
     exits 2.

All runs target a throwaway --dest, so nothing on the host is touched.

Known cosmetic quirk (surfaced, NOT asserted here): the final `done` line prints
"(dry-run; no state changes)" even on a real run, because line 287 uses
`${DRY_RUN:+...}` and DRY_RUN is "0" (non-empty) on real runs — the suffix
always expands. This is a display-only bug (parallels the install.sh
resolution-line quirk from PR #11); it does not affect the safety contract, so
this test does not use that line as a discriminator.

Exit codes: 0 all pass · 1 any fail.
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent.parent
UNINSTALL_SH = PROJECT_ROOT / "uninstall.sh"

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, cond: bool, detail: str = "") -> None:
    if cond:
        PASSED.append(label)
        print(f"  PASS {label}")
    else:
        FAILED.append((label, detail))
        print(f"  FAIL {label}" + (f" — {detail}" if detail else ""))


def run(*flags: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(UNINSTALL_SH), *flags],
        capture_output=True, text=True, cwd=str(PROJECT_ROOT), timeout=60,
    )


def seed_dest() -> tempfile.TemporaryDirectory:
    """A throwaway --dest with a marker file the uninstaller must not touch."""
    td = tempfile.TemporaryDirectory(prefix="uninstall-safety-")
    d = Path(td.name)
    (d / ".claude" / "hooks").mkdir(parents=True)
    (d / ".claude" / "hooks" / "marker.txt").write_text("MARKER-SURVIVES")
    return td


def marker_survives(dest: str) -> bool:
    p = Path(dest) / ".claude" / "hooks" / "marker.txt"
    return p.is_file() and p.read_text() == "MARKER-SURVIVES"


def main() -> int:
    print("=== uninstall.sh safety-contract test (scaffold stage) ===")

    if not UNINSTALL_SH.exists():
        check("uninstall.sh present", False, f"missing {UNINSTALL_SH}")
        print("Result: 0/1 passed")
        return 1
    check("uninstall.sh present", True)

    # 1. THE load-bearing safety guard: --purge without --yes aborts (exit 3).
    r = run("--purge")
    check("--purge without --yes aborts (exit 3)", r.returncode == 3, f"rc={r.returncode}")
    check("--purge abort states the irreversibility reason",
          "irreversible" in (r.stdout + r.stderr).lower(), (r.stdout + r.stderr)[-200:])

    # 2. --dry-run makes no state changes.
    with seed_dest() as dest:
        r = run("--dry-run", "--dest", dest)
        out = r.stdout + r.stderr
        check("--dry-run exits 0", r.returncode == 0, f"rc={r.returncode}")
        check("--dry-run emits 'would:' preview lines", "would:" in out)
        check("--dry-run makes no state changes (marker survives)", marker_survives(dest))

    # 3. --purge --yes --dry-run: guard passes, still inert under dry-run.
    with seed_dest() as dest:
        r = run("--purge", "--yes", "--dry-run", "--dest", dest)
        check("--purge --yes --dry-run does not abort (guard satisfied)", r.returncode == 0,
              f"rc={r.returncode}")
        check("--purge --yes --dry-run deletes nothing (marker survives)", marker_survives(dest))

    # 4. Scaffold honesty: a REAL run is a no-op on files (removal ops are stubs).
    with seed_dest() as dest:
        r = run("--dest", dest)
        out = r.stdout + r.stderr
        check("real run emits honest STUB warning (removal unimplemented)",
              "STUB" in out and "not implemented" in out, out[-200:])
        check("real run deletes nothing in scaffold stage (marker survives)", marker_survives(dest))

    # 5. Argument contract.
    r = run("--version")
    check("--version prints scaffold version (exit 0)",
          r.returncode == 0 and "0.0.1-scaffold" in (r.stdout + r.stderr),
          f"rc={r.returncode} out={(r.stdout + r.stderr).strip()!r}")

    r = run("--help")
    check("--help shows EXIT CODES section (exit 0)",
          r.returncode == 0 and "EXIT CODES" in (r.stdout + r.stderr), f"rc={r.returncode}")

    r = run("--bogus-flag")
    check("unknown flag exits 1", r.returncode == 1, f"rc={r.returncode}")

    with seed_dest() as dest:
        r = run("--profile", "bogus", "--dest", dest)
        check("unknown profile exits 2", r.returncode == 2, f"rc={r.returncode}")

    total = len(PASSED) + len(FAILED)
    print()
    print(f"Result: {len(PASSED)}/{total} passed")
    for label, detail in FAILED:
        print(f"  - {label}: {detail}")
    return 0 if not FAILED else 1


if __name__ == "__main__":
    sys.exit(main())
