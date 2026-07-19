---
title: ".claude/modes/ — root-modules mode files"
type: reference
subtype: subdir-readme
domain: cross-domain
status: draft
confidence: medium
created: 2026-05-06
updated: 2026-05-06
maturity: seed
sources:
  - id: brain-improvement-mandate-2026-05-06
    type: directive
    file: ../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
tags: [readme, modes, agent-authored, draft]
---

# `.claude/modes/` — operator-pickable mode files

> **DRAFT v1 — agent-authored 2026-05-06** per SB-095. Operator may revise / promote / replace.

## Summary

Indexes the 3 mode files in `$HOME/.claude/modes/` (PM Scrum Master, DevOps Architect, Dual Expert). Modes are **operator-choice** per directive 2026-05-05 — agent does NOT auto-enable. State file `$HOME/.claude/active-mode` (single line: `pm-scrum-master` / `devops-architect` / `dual-expert` / empty) is the source-of-truth read by `mode-enforcement.sh` (per-prompt banner) + `/cycle` (cycle-step routing) + `mindfulness.sh` (silent-when-no-mode) + `end-of-cycle-stamp.sh` (auto-render-when-mode-set). Each mode file declares persona, voice table (5-10 qualities clustered drive/technical/discipline per SB-129), primary brain pieces, /cycle sequence steps, when-to-switch-out criteria. Modes are durable across turns (state-file-mediated) and switch via `/mode-{pm,architect,dual,clear}` slash commands.

## The 3 modes

| Mode | Persona | When to switch in | Primary brain pieces |
|---|---|---|---|
| **[`pm-scrum-master.md`](pm-scrum-master.md)** | PM Scrum Master — backlog grooming + decision surfacing + status reports | Operator wants project-management lens (blockers / progress / decisions) | CONTEXT.md, blockers.md, progress.md, decisions.md, _index.md |
| **[`devops-architect.md`](devops-architect.md)** | DevOps Architect — design + IaC + hooks + vendor manifests; BOTH top-down architecture AND bottom-up implementation per SB-066 | Operator wants implementation lens (code edits / hook refinement / tools augmentation) | ARCHITECTURE.md, DESIGN.md, methodology.yaml, source-syntheses |
| **[`dual-expert.md`](dual-expert.md)** | Dual Expert — both lenses; switches per question | Cross-cutting work (PM decision whose downstream is engineering, OR architecture choice with PM implications) | Both above |

## Mode-aware mechanisms (composition)

| Mechanism | How mode affects it |
|---|---|
| `mode-enforcement.sh` (UserPromptSubmit hook) | Reads `active-mode` + parses the mode file's persona section + cycle steps + voice table; injects per-prompt `additionalContext` banner with persona reminder |
| `/cycle` slash command | Reads `active-mode` → routes to mode-specific cycle steps in pm-scrum-master.md / devops-architect.md / dual-expert.md |
| `mindfulness.sh` hook | Fires per-prompt only when `active-mode` is set (silent baseline when no mode) |
| `end-of-cycle-stamp.sh` Stop hook | When `enabled=auto` (default), stamp renders only if `active-mode` set |

## Cycle-sequence comparison

| Step | PM Scrum Master | DevOps Architect | Dual Expert |
|---|---|---|---|
| 1 | `/orient` refresh | `/orient` refresh | `/orient` refresh |
| 2 | Blocker decumulate/filter sweep + auto-research filter + DECISION PACKAGE format (SB-065/071/072) | Top-down architecture review (ARCHITECTURE.md + DESIGN.md staleness) | PM lens — blocker decumulate (per pm-scrum-master step 2) |
| 3 | Decision-package surfacing | Bottom-up implementation scan (in-flight code, tools-internal bugs, hook refinement) | Architect lens — top-down + bottom-up (per devops-architect steps 2-3) |
| 4 | Backlog status table | Implementation-progress per SFIF tasks | Cross-cutting (both lenses) |
| 5 | Risk + blocker drift scan | Stage gate check (per methodology.yaml) | Systemic-bugs tracker iteration |
| 6 | Substance-per-cycle gate (SB-128) + report | Cross-cutting top-down ↔ bottom-up reconciliation | Substance-per-cycle gate (SB-128) + report |
| 7 | Wait + last-line `Productive output: ...` | Wait + last-line `Productive output: ...` | Wait + last-line `Productive output: ...` |

## Mode-entry discipline (per directive 2026-05-05)

> **Operator-choice — never auto-enable.** Agent does NOT pick a mode without explicit `/mode-pm` / `/mode-architect` / `/mode-dual` invocation from the operator. /orient surfaces the option in the report; operator decides.

## When to switch out

