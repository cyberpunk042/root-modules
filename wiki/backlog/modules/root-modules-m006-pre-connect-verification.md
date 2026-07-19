---
title: "root-modules M006 — Pre-Connect Verification"
aliases:
  - "M006 — Stream 1 pre-connect"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Stream-1-Pre-Connect
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
  - id: sister-projects-registry
    type: file
    file: wiki/config/sister-projects.yaml
    description: "root-modules entry: type=root, group=operating-system-setup, auto_connect=false"
tags: [module, p0, root-modules, second-brain-integration, stream-1, pre-connect-verification, m006]
---

# M006 — Pre-Connect Verification

## Summary

Before running `tools.setup --connect-project $HOME` (which lands as M007), verify the prerequisites are in place: Stream 2 M001 (AGENTS.md) is complete in $HOME because the connect script writes the `## Second Brain Connection` block INTO an existing AGENTS.md or CLAUDE.md; root-modules is at a clean git state so the connect script's mutations are reviewable as a single diff; operator authorizes the connection (the auto_connect=false flag in sister-projects.yaml is the explicit gate). M006 is short — checklist + sign-off — but skipping it is what causes connect-script failures and partial-state cleanups in $HOME.

## Done When

- [ ] $HOME/AGENTS.md exists (M001 dependency satisfied) — verified by file existence + line count
- [ ] $HOME/.git status is clean: no uncommitted changes that would be overwritten or that mix with the connect-script's diff
- [ ] sister-projects.yaml entry for root-modules verified: type=root, group=operating-system-setup, path=~/, auto_connect=false (current state) — and operator explicitly authorizes the manual --connect-project run
- [ ] Operator captures: any prior $HOME/.mcp.json content (so connect-script's MCP entry is added, not overwriting unknown state)
- [ ] Operator captures: any prior $HOME/tools/ Python content (so gateway.py + view.py forwarders are added without colliding)
- [ ] Pre-connect snapshot taken (git commit or tar) so M007 can be rolled back atomically if needed

## Dependencies

- M001 (CLAUDE.md + AGENTS.md) — explicit dependency
- Reviewed sister-projects.yaml entry — already exists in second brain (created during wiki-side prep)
- Operator authorization — explicit, not implicit

## Open Questions

> [!question] What if $HOME/.mcp.json already exists with content from prior sessions?
> Connect-script behaviour with pre-existing .mcp.json needs to be specified: append the research-wiki entry, or refuse and require manual merge? Read tools/setup.py for the actual behaviour before running.

> [!question] What if $HOME/tools/gateway.py already exists?
> Same question — the connect-script's `_install_view_forwarder` (and equivalent for gateway) must be checked for collision behaviour. Pre-connect verification reads the actual code path.

> [!success] Dry-run is supported (patched 2026-05-04)
> `python3 -m tools.setup --connect-project $HOME --dry-run` previews the four artefacts (.mcp.json mutation, gateway.py + view.py forwarders, AGENTS.md/CLAUDE.md brain-pointer block) without writing. Use this BEFORE the real run; review the diff. M006 includes the dry-run as a mandatory pre-step.

> [!question] Atomic rollback strategy?
> Best: a git commit pre-connect, so post-connect changes can be reverted as a single revert. Worst case: tar the relevant $HOME subtree. Operator picks the granularity.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M006-1 | Verify $HOME/AGENTS.md exists; record line count and frontmatter excerpt | ⊙ pending |
| T-M006-2 | `cd $HOME && git status` — confirm clean working tree; commit any pending work first | ⊙ pending |
| T-M006-3 | Capture $HOME/.mcp.json (if present) and $HOME/tools/ contents (if present) for collision-check | ⊙ pending |
| T-M006-4 | Read tools/setup.py path for `_install_*_forwarder` to know connect-script behaviour with pre-existing files | ⊙ pending |
| T-M006-5 | Determine if --dry-run is supported on tools.setup --connect-project; if yes, run and review diff | ⊙ pending |
| T-M006-6 | Take pre-connect snapshot (git commit or tar) | ⊙ pending |
| T-M006-7 | Operator authorizes M007 to run | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BLOCKED BY: [[root-modules-m001-author-claude-md-and-agents-md|M001]] (AGENTS.md must exist)
- ENABLES: [[root-modules-m007-connect-second-brain|M007 — Connect (--connect-project)]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M001]]
[[M007 — Connect (--connect-project)]]
