---
title: "M-E007-1 — Input-intent commands taxonomy + slash command set (gated on M-E007-8 quality standards landing)"
type: module
status: in-progress
priority: P3
parent_epic: "epic-e007-driver-empowerment-and-input-intent-disambiguation"
parent_milestone: "v0.2-ai-natural-task-management"
sfif_stage: foundation
current_stage: document
readiness: 20
created: 2026-05-07
updated: 2026-05-07
tags: [agent-drafted, m-e002-1-create-verb, e007, input-intent-commands, slash-command-design, gated-on-m-e007-8]
---

# M-E007-1 — Input-intent commands taxonomy

> **Agent-DRAFT v1** (per SB-095, operator-revisable). Created 2026-05-07 cron F53 in autopilot loop. Promoted from Epic E007's M-E007-1 bullet to scope-doc. **Gated**: command implementation MUST wait for M-E007-8 quality standards rule to land (per Epic E007 risk-mitigation table: "commands earn their place per the standard").

## Operator-stated seed (sacrosanct)

> *"things the second-brain are saying make me think that we could have compound and waterfall commands and even comment and such to allow me to not even let it to chance how to interprete what I just gave in input for example. not that there is no need for a mimimal logic and routing when I dont use a command but that if I know I am just makinga **comment or a sidenote vs something I want to target now or add to the compound** and etc.... I should know very well my command and how to change the mission the focus and etc and or even multiple things at the same time / group and chain calls and such."* — 2026-05-07 (Epic E007 founding directive)

## Mission

Define the **canonical input-intent vocabulary** — slash commands the operator types to declare their input's intent so AI doesn't INTERPRET-by-chance. Operator's literal seed: **4 categories** (comment / sidenote / target-now / compound-add). Agent-proposed extensions surface as DRAFT for operator-revision.

The taxonomy MUST satisfy M-E007-8's S1 proliferation criterion (≥3 of 5: distinct semantic intent · operator-stated need · composes with existing tools · documented use cases · no alias-only justification).

## Operator-stated 4 categories (sacrosanct, MUST be preserved)

