---
title: "M-E005-1 — Inventory existing partial-view tools (Big-Picture-Vision Epic E005 — survey-and-gap-analysis stage)"
type: module
status: in-progress
priority: P3
parent_epic: "epic-e005-big-picture-vision-tool"
parent_milestone: "v0.2-ai-natural-task-management"
sfif_stage: foundation
current_stage: document
readiness: 30
created: 2026-05-07
updated: 2026-05-07
tags: [agent-drafted, m-e002-1-create-verb, e005, inventory, big-picture-vision, survey]
---

# M-E005-1 — Inventory existing partial-view tools

> **Agent-DRAFT v1** (per SB-095, operator-revisable). Created 2026-05-07 in autopilot loop fire post-CLAUDE.md/hook-architecture drift refresh. Promotes Epic E005's first module from bullet to claimable scope-doc with seed inventory.

## Operator-stated seed (sacrosanct)

> *"Is there not tool that give big picture visions are you not supposed to used them ? are you not dirrected to use the proper information ? are not even piece injected ? maybe that is still missing. that should probably be at least one new Epic with tasks.."* — 2026-05-07 (E005 Epic founding directive)

## Mission

**Enumerate every existing surface** in `$HOME/` that provides a project-state view (full or partial) — tools, state files, hook outputs, slash commands, MCP, banner, stamp. Tabulate WHAT each surfaces vs WHAT it omits. Identify the **gap** between current scattered partial views and the operator-named "big picture vision" that grounds agent decision-points.

## Scope (in-scope vs out-of-scope)

