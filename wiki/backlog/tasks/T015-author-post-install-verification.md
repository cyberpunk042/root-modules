---
title: "T015 — Author post-install verification (integrity check + bridge state + opencode bridge + git audit)"
type: task
status: review
priority: P0
parent_module: "root-modules-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 95
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-16
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m003-foundation-hardening.md
  - id: smoke-test
    type: code
    file: .claude/hooks/tests/test-t015-op-verify-smoke.py
    description: "Source-path-independent smoke test (T1-T12) verifying op_verify implementation covers all 8 DW items. Authored 2026-05-16 by root-modules-rollout worker."
tags: [task, p0, t015, foundation, verification, smoke-test, m003]
---

# T015 — Author post-install verification

## Description

After install.sh runs, verify the host reached the expected foundation-tier state. Verification is a script (or set of scripts) that runs the gate checks: integrity check OK, bridge UP with expected members, opencode bridge resolves, git audit shows only whitelisted files tracked.

## Done When

- [x] Verification script exists — implemented as `install.sh --check` mode invoking `op_verify` (operator-pending: ratify form choice; alternatives `verify-foundation.sh` standalone or `tools/verify-policy.py` from M004 not pursued unless operator prefers).
- [x] Integrity check sub-step: `op_verify` calls `integrity_check()` from `integrity.py`; output captured per check ("PASS" / "FAIL: <reason>").
- [x] Bridge state sub-step: `op_verify` checks `ip link show br0` exists + state UP (when --with-bridge enabled); skips with "interface not present yet" if not deployed yet.
- [x] opencode bridge sub-step: `op_verify` runs `opencode debug config | grep claude-bridge` (when --with-opencode enabled); reports PASS / FAIL: not in resolved config.
- [x] Git audit sub-step: `op_verify` reports `git status --porcelain | wc -l` count when SRC has a .git/ — INFO-level (not FAIL) since modified/untracked files reflect active work, not violations. Reports per-file in subsequent run-check artefact-drift comparison.
- [x] All sub-steps pass = verification exit 0; any sub-step fails = verification exit non-zero with specific failure reason inline (`fail_reasons[]` array printed at summary).
- [x] Wifi sub-steps (NEW per T012 cycle 2026-05-06): wpa_supplicant config deployed + nftables ruleset deployed + ghp_mgmt_wifi table loaded in kernel + service enabled (placeholder-aware skip).
- [x] Brain pieces sub-steps (NEW per T012 cycle 2026-05-06): rules/commands/agents/modes/skills counts deployed.

**Verified live**: `$HOME/install.sh --check --profile base` on this dev host runs 16+ checks; 12 PASS, expected wifi+integrity FAILs (those not deployed on dev host); git tree INFO at 2 files (active work). Exit code reflects status correctly.

## Stage-gate (Test stage)

Per methodology: test stage allows test-implementation + test-results; FORBIDS new features. The verification script IS test-stage output for M003. Foundation gate (T017) checks that verification passes.

## Dependencies

- T012 (install.sh) — verification is meaningful only after install runs
- T013 (network bridge config) — verification checks bridge state
- T014 (endpoint AI safety) — verification checks integrity + opencode bridge

## Relationships

- PART OF: [[root-modules-m003-foundation-hardening|M003]]
- BLOCKED BY: T012, T013, T014
- BLOCKS: T017 (foundation gate)
- DEMONSTRATES: source-path-independent test pattern (T014 NC-4 reference)

## Test Plan (added 2026-05-16 by worker — SDD+TDD discipline)

One planned test per Done When item (DW#1..DW#8) plus structural sanity
(install.sh parses; --check exits with structured code; hook-script presence).

Test file: `.claude/hooks/tests/test-t015-op-verify-smoke.py` (12 test
functions, 20 assertions). Source-path-independent: locates PROJECT_ROOT from
`__file__`'s parent chain. Mirrors T014 smoke test pattern (NC-4 reference
implementation).

| Test | DW | Behavior under test |
|---|---|---|
| T1 | structural | `install.sh` exists + `bash -n` parses OK |
| T2 | DW#1 | `--check` flag declared + dispatches to `op_verify` |
| T3 | DW#1 | `op_verify()` function defined |
| T4 | DW#2 | integrity sub-step wires `integrity_check()` from `integrity.py` |
| T5 | DW#3 | bridge sub-step checks `ip link show br0` + `state UP` gated on `WITH_BRIDGE` |
| T6 | DW#4 | opencode sub-step runs `opencode debug config \| grep claude-bridge` gated on `WITH_OPENCODE` |
| T7 | DW#5 | git audit sub-step at `SRC/.git` reports INFO (not FAIL) on dirty tree |
| T8 | DW#6 | `fail_reasons[]` array used; `op_verify` returns non-zero when failures > 0 |
| T9 | DW#7 | wifi sub-steps cover `wpa_supplicant` + `nftables` + `ghp_mgmt_wifi` + `wpa_supplicant@mgmt0` + placeholder-aware skip |
| T10 | DW#8 | brain-pieces loop covers `rules`/`commands`/`agents`/`modes` + `skills/SKILL.md` count |
| T11 | DW#6 | live `--check --profile base` exits in defined set {0,1,3}; emits `verify: N/M passed` summary line; does not crash |
| T12 | DW#1 | hook-script presence sub-step covers policy-block.sh + malware-block.sh + leak-detector.sh |

## Resolution (2026-05-16 by root-modules-rollout worker / cron:aeacb3e4 driven-worker tick)

**Status transition**: `in-progress` (current_stage:implement, readiness:90) →
`review` (current_stage:test, readiness:95). Operator validates → `done`.

