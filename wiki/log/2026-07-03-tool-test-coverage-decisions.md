# Session log — tool-layer test coverage: tools.decisions (2026-07-03)

> Work-block under operator goal directive: *"continue maturing root-ghostproxy"*.
> Branch `claude/ghostproxy-sovereign-os-prep-ole9ul`, restarted from `origin/main`
> after PR #5 merged. Continues the verification-layer-reach theme, now reaching
> the GOVERNANCE tool layer.

## Summary

Added `tools/tests/test-decisions-tier3.py` (22 assertions) — the fourth
tool-layer regression test, and the first covering a **governance** tool.
`tools/decisions.py` parses the D### logbook, computes next IDs, extracts
entries, verifies ID-sequence integrity, and appends new entries. It backs 4
MCP tools (`root_decisions_*`) + the `/decisions` and `/audit` surfaces, so a
regex or ID-arithmetic regression would silently corrupt the decision audit
trail. Aggregate: **287/287 → 309/309 across 16 files** (12 hook + 4 tool).

## What it covers

Unlike the priorities/objective tests (subprocess + `HOME` isolation), this one
runs **in-process**: `decisions.py` resolves `DECISIONS_DOC` from the repo root
via `tools._paths` (no HOME/env override), so the test imports the module and
repoints the module-global `DECISIONS_DOC` at a temp fixture per case — the real
governance logbook is never read or written. This is the tier-3-style companion
named in decisions.py's own docstring.

- **parse_entries** — captures id/summary/date from the ENTRY_PATTERN regex;
  missing file and header-only both → `[]`.
- **next_id** — `D001` on empty; `max+1` not `count+1` (a gap like D001,D005 must
  yield D006, never reuse a number — the ID-collision guard).
- **get_entry** — returns the requested entry, does NOT bleed into the next one
  (the `(?=^### D\d+)` lookahead boundary); unknown id → `None`.
- **verify** — sequential → ok; a gap (D001,D003) → not-ok with a "sequential"
  issue; empty → not-ok.
- **append_entry** — inserts at `next_id()`, stamps today's date, preserves the
  operator-verbatim quote (sacrosanct-discipline field), is **newest-first**
  (new entry before the pre-existing one), and the result re-parses as
  sequential. Guards: missing insertion marker → rc 1 with **no mutation**;
  missing file → rc 1.

The append test writes only to a temp fixture, so the operator-gated
governance-write path is exercised safely.

## Verification (inline, per Hard Rule 1 / P4)

```
$ HOME=<repo> python3 -m tools.run-tests
  ✓ test-decisions-tier3.py                    22/ 22
  ... (16 files)
AGGREGATE: 309/309 PASS across 16 files
```

## Productive output

`verified-edit` — fourth tool-layer regression test (tools/tests/test-decisions-tier3.py,
22 assertions on the governance logbook: parse / next-id / get / verify / append,
incl. the max-not-count ID guard, the get-entry boundary, and the append newest-first +
no-mutation-on-guard-failure invariants); suite green at 309/309 across 16 files.
Counts refreshed across CLAUDE.md / AGENTS.md / methodology.md / routing.md.

## Cross-references

- Added: `tools/tests/test-decisions-tier3.py`
- Tool under test: `tools/decisions.py` (governance logbook; backs root_decisions_* MCP + /decisions + /audit)
- Sibling increments: `wiki/log/2026-07-03-tool-test-coverage-priorities.md`, `-objective.md`,
  `2026-07-03-test-suite-hardening-and-count-drift-correction.md`
- Sacrosanct discipline the append field enforces: `.claude/rules/words-are-sacrosanct.md`
