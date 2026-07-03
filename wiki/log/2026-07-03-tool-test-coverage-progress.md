# Session log — tool-layer test coverage: tools.progress (2026-07-03)

> Work-block under operator goal directive: *"continue maturing root-ghostproxy"*.
> Branch `claude/ghostproxy-sovereign-os-prep-ole9ul`, restarted from `origin/main`
> after PR #8 merged. Eighth tool-layer regression test — and the natural
> closing increment of the clean-tool-coverage campaign (see "Boundary reached").

## Summary

Added `tools/tests/test-progress.py` (17 assertions) covering `tools/progress.py`
— the journey/progress computation behind `/progress`, `/sync-progress`,
`wiki/governance/progress.md`, and the `root_progress` MCP tool. Its
`compute_progress()` aggregates the backlog (module status/SFIF distributions,
task status counts, epic readiness) — where a silent regression would misreport
how far along the project is. Zero coverage until now. Aggregate: **366/366 →
383/383 across 20 files** (12 hook + 8 tool).

## What it covers — real aggregation, fixture-isolated

Unlike the config/state tools (HOME-isolated), progress.py resolves its globs
from repo-root-derived module globals. This test repoints
`MODULES_GLOB / TASKS_GLOB / LOG_GLOB / EPIC_PATH / ROOT` at a **fixture backlog
tree** (3 modules, 4 tasks, 1 epic, 2 logs) — so `compute_progress()` runs its
real aggregation against controlled inputs, never the live backlog:

- **parse_frontmatter_field** — value extraction, quote-stripping, missing-field
  → `''`, missing-file → `''`, no-frontmatter → `''`.
- **module aggregation** — total count; `by_status` distribution
  (`{done:1, in-progress:2}`); `by_sfif_stage` distribution
  (`{Scaffold:1, Foundation:2}`).
- **task aggregation** — total; `by_status` distribution
  (`{done:1, not-started:2, in-progress:1}`).
- **epic** — readiness + title surfaced from the epic page.
- **recent_logs** — lists the fixture log filenames.
- **recent_commits** — the non-git-fixture path returns the `(no git repo)`
  sentinel gracefully.
- **empty backlog** — modules/tasks total 0; no logs → empty list.

## Boundary reached — clean-tool-coverage campaign closing here

This is the eighth tool test and a deliberate closing point. The four remaining
untested tools are a genuine step-change in test cost / lower marginal value:
- `mcp_server.py` — needs the `mcp` Python package, which is **not installed in
  this environment** (import fails), so it can't be exercised here at all.
- `blockers.py` — `detect_drift()` couples to a hardcoded `BLOCKER_TO_TASK`
  mapping tied to specific real tasks; a meaningful test needs that plus a
  fixture governance doc.
- `cycle.py` — a 973-line orchestrator composing many of the above.
- (progress's own render/print paths are cosmetic; the compute path — the part
  that matters — is now covered.)

Pushing into those on autopilot risks shallow or brittle tests, which would
violate the project's own "synthetic tests are not real verification" principle.
The eight covered tools were the cleanly-isolatable, high-value core; each locked
a distinct silent-failure class (composition / index-arithmetic /
layer-independence / ID-collision / git-state / parsing / config-sanitization /
backlog-aggregation).

## Verification (inline, per Hard Rule 1 / P4)

```
$ HOME=<repo> python3 -m tools.run-tests
  ✓ test-progress.py                           17/ 17
  ... (20 files)
AGGREGATE: 383/383 PASS across 20 files
```

## Productive output

`verified-edit` — eighth (closing) tool-layer regression test
(tools/tests/test-progress.py, 17 assertions on compute_progress's backlog
aggregation, fixture-tree isolated); suite green at 383/383 across 20 files.
Counts refreshed across CLAUDE.md / AGENTS.md / methodology.md / routing.md.

## Cross-references

- Added: `tools/tests/test-progress.py`
- Tool under test: `tools/progress.py` (journey computation; backs /progress + /sync-progress + root_progress MCP)
- Campaign session logs: the seven prior `wiki/log/2026-07-03-tool-test-coverage-*.md` +
  `2026-07-03-test-suite-hardening-and-count-drift-correction.md`
