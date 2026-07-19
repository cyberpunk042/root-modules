---
title: "T038 — Read tools/setup.py --connect-project implementation (already done in M006 T034)"
type: task
status: done
priority: P0
parent_module: "root-modules-m007-connect-second-brain"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 100
sfif_stage: Stream-1-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m007-connect-second-brain.md
  - id: m006-task
    type: wiki
    file: wiki/backlog/tasks/T034-read-tools-setup-py-collision-behavior.md
tags: [task, p0, t038, stream-1, connect, code-review, done, m007]
---

# T038 — Read tools/setup.py implementation

## Description

Read `tools/setup.py:370-639` (`connect_second_brain` + helpers) before running --connect-project for real. Already completed in M006 task T034.

## Resolution

Done 2026-05-04. Behavior documented in M007 module page § "Verified behavior" + T034.

## Relationships

- PART OF: [[root-modules-m007-connect-second-brain|M007]]
- DUPLICATE OF: [[T034-read-tools-setup-py-collision-behavior|T034]] (kept as separate task page for module-traceability; status=done since same work)
