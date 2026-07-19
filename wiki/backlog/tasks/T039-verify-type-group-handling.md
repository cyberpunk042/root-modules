---
title: "T039 — Verify --connect-project handles type=root + group=operating-system-setup correctly (DONE — patched 2026-05-04)"
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
  - id: setup-py-patch
    type: file
    file: /opt/devops-solutions-information-hub/tools/setup.py
    description: "Patched 2026-05-04 with --dry-run + type/group-aware brain-pointer block (variant=ROOT_OS_SETUP)"
tags: [task, p0, t039, stream-1, connect, type-aware, done, m007]
---

# T039 — Verify --connect-project handles type=root + group=operating-system-setup

## Description

The connect script must honor the type/group fields added to sister-projects.yaml during the preparation session. Operator-authorized patch added: `_load_sister_entry()` resolves the target's sister-projects.yaml entry; `_render_brain_pointer_block()` selects ROOT_OS_SETUP variant when type=root + group=operating-system-setup.

## Resolution

Patched in `tools/setup.py` 2026-05-04. Verified via dry-run against $HOME: output confirms `Sister entry resolved: name=root-modules type=root group=operating-system-setup` and `variant=ROOT_OS_SETUP`. Backwards-compatible: sisters without type/group fields fall back to the generic block.

## Done When

- [x] tools/setup.py has `_load_sister_entry` + `_render_brain_pointer_block` + `_BRAIN_POINTER_BLOCK_ROOT_OS_SETUP` constant.
- [x] Dry-run against $HOME reports variant=ROOT_OS_SETUP.
- [x] Dry-run against /opt/devops-solutions-information-hub (the hub itself, no sister entry) reports variant=GENERIC.
- [x] Backwards-compatible — existing sisters (openarms, openfleet, etc., without type/group) get the generic variant.

## Relationships

- PART OF: [[root-modules-m007-connect-second-brain|M007]]
- ENABLES: T040 (real connect run with correct variant)
