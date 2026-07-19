---
title: "T003 — Define $HOME/CLAUDE.md scope (Claude Code-specific delta)"
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
tags: [task, p0, t003, scaffold, claude-md, scope-definition, m001]
---

# T003 — Define $HOME/CLAUDE.md scope

## Description

Decide CLAUDE.md scope = the Claude-Code-specific delta. NOT a duplicate of AGENTS.md (universal cross-tool stuff). NOT a duplicate of README.md (project description). CLAUDE.md unique value: operator-intent → tool/command routing for THIS project's actual operations + methodology pointer per Adoption Guide step 5 + Claude-Code-specific hard rules that don't apply to other AI tools.

## Done When

- [x] Documented decision: CLAUDE.md content = operator-intent routing table (organized by operation category), methodology section with stages + gates, Claude-specific hard rules.
- [x] Documented decision: CLAUDE.md POINTS at AGENTS.md for universal cross-tool rules, README.md for project description, CONTEXT.md for current operational state.
- [x] Length budget: ~175-200 lines.

## Resolution

Scope decision applied to $HOME/CLAUDE.md authored 2026-05-05 (175 lines). Routing table organized by 5 categories: foundation operations, network bridge ops, module ops, second-brain ops, backlog ops. 10 Claude-Code-specific hard rules. References AGENTS.md for universal rules.

## Dependencies

- T001 (AGENTS.md scope decision; CLAUDE.md scope is the complement) ✓

## Relationships

- PART OF: [[root-modules-m001-author-claude-md-and-agents-md|M001]]
- BLOCKED BY: T001
- BLOCKS: T004 (CLAUDE.md authoring)
