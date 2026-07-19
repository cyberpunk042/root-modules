---
title: "T049 — Test failure mode: second brain unreachable, verify clear error"
type: task
status: not-started
priority: P1
parent_module: "root-modules-m008-smoke-test-from-inside"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Verify
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m008-smoke-test-from-inside.md
tags: [task, p1, t049, stream-1, smoke-test, failure-mode, m008]
---

# T049 — Test failure mode (second brain unreachable)

## Description

If `/opt/devops-solutions-information-hub` becomes unreachable (e.g. unmounted on a host change), the forwarders should fail with a clear error message rather than silently hanging or crashing.

## Done When

- [ ] Temporarily make `/opt/devops-solutions-information-hub` unreachable (e.g. `sudo mv` to a backup path; on a multi-host setup, simulate by stopping the second brain's services).
- [ ] Run `python3 -m tools.gateway orient` from $HOME.
- [ ] Verify: forwarder fails with FileNotFoundError or operator-friendly error; not silent hang or cryptic crash.
- [ ] Restore reachability.
- [ ] Re-run gateway orient → succeeds again.
- [ ] Failure mode test results captured in `$HOME/wiki/log/<date>-m008-failure-mode-test.md`.
- [ ] If error message is unclear / hangs / cryptic: file a setup.py improvement task.

## Dependencies

- T044, T041

## Relationships

- PART OF: [[root-modules-m008-smoke-test-from-inside|M008]]
- BLOCKED BY: T044, T041
