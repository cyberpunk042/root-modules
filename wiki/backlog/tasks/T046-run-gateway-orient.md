---
title: "T046 — Run `python3 -m tools.gateway orient` from inside $HOME, capture output"
type: task
status: not-started
priority: P0
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
tags: [task, p0, t046, stream-1, smoke-test, gateway-orient, m008]
---

# T046 — Gateway orient from $HOME

## Description

`python3 -m tools.gateway orient` (via the forwarder installed by M007) dispatches to the second brain's gateway with `--wiki-root $HOME`. The orient output should be context-aware: detects sister-project mode + fresh-mode + reports root-modules's identity.

## Done When

- [ ] `cd $HOME && python3 -m tools.gateway orient` exits 0.
- [ ] Output captured.
- [ ] Output mentions root-modules + type=root + group=operating-system-setup (per the identity profile in the second brain).
- [ ] Output is appropriate for sister-project context (not the second-brain's-own-orientation output).

## Dependencies

- T044 (fresh session)
- T040, T041 (forwarder installed)

## Relationships

- PART OF: [[root-modules-m008-smoke-test-from-inside|M008]]
- BLOCKED BY: T044, T041
- BLOCKS: T050
