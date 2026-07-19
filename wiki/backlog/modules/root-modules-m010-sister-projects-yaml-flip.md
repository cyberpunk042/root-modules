---
title: "root-modules M010 — sister-projects.yaml auto_connect Decision"
aliases:
  - "M010 — auto_connect flip decision"
type: module
domain: backlog
status: draft
priority: P2
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Stream-1-Operator-Decision
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
    description: "Current root-modules entry: type=root, group=operating-system-setup, auto_connect=false"
tags: [module, p2, root-modules, second-brain-integration, stream-1, operator-decision, auto-connect, m010]
---

# M010 — sister-projects.yaml auto_connect Decision

## Summary

After M007–M009 prove the second-brain integration works end-to-end and the connection is stable, the operator decides whether to flip root-modules's `auto_connect` field in `wiki/config/sister-projects.yaml` from `false` to `true`. Flipping to `true` means subsequent `python3 -m tools.setup` runs (no args) will hook root-modules automatically when the path resolves locally — convenient for multi-host scenarios but also reduces the operator's explicit-authorization point. For a project of type=root + group=operating-system-setup that gates the security envelope of the host, the operator may prefer to keep `auto_connect: false` permanently as a friction-by-design measure. M010 is short — it's an operator decision logged with rationale.

## Done When

- [ ] M009 is complete (worked example proven; connection demonstrated bidirectional)
- [ ] Operator decision recorded: keep `auto_connect: false` (manual --connect-project always required) OR flip to `true` (auto-hookup on tools.setup runs)
- [ ] Decision and rationale documented in this module page (or as an ADR-style page in second brain)
- [ ] If flipped to true: `wiki/config/sister-projects.yaml` updated; `pipeline post` passes; downstream behaviour smoke-tested (re-run tools.setup and verify root-modules re-connects without --connect-project flag)
- [ ] If kept false: rationale captured (likely: type=root projects gate the security envelope and warrant explicit authorization gates)

## Dependencies

- M009 (Worked example) — explicit; the decision is informed by integration stability evidence
- Operator authorization is the entire content of this module

## Open Questions

> [!question] Should ALL type=root projects share the same auto_connect default?
> If multiple type=root projects emerge (container-runtime-setup, network-edge-setup, etc.), is the policy "type=root → auto_connect always false"? That's a higher-level standard, not a per-project decision. Document as such if operator confirms.

> [!question] What if the operator wants a third option: "auto_connect with a confirmation prompt"?
> tools.setup currently has binary auto_connect. A "prompt-on-connect" mode would require a second-brain enhancement. Out of scope for this module unless operator wants it; surface as a tools.setup feature request.

> [!question] Does sister-projects.yaml have a `notes` or `rationale` field for capturing the decision rationale inline?
> Check the schema. If not, add one (small schema extension); the rationale belongs near the data.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M010-1 | M009 must be complete and stable for ≥1 week before this decision lands (operator's call on the cooling-off period) | ⊙ pending |
| T-M010-2 | Operator decides: false (status quo) or true (auto-hookup) — capture rationale verbatim | ⊙ pending |
| T-M010-3 | If true: edit sister-projects.yaml, run pipeline post, smoke test re-connect | ⊙ pending |
| T-M010-4 | If false: document rationale in this module page (and possibly as a higher-level standard for type=root projects) | ⊙ pending |
| T-M010-5 | Close the epic (mark all 10 modules done; update epic readiness; pipeline post + crossref) | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BLOCKED BY: [[root-modules-m009-worked-example-readme-ingest|M009 — Worked example]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M009 — Worked example]]
