---
title: "Epic E006 — Guided Workflow Continuation: every interaction triggers right continuation + right progress"
type: epic
status: not-started
priority: P2
parent_milestone: "v0.2-ai-natural-task-management"
readiness: 5
created: 2026-05-07
updated: 2026-05-07
sfif_stage: foundation
operator_directive_verbatim: "For the Ai it should feel like a Guided workflow each prompt, each interaction, even when its not comming from me should trigger the right continuition, the right progresses. This too deserves its own epic. its part of the context engineering knowleding and structure and addlc / sdlc and methodologies and high standards and Wiki LLM and other things that the Second-brain teach and help adhere to. this will be a continuous progress."
tags: [agent-drafted, epic, guided-workflow, context-engineering, sdlc, second-brain-doctrine]
---

# Epic E006 — Guided Workflow Continuation

> Agent-DRAFT v1 created 2026-05-07 per operator directive. Per SB-095 — flagged agent-DRAFT, operator-revisable.

## Mission

Every interaction with the AI — operator-typed prompt, cron-fire, PostCompact resume, SessionStart, hook-injected directive, auto-pilot loop iteration — MUST trigger the **right continuation** and the **right progress**. Not just substance-per-cycle (SB-128 already covers that); the substance must be **directionally correct** for where the project + the operator + the methodology + the Wiki LLM doctrine + the active mode + the priorities all converge.

This is **continuous progress**, not a one-time fix. The Epic is a forever-evolving discipline; modules under it advance the discipline incrementally.

## Why this is its own Epic (not absorbed into existing ones)

This Epic CROSSES every existing operational layer rather than fitting inside one:

| Existing layer | What this Epic adds |
|---|---|
| Cycle taxonomy (SB-128 / M-E001-1) | Substance gate — accepts ANY substance. E006 adds DIRECTIONAL gate — substance must align with the current vector of progress. |
| Mindfulness baseline (SB-126) | Per-prompt discipline reminder. E006 asks: does the discipline ENABLE the right continuation, or just block wrong patterns? |
| Iterative-evolution-pathway rule (D044) | Backlog-evolution + stage-gate + lens synergy + governance-integration discipline. E006 asks: do those discplines guide the agent IN-FLIGHT toward the right next step, or do they only post-hoc evaluate? |
| Mode-enforcement (SB-056/117) | Persona + cycle-steps + live-state. E006 asks: does the mode banner tell the agent WHAT to pick THIS fire (right continuation), or just remind WHO it is? |
| Priorities-as-guide (D6 of pathway) | P1-PN ordering. E006 asks: does the prioritization MECHANISM produce continuation-readiness, or just labels? |
| Context-engineering rule (auto/pre/on-demand/facultative) | What to inject when. E006 asks: does the right knowledge land at the right moment to enable the right next move? |

E006 is the **integration discipline** that ties these into a guided experience for the agent. Cousin to E001 auto-pilot rework + E002 piling-tasks + E003 compound-retention but at a higher abstraction layer.

## Scope

