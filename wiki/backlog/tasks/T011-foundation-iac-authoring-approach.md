---
title: "T011 — Operator decides Foundation IaC authoring approach (greenfield vs extend prior debris)"
type: task
status: done
priority: P0
parent_module: "root-modules-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 100
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-05
decision_date: 2026-05-05
decision: "GREENFIELD — operator verbatim 'imagine virgin' + 'build from bottom-up' + 'STOP FUCKING WORKING IN REVERSE'"
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m003-foundation-hardening.md
  - id: prior-debris-task
    type: wiki
    file: wiki/backlog/tasks/T006-prior-debris-reconciliation.md
tags: [task, p0, t011, foundation, design-decision, operator-pending, m003]
---

# T011 — Foundation IaC authoring approach decision

## Description

Operator decides whether the foundation IaC (install.sh, hooks, integrity sentinel, opencode bridge) is **authored greenfield** (fresh, ignoring the prior $HOME debris entirely per the "imagine virgin" framing) OR **extends the prior $HOME files** as a starting point with explicit "this was prior debris being reframed" reframing.

## Done When

- [x] Operator decides: **GREENFIELD** (decided via 2026-05-05 verbatim directives — see Decision section).
- [x] Decision rationale documented in $HOME/wiki/log/ — multiple operator-verbatim logs this session capture the rationale.
- [x] If greenfield: T006 (prior debris reconciliation) decides cleanup policy → T006 also decided this session (effectively "leave-in-place; M003 proceeds as-if virgin").
- [N/A] Extend path not chosen.

## Decision (2026-05-05)

**Greenfield approach** — the foundation IaC (install.sh, hooks, integrity sentinel, opencode bridge, network-bridge config) is authored from scratch per the methodology-driven flow.

**Operator verbatim directives that decided this:**

> *"imagine there is no fucking root-GHOSTPROXY project right NOW.. this whole system is virgin"*

> *"WE NEED TO BUILD IT FROM THE BOTTOM-UP"*

> *"STOP FUCKING WORKING IN REVERSE"*

> *"I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST"*

These are sacrosanct decisions. Build virgin; do not extend prior $HOME debris.

**Downstream impact:**
- T012-T017 (Foundation authoring tasks) proceed with greenfield framing; no inheritance from prior debris.
- T006 (prior-debris reconciliation) effectively decided as "leave-in-place; cleanup orthogonal to foundation work".
- M003 unblocked from this gate.

## Trade-offs

| Greenfield | Extend prior |
|---|---|
| Aligned with "imagine virgin" framing | Preserves known-working pieces |
| Forces re-derivation of every design decision | Risks importing prior-session contamination |
| Operator's full authoring discipline | Faster initial deliverable |
| Methodology-driven flow at every step | Some steps may inherit non-methodology shortcuts |

## Dependencies

- M001 brain files exist ✓ (provide context for authoring)
- T006 (prior-debris reconciliation) — orthogonal but informative

## Relationships

- PART OF: [[root-modules-m003-foundation-hardening|M003]]
- RELATES TO: [[T006-prior-debris-reconciliation|T006]]
- BLOCKS: T012, T013, T014, T015, T016, T017
