---
title: "root-modules M001 — Author CLAUDE.md + AGENTS.md"
aliases:
  - "M001 — root-modules CLAUDE.md + AGENTS.md"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Scaffold
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
  - id: identity-profile
    type: wiki
    file: wiki/ecosystem/project_profiles/root-modules/identity-profile.md
  - id: model-skills-commands-hooks
    type: wiki
    file: wiki/spine/models/agent-config/model-skills-commands-hooks.md
    description: "Three-layer agent context — AGENTS.md universal cross-tool, CLAUDE.md Claude Code-specific routing, skills auto-trigger"
tags: [module, p0, root-modules, sfif-scaffold, claude-md, agents-md, three-layer-context, m001]
---

# M001 — Author CLAUDE.md + AGENTS.md for root-modules

## Summary

Author the two top-level agent-context files for the root-modules repo: AGENTS.md (universal cross-tool context, < 100 lines) and CLAUDE.md (Claude Code-specific routing table, < 200 lines). These are the load-bearing documents a fresh agent reads when opening the repo, and they must be authored FROM the second brain's templates, not improvised. AGENTS.md is the dependency for M007 (the `tools.setup --connect-project` script writes the `## Second Brain Connection` block INTO an existing AGENTS.md or CLAUDE.md — the file must exist first). Goldilocks identity: type=root, group=operating-system-setup, simplified profile, scaffold phase, micro scale, solo execution mode, L1 PM, operator-supervised trust.

## Done When

- [ ] `$HOME/AGENTS.md` exists, < 100 lines, captures: identity, mission, sacrosanct directives (verbatim), hard rules, the working contract (driver/horse), pointers to README and install.sh
- [ ] `$HOME/CLAUDE.md` exists, < 200 lines, captures: identity tier, routing table for operator intents, hard rules (Claude-specific), pointer to AGENTS.md for universal context
- [ ] Both files are authored by extracting the right blocks from the second brain (templates, identity profile, sacrosanct directives, working contract) — NOT improvised
- [ ] Operator approves both files before they land at $HOME (per "ME APPROVING THEM ONE BY ONE" contract)
- [ ] Pipeline post on the second brain side passes 0 errors after the identity profile / template adjustments this module may surface

## Dependencies

- Parent epic must be in document/scaffold stage (it is — readiness 10)
- Identity profile must exist at `wiki/ecosystem/project_profiles/root-modules/identity-profile.md` (it does)
- Templates for AGENTS.md and CLAUDE.md should be sourced from second brain's standards. The second brain's own CLAUDE.md and AGENTS.md serve as one reference point; lighter "simplified-profile" variants may be more appropriate for a micro-scale OS-setup project
- Operator decision needed: which OS-setup-relevant scope should AGENTS.md cover? (security envelope, hooks, install.sh classified as not-IaC, two-layer hook architecture, integrity.py)

## Open Questions

> [!question] How thin should $HOME/CLAUDE.md and $HOME/AGENTS.md be at scaffold stage?
> The second brain's own CLAUDE.md is ~240 lines (mature production project). For a micro-scale scaffold-stage project, < 100 / < 200 lines is the SFIF discipline target. Operator may want even thinner at this stage, expanding only as Foundation phase fleshes out.

> [!question] Should sacrosanct directives be inlined in $HOME/AGENTS.md or sourced from $HOME/.claude/projects/-root/memory/?
> The memory layer auto-loads the feedback rules. AGENTS.md could pointer to them (DRY) or inline the most load-bearing ones (resilient against memory-layer changes). Operator's call.

> [!question] How does the prior session's contaminated $HOME state get reconciled?
> The prior session left $HOME/docs/SESSION-2026-05-04*.md handoffs, install.sh, README.md, plus 3 memory files at -root/memory/. Some of these contain hallucinated framing (e.g. "separate ghostproxy project"). M001 must explicitly decide: integrate, scrap, or rewrite each pre-existing artefact. (This blocks scaffold-purity.)

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M001-1 | Operator decides scope and tone for AGENTS.md (sacrosanct inline vs pointer; security envelope inclusion; install.sh framing) | ⊙ pending |
| T-M001-2 | Draft $HOME/AGENTS.md based on operator-confirmed scope, FROM second brain templates | ⊙ pending |
| T-M001-3 | Draft $HOME/CLAUDE.md with routing table tailored to OS-setup project (likely simpler than second brain's CLAUDE.md) | ⊙ pending |
| T-M001-4 | Operator reviews + approves drafts (one-by-one per working contract) | ⊙ pending |
| T-M001-5 | Land both files at $HOME after approval | ⊙ pending |
| T-M001-6 | Decide reconciliation for prior $HOME artefacts (memory files, handoffs, install.sh, README.md) | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BLOCKS: [[root-modules-m007-connect-second-brain|M007 — Connect (--connect-project script needs AGENTS.md)]]
- BUILDS ON: [[identity-profile|root-modules Identity Profile]]
- BUILDS ON: [[model-skills-commands-hooks|Model — Skills, Commands, and Hooks]]
- RELATES TO: [[root-modules-m002-methodology-layer-decision|M002 — Methodology layer decision]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M007 — Connect (--connect-project script needs AGENTS.md)]]
[[root-modules Identity Profile]]
[[model-skills-commands-hooks|Model — Skills, Commands, and Hooks]]
[[M002 — Methodology layer decision]]
