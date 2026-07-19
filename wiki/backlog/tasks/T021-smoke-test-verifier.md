---
title: "T021 — Smoke-test verify-policy: known-good passes; deliberate degradation fails"
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
tags: [task, p0, t021, infrastructure, smoke-test, m004]
---

# T021 — Smoke-test verify-policy

## Description

Verify the verifier itself works — both happy path (known-good state passes) and failure paths (deliberate degradation is caught with specific reason).

## Done When

- [ ] Known-good state: post-install host with valid policy → `python3 -m tools.verify_policy` exits 0 with all-pass output.
- [ ] Failure path 1: temporarily remove a hook script (rename) → verifier exits non-zero, names the missing hook in output. Restore.
- [ ] Failure path 2: temporarily edit settings.json to set `disableAllHooks: true` → verifier exits non-zero, says hooks disabled. Restore.
- [ ] Failure path 3: temporarily remove ~5 deny-set patterns to drop count below threshold → verifier exits non-zero, names threshold + actual count. Restore.
- [ ] Failure path 4: temporarily make a hook script non-executable (chmod 0644) → verifier exits non-zero, names the non-executable hook. Restore.
- [ ] Smoke test results captured in $HOME/wiki/log/<date>-verify-policy-smoke-test.md.
- [ ] After all failure paths: known-good state restored; final verify-policy run exits 0.

## Stage-gate

Test stage: 0 test failures in the smoke test (all expected behaviors confirmed). Failure paths must each be caught + reported with the right reason.

## Dependencies

- T019 (verifier authored) ✓ when complete

## Relationships

- PART OF: [[root-modules-m004-infrastructure-tooling|M004]]
- BLOCKED BY: T019
- BLOCKS: T023 (foundation re-gate)
