---
title: "T009 — Copy methodology.yaml + chosen profiles from second brain to $HOME/wiki/config/"
type: task
status: done
priority: P0
parent_module: "root-modules-m002-methodology-layer-decision"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: scaffold
readiness: 100
sfif_stage: Scaffold
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m002-methodology-layer-decision.md
tags: [task, p0, t009, scaffold, methodology, profiles, m002]
---

# T009 — Copy methodology + 3 profiles into $HOME/wiki/config/

## Description

Per the local-copy-and-adapt decision (T007) and Adoption Guide step 1, copy four configuration files from the second brain into root-modules's wiki/config/. The chosen profiles align with root-modules's Goldilocks identity:
- **SDLC profile: `simplified`** — right-sized for micro scale + solo execution
- **Domain profile: `infrastructure`** — gate-command + path-pattern overrides for IaC work
- **Methodology profile: `stage-gated`** — hard ALLOWED/FORBIDDEN per stage

## Done When

- [x] `$HOME/wiki/config/methodology.yaml` exists (copy from second brain's `wiki/config/methodology.yaml`).
- [x] `$HOME/wiki/config/sdlc-profile.yaml` exists (copy from `wiki/config/sdlc-profiles/simplified.yaml`).
- [x] `$HOME/wiki/config/domain-profile.yaml` exists (copy from `wiki/config/domain-profiles/infrastructure.yaml`).
- [x] `$HOME/wiki/config/methodology-profile.yaml` exists (copy from `wiki/config/methodology-profiles/stage-gated.yaml`).
- [x] Files copy verbatim — adaptation is layered on top via separate edits, not by mixing copy + edit.

## Resolution

All four files copied 2026-05-05 via `cp` from `/opt/devops-solutions-information-hub/wiki/config/`. Line counts: methodology.yaml 657, sdlc-profile.yaml 67, domain-profile.yaml 68, methodology-profile.yaml 166.

## Dependencies

- T007 (decision: local copy + adapt) ✓

## Relationships

- PART OF: [[root-modules-m002-methodology-layer-decision|M002]]
- BLOCKED BY: T007
- BLOCKS: T010 (decision documentation in CLAUDE.md / DESIGN.md / dedicated ADR)
- ENABLES: methodology-driven work loop in future sessions
