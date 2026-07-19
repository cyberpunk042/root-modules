---
title: "T007 — Operator confirms the trade-off table and chooses pointer or local (or hybrid) methodology"
type: task
status: done
priority: P0
parent_module: "root-modules-m002-methodology-layer-decision"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 100
sfif_stage: Scaffold-Design
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m002-methodology-layer-decision.md
  - id: adoption-guide
    type: file
    file: /opt/devops-solutions-information-hub/wiki/spine/references/adoption-guide.md
    description: "Adoption Guide step 1: Copy and adapt methodology.yaml"
tags: [task, p0, t007, scaffold-design, methodology, decision, m002]
---

# T007 — Methodology layer trade-off decision (pointer vs local vs hybrid)

## Description

Decide whether root-modules uses local methodology engine (copy + adapt) OR pointer-only (reference second brain's methodology) OR hybrid. Per Goldilocks (simplified profile, micro scale, solo mode), pointer-only is the minimum-overhead default. Per Adoption Guide step 1, copy + adapt is the strictly-defined adoption process.

## Done When

- [x] Operator confirms decision: **local copy + adapt** (NOT pointer-only).
- [x] Decision rationale documented: per Adoption Guide step 1, the project owns its methodology layer adapted per domain. Pointer-only would gate every methodology operation on second-brain availability + freeze the project to second-brain's exact gate commands; copy + adapt enables per-project gate command customization (e.g. for IaC: stage gates translate to install.sh --dry-run + integrity check).
- [x] Escape hatch documented: re-copy from second brain when methodology.yaml evolves; per-project adaptations remain local.

## Resolution

Decision: **local copy + adapt**. Implemented 2026-05-05 by copying methodology.yaml + 3 chosen profiles (simplified SDLC, infrastructure domain, stage-gated methodology) from `/opt/devops-solutions-information-hub/wiki/config/` to `$HOME/wiki/config/`.

## Dependencies

- Identity profile exists ✓
- Adoption Guide accessible ✓
- Operator confirms (✓ via the implementation directive 2026-05-05)

## Relationships

- PART OF: [[root-modules-m002-methodology-layer-decision|M002]]
- BLOCKS: T008, T009, T010
