---
title: "T045 — Time-to-orient: agent reads context + orients within 60 seconds"
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
tags: [task, p0, t045, stream-1, smoke-test, time-to-orient, m008]
---

# T045 — Time-to-orient ≤ 60 seconds

## Description

Per the parent epic's cross-cutting verification: a fresh Claude Code session opened in $HOME must orient itself within 60 seconds via CLAUDE.md + gateway orient — no manual intervention.

## Done When

- [ ] Stopwatch starts when fresh session opens.
- [ ] Within 60 seconds: agent has read $HOME/CLAUDE.md, run `python3 -m tools.gateway orient`, and reported valid orientation including the second brain's identity.
- [ ] Time-to-orient measurement captured to `$HOME/wiki/log/<date>-m008-smoke-test-results.md`.

## Dependencies

- T044 (fresh session opened)

## Relationships

- PART OF: [[root-modules-m008-smoke-test-from-inside|M008]]
- BLOCKED BY: T044
- BLOCKS: T050 (M008 module exit)
