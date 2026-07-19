---
title: "T047 — Run `python3 -m tools.view spine` from inside $HOME, capture output"
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
tags: [task, p0, t047, stream-1, smoke-test, view-spine, m008]
---

# T047 — view spine from $HOME

## Description

`python3 -m tools.view spine` (via forwarder) dispatches to the second brain's view tool. Should print the second brain's spine: 16 models + 5 sub-models + 25 standards + paths.

## Done When

- [ ] `cd $HOME && python3 -m tools.view spine` exits 0.
- [ ] Output includes the 16 named models with summaries.
- [ ] Output is the second brain's spine, not an empty/error response.

## Dependencies

- T044, T041 (forwarder + session)

## Relationships

- PART OF: [[root-modules-m008-smoke-test-from-inside|M008]]
- BLOCKED BY: T044, T041
- BLOCKS: T050