| In-scope | Out-of-scope |
|---|---|
| Designing how each interaction surface (prompt / cron / PostCompact / SessionStart / hook-injected) computes its "right continuation" | Re-implementing existing hook/skill mechanics (use them; don't replace) |
| Bridging Wiki LLM (second-brain) doctrine consumption into the agent's per-fire decision-making | Authoring new Wiki LLM content (that's second-brain's authoring layer) |
| AIDLC / SDLC / methodology / Wiki LLM / context-engineering / second-brain-teaching INTEGRATION patterns | Replacing methodology engine with new framework |
| Detection mechanisms for "wrong continuation" (drift, divergence, phantom-invocation per SB-142) | Strict enforcement that would block legitimate work; this is guidance not gating |
| Handoff documents, stamp content, mode banner content — making them DIRECTIONAL not just informational | Replacing the existing handoff/stamp/banner systems |

## Operator-stated themes (sacrosanct)

The directive enumerates these as part of the Epic's territory:

1. **Context engineering** — when knowledge lands; how it lands; in what shape (per `.claude/rules/context-engineering.md`)
2. **Knowledge structure** — how the project's wiki + governance + brain pieces compose (per wiki-schema + Concept-Page-Standards)
3. **AIDLC / SDLC** — application info-delivery lifecycle + software dev lifecycle integration
4. **Methodologies** — the 9 methodology models + 5 stage gates per `wiki/config/methodology.yaml`
5. **High standards** — quality bar per second-brain `wiki/spine/standards/` (25 standards)
6. **Wiki LLM** — second-brain as knowledge consumer; project consumes second-brain's syntheses
7. **Other second-brain teachings** — the sister-project doctrine + adoption guide + identity profiles

Each module under this Epic advances ONE or MORE of these themes through a concrete deliverable.

## Modules (DRAFT v1, agent-flagged per SB-095, operator-revisable)

### M-E006-1 — Continuation-readiness scoring per interaction surface

For each interaction type (operator-typed / cron-fire / PostCompact / SessionStart / hook-injected), define what "ready for right continuation" means + how to score it. Output: scoring schema + per-surface readiness check.

### M-E006-2 — Right-continuation candidate generator

Per fire, generate a ranked list of candidate next-actions grounded in: (a) active priorities · (b) active mode's cycle steps · (c) recent operator directives in `wiki/log/` · (d) decisions logbook GREENLIT items · (e) tracker rows in-progress · (f) methodology stage-gate readiness · (g) Wiki LLM consumed knowledge. The agent's per-fire pick = top of list (or operator-overridden). Output: tool/library that emits ranked candidates.

### M-E006-3 — Phantom-invocation guard (closes SB-142)

Pre-skill-execution premise-confirmation gate. Before executing forced-step skills (`/finish-smoothly`, `/terminate`, `/handoff`), agent verifies operator's literal invocation in recent message history (post-conversation-summary). If absent → confirm with operator. Output: hook + mindfulness clause #10 + tests.

### M-E006-4 — Wiki LLM consumption channel (depends on M007)

After M007 connect lands, build agent-side patterns for consuming second-brain knowledge per fire: (a) when to query `gateway query` · (b) when to read source-syntheses · (c) when to escalate to brain `wiki_search` MCP · (d) how to flag agent-DRAFT vs operator-confirmed knowledge per SB-095. Output: routing rule + decision tree.

### M-E006-5 — Continuation-drift detection

Cross-fire pattern detection: track edit-distribution per N=5 sliding window (project-layer vs meta-layer per SB-140 lesson); track action-type-distribution per N=5 (M-E001-1 vocabulary spread); track alignment-with-priorities (P1-PN advance vs short-circuit). When drift detected → emit warning + suggest pivot. Output: hook + tracker.

### M-E006-6 — Guided-workflow handoff template

Replace ad-hoc /handoff content with directional handoff: NOT just snapshot of state, but ranked continuation candidates + per-candidate "why this is right now" + per-candidate first-3-steps. Post-compact AI reads this and knows EXACTLY which fire to execute first. Output: template + rendering tool.

### M-E006-7 — Mode-banner directional content

Extend mode-enforcement banner to include "next-best-action this fire" candidate (top of M-E006-2's list). Currently banner shows mission/focus/priorities (descriptive); add continuation-pick (prescriptive). Output: hook extension + tests.

### M-E006-8 — AIDLC/SDLC/methodology integration synthesis

Single canonical doc explaining how AIDLC stages + SDLC stages + methodology stage-gates + SFIF macro-stages + project-lifecycle iterations all compose for guided-workflow purposes. Cross-references the 4 governing principles + 16 methodology models. Output: synthesis page in `wiki/concepts/` or equivalent.

### M-E006-9 — Continuous-progress tracking

Per-week or per-N-fire snapshot of guided-workflow discipline maturation: which modules landed, which interaction surfaces improved, which drift patterns reduced. Operator-empirical evaluation surface. Output: tracking rule + cadence.

## Dependencies

- **Hard**: `.claude/rules/iterative-evolution-pathway.md` (D044) — D8 SDD+SFIF+methodology+Wiki-LLM awareness section is the substrate
- **Hard**: M007 second-brain connect (gateway query / wiki_search MCP) — M-E006-4 gated on this
- **Soft**: Epic E001 auto-pilot rework — E006 sits ABOVE E001 (E001 = mechanism; E006 = directional discipline applied to mechanism)
- **Soft**: Epic E004 AI Modes Assistant doctor — cousin (E004 = reactive watchdog; E006 = proactive guidance)
- **Soft**: Epic E005 big-picture vision tool — cousin (E005 = surface for grounding; E006 = act per grounding)
- **Soft**: SB-142 phantom-invocation — M-E006-3 directly closes this

## Done When (Epic-level)

- [ ] All 9 modules created at `wiki/backlog/modules/root-modules-m-e006-*.md` with operator-revised scope
- [ ] M-E006-3 phantom-invocation guard mitigation landed (closes SB-142)
- [ ] Empirical evidence: 5+ consecutive autopilot loop runs show right-continuation pattern (operator-empirical-confirmed)
- [ ] Operator says: "the AI feels guided, each interaction continues the right way" (or revises this success criterion)
- [ ] Lessons captured at `wiki/lessons/01_drafts/guided-workflow-continuous-progress.md` for second-brain promotion candidate

## Connects to

- D044 iterative-evolution-pathway rule (the substrate this Epic operationalizes)
- D045 SB-140+SB-141 fix (informs the drift-detection mechanism for M-E006-5)
- SB-142 phantom-invocation (M-E006-3 closes)
- SB-128 substance-per-cycle (E006 adds directional dimension orthogonal to substance dimension)
- SB-117 modes deeper Epic (mode-banner directional content M-E006-7 builds on)
- E001 auto-pilot rework / E002 piling-tasks / E003 compound-retention / E004 doctor / E005 vision tool — sister Epics composing the autopilot doctrine
- `.claude/rules/iterative-evolution-pathway.md` D8 (SDD/SFIF/methodology/Wiki-LLM) — primary substrate
- `.claude/rules/context-engineering.md` — auto/pre/on-demand/facultative injection modes are the WHAT-WHEN; E006 is the WHY-NOW
- `<second-brain>/wiki/spine/super-model/super-model.md` — Wiki LLM doctrine reference
- Concept-Page-Standards (second-brain) — quality bar for E006's synthesis docs

## Operator-verbatim primary source

> *"For the Ai it should feel like a Guided workflow each prompt, each interaction, even when its not comming from me should trigger the right continuition, the right progresses. This too deserves its own epic. its part of the context engineering knowleding and structure and addlc / sdlc and methodologies and high standards and Wiki LLM and other things that the Second-brain teach and help adhere to. this will be a continuous progress."* — 2026-05-07, sacrosanct
