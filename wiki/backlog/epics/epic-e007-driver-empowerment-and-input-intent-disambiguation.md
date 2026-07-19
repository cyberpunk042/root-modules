---
title: "Epic E007 — Driver Empowerment + Input-Intent Disambiguation: explicit commands for comment/sidenote/target-now/compound/waterfall + master manual + group/chain primitives"
type: epic
status: not-started
priority: P3
parent_milestone: "v0.2-ai-natural-task-management"
readiness: 5
created: 2026-05-07
updated: 2026-05-07
sfif_stage: foundation
operator_directive_verbatim: "things the second-brain are saying make me think that we could have compound and waterfall commands and even comment and such to allow me to not even let it to chance how to interprete what I just gave in input for example. not that there is no need for a mimimal logic and routing when I dont use a command but that if I know I am just makinga comment or a sidenote vs something I want to target now or add to the compound and etc.... we will need to think about all this. again at least one new Epic with new tasks (obviously this all comes with the need for cross references and a master manual and manuals and directives and assistance) this is all part of the aidlc / sdlc and methodology mindset. I should know very well my command and how to change the mission the focus and etc and or even multiple things at the same time / group and chain calls and such. with the proper set of commands and manuals a Driver is well more equiped and the AI too. with the right tools and explained and no polution or low standard of commands and documentation and manuals and also tools I guess"
tags: [agent-drafted, epic, driver-empowerment, input-intent-disambiguation, compound-waterfall-commands, master-manual, aidlc-sdlc, no-pollution]
---

# Epic E007 — Driver Empowerment + Input-Intent Disambiguation

> Agent-DRAFT v1 created 2026-05-07 14:34 EDT per operator directive in autopilot loop. Per SB-095 — flagged agent-DRAFT, operator-revisable.

## Mission

The operator-driver and the AI co-pilot work better when the operator's input INTENT is **explicit-by-command** rather than **interpreted-by-AI**. Today, prose without a slash command requires the AI to infer: is this a comment? a sidenote? a target-now directive? a compound-state addition? a waterfall flow? Each interpretation has different action semantics. Misinterpretation costs cycles (cousin to SB-090 premise-construction + SB-121 cron-vs-operator-collide-not-compound).

E007 closes the gap by:
- Adding **input-intent commands** the operator can prefix to declare intent: `/comment` / `/sidenote` / `/aside` / `/target-now` / `/compound-add` / `/waterfall-add` (names DRAFT, operator-revisable).
- Adding **compound + waterfall semantic commands** the operator uses to LAYER content (compound) or SEQUENCE content (waterfall) explicitly.
- Adding **group + chain primitives** so the operator can change multiple state pieces at once (mission + focus + priorities together) or sequence them deterministically.
- Authoring a **master manual** + per-command manuals so the operator-driver knows the toolkit + the AI has the manual as authoritative reference.
- Establishing **anti-pollution standards**: when to add a new command vs extend existing; documentation quality bar; tools quality bar.
- Preserving **routing-for-prose**: operator can still type prose without command; minimal-logic routing handles that path (per `routing.md`).

This Epic is **continuous-progress** — manuals + commands + standards iterate as the project evolves.

## Why this is its own Epic (not absorbed into existing ones)

