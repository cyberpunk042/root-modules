# Session log — install.sh composition test (2026-07-03)

> Work-block under operator goal directive: *"continue maturing root-ghostproxy"*.
> Branch `claude/ghostproxy-sovereign-os-prep-ole9ul`, restarted from `origin/main`
> after PR #10 merged. Second increment on the install.sh behavioral seam.

## Summary

Added `.claude/hooks/tests/test-install-composition.py` (11 assertions) locking
install.sh's **scope-composition matrix**: `--profile` × `--mode` × granular
`--with-group`/`--no-group`. This is the exact logic the sovereign-os SDD-046
endpoint binding and every per-project deploy rely on, and only the endpoint
slice was covered before (test-sovereign-endpoint-mode.py). Aggregate: **392/392
→ 403/403 across 22 files** (14 hook + 8 tool). All runs are `--dry-run` into a
throwaway `--dest` — no state touched.

## What it locks

The composition rule is *"an op is installed iff (profile says yes) AND
(mode_includes(op))"*, granular flags overriding.

- **profile axis** (mode=endpoint): base = hooks+integrity+tools, ccstatusline
  OFF; full = base + ccstatusline (Features tier); project disables OS-level ops
  (opencode + integrity OFF) while keeping brain + tools.
- **mode axis** (profile=base): endpoint gates bridge + wifi OFF; bridge gates
  them ON.
- **op-application authority**: project → `skip: opencode bridge` +
  `skip: integrity sentinel`; full deploys substantially more ccstatusline lines
  than base; `--no-group wifi` actually skips the wifi op even in bridge mode.
- every dry-run ends with the `dry-run; no state changes` footer.

## Finding surfaced (not fixed — foundation-touching, cosmetic)

The resolution diagnostic line `profile=X mode=Y → ... wifi=N ...` is printed in
`apply_profile()` (install.sh:421) **before** the granular `--with-group` /
`--no-group` selection is applied (~install.sh:1639). So with `--no-group wifi`
in bridge mode, the line shows `wifi=1` even though the wifi op is correctly
skipped. This is a **display quirk, not a functional bug** — the op-application
is correct (`skip: management wifi` fires). I did NOT fix install.sh (foundation
code; the line is a cosmetic diagnostic, and a fix leans propose→approve). The
test asserts the op-application authority (the skip line), not the pre-granular
resolution line, and documents this in its own docstring. Flagged here for the
operator: if desired, re-printing the resolution line after granular selection
(or moving it) would make the diagnostic accurate — a small, safe follow-up.

## Verification (inline, per Hard Rule 1 / P4)

```
$ python3 .claude/hooks/tests/test-install-composition.py
  ... 11 assertions ...
  Result: 11/11 passed

$ HOME=<repo> python3 -m tools.run-tests
  ✓ test-install-composition.py               11/ 11
  ... (22 files)
AGGREGATE: 403/403 PASS across 22 files
```

## Productive output

`verified-edit` — install.sh profile×mode×granular composition test
(.claude/hooks/tests/test-install-composition.py, 11 assertions, all dry-run),
locking the scope-resolution the sovereign-os binding + per-project deploys
depend on; suite green at 403/403 across 22 files. Surfaced a cosmetic
resolution-line-vs-granular display quirk (not fixed — foundation-touching,
flagged for operator). Counts refreshed across CLAUDE.md / AGENTS.md /
methodology.md / routing.md.

## Cross-references

- Added: `.claude/hooks/tests/test-install-composition.py`
- Installer under test: `install.sh` (M003 Foundation; profile/mode/granular composition)
- Complements: `.claude/hooks/tests/test-sovereign-endpoint-mode.py` (endpoint slice),
  `test-t014/t015/t016` (safety / op_verify / idempotency)
- Consumer that depends on this logic: `cyberpunk042/sovereign-os` SDD-046 endpoint binding
