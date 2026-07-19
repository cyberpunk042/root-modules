---
title: "T008 — CLAUDE.md routing references the methodology layer (per Adoption Guide step 5)"
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
tags: [task, p0, t008, scaffold, claude-md, methodology, m002]
---

# T008 — CLAUDE.md methodology section per Adoption Guide step 5

## Description

Per Adoption Guide step 5: "Add methodology rules to CLAUDE.md." CLAUDE.md must reference the methodology engine at `wiki/config/methodology.yaml` + the chosen profiles, document the 5 universal stages, and specify project-adapted gate commands.

## Done When

- [x] CLAUDE.md has a Methodology section.
- [x] Methodology section references all 4 config files: methodology.yaml + sdlc-profile.yaml + domain-profile.yaml + methodology-profile.yaml.
- [x] 5 universal stages documented (document, design, scaffold, implement, test) with ALLOWED/FORBIDDEN per stage.
- [x] Project-adapted gate commands per stage (e.g. for scaffold: `install.sh --dry-run` exists and runs cleanly; for implement: `install.sh` runs and box reaches target state; for test: idempotent re-run is no-op + integrity verifications).
- [x] Backlog hierarchy explained (Epic → Module → Task; readiness flows up; work on tasks not epics).
- [x] Active epic referenced.

## Resolution

CLAUDE.md authored 2026-05-05 with a Methodology section that meets all the above criteria. See [$HOME/CLAUDE.md § Methodology](../../../CLAUDE.md#methodology).

## Dependencies

- T007 (methodology-layer decision: local copy chosen) ✓
- T004 (CLAUDE.md authored) ✓ — methodology section is part of CLAUDE.md

## Relationships

- PART OF: [[root-modules-m002-methodology-layer-decision|M002]]
- BLOCKED BY: T007, T004
- ENABLES: methodology-driven work loop in future sessions
