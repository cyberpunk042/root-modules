---
title: "T031 — Verify $HOME/AGENTS.md exists (M001 dependency)"
type: task
status: done
priority: P0
parent_module: "root-modules-m006-pre-connect-verification"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 100
sfif_stage: Stream-1-Pre-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m006-pre-connect-verification.md
tags: [task, p0, t031, stream-1, pre-connect, agents-md-check, m006]
---

# T031 — Verify $HOME/AGENTS.md exists

## Description

`tools.setup --connect-project` writes the `## Second Brain Connection` block INTO an existing AGENTS.md (preferred) or CLAUDE.md (fallback). Pre-connect verification confirms AGENTS.md exists.

## Done When

- [x] `test -f $HOME/AGENTS.md` returns 0.
- [x] AGENTS.md is project-specific (not the second-brain copy).
- [x] AGENTS.md line count + frontmatter excerpt captured for the audit log.

## Resolution

AGENTS.md exists at $HOME/AGENTS.md (168 lines, project-specific) per T002 + T005. Verified by file inspection 2026-05-05.

## Relationships

- PART OF: [[root-modules-m006-pre-connect-verification|M006]]
- BLOCKED BY: T002 (M001 AGENTS.md authored)
- BLOCKS: T037 (M006 audit log assembly), T038 (M007 connect)
