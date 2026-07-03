# Session log — uninstall.sh safety-contract test (2026-07-03)

> Work-block under operator goal directive: *"continue maturing root-ghostproxy"*.
> Branch `claude/ghostproxy-sovereign-os-prep-ole9ul`, restarted from `origin/main`
> after PR #12 merged. Third increment on the foundation-script seam — the
> reverse-operation surface (uninstall.sh), previously untested.

## Summary

Added `.claude/hooks/tests/test-uninstall-safety-contract.py` (14 assertions)
locking the **testable safety contract** of `uninstall.sh` — the reverse-operation
companion to install.sh. Aggregate: **411/411 → 425/425 across 24 files**
(16 hook + 8 tool). All runs target a throwaway `--dest`; no host state touched.

## Why this shape, and what it deliberately does NOT assert

`uninstall.sh` is at `0.0.1-scaffold` (its own header line 16: *"CURRENT STAGE:
scaffold — operations are STUBS"*). The per-op REMOVAL logic is unimplemented —
each `op_uninstall_*` emits `would:` under `--dry-run` or a `STUB: ... not
implemented` warning on a real run, and deletes nothing.

So the test deliberately does **not** assert "uninstall reverses install" — that
behavior does not exist yet, and asserting it would be a false green (the exact
"synthetic-as-verified" failure mode the project's work-mode rule forbids). What
IS implemented and IS load-bearing even in scaffold stage is the **safety
contract**, which is what this locks:

- **`--purge` without `--yes` aborts (exit 3)** — the single most important
  guard: it stops an irreversible outright-delete from running without explicit
  confirmation. Must hold at every stage.
- **`--dry-run` makes no state changes** — a marker file in the target survives.
- **`--purge --yes --dry-run`** — guard passes but dry-run is still inert (marker
  survives); the dangerous combo is proven harmless under dry-run.
- **Scaffold honesty** — a real (non-dry) invocation is a no-op on files because
  removal ops are stubs: it emits the honest `STUB: ... not implemented` warning
  and leaves the marker intact. The test both proves the no-op AND documents in
  its docstring that removal is unimplemented, so no reader mistakes it for a
  working uninstall.
- **Argument contract** — `--version` → `0.0.1-scaffold` (exit 0); `--help` shows
  the EXIT CODES section (exit 0); unknown flag → exit 1; unknown profile → exit 2.

## Finding surfaced (not fixed — foundation-touching, cosmetic)

`uninstall.sh:287` — `log_info "${SCRIPT_NAME} done${DRY_RUN:+ (dry-run; no state
changes)}"`. `${DRY_RUN:+...}` expands whenever `DRY_RUN` is non-empty, and
`DRY_RUN` is always `"0"` or `"1"` (both non-empty). So the `(dry-run; no state
changes)` suffix prints on **every** run, including real ones — a display-only
bug (the empirical probe showed it on a non-dry invocation). This is the direct
cousin of the install.sh resolution-line quirk flagged in PR #11: a diagnostic
line that misreports, with no effect on the actual behavior. I did NOT fix
uninstall.sh (foundation code; a fix leans propose→approve). Because the line is
unreliable, the test does not use it as a discriminator — it asserts on the
marker-survives invariant + the STUB warning instead. Flagged for the operator:
changing line 287 to `[[ "${DRY_RUN}" -eq 1 ]] && suffix=" (dry-run; no state
changes)"` (or `${DRY_RUN/0/}` guard) would make the diagnostic accurate — a
small, safe follow-up, same family as the PR #11 flag.

## Verification (inline, per Hard Rule 1 / P4)

```
$ python3 .claude/hooks/tests/test-uninstall-safety-contract.py
  ... 14 assertions ...
  Result: 14/14 passed

$ HOME=<repo> python3 -m tools.run-tests
  ✓ test-uninstall-safety-contract.py         14/ 14
  ... (24 files)
AGGREGATE: 425/425 PASS across 24 files
```

Empirical split: `ls .claude/hooks/tests/test-*.py | wc -l` = 16;
`ls tools/tests/test-*.py | wc -l` = 8.

## Productive output

`verified-edit` — uninstall.sh scaffold-stage safety-contract test
(.claude/hooks/tests/test-uninstall-safety-contract.py, 14 assertions, all
against a throwaway `--dest`), locking the purge-requires-`--yes` guard +
dry-run no-op + scaffold-honesty (removal ops stubbed, no deletion) without
falsely asserting uninstall reverses install; suite green at 425/425 across 24
files. Surfaced a cosmetic `${DRY_RUN:+...}` "done (dry-run)" misreport on real
runs (not fixed — foundation-touching, flagged for operator, cousin to the
PR #11 install.sh flag). Counts refreshed across CLAUDE.md / AGENTS.md /
methodology.md / routing.md.

## Cross-references

- Added: `.claude/hooks/tests/test-uninstall-safety-contract.py`
- Script under test: `uninstall.sh` (M003 Foundation; reverse-operation companion, scaffold stage)
- Sibling foundation smoke tests: `.claude/hooks/tests/test-t014-endpoint-safety-smoke.py`,
  `test-t015-op-verify-smoke.py`, `test-t016-idempotency-smoke.py`,
  `test-install-composition.py`, `test-install-check-drift.py`
- Prior cosmetic-diagnostic flag of the same family: install.sh resolution-line quirk (PR #11)
