---
title: "T041 — Inspect each of the 4 written artefacts for correctness"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m007-connect-second-brain"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m007-connect-second-brain.md
tags: [task, p0, t041, stream-1, connect, post-run-verify, m007]
---

# T041 — Inspect connect-script artefacts

## Description

After T040, verify each of the 4 artefacts the connect-script wrote.

## Done When

- [ ] **`$HOME/.mcp.json`** has `mcpServers.research-wiki` entry pointing at `/opt/devops-solutions-information-hub/.venv/bin/python -m tools.mcp_server` with `cwd=/opt/devops-solutions-information-hub`.
- [ ] **`$HOME/tools/gateway.py`** exists, has the auto-gen marker comment, dispatches to `cwd=/opt/devops-solutions-information-hub/`. `python3 -m tools.gateway --help` from $HOME prints the gateway's help (forwarder works).
- [ ] **`$HOME/tools/view.py`** exists, has the auto-gen marker, dispatches similarly. `python3 -m tools.view --help` from $HOME works.
- [ ] **`$HOME/AGENTS.md`** has the `<!-- SECOND-BRAIN-CONNECTION -->` block injected with variant=ROOT_OS_SETUP content (per `_BRAIN_POINTER_BLOCK_ROOT_OS_SETUP` template — OS-setup-tier framing emphasizing methodology + verification, not generic adoption-tier framing).
- [ ] Inspection results captured to `$HOME/wiki/log/<date>-m007-artefact-inspection.md`.

## Dependencies

- T040 (real connect run)

## Relationships

- PART OF: [[root-modules-m007-connect-second-brain|M007]]
- BLOCKED BY: T040
- BLOCKS: T042 (commit), T043 (rollback policy on failure)