| In-scope | Out-of-scope |
|---|---|
| Inventory of EXISTING surfaces | Authoring the new big-picture tool (M-E005-2+ scope) |
| Composability matrix (which surfaces compose, which collide) | Re-implementing existing surfaces |
| Gap analysis (what isn't covered by ANY current surface) | Replacing /orient or /audit (use, don't replace) |
| Cross-reference to wiki-LLM (second-brain) consumption channels | M007 connect work itself |
| Decision-point grounding pattern (where in agent's per-fire flow the big picture should land) | Implementation of the grounding mechanism |

## Initial inventory (DRAFT v1 — agent-authored 2026-05-07, empirically counted)

### Tools (15 .py modules at `$HOME/tools/`)

| Tool | View provides | Coverage |
|---|---|---|
| `tools.state` | Active mode + system identity | Narrow (mode + identity) |
| `tools.blockers` | Pending operator decisions + drift check | Narrow (governance) |
| `tools.progress` | Active milestone + journey + callout | Narrow (progress) |
| `tools.decisions` | Decision logbook (D001-D046) | Narrow (decisions) |
| `tools.cycle` | Active mode + cycle definition + state + blockers + progress + lifecycle signals | **Composed** (multiple views in one command — closest to "big picture") |
| `tools.tasks` | Task list / claimable / cursor / create | Narrow (tasks) |
| `tools.objective` | Mission / Focus / Impediment | Narrow (objective layer) |
| `tools.priorities` | P1-PN list | Narrow (priorities) |
| `tools.questions` | Agent-pending questions queue | Narrow (questions) |
| `tools.stamp` | Stamp layout config + render | Narrow (stamp config) |
| `tools.group` | Chain/group/tree composition primitive | Narrow (composition) |
| `tools.run-tests` | Aggregate test result | Narrow (regression) |
| `tools.mcp_server` | MCP tool server (10 `root_*` tools) | Narrow (per-tool) |
| `tools._paths` | Path resolution helper | Internal |
| `tools.__init__` | Package init | Internal |

### State files (`.claude/active-*`)

| State file | View provides |
|---|---|
| `.claude/active-mode` | Active mode (single value) |
| `.claude/active-mission` | Active mission (single string) |
| `.claude/active-focus` | Active focus (single string) |
| `.claude/active-impediment` | Active impediment (single string or unset) |
| `.claude/active-priorities` | Priorities list (P1-PN) |
| `.claude/active-task` | Active task cursor (T### or unset) |
| `.claude/active-questions-detail/` | Agent-pending questions detail dir |

### Composed surfaces (multi-view rendering)

| Surface | Composes | When |
|---|---|---|
| `/orient` (slash command) | 21-step chain reading brain + tracker + recent logs + git state + mode + sister-projects | Cold-pickup OR operator-on-demand |
| `/cycle` (mode-aware) | Active mode's cycle steps + mission/focus/impediment + blockers + progress + tracker | Per-cron-fire OR operator-on-demand |
| `end-of-cycle-stamp.sh` (Stop hook) | Status / Journey / Plan / Tracker / Cursor / Mission / Focus / Impediment / Priorities | End-of-turn |
| `mode-enforcement.sh` (UserPromptSubmit hook) | Mode + persona + cycle steps + priorities + mission/focus/impediment + live state | Per-prompt when active-mode set |
| `python3 -m tools.cycle --ansi-horizontal` | Stamp render on demand | Operator-on-demand |
| `python3 -m tools.cycle --json` | Structured cycle state for AI/MCP consumers | Programmatic |
| `python3 -m tools.cycle --json` + `tools.cycle` lifecycle_signals | Auto-flagged scenarios per loop-cron-lifecycle.md | Cron-fire self-eval |
| `/audit` (slash command) | 10-step integrity check (yamls + hooks + blockers + decisions + state files) | On-demand |
| `root_orient` MCP tool | Structured intel for AI consumers | MCP |

### MCP tools (10 `root_*`)

`root_state` · `root_blockers` · `root_progress` · `root_decisions_{list,get,verify,next_id}` · `root_objective` · `root_questions` · `root_orient`

### Slash commands (43, per CLAUDE.md row 243 empirically verified 2026-05-06)

8 categories: orient/cycle, modes, stamp, statusline, objective layer, backlog, knowledge/audit, install. Most are NARROW (single-surface view); `/orient` + `/cycle` + `/audit` are COMPOSED.

## Gap analysis (DRAFT v1, agent-flagged per SB-095)

**What's covered well**:
- Per-axis view (each axis has a tool: blockers, progress, decisions, tasks, etc.)
- Composed views for cold-pickup (/orient) + per-cycle (/cycle) + end-of-turn (stamp)
- Programmatic surfaces for MCP consumers
- Mode-aware banner-layer composition

**What's gap (operator-stated theme)**:

1. **Decision-point grounding view** — at the moment the agent picks next-fire substance, no single command surfaces the FULL relevant context (active priorities + open SBs + claimable tasks + recent operator directives + recent decisions + pending Qs + integrity drift status). The agent currently composes this manually per fire. A single `tools.bigview` or `/bigview` would compose it deterministically.

2. **Cross-Epic visibility** — current surfaces show ACTIVE Epic state (M003 Foundation), but Epic E001-E006 cross-cutting state (which Epic has most modules in-progress, which is most stalled, which has most-recent operator directives) is NOT surfaced anywhere.

3. **Wiki-LLM (second-brain) consumption layer** — `gateway query` exists (after M007 connect) but is not threaded into agent's per-fire decision-point. M-E006-4 covers the channel; M-E005 covers the surface that would consume it.

4. **Drift surface** — `install.sh --check` shows install drift; `tools.blockers --check` shows blocker-vs-task-status drift; `tools.run-tests` shows regression status. No SINGLE surface shows ALL drift dimensions composed.

5. **Recent-cycle distribution view** — pathway D5 self-eval suggests tracking edit-distribution per N=5 sliding window (project-layer vs meta-layer) per SB-140 lesson. No tool currently surfaces this. Would require parsing recent git log + categorizing.

6. **Continuation-readiness signal** — Epic E006 module M-E006-1 sketches this (per-interaction-surface readiness scoring). Sister to M-E005-1 — E005 is the broad inventory; E006-1 is the readiness scoring.

7. **Operator-directive-recency surface** — recent `wiki/log/<date>-*.md` files contain operator directives. No surface currently parses + summarizes "what operator directed in the last N hours". `/orient` reads recent logs but doesn't surface them as a directive-list.

## Done When (M-E005-1 module-level)

- [x] Initial inventory enumerated (13 functional tools + 5 state files + 7 composed surfaces + 10 MCP + 43 slash commands)
- [x] 7 gap categories named (decision-point grounding · cross-Epic visibility · Wiki-LLM consumption · drift composite · recent-cycle distribution · continuation-readiness · operator-directive-recency)
- [ ] Operator review of inventory + gap analysis (operator-revisable)
- [ ] Promote selected gap candidates to dedicated M-E005-N modules (ranked by operator)
- [ ] Cross-reference to second-brain `<second-brain>/wiki/sources/` for prior-art (ANY existing big-picture-vision tool patterns in second brain that root-modules can adapt)
- [ ] Operator-confirmed scope of M-E005-2 (probably "build the bigview composer" — depends on operator pick)
- [ ] Empirical: agent uses bigview composer per-fire and reports continuation quality improves (operator-empirical)

## Dependencies

- **Hard**: Existing 13 tools + state files + composed surfaces (this module surveys them, doesn't build new ones)
- **Hard**: Hard Rule 15 empirical-count-verification — this module's inventory MUST be empirically grounded, not memory-derived
- **Soft**: M007 second-brain connect (Wiki-LLM consumption layer gap-fill depends on this)
- **Soft**: Epic E006 module M-E006-1 (continuation-readiness scoring) — sister-module providing per-interaction signal that bigview composer would compose
- **Soft**: Epic E004 module M-E004-1 (doctor pattern research) — cousin (E004 = reactive watchdog detecting stalled loops; E005 = proactive grounding)

## Connects to

- Epic E005 (parent): `wiki/backlog/epics/epic-e005-big-picture-vision-tool.md`
- Epic E006 (sister): `wiki/backlog/epics/epic-e006-guided-workflow-continuation.md`
- Epic E004 (cousin): `wiki/backlog/epics/epic-e004-ai-modes-assistant-doctor.md`
- D044 iterative-evolution-pathway rule (D6 priorities-as-guide consumes the bigview)
- SB-140 frozen-loop pattern (bigview's drift-distribution view would catch recurrence)
- Hard Rule 15 empirical-count-verification (this inventory IS the recipe)
- `<second-brain>/wiki/sources/` (prior-art consumption — operator-pending whether second-brain has comparable tools)
- `<second-brain>/wiki/spine/super-model/super-model.md` (Wiki-LLM doctrine reference)
