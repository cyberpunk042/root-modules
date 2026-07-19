---
title: "T044 — Open a fresh Claude Code session in $HOME"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m008-smoke-test-from-inside"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Verify
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m008-smoke-test-from-inside.md
tags: [task, p0, t044, stream-1, smoke-test, fresh-session, m008]
---

# T044 — Open fresh Claude Code session in $HOME

## Description

Operator opens a brand-new Claude Code session inside `$HOME` after M007 connect completes. This is the verification gate for "the future session works."

## Done When

- [ ] `cd $HOME && claude` (or operator's Claude Code launch command) starts a new session.
- [ ] The session auto-loads $HOME/CLAUDE.md + $HOME/AGENTS.md per Claude Code convention.
- [ ] The session has access to the research-wiki MCP server (per $HOME/.mcp.json entry).

## Dependencies

- T040 (M007 connect complete)
- T041 (artefacts inspected and correct)

## Relationships

- PART OF: [[root-modules-m008-smoke-test-from-inside|M008]]
- BLOCKED BY: T040, T041
- BLOCKS: T045 through T050
