---
title: "T002 — Author $HOME/AGENTS.md (cross-tool agent contract)"
type: task
status: done
priority: P0
parent_module: "root-modules-m001-author-claude-md-and-agents-md"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: scaffold
readiness: 100
sfif_stage: Scaffold
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m001-author-claude-md-and-agents-md.md
tags: [task, p0, t002, scaffold, agents-md, authoring, m001]
---

# T002 — Author $HOME/AGENTS.md

## Description

Author $HOME/AGENTS.md per the scope decision from T001. Tight + pointer-based — the cross-tool agent contract: no-policy-duplication invariant, canonical tool-call envelope shape, hook firing order, two-layer hook architecture, universal hard rules that bind every AI tool, mission verbatim, pointer table to canonical sources.

## Done When

- [x] $HOME/AGENTS.md exists and is operator-approved.
- [x] Content is project-specific (not template scaffold).
- [x] Cross-tool agent contract sections present: no-policy-duplication invariant, canonical envelope, hook firing order, two-layer architecture.
- [x] Universal hard rules present (10 rules covering: deny-by-default, tamper detection, cross-AI consistency, words sacrosanct, prior-debris-not-authoritative, memory-folder-rejected, methodology stage boundaries, modules facultative, two-layer hooks, status-claims-inline-verification).
- [x] Mission verbatim included (operator's project-framing quote).
- [x] Pointers to all 8 other brain files (README, CLAUDE, CONTEXT, ARCHITECTURE, DESIGN, TOOLS, SKILLS, SECURITY) + canonical second-brain paths.
- [x] No reference to memory folder (operator-rejected per 2026-05-05 directive).
- [x] No prior-/root-debris specifics framed as authoritative.

## Resolution

$HOME/AGENTS.md authored 2026-05-05 (168 lines). Multiple iterations driven by operator feedback — the first attempt was rejected as "trash" (abstract template, duplication of content). The successful version reframes around the cross-tool agent contract scope, references canonical sources without restating their content.

## Dependencies

- T001 (scope decision) ✓
- Identity profile in second brain ✓
- Operator's verbatim project-framing directive logged ✓

## Relationships

- PART OF: [[root-modules-m001-author-claude-md-and-agents-md|M001]]
- BLOCKED BY: T001 (scope decision)
- BLOCKS: T005 (operator review of AGENTS.md), T006 (M007 connect dependency on AGENTS.md existing)
