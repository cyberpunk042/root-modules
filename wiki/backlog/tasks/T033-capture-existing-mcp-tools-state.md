---
title: "T033 — Capture existing $HOME/.mcp.json + $HOME/tools/ state for collision-check"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m006-pre-connect-verification"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Pre-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m006-pre-connect-verification.md
tags: [task, p0, t033, stream-1, pre-connect, collision-check, m006]
---

# T033 — Capture pre-connect state of $HOME/.mcp.json + $HOME/tools/

## Description

Per `tools.setup` verified behavior (M007 module page): `--connect-project` overwrites `mcpServers.research-wiki` in $HOME/.mcp.json (idempotent re-runs land same entry); writes `$HOME/tools/gateway.py` + `view.py` only if not already present without our auto-gen marker (preserves user's). Capture pre-connect state so post-connect diff is reviewable.

## Done When

- [ ] If `$HOME/.mcp.json` exists: capture content. Note any existing `mcpServers.research-wiki` entry that would be overwritten.
- [ ] If `$HOME/tools/` exists: list contents. Note any existing `gateway.py` or `view.py` that would prevent forwarder install.
- [ ] If neither exists: confirmed; the connect-script will create them fresh.
- [ ] State captured to `$HOME/wiki/log/<date>-pre-connect-state-snapshot.md`.

## Dependencies

(None — diagnostic only.)

## Relationships

- PART OF: [[root-modules-m006-pre-connect-verification|M006]]
- BLOCKS: T037 (audit log)
