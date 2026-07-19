---
title: "T020 — Wire validation pipeline (pre-commit hook OR CI workflow)"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m004-infrastructure-tooling"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 0
sfif_stage: Infrastructure
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m004-infrastructure-tooling.md
tags: [task, p0, t020, infrastructure, validation-pipeline, pre-commit, ci, m004]
---

# T020 — Wire validation pipeline

## Description

Run `verify-policy` automatically on relevant changes. Operator-decision: pre-commit hook (local-only, fast feedback) vs CI workflow (catches drift on every push, but requires GitHub remote) vs both.

## Done When

- [ ] Operator decides: pre-commit / CI / both.
- [ ] If pre-commit: `.pre-commit-config.yaml` authored at $HOME with verify-policy hook (e.g. `python3 -m tools.verify_policy --quick`).
- [ ] If CI: `.github/workflows/verify.yml` authored running verify-policy on push.
- [ ] If both: both files exist with consistent invariants.
- [ ] Failure of verify-policy blocks the commit (pre-commit) and the push (CI).
- [ ] Pipeline output is human-readable (not just exit codes).
- [ ] Operator bypass mechanism documented for legitimate emergencies (e.g. `--no-verify` with operator approval logged).

## Stage-gate

Implement stage: pipeline files authored + verified to fire. Test stage: deliberately failing input is caught + blocked.

## Dependencies

- T019 (verify-policy.py authored) ✓ when complete
- Operator decision (pre-commit / CI / both)
- (CI option only) GitHub remote configured for $HOME — currently `auto_connect: false` is the operator default; may not have a remote yet

## Relationships

- PART OF: [[root-modules-m004-infrastructure-tooling|M004]]
- BLOCKED BY: T019
- BLOCKS: T021 (smoke test exercises the pipeline), T023 (foundation re-gate)
