---
title: "T010 — Document the methodology-layer decision (which + why + escape hatch)"
type: task
status: done
priority: P0
parent_module: "root-modules-m002-methodology-layer-decision"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 100
sfif_stage: Scaffold
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m002-methodology-layer-decision.md
tags: [task, p0, t010, scaffold, methodology, documentation, m002]
---

# T010 — Document methodology-layer decision

## Description

Document the methodology-layer decision in the brain files: which choice (local copy + adapt), why (Adoption Guide + per-project gate-command adaptation needs + Goldilocks profile match), and escape hatch (re-copy from second brain when methodology.yaml evolves).

## Done When

- [x] Decision recorded in CLAUDE.md Methodology section (which + per-profile rationale).
- [x] Decision recorded in DESIGN.md as one of the specific design choices ("Methodology adoption (copy + adapt vs pointer)").
- [x] Decision recorded in ARCHITECTURE.md ADR table.
- [x] Each profile's rationale documented (simplified for micro+solo; infrastructure for IaC; stage-gated for OS-setup).
- [x] Escape hatch documented: re-copy when methodology.yaml evolves; per-project adaptations remain local. Documented in DESIGN.md "what it costs / mitigation."

## Resolution

Decision documented across CLAUDE.md (Methodology section, ~30 lines), DESIGN.md (specific design choices, "Methodology adoption" subsection with alternatives + costs + gains), ARCHITECTURE.md (ADR table). All three brain files reference the same decision consistently. The decision is also recorded in the session log at `wiki/log/2026-05-05-preparation-session-foundation-scaffolding.md`.

## Dependencies

- T007 (decision made) ✓
- T009 (files copied so the documentation has something to reference) ✓

## Relationships

- PART OF: [[root-modules-m002-methodology-layer-decision|M002]]
- BLOCKED BY: T007, T009
- ENABLES: methodology-driven work loop with operator-clear rationale