| Existing layer | What E007 adds |
|---|---|
| `routing.md` (operator-intent → tool routing) | Routing covers PROSE-only inputs. E007 adds explicit-COMMAND inputs that bypass interpretation entirely. |
| `compound-and-waterfall.md` rule (compound vs waterfall axes) | Rule defines the AXES; E007 operationalizes them as COMMANDS the operator can invoke. |
| Epic E003 compound-retention + multi-group | E003 is the substrate (group/chain primitives). E007 extends with COMMAND-LAYER semantics + manuals. |
| Epic E006 guided workflow | E006 = right continuation per interaction. E007 = explicit naming of what THIS interaction IS so right continuation is deterministic-not-interpretive. |
| `words-are-sacrosanct.md` (operator words sacrosanct, premise-confirmation) | Rule is reactive (don't infer wrong). E007 is proactive (operator-typed command says intent, no inference needed). |
| Existing 43 slash commands | Most are state-mutation (change mission / focus / priorities individually). E007 adds GROUP/CHAIN composers + INPUT-INTENT prefixes. |

## Scope

| In-scope | Out-of-scope |
|---|---|
| New input-intent slash commands (`/comment` / `/sidenote` / `/aside` / `/target-now` / etc.) | Re-implementing existing 43 commands |
| Compound-add + waterfall-add semantic commands | Re-defining the compound/waterfall RULE (already exists at `.claude/rules/compound-and-waterfall.md`) |
| Group + chain primitives at command layer | Re-implementing `tools.group` (already exists) |
| Master manual document | Replacing existing `.claude/commands/README.md` |
| Per-command manual pages | Replacing per-command `.md` files |
| Cross-reference graph (which command relates to which) | Building a full ontology engine |
| Anti-pollution standards | Auditing existing commands for compliance (separate Epic if needed) |
| Documentation + assistance surface (which command to use when) | Replacing existing `routing.md` (extends it) |

## Modules (DRAFT v1, agent-flagged per SB-095, operator-revisable)

### M-E007-1 — Input-intent commands taxonomy + slash command set

Define the canonical input-intent vocabulary. Operator's seed: `comment / sidenote / target-now / compound-add`. Agent-proposed extensions: `/aside` (similar to comment but flagged for next-fire reading) · `/waterfall-add` (sister to compound-add for sequential flow) · `/now-cancel` (cancel a target-now mid-fire). Output: 4-8 slash commands at `.claude/commands/<name>.md` + tests.

### M-E007-2 — Compound-add + waterfall-add semantic commands

Explicit commands for "ADD this content to the compound state" (mission/focus/priorities — layer it) vs "ADD this to the waterfall flow" (cycle event sequence — sequence it). Composes with M-E006 directional handoff. Output: 2 slash commands + composes with `tools.objective` / `tools.priorities`.

### M-E007-3 — Group + chain command primitives

Multi-state-change in one operator turn: e.g. `/group set --mission "X" --focus "Y" --priorities "P1,P2,P3"` (atomic). Or chain: `/chain mission "X" -> focus "Y" -> priorities-add "Z"` (sequential, can fail mid-chain). Operator's seed: *"change the mission the focus and etc and or even multiple things at the same time / group and chain calls"*. Output: 2 slash commands + `tools.group` extension if needed (already exists per Q1 Layer A canonical taxonomy).

### M-E007-4 — Master manual

Single canonical doc operator-driver reads to know the FULL toolkit. NOT a replacement for `.claude/commands/README.md` (which is the index); the manual is the **HOW-TO compendium**: usage patterns, common workflows, anti-patterns, examples. Path candidate: `MANUAL.md` at project root or `wiki/manuals/master-manual.md`. Cross-references all 43+ existing commands + new E007 commands.

### M-E007-5 — Per-command manual pages

For commands NEEDING deeper manual (not all need it — anti-pollution): `wiki/manuals/<command>/manual.md` per command. Compounds with the command's `.md` definition (which is the implementation) by separating WHAT (definition) from HOW-TO-USE-IT (manual).

### M-E007-6 — Cross-reference graph

Which commands relate to which. E.g. `/mission` ↔ `/focus` ↔ `/priorities` ↔ `/group`. Output: cross-ref doc + frontmatter `composes_with` field on existing commands. Composes with the F011 future-decision (slash-command frontmatter empowerment per `context-engineering.md`).

### M-E007-7 — Directives + assistance surface

Proactive AI-side surface: when operator types prose, AI suggests "did you mean to use `/<X>` here?" if the prose maps to a known command. Not blocking — informational. Output: hook extension OR slash command `/assist` that takes prose + suggests command + verb. Composes with E005 big-picture vision + E006 guided workflow.

### M-E007-8 — Anti-pollution + quality standards

Standards doc establishing: when to add a new command vs extend existing; per-command documentation minimum; manual quality bar. Cross-references second-brain `wiki/spine/standards/` (when M007 lands). Output: rule at `.claude/rules/command-quality-standards.md`.

### M-E007-9 — Operator-driver onboarding journey

A walkthrough: "if you're new (or returning after compaction), here's how to get effective with the toolkit in N minutes". Cousin to BOOTSTRAP.md (which is for AI cold-pickup). Output: doc at `wiki/manuals/operator-driver-onboarding.md`.

### M-E007-10 — Continuous-quality-tracking

Per-week or per-N-fire quality check: which commands underused? overused? misnamed? Documentation drift? Manual staleness? Cousin to E006 module M-E006-9. Output: tracking rule + cadence.

## Operator-stated themes (sacrosanct, must be preserved)

1. **Don't leave to chance how AI interprets input** — explicit-command-typed = no interpretation; prose-no-command = routing layer interprets minimally
2. **Comment / sidenote vs target-now / compound-add distinction** — 4 named intent categories minimum
3. **Multi-things-at-once via group + chain** — operator can change mission + focus + priorities atomically OR sequentially via single command invocation
4. **Master manual + per-command manuals + cross-references + directives + assistance** — documentation hierarchy
5. **AIDLC / SDLC / methodology mindset** — Epic embedded in methodology engine + iterates per stage gates
6. **Driver well-equipped + AI well-equipped** — bilateral; both benefit from explicit commands
7. **No pollution + no low-standard** — quality discipline; new commands earn their place

## Done When (Epic-level)

- [ ] All 10 modules created at `wiki/backlog/modules/root-modules-m-e007-*.md` with operator-revised scope
- [ ] M-E007-1 through M-E007-3 slash commands authored + tested + wired
- [ ] M-E007-4 master manual authored + cross-referenced from CLAUDE.md / AGENTS.md / BOOTSTRAP.md
- [ ] M-E007-7 assistance surface authored
- [ ] M-E007-8 quality standards rule authored
- [ ] Empirical: 3+ consecutive sessions show operator using new commands deliberately + AI responding correctly per command-named intent
- [ ] Operator says: "the toolkit is well-equipped, no pollution" (or revises this success criterion)
- [ ] Lessons captured at `wiki/lessons/01_drafts/driver-empowerment-and-input-intent-disambiguation.md` for second-brain promotion candidate

## Dependencies

- **Hard**: `.claude/rules/compound-and-waterfall.md` (the substrate axis E007 commands operationalize)
- **Hard**: `.claude/rules/words-are-sacrosanct.md` + premise-confirmation gate (E007 commands are the proactive flip side of the reactive rule)
- **Hard**: Epic E003 multi-group composition + `tools.group` primitive (group + chain commands compose this)
- **Soft**: M007 second-brain connect (anti-pollution standards reference second-brain `wiki/spine/standards/`; manuals can adopt second-brain Concept-Page-Standards)
- **Composes with**: Epic E006 guided workflow (E007 commands are the operator-side flip; E006 is the AI-side continuation)
- **Composes with**: Epic E005 big-picture vision (master manual + assistance surface compose with bigview composer)
- **Cousins**: Epic E001 (M-E001-1 agent-action vocabulary) + Epic E002 piling-tasks (backlog hierarchy authoring) + Epic E003 (compound-retention) + Epic E004 (doctor) — different sides of the same overall doctrine

## Risk + caveats

| Risk | Mitigation |
|---|---|
| Command proliferation (adding 8-10 commands violates the "no pollution" criterion the directive itself names) | M-E007-8 quality standards rule MUST land BEFORE M-E007-1 slash commands; commands earn their place per the standard |
| Operator-driver onboarding cost (new commands to learn) | M-E007-9 onboarding journey doc; bootstrap from a minimal subset operator agrees is highest-value |
| Manual staleness (manuals drift faster than commands) | M-E007-10 continuous-quality-tracking; per-week or per-N-fire health-check |
| Cross-Epic confusion (E006 + E007 + E005 all sound similar) | This Epic page's "Why this is its own Epic" table addresses; operator may merge if too redundant |
| Naming collisions (`/comment` may conflict with existing tools) | M-E007-1 must enumerate existing namespace before proposing names |

## Connects to

- D044 iterative-evolution-pathway rule (D7 artifact-preparation + D8 SDD/SFIF/methodology — substrate)
- `.claude/rules/compound-and-waterfall.md` (rule the commands operationalize)
- `.claude/rules/words-are-sacrosanct.md` (proactive flip)
- `.claude/rules/routing.md` (extends — routing handles prose; commands handle explicit intent)
- `.claude/rules/context-engineering.md` (auto/pre/on-demand/facultative — manuals are on-demand)
- Epic E001 / E002 / E003 / E004 / E005 / E006 (sisters — same overall doctrine)
- M-E006-1 continuation-readiness scoring (E006 module) — composes with E007 commands as input-intent signal
- M-E006-7 mode-banner directional content — composes with E007 master manual
- `<second-brain>/wiki/spine/standards/` (manual quality bar reference)
- `<second-brain>/wiki/spine/super-model/` (Wiki LLM doctrine)

## Operator-verbatim primary source

> *"things the second-brain are saying make me think that we could have compound and waterfall commands and even comment and such to allow me to not even let it to chance how to interprete what I just gave in input for example. not that there is no need for a mimimal logic and routing when I dont use a command but that if I know I am just makinga comment or a sidenote vs something I want to target now or add to the compound and etc.... we will need to think about all this. again at least one new Epic with new tasks (obviously this all comes with the need for cross references and a master manual and manuals and directives and assistance) this is all part of the aidlc / sdlc and methodology mindset. I should know very well my command and how to change the mission the focus and etc and or even multiple things at the same time / group and chain calls and such. with the proper set of commands and manuals a Driver is well more equiped and the AI too. with the right tools and explained and no polution or low standard of commands and documentation and manuals and also tools I guess"* — 2026-05-07, sacrosanct
