---
title: "root-modules M013 — Agent modes (PM Scrum Master / DevOps Architect / Dual Expert) + mode-aware /loop sequences"
aliases:
  - "M013 — agent modes + mode-aware /loop"
type: module
domain: backlog
status: draft
priority: P1
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 5
progress: 0
sfif_stage: Infrastructure
sfif_ordering: "Stream 2, Infrastructure tier — composes with M004 (verifier), M011 (statusline), M012 (vendor manifest). Modes operate ABOVE the methodology layer; they're persona/operating-context overlays that gate which command sequences are appropriate."
stages_completed: []
artifacts: []
confidence: medium
created: 2026-05-05
updated: 2026-05-05
sources:
  - id: operator-directive-2026-05-05-modes-and-claudeignore
    type: directive
    file: /opt/devops-solutions-information-hub/raw/notes/2026-05-05-claudeignore-purpose-and-modes-architecture-directive.md
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
  - id: skills-commands-hooks-model
    type: wiki
    file: /opt/devops-solutions-information-hub/wiki/spine/models/agent-config/model-skills-commands-hooks.md
    description: "5-mechanism determinism ladder (commands 100%, skills ~70-95%, hooks ~70-85%, MCP/CLI 100% on invoke)"
tags: [module, p1, root-modules, sfif-infrastructure, m013, modes, agent-modes, pm-scrum-master, devops-architect, dual-expert, loop-sequences, mode-aware, sub-agent-profiles, brain-pieces]
---

# M013 — Agent modes + mode-aware /loop sequences

## Summary

A **mode** is a higher-level operating-context overlay for the agent: a persona + a curated subset of brain pieces + a set of pre-defined command/loop sequences appropriate to that persona. When the operator enables a mode, `/loop` (and other recurring or self-paced triggers) fire mode-specific sequences instead of generic chains.

Three modes named by operator (2026-05-05):

