---
title: "T004 — Author $HOME/CLAUDE.md (Claude Code-specific routing)"
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
tags: [task, p0, t004, scaffold, claude-md, authoring, m001]
---

# T004 — Author $HOME/CLAUDE.md

## Description

Author $HOME/CLAUDE.md per the scope decision from T003. Tight + Claude-Code-specific. Operator-intent → tool/command routing organized by category. Methodology section with 5 universal stages + gate commands per stage. 10 Claude-Code-specific hard rules. Pointers to depth files. Session-bootstrap section.

## Done When

- [x] $HOME/CLAUDE.md exists and is operator-approved.
- [x] Content is project-specific (not template scaffold).
- [x] Operator-intent routing table present, organized by 5 categories (foundation operations, network bridge ops, module ops, second-brain ops, backlog ops).
- [x] Methodology section present with 5 universal stages, ALLOWED/FORBIDDEN per stage, project-specific gate commands.
- [x] 10 Claude-Code-specific hard rules present (status-claims-inline-verification, don't-edit-safety-policy-without-reverify, don't-bypass-malware-block-by-editing-it, modules-facultative, two-layer-hooks, methodology-stage-boundaries, URL-ingestion-via-second-brain, prior-debris-not-authoritative, forwarders-via-connect-project, memory-folder-debris).
- [x] Working contract section.
- [x] Pointers to all 8 other brain files.
- [x] Session bootstrap section.
- [x] Second-brain-connection placeholder for `--connect-project` injection.
- [x] No reference to memory folder.
- [x] No prior-/root-debris specifics as authoritative.

## Resolution

$HOME/CLAUDE.md authored 2026-05-05 (175 lines). Multiple iterations under operator-driven loop. Routing table covers 5 operation categories with concrete commands. Hard rules align with operator-stated invariants.

## Dependencies

- T003 (CLAUDE.md scope decision) ✓
- T002 (AGENTS.md exists, so CLAUDE.md can reference it) ✓

## Relationships

- PART OF: [[root-modules-m001-author-claude-md-and-agents-md|M001]]
- BLOCKED BY: T003, T002
- BLOCKS: T005 (operator review)
