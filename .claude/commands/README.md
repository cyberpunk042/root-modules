---
title: ".claude/commands/ — root-modules slash commands"
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
tags: [readme, commands, slash, agent-authored, draft]
---

# `.claude/commands/` — operator-invoked slash commands

> **DRAFT v1 — agent-authored 2026-05-06** per SB-095. Operator may revise / promote / replace.

## Summary

Indexes the 43 slash commands in `$HOME/.claude/commands/`. Commands are **100% deterministic on invoke** — Claude Code's harness executes the `.md` template body exactly when operator types `/<name>` literally. This makes them the fastest + most-reproducible mechanism in the project's trigger model (vs hooks which fire on tool-call lifecycle events, vs skills which auto-trigger on description-match at ~70% reliability, vs MCP/CLI which require Bash dispatch). Commands are organized by 8 categories (orient/cycle, modes, stamp, statusline, objective layer, backlog management, knowledge/audit, install) for cold-pickup navigability. The statusline category (12 commands: 3 generic + 9 per-profile shortcuts) parallels the stamp category's sub-feature pattern. This README is the structured-by-category fuller guide; `/help-root` is the in-session compact cheatsheet.

## Quick lookup — `/help-root`

```
/help-root
```

is the in-session catalog (compact one-liner per command). This README is the structured-by-category fuller guide.

## Commands by category (30 total)

### Orient + handoff (5)

| Command | Purpose | When to use |
|---|---|---|
| `/orient` | Deterministic 21-step intel chain — load brain, read recent logs, verify methodology engine, detect active mode, emit structured ORIENT REPORT | Fresh session start; post-/compact recovery; operator types it explicitly |
| `/cycle` | Run one cycle of active mode's autopilot sequence (PM / Architect / Dual) | Wrapped in `/loop <interval> /cycle` for autopilot; one-shot otherwise |
| `/handoff` | Snapshot in-flight state to single doc for cold-pickup | Mid-loop checkpoint; before context-switch |
| `/terminate` | High-standard session-termination prep — full status/progress/artifacts/role sweep + handoff doc | End/pause/pivot session; goes BEYOND `/handoff` |
| `/finish-smoothly` | Forced knowledge-extraction pass — lessons + patterns + decisions captured to wiki BEFORE handoff | End-of-session AND knowledge produced; capture-or-lose moment |

### Modes (5 — operator-choice; never auto-enable per directive 2026-05-05)

| Command | Sets `active-mode` to | Lens applied |
|---|---|---|
| `/mode-pm` | `pm-scrum-master` | PM Scrum Master — backlog grooming + decision surfacing + status reports |
| `/mode-architect` | `devops-architect` | DevOps Architect — design + IaC implementation + hooks + vendor manifests |
| `/mode-dual` | `dual-expert` | Dual Expert — both lenses; switches per question |
| `/mode-clear` | (empty) | No mode active; baseline behavior |
| `/mode-status` | (read) | Show current active mode + persona excerpt |

### Stamp control (6 — SB-115 redesign)

| Command | Effect | Notes |
|---|---|---|
| `/stamp-on` | `enabled=on` (always render) | Persists to `.claude/stamp-config.json` |
| `/stamp-off` | `enabled=off` (always silent) |  |
| `/stamp-auto` | `enabled=auto` (render only if active-mode set) | Default per SB-114 inversion |
| `/stamp-horizontal` | `layout=horizontal` (compact 6-line) |  |
| `/stamp-vertical` | `layout=vertical` (full ANSI-fence stack) |  |
| `/stamp-status` | Show current config (read-only) |  |

### Objective layer (4 — SB-118 + SB-127)

| Command | Manages | State file |
|---|---|---|
| `/mission` | Multi-cycle objective | `$HOME/.claude/active-mission` |
| `/focus` | Sub-objective within mission | `$HOME/.claude/active-focus` |
| `/impediment` | Block on focus (comes-and-goes) | `$HOME/.claude/active-impediment` |
| `/priorities` | Imminent-work queue (above PM tier) | `$HOME/.claude/active-priorities` (verbs: add/show/clear/remove/promote/demote/set/insert/update) |

### Backlog management (4)

| Command | Purpose |
|---|---|
| `/blockers` | Surface operator-decision-pending items in DECISION PACKAGE format (CONTEXT + GUIDANCE + RECOMMEND + ALTERNATIVES + TO ANSWER) |
| `/decisions` | Append to decisions logbook OR list entries |
| `/progress` | Refresh `progress.md` callout from live state (counts) |
| `/sync-progress` | Hard refresh — re-derives all governance counts |
| `/task` | Manage active-task cursor (show/set/clear) AND create new tasks (under-epic / under-task / from-blocker — DRAFT scaffolds per SB-124d + E002) |