| Category | Operator's literal phrasing | Semantic |
|---|---|---|
| **comment** | *"comment"* | Background context; AI logs but doesn't act. |
| **sidenote** | *"sidenote"* | Aside related to current work; AI integrates as context-additive (per principle #6) but doesn't pivot. |
| **target-now** | *"something I want to target now"* | Current-fire action directive; AI prioritizes this in the active fire's substance. |
| **compound-add** | *"add to the compound"* | Layer onto existing compound state (mission/focus/priorities/etc.) per `compound-and-waterfall.md` axis. |

## Agent-proposed extensions (DRAFT v1, agent-flagged per SB-095)

| Category (proposed) | Why proposed | M-E007-8 S1 score | Operator-decision |
|---|---|---|---|
| **/aside** | Subtler than /comment — flagged for next-fire pickup, not just background | 3/5 (distinct + composes-with-cycle-skill + use-cases) | revisable |
| **/waterfall-add** | Sister to /compound-add for sequential flow per `compound-and-waterfall.md` waterfall axis | 4/5 (distinct + operator-axis-stated + composes + use-cases) | revisable |
| **/now-cancel** | Cancel a target-now mid-fire if operator changes mind | 3/5 (distinct + composes + use-cases) | revisable |
| **/clarify** | Operator's input is intentionally ambiguous; AI should ASK rather than infer | 4/5 (distinct + premise-confirmation aligned + composes + use-cases) | revisable |
| **/silent-note** | Like /comment but explicitly suppresses AI acknowledgment in response | 3/5 (distinct + composes + use-cases; weak alias-risk vs /comment) | revisable; possibly merge with /comment |

## Composition with existing 44 slash commands

Per Epic E007's "Why this is its own Epic" + per work-mode.md + per `routing.md`: input-intent commands operate at a DIFFERENT layer than state-mutation commands.

| Layer | Examples | Layer purpose |
|---|---|---|
| **State-mutation** | `/mission`, `/focus`, `/impediment`, `/priorities`, `/task`, `/questions`, `/decisions`, `/log` | Change project state |
| **State-display** | `/orient`, `/blockers`, `/progress`, `/audit`, `/help-root`, `/mode-status`, `/stamp-status`, `/statusline-status` | Read project state |
| **Cycle-driver** | `/cycle`, `/finish-smoothly`, `/terminate`, `/handoff`, `/sync-progress` | Drive autopilot or session lifecycle |
| **Mode-set** | `/mode-{pm,architect,dual,clear,status}` | Set/get active mode |
| **Visual-config** | `/stamp-{horizontal,vertical,...}`, `/statusline-{focus,base,...}`, `/install-agent-brain` | Configure visual / install state |
| **NEW: Input-intent (M-E007-1)** | `/comment`, `/sidenote`, `/target-now`, `/compound-add` (operator-stated 4) + DRAFT extensions | Declare what THIS interaction IS so AI doesn't interpret by chance |

## Composition with group/chain primitives (M-E007-3)

Per Epic E007's M-E007-3: group + chain primitives let operator change multiple state pieces at once (group: atomic; chain: sequential). Input-intent commands compose:

- `/group --intent target-now --mission "X" --focus "Y"` — atomic group with target-now intent
- `/chain --intent compound-add /focus "X" -> /priorities-add "Y"` — sequential chain with compound-add intent

This composition fits per M-E007-8 S1 criterion 3 (composes with existing tools).

## Implementation sequencing (per Epic E007 risk-mitigation)

**M-E007-8 MUST LAND FIRST** — quality standards rule at `.claude/rules/command-quality-standards.md`. Each command in this M-E007-1 taxonomy MUST satisfy S1 proliferation criterion before authoring. Commands authored before M-E007-8 lands BYPASS the gate.

**Per-command authoring pattern** (when M-E007-8 lands):

1. Author command file at `.claude/commands/<name>.md` per M-E007-8 S2 (frontmatter description ≤80 chars, body sections, cross-references)
2. Compose with existing tools (e.g. `/comment` → invokes `tools.log` with intent flag)
3. Add to cross-reference graph per M-E007-6
4. If complex: author per-command manual page per M-E007-5 S3
5. Test: hook-test verifying invocation produces correct intent classification

## Done When (M-E007-1 module-level)

- [ ] M-E007-8 quality standards rule landed (gating dependency)
- [ ] Operator review of operator-stated 4 categories + agent-proposed extensions (decision: which extensions adopt, drop, or modify)
- [ ] Decision logbook entry capturing operator's command-set selection (D-XXX)
- [ ] Per-command authoring per M-E007-8 S2: 1 `.md` file per adopted command (4 minimum + N extensions)
- [ ] Cross-reference graph updated per M-E007-6 (composes_with field on existing commands' frontmatter where applicable)
- [ ] Documentation: master manual section per M-E007-4 + per-command manuals per M-E007-5 S3 where warranted
- [ ] Hook-test coverage: verify each command classified correctly + no unintended interactions with existing commands
- [ ] Empirical: 1+ session shows operator using new commands deliberately + AI responding per intent classification
- [ ] Lessons captured at `wiki/lessons/01_drafts/input-intent-disambiguation-empirical.md` post-empirical

## Dependencies

- **Hard**: M-E007-8 quality standards rule (gating per Epic E007 risk-mitigation)
- **Hard**: Operator review of operator-stated 4 categories + agent-proposed extensions (operator-pick scope)
- **Hard**: `.claude/rules/words-are-sacrosanct.md` (the substrate this module operationalizes — proactive flip of premise-confirmation gate)
- **Soft**: M-E007-3 group + chain primitives (composition target)
- **Soft**: M-E007-4 master manual (where these commands get documented)
- **Soft**: M-E007-6 cross-reference graph (where composes-with field gets populated)
- **Soft**: M007 second-brain connect (for cross-referencing canonical Concept-Page-Standards)

## Risk + caveats

| Risk | Mitigation |
|---|---|
| Naming collisions with existing 44 commands | M-E007-8 S5 anti-pollution rejection trigger #1 (semantic-verb duplication); enumerate existing namespace before authoring each command |
| Agent-proposed extensions adopted without operator-explicit-review | Per SB-095 + this page's flagging — adoption requires operator-pick decision logbook entry |
| `/comment` and `/sidenote` semantically overlap (both = background context) | Operator-pick: merge into one OR clarify distinction in M-E007-4 manual |
| Operator-driver onboarding cost (4-8 new commands to learn) | M-E007-9 onboarding journey doc; bootstrap from minimal subset (start with operator-stated 4) |
| Implementation drift from M-E007-8 standard (commands authored bypass the gate) | Sequencing discipline: this module's Done-When item 1 is M-E007-8 landed; downstream items gated |

## Connects to

- Epic E007 (parent): `wiki/backlog/epics/epic-e007-driver-empowerment-and-input-intent-disambiguation.md`
- Sister M-E007-8 (gating quality standards): `wiki/backlog/modules/root-modules-m-e007-8-anti-pollution-quality-standards.md`
- Sister M-E007-3 (group + chain primitives — composition target)
- Sister M-E007-4 (master manual)
- Sister M-E007-6 (cross-reference graph)
- `.claude/rules/words-are-sacrosanct.md` (substrate — premise-confirmation gate proactive flip)
- `.claude/rules/compound-and-waterfall.md` (substrate — compound + waterfall axes /compound-add and /waterfall-add operationalize)
- `.claude/rules/routing.md` (extends — routing handles prose; commands handle explicit intent)
- D044 iterative-evolution-pathway rule
- Cousin Epic E006 module M-E006-1 continuation-readiness scoring (input-intent IS one signal continuation-readiness consumes)
