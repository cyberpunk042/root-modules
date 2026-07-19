---
title: "M-E004-1 — Research: doctor pattern (second-brain + openfleet) — document-stage scope"
type: module
status: in-progress
priority: P4
parent_epic: "epic-e004-ai-modes-assistant-doctor"
parent_milestone: "v0.2-ai-natural-task-management"
sfif_stage: foundation
current_stage: document
readiness: 20
created: 2026-05-07
updated: 2026-05-07
tags: [agent-drafted, m-e002-1-create-verb, e004, doctor-pattern, research-module, sub-agent-dispatch-candidate]
---

# M-E004-1 — Research: doctor pattern (second-brain + openfleet)

> **Agent-DRAFT v1** (per SB-095, operator-revisable). Created 2026-05-07 in autopilot loop fire post-test-count-refresh. Promotes Epic E004's first bullet from sketch to claimable scope-doc; module gates M-E004-2 through M-E004-8.

## Operator-stated seed (sacrosanct)

> *"we can probably add an AI Modes Assistant that help to enforce the mode and help with the tracking and the progress and detect when there is no stamp update or when the AI is in a recursive or needless endless loop or such. **A bit like the doctor notion in the second-brain and openfleet** I guess. We can take the time to create an EPIC and think about it... if we are in a mode and its been X tiem and or X prompts that the stamp didn't diff even one bit... with hhoks and all"* — 2026-05-07 (Epic E004 founding directive)

## Mission

Research the "doctor" notion as it exists in **second-brain** (`/opt/devops-solutions-information-hub/`) and **openfleet** (sister project). Surface: what doctor-pattern they implement, which surfaces it watches, which signals it acts on, which actions it takes (alert / pause / retarget / cancel), how it composes with mode-enforcement / cycle steps / hook envelope. Output: a single research-synthesis doc operator can review to decide which doctor-elements to adopt as-is, adapt for root-modules, or ignore.

## Research targets (in-scope)

| Target | Where to look | What to surface |
|---|---|---|
| **Second-brain doctor-pattern** | `/opt/devops-solutions-information-hub/.claude/rules/`, `wiki/spine/standards/`, `wiki/concepts/`, `raw/notes/` | Any rule / standard / concept page mentioning "doctor", "watchdog", "health-check", "stuck-detector", "recursion-detector". Capture verbatim doctrine + cross-refs. |
| **Openfleet doctor-pattern** | `~/openfleet/` (if accessible) — `.claude/`, `docs/`, `lib/` | Implementation specifics: how the doctor watches agents in fleet, what it pages on, which actions it autonomously takes vs operator-pending. |
| **Cross-references** | Both projects' brain files (CLAUDE.md / AGENTS.md / mode-files) | Mentions of "doctor" / "physician" / "stuck-loop-detector" / similar concepts. |
| **Identity-profile relevance** | `<second-brain>/wiki/ecosystem/project_profiles/` | Whether identity-profile dimensions affect whether/how doctor applies (e.g., type=root vs type=tool difference). |
| **Relationship to existing root-modules mechanisms** | `mode-enforcement.sh` · `mindfulness.sh` · `agent-output-scan.sh` (just landed F31) · `loop-cron-lifecycle.md` rule | Which existing mechanisms ALREADY perform doctor-shaped work; which gaps a new doctor would fill. |

## Research targets (out-of-scope for THIS module)