1. **PM Scrum Master Mode** — backlog grooming, decision-tracking, status reports, methodology-stage coordination, dependency surfacing.
2. **DevOps Software Engineer & Architect Mode** — code authoring, IaC scripting, architecture design, hooks/integrations/vendor manifests, implementation work.
3. **Dual Expert Mode** — both lenses simultaneously; switches per question/per task. Useful when no separate human PM and engineer exist (the operator's solo + AI scenario).

When a mode is enabled + `/loop` is triggered, a desired sequence (or group of sequences) fires per cron interval / self-pace.

## Operator directive (verbatim, 2026-05-05)

> "we will also invent modes and we will have the PM Scrum Master Mode and the DevOps Software Engineer & Architect expert mode and the Dual Expert mode and we will when those mode are enabled allow be to trigger with a /loop a desired sequence or group of sequence."

> "you can even create agent ro sub-agent profiles and different other pieces and brain pieces."

## Scope

### Phase A — design the modes architecture

Decide:
- Where mode-state lives (env var `ROOT_GHOSTPROXY_MODE=pm` ? config file `~/.root-modules-mode`? slash-command `/mode-pm`?)
- How agents discover the active mode (Read of state-file? hook outputs current mode in additionalContext?)
- How mode persists across sessions (config-file is durable; env var session-only)
- Default mode (none / Dual / operator-pick)

### Phase B — author per-mode brain pieces

Each mode needs:
- Persona description (in CLAUDE.md or a mode-specific brain file)
- Command sequences appropriate to the mode (stored as `/loop` sequence groups)
- Sub-agent profile (optional — could spawn a `pm-scrum-master` sub-agent for PM-mode tasks)
- Brain-piece subset prioritized (PM mode: backlog + decisions + status; Architect mode: ARCHITECTURE.md + DESIGN.md + TOOLS.md + methodology yamls)

### Phase C — wire mode-aware /loop

Mode + `/loop <interval>` fires:
- **PM mode + /loop 30m** → sequence: `/orient → /surface-decisions → /backlog-status → wait`
- **Architect mode + /loop 30m** → sequence: `/orient → /architecture-review → /implementation-progress → wait`
- **Dual mode + /loop 30m** → sequence: alternating between PM and Architect chains

Each sequence is a list of slash-commands chained per the methodology pattern.

### Phase D — sub-agent profiles + brain pieces composition

Realize modes via Claude Code's agent + sub-agent system:
- A `pm-scrum-master` sub-agent profile (separate `agents/pm-scrum-master.md`) with its own brain piece
- A `devops-architect` sub-agent profile
- Dual mode dispatches to whichever profile fits the current question
- Brain pieces (read on demand) are filtered per active mode to keep context focused

## Done When

- [ ] **Phase A**: mode-state mechanism chosen + documented (slash-command? env var? config file?)
- [ ] **Phase B**: at least 2 modes have authored persona + command sequences (PM + Architect; Dual is composition of both)
- [ ] **Phase C**: at least one /loop mode-aware sequence works end-to-end (e.g., `/loop 30m` in PM mode fires PM chain)
- [ ] **Phase D**: at least one sub-agent profile exists for one mode (proves the realization pattern)
- [ ] All commands in any mode-sequence are themselves authored (M013 may force authoring of `/surface-decisions`, `/backlog-status`, `/architecture-review`, etc.)

## Dependencies

- M001-M002 done (brain files + methodology in place — required for any mode persona)
- `/orient` command exists ✓ (authored 2026-05-05)
- `/loop` skill works (already provided by Claude Code's loop skill)
- Possibly M011 (ccstatusline) for in-statusline mode display
- Possibly M012 Phase A for the gitignore handling that mode config files need

## Open questions

> [!question] How does mode-state live across sessions?
> Options: (a) `~/.root-modules-mode` plain-text file persisted; (b) env var `ROOT_GHOSTPROXY_MODE` session-only; (c) entry in CONTEXT.md updated by `/mode-set <name>` command. Operator decides. Lean toward (a) for durability + (c) for traceability — store in CONTEXT.md so it's also auditable.

> [!question] What's a "sequence group" vs a "sequence"?
> Operator's verbatim: "a desired sequence or group of sequence". A sequence = one chain of commands (e.g., orient → status → decisions). A group of sequences = multiple chains tagged for the mode. /loop firing in PM mode might pick which sequence to fire based on time-of-day, day-of-week, or rotate through the group. Operator confirms semantics.

> [!question] Mode vs methodology — overlap or orthogonal?
> Methodology dictates stage (document → design → scaffold → implement → test) and gates. Mode dictates persona/loop pattern. They're orthogonal: a Document-stage task can be PM-driven (clarify scope, surface stakeholder questions) or Architect-driven (sketch design constraints). The mode shapes HOW the stage is executed; it doesn't replace the stage. Confirm.

> [!question] Should there be more than 3 modes?
> Operator named PM, Architect, Dual. Other plausible modes: "Researcher" (read-heavy, source-synthesis-focused), "Operator-companion" (very high decision-surfacing), "Audit/Review" (read-only, find-issues). Operator decides scope.

> [!question] Default mode at session start?
> If operator hasn't set one, default to: (a) None — agent operates per CLAUDE.md / BOOTSTRAP.md baseline; (b) Dual — most flexible; (c) Operator-prompted at first turn. The new SessionStart orient hook could surface "no mode set — use /mode-pm or /mode-architect or /mode-dual" if operator wants this prompt.

## Tasks

(No atomic task pages T### yet — operator gives go-ahead before authoring T-M013-* tasks.)

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BUILDS ON: [[root-modules-m001-author-claude-md-and-agents-md|M001 — CLAUDE.md + AGENTS.md]] (mode personas extend the cross-tool agent contract)
- BUILDS ON: [[root-modules-m002-methodology-layer-decision|M002 — Methodology layer]] (modes are orthogonal to stages but operate atop them)
- RELATES TO: [[root-modules-m011-ccstatusline-statusline-widget|M011 — ccstatusline]] (active mode shown in statusline)
- IMPLEMENTS: Per operator directive 2026-05-05 — modes + mode-aware /loop sequences

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M001 — CLAUDE.md + AGENTS.md]]
[[M002 — Methodology layer]]
[[M011 — ccstatusline]]
