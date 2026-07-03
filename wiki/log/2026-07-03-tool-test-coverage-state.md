# Session log — tool-layer test coverage: tools.state (2026-07-03)

> Work-block under operator goal directive: *"continue maturing root-ghostproxy"*.
> Batched into the decisions coverage PR (branch
> `claude/ghostproxy-sovereign-os-prep-ole9ul`).

## Summary

Added `tools/tests/test-state.py` (14 assertions) — the fifth tool-layer
regression test — covering `tools/state.py`, the deterministic read-side
project-state aggregator (active-mode + git tree state + bootstrap presence +
second-brain reachability). It backs the root_state MCP tool, /audit step 6, and
is imported by tools.cycle. Its docstring named an unwritten test file AND
claimed transitive coverage via tools.cycle tests that don't exist — so it had
zero real coverage. Aggregate: **309/309 → 323/323 across 17 files** (12 hook +
5 tool).

## What it covers

In-process, repointing state.py's module globals (ACTIVE_MODE_PATH / ROOT /
BOOTSTRAP_PATH) at temp dirs — incl. a real throwaway `git init` repo for the
git-state branch — so the reader runs against controlled filesystem state, never
the live repo.

- **read_active_mode** — absent file → `(none)`; empty/whitespace → `(none)`;
  set value returned stripped.
- **read_git_state** — non-git dir → `("not-init", 0)`; fresh `git init` (no
  files) → `("clean", 0)`; an untracked file → `("uncommitted", count≥1)`. (No
  commit needed — `status --porcelain` alone drives all three, so no git
  user.name/email config dependency.)
- **read_state** — returns exactly the 5 documented fields; `bootstrap-exists`
  flips False→True with the file; `git-uncommitted` is an int.
- **CLI** — `--field <unknown>` → exit 1 with "unknown field"; `--field
  active-mode` → exit 0; `--json` emits valid JSON carrying all 5 keys.

## Verification (inline, per Hard Rule 1 / P4)

```
$ HOME=<repo> python3 -m tools.run-tests
  ✓ test-state.py                              14/ 14
  ... (17 files)
AGGREGATE: 323/323 PASS across 17 files
```

## Productive output

`verified-edit` — fifth tool-layer regression test (tools/tests/test-state.py, 14
assertions on the read-side state aggregator: active-mode / git-state / read_state
shape / CLI field+json), with a real temp git repo exercising the clean-vs-
uncommitted branch; suite green at 323/323 across 17 files. Counts refreshed
across CLAUDE.md / AGENTS.md / methodology.md / routing.md.

## Cross-references

- Added: `tools/tests/test-state.py`
- Tool under test: `tools/state.py` (read-side aggregator; backs root_state MCP + /audit step 6 + tools.cycle)
- Sibling increments: the four prior `wiki/log/2026-07-03-tool-test-coverage-*.md` +
  `2026-07-03-test-suite-hardening-and-count-drift-correction.md`