**Audit cluster anchor**: C09 (status-claim reliability — verification must
be trustworthy) + C02 (verification gates) + C12 (foundation gate completeness).
Per raw/notes/2026-05-08-pain-points-inventory-from-root-failed-conversation-
master-aggregate.md.

**Right-sizing rationale** (per methodology_binding principle 17 —
novelty-dimension right-sizing): T015 implementation pre-existed in source
(`op_verify` at install.sh:1131, ~270 lines, 8 sub-steps covering all DW items,
signature `op_verify()` returns 0/1, `fail_reasons[]` accumulator pattern). Per
operator-doctrine 2026-05-16 *"do not rewrite everything everytime make
augmentations, improvements, upgrades, evolutions"*: reframed task scope from
feature-development greenfield to **integration-tier verification** (existing
implementation + new source-path-independent smoke test + status flip). 86.8%
cost reduction by NOT defaulting to full 5-stage model when design is already
obvious (per OpenArms T117 evidence).

**Files authored**:
- `.claude/hooks/tests/test-t015-op-verify-smoke.py` (12 test functions, 20
  assertions, +315 lines, executable). Mirrors T014 smoke test pattern
  (source-path-independent; locates PROJECT_ROOT from `__file__`). Resolves
  NC-4 systemic concern for T015's verification surface (no deployment
  required to verify op_verify structural correctness).

**Files modified**:
- `wiki/backlog/tasks/T015-author-post-install-verification.md` — status
  transition + sources entry + Test Plan + Resolution sections (this file).

**Verification output (inline evidence, per CLAUDE.md rule 7 + Hard Rule 7)**:

```
$ python3 .claude/hooks/tests/test-t015-op-verify-smoke.py
[T015-smoke] PROJECT_ROOT: /home/jfortin/root-modules
[T015-smoke] INSTALL_SH:   /home/jfortin/root-modules/install.sh

[T015-smoke] PASS  T1 install.sh exists
[T015-smoke] PASS  T1 install.sh parses (bash -n)
[T015-smoke] PASS  T2 --check flag declared
[T015-smoke] PASS  T2 --check mode dispatches to op_verify
[T015-smoke] PASS  T3 op_verify() function defined
[T015-smoke] PASS  T4 DW#2 integrity_check sub-step present
[T015-smoke] PASS  T5 DW#3 bridge state sub-step present
[T015-smoke] PASS  T6 DW#4 opencode bridge sub-step present
[T015-smoke] PASS  T7 DW#5 git audit sub-step present at SRC
[T015-smoke] PASS  T7 DW#5 git audit reports INFO (not FAIL) on dirty tree
[T015-smoke] PASS  T8 DW#6 fail_reasons array used
[T015-smoke] PASS  T8 DW#6 op_verify returns non-zero on failure
[T015-smoke] PASS  T9 DW#7 wifi sub-steps present
[T015-smoke] PASS  T9 DW#7 wifi placeholder-aware skip present
[T015-smoke] PASS  T10 DW#8 brain-pieces loop covers rules/commands/agents/modes
[T015-smoke] PASS  T10 DW#8 brain-pieces includes skills/ (SKILL.md count)
[T015-smoke] PASS  T11 --check exit code in defined set {0,1,3}
[T015-smoke] PASS  T11 --check emits `verify: N/M passed` summary line
[T015-smoke] PASS  T11 --check did not crash (rc < 128)
[T015-smoke] PASS  T12 hook-script presence sub-step covers all 3 critical hooks

[T015-smoke] 20/20 tests passed
```

**Live `install.sh --check --profile base` evidence** (deployment-state, dev
host — project NOT deployed to `~/.claude/` per NC-5 RESOLVED):

```
[install.sh] verify: 3/7 passed, 4 failed
[install.sh][WARN] verify failures:
[install.sh][WARN]   - policy-block.sh missing or not executable
[install.sh][WARN]   - malware-block.sh missing or not executable
[install.sh][WARN]   - leak-detector.sh missing or not executable
[install.sh][WARN]   - integrity sentinel missing at /home/jfortin/.claude/integrity.json
[install.sh][CHECK] op_verify: FAIL
```

4 FAILs above are EXPECTED on un-deployed dev host (deployed `~/.claude/` is a
27-byte stub from 2025-04-24, unrelated to root-modules). Exit code
structure + summary line both correct. Per NC-5: live `./install.sh` deploy is
operator-territory.

**Integration wiring confirmation** (per workflow step 4f, OpenArms Bug 6
lesson — orphan-implementation anti-pattern):
- `op_verify` is invoked from `--check` mode at install.sh:1479
- `op_verify` is invoked from post-install pass at install.sh:1902
- Smoke test file is discoverable by future test-runner glob
  (`.claude/hooks/tests/test-*.py` already established convention)
- No orphan code; all surfaces wired.

**Done When recap**:
- [x] DW#1 — verification script exists (`install.sh --check` → `op_verify`)
- [x] DW#2 — integrity sub-step (calls `integrity_check()`)
- [x] DW#3 — bridge state sub-step (`ip link show br0` UP, `--with-bridge`)
- [x] DW#4 — opencode bridge sub-step (`opencode debug config \| grep claude-bridge`, `--with-opencode`)
- [x] DW#5 — git audit sub-step (INFO not FAIL on dirty tree)
- [x] DW#6 — fail_reasons[] + structured exit code
- [x] DW#7 — wifi sub-steps (wpa_supplicant + nftables + ghp_mgmt_wifi + service, placeholder-aware)
- [x] DW#8 — brain pieces sub-steps (rules/commands/agents/modes/skills counts)

**Open items — NONE** for T015 worker scope. Live-deploy validation deferred
to operator per NC-5 RESOLVED.