- Implementation work needed → propose `/mode-architect` or `/mode-dual`
- Operator says "let's design X" → `/mode-architect` or `/mode-dual`
- Cross-cutting work (PM + Architect both relevant) → `/mode-dual`
- Backlog grooming / status report needed → `/mode-pm` or `/mode-dual`
- Operator says "what's our state?" → `/mode-pm` (or just answer briefly without switching)

## Autopilot

`/loop <interval> /cycle` (in any mode) = autopilot. Each fire executes the active mode's cycle, which is deterministic per the mode file. Switching modes mid-loop changes the cycle on the next fire (state file is read fresh each time).

## Loop-cron-lifecycle (per `$HOME/.claude/rules/loop-cron-lifecycle.md`)

Each mode's loop self-evaluates per cycle for autonomous cancellation/pause per the registered scenarios L1-L7. Mode-dependent gating applies (e.g. PM mode has higher L1 sensitivity than Architect; Dual requires both lenses at refined-trigger before L4 cancellation).

## Mode-file structure

Each mode file follows a common shape (see any of the 3 for the full template):

```
---
frontmatter (mode-name, brain-pieces, scope-discipline)
---

## Persona
## Persona voice — DRAFT v1 (compiled 2026-05-06)
| Quality | Sounds like | Anti-pattern | Why/cite |
| (5-10 voice qualities clustered drive/technical/discipline)

## Primary brain pieces
## Scope discipline
## /cycle sequence
## Cycle vs between-cycle action (do not conflate)
## When to switch out
## Autopilot mention
## Loop-cron-lifecycle
```

The voice table is the **structured canonical** (SB-129 stage c) — parsed by `mode-enforcement.sh` to extract per-mode persona qualities + cite-bracket attribution.

## Relationships

- **USED BY** [`../hooks/mode-enforcement.sh`](../hooks/mode-enforcement.sh) — per-prompt mode-banner hook reads mode files dynamically
- **USED BY** [`../commands/cycle.md`](../commands/cycle.md) — cycle dispatch routes to mode-specific steps
- **CONSTRAINED BY** [`../rules/loop-cron-lifecycle.md`](../rules/loop-cron-lifecycle.md) — modes have mode-dependent autonomous-cancellation gating
- **PARALLELS** [`../rules/compound-and-waterfall.md`](../rules/compound-and-waterfall.md) — mode is the persona layer in the compound stack
- **DERIVED FROM** operator directive 2026-05-05 (mode-entry is operator-choice) + 2026-05-06 (brain-improvement mandate)
- **RELATES TO** [`/.claude/skills/README.md`](../skills/README.md) — skills auto-trigger irrespective of mode; modes filter cycle behavior
- Root README — [`/README.md`](../../README.md)

## Cross-references (informal navigation)

Same surface as Relationships above; kept for cold-pickup agents searching for "Cross-references".

### Operator-facing mode commands (the 5 entry/exit/inspect surfaces)

- [`/mode-pm`](../commands/mode-pm.md) — enable PM Scrum Master
- [`/mode-architect`](../commands/mode-architect.md) — enable DevOps Architect
- [`/mode-dual`](../commands/mode-dual.md) — enable Dual Expert (both lenses)
- [`/mode-clear`](../commands/mode-clear.md) — return to no-mode default
- [`/mode-status`](../commands/mode-status.md) — read current mode

### Action emission per Hard Rule 14

Each mode's `/cycle` emits one of 9 canonical M-E001-1 productive-cycle action types per fire (mandatory cycle-report last-line `Productive output: <type> — <one-line specific>`). Per-mode subset preferences:

- **PM**: `blocker-surface` · `sb-closure` · `drift-fix-with-empirical` · `explicit-standby-with-named-reason`
- **Architect**: `verified-edit` · `sb-closure` · `drift-fix-with-empirical` · `new-artifact` · `doc-refresh` · `explicit-standby-with-named-reason`
- **Dual**: ANY of the 9 (cycle is broadest)

See [`wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`](../../wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) for the canonical vocabulary spec.

### Iterative evolution pathway

Mode selection is Dimension 9 (mode-alternance + hybrid + repeat patterns) per [`.claude/rules/iterative-evolution-pathway.md`](../rules/iterative-evolution-pathway.md). 3 cadence patterns recognized: single-mode-sustained · hybrid-sustained (dual default) · alternance (operator-coordinated mode-switching mid-work-item).

## Extending — adding a new mode

Future modes are operator-decision. To author one:

1. Place at `.claude/modes/<mode-name>.md` matching the structure above
2. Author the voice table (5-10 qualities clustered)
3. Define cycle-sequence steps
4. Add to `mode-enforcement.sh` mode-file detection (currently parses 3 known modes)
5. Author `/mode-<name>.md` slash command setting `active-mode` to `<mode-name>`
6. Update this README's "3 modes" table
7. Update root README brain-piece counts (modes count)
