#!/usr/bin/env python3
"""Regression tests for tools/decisions.py — the governance decisions logbook.

decisions.py parses D### entries from wiki/governance/decisions.md, computes the
next sequential ID, extracts single entries, verifies ID-sequence integrity, and
appends new entries (operator-gated). It backs 4 MCP tools (root_decisions_*) and
the /decisions + /audit surfaces, so a regression in its regex parsing or ID
arithmetic would silently corrupt the audit trail or mis-number a decision.

Isolation: decisions.py resolves DECISIONS_DOC from the repo root (via
tools._paths, no HOME/env override), so these run IN-PROCESS and repoint the
module-global `tools.decisions.DECISIONS_DOC` at a temp fixture per test — the
real governance logbook is never read or written.

This is the tier-3-style companion test named in tools/decisions.py's own
docstring (tools/tests/test-decisions-tier3.py). Emits the canonical
`Result: N/M passed` line consumed by tools.run-tests. Exit 0 iff all pass.
"""
from __future__ import annotations

import sys
import tempfile
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import tools.decisions as dec  # noqa: E402

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, cond: bool, detail: str = "") -> None:
    if cond:
        PASSED.append(label)
        print(f"  PASS {label}")
    else:
        FAILED.append((label, detail))
        print(f"  FAIL {label}" + (f" — {detail}" if detail else ""))


HEADER = "# Decisions logbook\n\n## Decisions made (chronological, newest first)\n\n---\n\n"


def entry(did: str, summary: str, day: str) -> str:
    return (
        f"### {did} — {summary}\n\n"
        f"- **Date**: {day}\n"
        f"- **Decision**: {summary}\n"
        f"- **Operator's verbatim**: *\"do the thing\"*\n"
        f"- **Rationale**: because\n\n---\n\n"
    )


def fixture(*entries: str) -> Path:
    d = Path(tempfile.mkdtemp(prefix="decisions-test-"))
    f = d / "decisions.md"
    f.write_text(HEADER + "".join(entries))
    return f


def use(path: Path) -> None:
    dec.DECISIONS_DOC = path  # repoint module global; functions read it at call time


def test_parse_entries() -> None:
    use(fixture(entry("D001", "first", "2026-05-01"),
               entry("D002", "second one", "2026-05-02")))
    entries = dec.parse_entries()
    check("parse finds all entries", len(entries) == 2)
    check("parse captures id + summary + date",
          entries[0] == {"id": "D001", "summary": "first", "date": "2026-05-01"}
          and entries[1]["summary"] == "second one")


def test_parse_empty_and_missing() -> None:
    use(Path(tempfile.mkdtemp(prefix="decisions-test-")) / "nonexistent.md")
    check("parse missing file → []", dec.parse_entries() == [])
    use(fixture())  # header only, no entries
    check("parse header-only → []", dec.parse_entries() == [])


def test_next_id() -> None:
    use(fixture())
    check("next-id on empty → D001", dec.next_id() == "D001")
    use(fixture(entry("D001", "a", "2026-05-01"), entry("D002", "b", "2026-05-02")))
    check("next-id after D002 → D003", dec.next_id() == "D003")
    # next_id uses max, not count — a gap must not fool it into reusing an ID.
    use(fixture(entry("D001", "a", "2026-05-01"), entry("D005", "e", "2026-05-05")))
    check("next-id uses max (D005) not count → D006", dec.next_id() == "D006")


def test_get_entry() -> None:
    use(fixture(entry("D001", "first", "2026-05-01"),
               entry("D002", "second", "2026-05-02")))
    body = dec.get_entry("D002")
    check("get returns the requested entry", body is not None and body.startswith("### D002 — second"))
    check("get does not bleed into the next entry", body is not None and "D001" not in body)
    check("get unknown id → None", dec.get_entry("D099") is None)


def test_verify() -> None:
    use(fixture(entry("D001", "a", "2026-05-01"), entry("D002", "b", "2026-05-02")))
    r = dec.verify()
    check("verify sequential → ok", r["ok"] is True and r["entries"] == 2 and r["issues"] == [])
    use(fixture(entry("D001", "a", "2026-05-01"), entry("D003", "c", "2026-05-03")))
    r2 = dec.verify()
    check("verify gap (D001,D003) → not ok", r2["ok"] is False and any("sequential" in i for i in r2["issues"]))
    use(fixture())
    check("verify empty → not ok with 'no entries'", dec.verify()["ok"] is False)


def test_append_entry() -> None:
    f = fixture(entry("D001", "first", "2026-05-01"))
    use(f)

    class Args:
        decision = "chose X"
        verbatim = "go with X"
        rationale = "cleanest"
        affected = "T001"
        reversibility = "fully-reversible"
        downstream = "unblocks Y"
        linked_blocker = "B001"

    rc = dec.append_entry(Args())
    check("append rc 0", rc == 0)
    content = f.read_text()
    check("append inserts D002 (next-id)", "### D002 — chose X" in content)
    check("append preserves operator verbatim quote", '*"go with X"*' in content)
    check("append stamps today's date", f"- **Date**: {date.today().isoformat()}" in content)
    # newest-first: the new D002 must appear BEFORE the pre-existing D001.
    check("append is newest-first (D002 before D001)", content.index("### D002") < content.index("### D001"))
    # and it must be re-parseable + still sequential.
    check("appended doc re-parses to 2 sequential entries", dec.verify()["ok"] is True and dec.verify()["entries"] == 2)


def test_append_guards() -> None:
    # Missing insertion marker → rc 1, no write.
    d = Path(tempfile.mkdtemp(prefix="decisions-test-"))
    nomarker = d / "decisions.md"
    nomarker.write_text("# Decisions\n\n" + entry("D001", "a", "2026-05-01"))
    use(nomarker)

    class Args:
        decision = decision = "x"; verbatim = "x"; rationale = "x"; affected = "x"
        reversibility = "fully-reversible"; downstream = "x"; linked_blocker = ""

    before = nomarker.read_text()
    check("append without marker → rc 1", dec.append_entry(Args()) == 1)
    check("append without marker does not mutate", nomarker.read_text() == before)
    # Missing file → rc 1.
    use(d / "gone.md")
    check("append on missing file → rc 1", dec.append_entry(Args()) == 1)


def main() -> int:
    print("=== tools.decisions (tier-3) regression tests ===")
    for t in (
        test_parse_entries, test_parse_empty_and_missing, test_next_id,
        test_get_entry, test_verify, test_append_entry, test_append_guards,
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
