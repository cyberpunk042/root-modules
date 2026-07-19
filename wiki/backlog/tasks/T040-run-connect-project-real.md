---
title: "T040 — Run `python3 -m tools.setup --connect-project $HOME` from second brain (no --dry-run)"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m007-connect-second-brain"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 0
sfif_stage: Stream-1-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m007-connect-second-brain.md
tags: [task, p0, t040, stream-1, connect, apply, m007]
---

# T040 — Run --connect-project for real

## Description

After M006 audit log + operator authorization, run the connection for real. Four artefacts land in $HOME: research-wiki MCP entry in .mcp.json, tools/gateway.py forwarder, tools/view.py forwarder, ## Second Brain Connection block in AGENTS.md (variant=ROOT_OS_SETUP).

## Done When

- [ ] From second brain: `cd /opt/devops-solutions-information-hub && python3 -m tools.setup --connect-project $HOME` (no --dry-run).
- [ ] Exit code 0.
- [ ] Output confirms: 4 artefacts written, variant=ROOT_OS_SETUP.
- [ ] Output captured to `$HOME/wiki/log/<date>-m007-connect-output.md`.

## Dependencies

- T037 (M006 audit log + operator authorization)
- T039 (type=root variant verified)

## Relationships

- PART OF: [[root-modules-m007-connect-second-brain|M007]]
- BLOCKED BY: T037, T039
- BLOCKS: T041, T042, T043
