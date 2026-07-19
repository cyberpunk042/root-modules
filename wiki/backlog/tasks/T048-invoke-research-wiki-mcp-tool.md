---
title: "T048 — Invoke at least one research-wiki MCP tool from the session"
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
tags: [task, p0, t048, stream-1, smoke-test, mcp-tool, m008]
---

# T048 — Invoke a research-wiki MCP tool

## Description

The MCP path is independent from the CLI forwarder path. Verify the MCP entry in $HOME/.mcp.json works by invoking at least one tool (e.g. `wiki_status`, `wiki_search root-modules`).

## Done When

- [ ] From the fresh session: invoke `wiki_status` (or operator-chosen MCP tool from the research-wiki server's catalog).
- [ ] Tool returns valid output (not error).
- [ ] Output captured.

## Dependencies

- T044 (fresh session)
- T041 (.mcp.json verified)

## Relationships

- PART OF: [[root-modules-m008-smoke-test-from-inside|M008]]
- BLOCKED BY: T044, T041
- BLOCKS: T050
