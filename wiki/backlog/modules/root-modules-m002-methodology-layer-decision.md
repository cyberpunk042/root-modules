---
title: "root-modules M002 — Methodology Layer Decision"
aliases:
  - "M002 — root-modules methodology layer"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Scaffold-Design
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
  - id: methodology-engine
    type: file
    file: wiki/config/methodology.yaml
    description: "Second brain's methodology engine — 9 models, 5 stages, ALLOWED/FORBIDDEN, gates"
  - id: project-self-identification-protocol
    type: wiki
    file: wiki/domains/cross-domain/methodology-framework/project-self-identification-protocol.md
    description: "Goldilocks 9-dimension protocol — guides per-project methodology right-sizing"
tags: [module, p0, root-modules, sfif-scaffold-design, methodology, goldilocks, m002]
---

# M002 — Methodology Layer Decision for root-modules

## Summary

Decide whether root-modules carries its own local methodology engine (`$HOME/wiki/config/methodology.yaml` + supporting templates and configs) OR points to the second brain's methodology via the `--connect-project` integration. Per Goldilocks (simplified profile, micro scale, solo mode), the pointer approach is the right-sized default — root-modules doesn't need a full methodology engine on day one and would not maintain it independently. The decision must be explicit and documented in $HOME/CLAUDE.md so future work knows where to query for stage selection, model selection, gate commands. Trade-off analysis required so operator picks deliberately, not by drift.

## Done When

- [ ] Decision documented in $HOME/CLAUDE.md (or in a dedicated `$HOME/docs/methodology-layer.md` ADR-style page) with: choice, rationale, trade-offs considered, escape hatch (how to switch later)
- [ ] If pointer chosen: $HOME/CLAUDE.md routing table includes methodology query routes (via `python3 -m tools.gateway query --model <name>` forwarder installed in M007)
- [ ] If local chosen: `$HOME/wiki/config/methodology.yaml` + minimal templates exist; operator approves the local subset (which models, which stages)
- [ ] Operator approves the decision (sacrosanct one-by-one approval gate)

## Dependencies

- Identity profile (already exists) — establishes that simplified profile + micro scale → pointer is likely
- M007 (Connect) — if pointer is chosen, this is how the methodology surface arrives in $HOME
- M001 (CLAUDE.md / AGENTS.md) — methodology pointer or local engine reference goes in those files

## Open Questions

> [!question] Pointer or local — what's the trade-off?
> | Aspect | Pointer (default per Goldilocks) | Local |
> |---|---|---|
> | Setup | One `--connect-project` call, gateway forwarder installed | Copy yaml + templates + supporting modules to $HOME |
> | Maintenance | Always current with second brain's evolution | Manual sync or stale |
> | Independence | Requires second brain reachable / mounted | Self-contained — works in airgapped scenarios |
> | Right-sized? | Yes for simplified-profile micro-scale | Overkill at scaffold; might fit at Infrastructure tier |
> | Override | Local additions can layer on top via additional config files | Already local |

> [!question] If pointer is chosen, what happens when /opt/devops-solutions-information-hub is unavailable?
> The gateway forwarder calls into the second brain's venv + tools. If the second brain path isn't mounted, methodology queries fail. Acceptable for a project that lives on the same host as the second brain; not acceptable for an airgapped deployment. Operator's threat model determines the answer.

> [!question] Could root-modules define a small subset of methodology (just the models it uses) locally and pointer for the rest?
> Hybrid mode. Likely premature optimization for scaffold stage. Document as a Phase-2 option.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M002-1 | Operator confirms the trade-off table and chooses pointer or local (or hybrid) | ⊙ pending |
| T-M002-2 | If pointer: ensure CLAUDE.md routing table references gateway forwarder methodology routes; document the dependency on second brain availability | ⊙ pending |
| T-M002-3 | If local: copy methodology.yaml subset, approve which models + which gate commands stay | ⊙ pending |
| T-M002-4 | Document the decision (which + why + escape hatch) | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BUILDS ON: [[project-self-identification-protocol|Project Self-Identification Protocol]]
- BUILDS ON: [[identity-profile|root-modules Identity Profile]]
- BLOCKED BY: [[root-modules-m001-author-claude-md-and-agents-md|M001 — CLAUDE.md / AGENTS.md (decision lands here)]]
- ENABLES: [[root-modules-m003-foundation-hardening|M003 — Foundation hardening (uses chosen methodology for gates)]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[Project Self-Identification Protocol]]
[[root-modules Identity Profile]]
[[M001 — CLAUDE.md / AGENTS.md (decision lands here)]]
[[M003 — Foundation hardening (uses chosen methodology for gates)]]
