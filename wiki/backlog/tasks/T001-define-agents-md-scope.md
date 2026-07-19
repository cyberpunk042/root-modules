---
title: "T001 — Define $HOME/AGENTS.md scope (what content vs what pointer)"
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
tags: [task, p0, t001, scaffold, agents-md, scope-definition, m001]
---

# T001 — Define $HOME/AGENTS.md scope

## Description

Before authoring `$HOME/AGENTS.md` content, decide what BELONGS inside the file vs what should remain a POINTER to a canonical source elsewhere. AGENTS.md is the cross-tool universal context — its scope is the **agent contract** that binds every AI tool running in / consuming this project. Project description belongs in README.md; Claude-Code-specific routing belongs in CLAUDE.md; tool reference belongs in TOOLS.md. AGENTS.md must EARN its existence by content that doesn't belong anywhere else.

## Done When

- [x] Documented decision: AGENTS.md content scope = the cross-tool agent contract (no-policy-duplication invariant, canonical tool-call envelope, hook firing order, two-layer hook architecture, universal hard rules).
- [x] Documented decision: AGENTS.md POINTS at canonical sources for everything else (project description in README.md, Claude-routing in CLAUDE.md, tool reference in TOOLS.md, threat model in SECURITY.md, design rationale in DESIGN.md).
- [x] Length budget set: ~150-200 lines. Tight + pointer-based.
- [x] Anti-duplication test defined: AGENTS.md content should NOT contain prose that already exists in canonical sources it points to. Per operator's *"USELESS DATA WASTE OF TOKEN AND MONEY"* directive 2026-05-05.

## Resolution

Scope decision applied to $HOME/AGENTS.md authored 2026-05-05 (168 lines). Cross-tool agent contract content is unique to AGENTS.md; other content references canonical sources.

## Dependencies

- Parent module M001 exists: ✓
- Operator confirms what AGENTS.md should provide that no other artefact provides: ✓ (via the iterative loop confirming the authored AGENTS.md content was project-specific enough)

## Relationships

- PART OF: [[root-modules-m001-author-claude-md-and-agents-md|M001]]
- BLOCKS: T002 (AGENTS.md authoring), T003 (CLAUDE.md scope), T004 (CLAUDE.md authoring)
- ENABLES: every subsequent agent-context-file task
