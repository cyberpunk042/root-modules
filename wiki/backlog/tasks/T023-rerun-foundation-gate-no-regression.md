---
title: "T023 — Re-run M003 Foundation gate to confirm no regression after Infrastructure tooling lands"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m004-infrastructure-tooling"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Infrastructure
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m004-infrastructure-tooling.md
  - id: m003-task
    type: wiki
    file: wiki/backlog/tasks/T017-foundation-gate-verification.md
tags: [task, p0, t023, infrastructure, regression-check, foundation-gate, m004]
---

# T023 — Re-run M003 Foundation gate (no-regression check)

## Description

After M004's verify-policy.py + validation pipeline land, the Foundation tier (M003) must still pass its gate. Adding Infrastructure tooling cannot regress Foundation. This task re-runs the M003 gate as the no-regression check.

## Done When

- [ ] All M003 gate sub-steps still green: install.sh --dry-run clean / install.sh --check / integrity sentinel OK / bridge state UP / opencode bridge resolved / git audit clean.
- [ ] Smoke test of safety policy still passes (per T017).
- [ ] verify-policy itself exits 0 on the post-M004 state.
- [ ] Idempotency confirmed: re-running install.sh after M004 lands is no-op.
- [ ] Re-gate report at $HOME/wiki/log/<date>-m004-no-regression-report.md.

## Stage-gate (M004 Test stage exit)

Passing this task marks M004 module complete. Module readiness reaches 100. Adding Infrastructure tooling did not regress Foundation.

## Dependencies

- T019 (verifier exists)
- T020 (validation pipeline wired)
- T021 (smoke-tested)
- T022 (documented in CLAUDE.md)
- T017 (M003 Foundation gate already passed)

## Relationships

- PART OF: [[root-modules-m004-infrastructure-tooling|M004]]
- BLOCKED BY: T019, T020, T021, T022, T017
- ENABLES: M005 (first feature module — gated on Foundation + Infrastructure both green)
