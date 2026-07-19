---
title: "T059 — If T058 decides flip-to-true: edit sister-projects.yaml, pipeline post, smoke-test re-connect"
type: task
status: not-started
priority: P2
parent_module: "root-modules-m010-sister-projects-yaml-flip"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 0
sfif_stage: Stream-1-Operator-Decision
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m010-sister-projects-yaml-flip.md
tags: [task, p2, t059, stream-1, m010, apply]
---

# T059 — Apply auto_connect: true (if T058 decides flip)

## Description

Conditional task. Only executes if T058 decides flip-to-true.

## Done When (conditional)

- [ ] `/opt/devops-solutions-information-hub/wiki/config/sister-projects.yaml` edited: `root-modules.auto_connect: true`.
- [ ] `pipeline post` (in second brain) returns 0 errors.
- [ ] Smoke-test: re-run `python3 -m tools.setup` (no flags, no path) from second brain; verify root-modules auto-connects (or auto-detects already-connected).
- [ ] Behavior confirmed.

## Dependencies

- T058 (operator decides flip-to-true)

## Relationships

- PART OF: [[root-modules-m010-sister-projects-yaml-flip|M010]]
- BLOCKED BY: T058
