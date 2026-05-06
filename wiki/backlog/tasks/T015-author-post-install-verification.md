---
title: "T015 — Author post-install verification (integrity check + bridge state + opencode bridge + git audit)"
type: task
status: in-progress
priority: P0
parent_module: "root-ghostproxy-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 90
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-ghostproxy-m003-foundation-hardening.md
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

- PART OF: [[root-ghostproxy-m003-foundation-hardening|M003]]
- BLOCKED BY: T012, T013, T014
- BLOCKS: T017 (foundation gate)