### Knowledge + audit (4)

| Command | Purpose |
|---|---|
| `/audit` | 10-step integrity check — yamls parseable + hooks executable + blockers/decisions verify + state files consistent |
| `/log` | Log operator directive verbatim to `wiki/log/<date>-<slug>.md` BEFORE acting (sacrosanct rule) |
| `/questions` | Manage agent-pending questions retention (state file + add/show/clear/answer/promote-to-decision per SB-134) |
| `/help-root` | One-line-per-command in-session cheatsheet |

### Install (1)

| Command | Purpose |
|---|---|
| `/install-agent-brain <path>` | Wrapper around `install.sh --profile project --dest <path>` — deploys agent brain (settings + hooks + rules + commands + agents + modes + skills + tools) into a sister project |

## Invocation discipline

- **Operator types literally**: `/orient`, `/cycle`, etc. The `/` prefix triggers Claude Code's slash-dispatch.
- **Bare prose is NOT the same**: per `routing.md` (24-row routing table), conversational "where are we" / "continue" / "evolve" are NOT slash-equivalent. Don't auto-invoke commands on bare prose unless the command's frontmatter description is description-match clear.
- **`$ARGUMENTS` substitution**: command bodies receive the operator's args verbatim. Verb-dispatching commands (e.g. `/priorities add ...`, `/task set T012`) parse `$ARGUMENTS` to route to the right tool subcommand.

## Composition

| Pattern | Example |
|---|---|
| Loop + cycle | `/loop 30m /cycle` — autopilot in active mode every 30min |
| Mode + cycle | `/mode-dual` then `/cycle` — switches the cycle's lens |
| Mission + focus + cycle | `/mission set "ship MVP"`, `/focus set "...."`, `/cycle` — cycle reports against named objective |
| Handoff vs Terminate vs Finish-smoothly | `/handoff` (light snapshot) ≪ `/terminate` (full sweep) ≪ `/finish-smoothly` (knowledge-extraction PASS forced) |

## Extending — adding a new command

When you author a new slash command:

1. **Place at `.claude/commands/<name>.md`** with frontmatter:
   ```yaml
   ---
   description: One-line summary (description-match auto-trigger reads this)
   argument-hint: [verb args | flags]
   ---
   ```
2. **Body** is what the harness executes when operator invokes — Bash blocks, Read calls, etc. all run as-written.
3. **Verb dispatch** for multi-action commands (see `/priorities` or `/task` for the pattern):
   ```bash
   ARG="$ARGUMENTS"
   case "$ARG" in
     ""|"show") ... ;;
     "clear")   ... ;;
     "set "*)   ... ;;
     ...
   esac
   ```
4. **Cross-reference** from this README's category table + from `/help-root`.
5. **Brain-piece counts** in root README.md need refresh when commands count changes.

## Anti-patterns (do not do)

- **Auto-trigger commands on bare prose** — slash command discipline requires literal `/` invocation. Bare "where are we?" is conversation, not `/orient`.
- **Replace existing commands wholesale** — additive ≠ destructive. Add new command files; don't rewrite established ones.
- **Forget the description frontmatter** — without it, description-match auto-trigger can't reach the command.
- **Hardcode paths in the command body** — use `$HOME` placeholder for portability across install users (root vs jfortin).

## Relationships

- **IMPLEMENTS** [`/.claude/rules/routing.md`](../rules/routing.md) — operator-intent → command/tool routing
- **USES** [`/tools/README.md`](../../tools/README.md) — commands dispatch to deterministic Python tools via `$ARGUMENTS`
- **USED BY** operator (literal `/<name>` invocation) + skills (description-match dispatch via Skill tool)
- **CONSTRAINED BY** [`/.claude/rules/hook-architecture.md`](../rules/hook-architecture.md) — hooks may invoke commands via additionalContext directive (~85% generative compliance)
- **RELATES TO** [`/.claude/skills/README.md`](../skills/README.md) — skills are description-match auto-trigger workflows that compose existing slash commands
- **DERIVED FROM** operator directive 2026-05-06 (brain-improvement mandate)
- Root README — [`/README.md`](../../README.md) (`43 slash commands` row)
- `/help-root` — in-session compact cheatsheet (live equivalent of this README)

## Cross-references (informal navigation)

Same surface as Relationships above; kept for cold-pickup agents searching for "Cross-references".