- Implementation of the doctor itself (M-E004-2 through M-E004-7 — gated on this module's findings)
- Schema design for doctor config (M-E004-7)
- Tests (M-E004-8)
- Operator-empirical verification (M-E004-8)
- Cross-project propagation pattern (separate concern — bidirectional inheritance per `self-reference.md`)

## Methodology

Per work-mode.md research-first principle (#5) + sub-agent dispatch convention:

### Phase A — Survey (read-only)

1. **Sub-agent dispatch** (using `Agent` tool with `subagent_type=Explore`): query second-brain for "doctor" / "watchdog" / "health-check" mentions across `wiki/`, `.claude/rules/`, `raw/notes/`. Tip: query is "thorough" level — search multiple naming patterns since concept may have multiple lexical forms.
2. **Sub-agent dispatch**: query openfleet (if accessible at `~/openfleet/`) for the same concepts.
3. Sub-agent reports: enumerated findings with verbatim quotes + file paths + cross-refs. Aggregate to a single "research log" file at `wiki/log/<ts>-doctor-pattern-research-findings.md`.

### Phase B — Synthesis (agent)

1. Read the aggregated findings.
2. Categorize: (a) explicit doctor-pattern docs (rules / standards) · (b) implicit doctor-shaped mechanisms (existing in code without being labeled doctor) · (c) absence (no relevant content).
3. Identify ROOT-GHOSTPROXY gaps + adaptation opportunities (per identity-profile dimensions).
4. Write synthesis doc at `wiki/concepts/doctor-pattern-synthesis.md` (or equivalent location operator chooses).

### Phase C — Operator review

1. Surface synthesis to operator.
2. Operator decides: adopt as-is / adapt / partial-adopt / ignore / iterate.
3. Operator-decision drives scope of M-E004-2 through M-E004-7.

## Deliverables

| Deliverable | Path | Owner |
|---|---|---|
| Research findings (verbatim quotes + paths) | `wiki/log/<ts>-doctor-pattern-research-findings.md` | sub-agent → agent aggregates |
| Synthesis doc | `wiki/concepts/doctor-pattern-synthesis.md` | agent (post-research) |
| Decision logbook entry capturing operator's adoption choice | `wiki/governance/decisions.md` (D-XXX) | operator-confirmed |
| Updated Epic E004 scope (M-E004-2..7 refined per doctor-elements adopted) | `wiki/backlog/epics/epic-e004-ai-modes-assistant-doctor.md` | agent (post-decision) |

## Done When (M-E004-1 module-level)

- [ ] Sub-agent dispatched to second-brain (Explore subagent type, thorough)
- [ ] Sub-agent dispatched to openfleet (if accessible; if not, document gap)
- [ ] Research findings aggregated at `wiki/log/<ts>-doctor-pattern-research-findings.md` with verbatim-quoted source content + file paths
- [ ] Synthesis doc authored at `wiki/concepts/doctor-pattern-synthesis.md` distinguishing (a) explicit doctor-pattern / (b) implicit doctor-shaped / (c) absence per project
- [ ] Gap analysis: which doctor-elements root-modules LACKS that second-brain or openfleet have
- [ ] Adaptation opportunities: which root-modules mechanisms could compose with adopted doctor-pattern (mode-enforcement / mindfulness / agent-output-scan / loop-cron-lifecycle)
- [ ] Operator review of synthesis + adoption decision (decision logbook entry)
- [ ] Epic E004 scope refined per adoption decision (M-E004-2..7 refined or scope-changed)

## Dependencies

- **Hard**: `Agent` tool (Explore subagent type) — required for the sub-agent dispatch
- **Hard**: Second-brain readability at `/opt/devops-solutions-information-hub/` (read-only OK per work-mode.md principle #9)
- **Soft**: Openfleet accessibility at `~/openfleet/` (if present). If absent: research limited to second-brain only; operator notes for follow-up
- **Soft**: M007 second-brain connect (when landed, `gateway query` becomes preferred channel over raw filesystem reads)
- **Soft**: Operator review window (sub-agent dispatch + operator review = potentially multi-fire arc; module is NOT atomic)

## Risk + caveats

| Risk | Mitigation |
|---|---|
| Sub-agent dispatch lands generative noise (false-positives, paraphrased rather than verbatim) | Sub-agent prompt MUST require verbatim-quote-with-path format; reject paraphrased-only output |
| "Doctor" concept may not exist by that label in second-brain/openfleet | Sub-agent prompt covers cousin terms (watchdog / health-check / stuck-detector); absence is itself a finding |
| Research finds rich pattern that doesn't translate to root-modules identity (type=root, group=operating-system-setup) | Synthesis must explicitly check identity-profile fit before recommending adoption |
| Sub-agent dispatch under autopilot loop is heavier than per-fire substance — may not complete in single fire | Treat as multi-fire arc; per-fire surface progress (Phase A start → Phase A complete → Phase B → Phase C) |
| Operator pending review during loop produces stall | Acceptable: sub-agent kicks off, operator reviews when ready, agent continues other modules in interim per Hard Rule 13 chain |

## Connects to

- Epic E004 (parent): `wiki/backlog/epics/epic-e004-ai-modes-assistant-doctor.md`
- Epic E005 (cousin — proactive grounding): `wiki/backlog/epics/epic-e005-big-picture-vision-tool.md`
- Epic E006 (cousin — guided continuation): `wiki/backlog/epics/epic-e006-guided-workflow-continuation.md`
- M-E006-3 (sister — phantom-invocation guard, also a behavioral-bug catcher): `wiki/backlog/modules/root-modules-m-e006-3-phantom-invocation-guard.md`
- D044 iterative-evolution-pathway rule (D8 SDD/SFIF/methodology/Wiki-LLM): `.claude/rules/iterative-evolution-pathway.md`
- Existing doctor-shaped mechanisms in root-modules: `agent-output-scan.sh` (reactive Stop-hook), `mindfulness.sh` (proactive UserPromptSubmit), `mode-enforcement.sh` (banner state), `loop-cron-lifecycle.md` (autonomous cancel rule)
- `<second-brain>/raw/notes/` (research target — read-only access)
- `~/openfleet/` (research target — if accessible)
- Three-layer mitigation pattern (cousin doctrine — proactive + reactive + tests): `wiki/patterns/01_drafts/three-layer-mitigation-for-agent-behavioral-bugs.md`
