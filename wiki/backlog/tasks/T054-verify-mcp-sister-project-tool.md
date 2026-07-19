---
title: "T054 — Verify second brain's `wiki_sister_project root-modules` MCP tool returns valid output"
type: task
status: not-started
priority: P1
parent_module: "root-modules-m009-worked-example-readme-ingest"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Worked-Example
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m009-worked-example-readme-ingest.md
tags: [task, p1, t054, stream-1, worked-example, mcp-sister-project, m009]
---

# T054 — Verify wiki_sister_project MCP tool

## Description

After M007 connect: from $HOME, invoke the second brain's `wiki_sister_project` MCP tool with `root-modules` as the argument. Should return the registry entry data.

## Done When

- [ ] MCP tool invocation: `wiki_sister_project root-modules` returns the sister entry: type=root, group=operating-system-setup, path=~/, auto_connect=false, etc.
- [ ] Output captured.

## Dependencies

- T044 (fresh session has MCP access)
- T053 (data exists)

## Relationships

- PART OF: [[root-modules-m009-worked-example-readme-ingest|M009]]
- BLOCKED BY: T044
