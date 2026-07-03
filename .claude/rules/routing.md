# $HOME/.claude/rules/routing.md — Operator intent → tool routing for root-ghostproxy

> Loaded on demand when operator intent is ambiguous. CLAUDE.md has the summary delta; this file has the routing table for THIS project (OS-setup IaC at $HOME).
>
> **Strictness tier** (per `operating-principles.md` §3): **Advisory** — informs operator-intent → mechanism dispatch judgment. Some rows promote to **Deterministic** (slash commands fire 100% on literal invoke; CLI commands programmatic) while others stay generative (skill description-match ~70-95%, hook-directive compliance ~85%).

## Mechanism Selection (8 mechanisms — full universal framing at `trigger-model.md`)

Per [`.claude/rules/trigger-model.md`](trigger-model.md) the unified signal→action→recovery model covers 8 mechanisms. Below is the routing-relevant subset for root-ghostproxy specifically (counts empirically verified 2026-05-06 evening):

| Mechanism | Determinism | Trigger | Project state (2026-05-06) |
|---|---|---|---|
| **Hook** | Logical (block + reason + remediation per design pattern) | Tool-call lifecycle event | **10 wired matchers across 8 events** (PreToolUse + PostToolUse + SessionStart + UserPromptSubmit (4-hook compound stack per SB-126) + PreCompact + PostCompact + Stop + SessionEnd); 17 .sh + 1 .py on disk; archived hooks retained per operator directive 2026-05-06. Per-hook inventory + WIRED-vs-ARCHIVE labels at [`.claude/hooks/README.md`](../hooks/README.md). |
| **Command** (`.claude/commands/`) | 100% deterministic on invoke | Operator types `/<name>` literally | **30 commands** by category (orient/cycle, modes, stamp, objective layer SB-118, priorities SB-127, backlog management, knowledge/audit, install). Per-category index at [`.claude/commands/README.md`](../commands/README.md). |
| **Skill** (`.claude/skills/`) | ~70-95% (description-match) | Auto-trigger on operator prose match | **2 local skills** (surface-state, surface-blockers) at `.claude/skills/<name>/SKILL.md` + user-level harness-provided. Per-skill index at [`.claude/skills/README.md`](../skills/README.md). |
| **Mode** (`.claude/modes/`) | Durable state (operator-set) | Operator types `/mode-<name>` | **3 modes** (PM Scrum Master / DevOps Architect / Dual Expert) + state file `$HOME/.claude/active-mode`. Per-mode index + cycle-sequence comparison at [`.claude/modes/README.md`](../modes/README.md). |
| **Sub-agent** (`.claude/agents/`) | Brain-loaded on spawn (project-specific per SB-081) | Parent agent invokes via Agent tool with `subagent_type` | **3 brain-loaded sub-agents** (root-explorer / root-architect / root-pm-scoper). Runtime gap: session-restart required for Claude Code to discover. Per-agent index at [`.claude/agents/README.md`](../agents/README.md). |
| **MCP tool** | Programmatic | AI invokes during reasoning | **Local: 10 root_* tools** at `tools/mcp_server.py` (root_state, root_blockers, root_progress, root_decisions_*, root_objective SB-118+SB-127, root_questions SB-134, root_orient). **External: 28 second-brain tools** (after M007 connect; deferred load via ToolSearch). |
| **CLI / Tools** | Programmatic | AI runs via Bash | **install.sh / uninstall.sh** at $HOME (implement-stage 98%; `--profile {base/full/project/interactive}` × `--mode {bridge/endpoint/hybrid/auto}` × per-op toggles + `--wizard` + granular `--with-group` / `--no-group`). **15 Python tools at `$HOME/tools/`** (state, blockers, progress, decisions, cycle, tasks, stamp, objective, priorities, questions, group, run-tests + mcp_server + _paths + __init__). Per-tool index at [`tools/README.md`](../../tools/README.md). |
| **Scheduled task** | Cron-deterministic OR self-paced (ScheduleWakeup) | Time-trigger or agent self-pace | Wraps any of the above for recurring autopilot — `/loop <interval> /cycle` is the canonical pattern. Auto-cancellation gating per [`loop-cron-lifecycle.md`](loop-cron-lifecycle.md). |

## Operator-intent routing (this project — 30 slash commands + tools/CLI)

| Operator says... | First action | Tool / command |
|---|---|---|
| `"orient"` / `"where are we (literal slash)"` | `/orient` slash command — deterministic 21-step intel chain | `/orient` |
| `"where are we"` (prose) / `"what's the state"` (prose) | Auto-trigger via `surface-state` skill → routes to `/orient` | `surface-state` skill |
| `"cycle"` / autopilot | `/cycle` per active-mode; loop with `/loop <interval> /cycle` | `/cycle` |
| `"set mission/focus/impediment"` | Use SB-118 commands | `/mission set <text>` · `/focus set <text>` · `/impediment set <text>` |
| `"add priority"` / `"P1 ..."` | Use SB-127 priorities tier (ABOVE PM blockers) | `/priorities add <text>` (verbs: add/show/clear/remove/promote/demote/set/insert/update) |
| `"set active task"` / `"working on T###"` | Use SB-124d cursor management | `/task set <T###>` (validates against backlog) |
| `"create new task"` | Use E002 piling-tasks scaffolds | `/task create under-epic --epic <slug> --title <text>` (DRAFT scaffolds) |
| `"agent has a question"` / `"retain Q"` | Use SB-134 retention layer | `/questions add <text>` (distinct from blockers + operator-pending decisions) |
| `"what's blocking"` (prose) / `"pending decisions"` (prose) | Auto-trigger via `surface-blockers` skill → `/blockers` | `surface-blockers` skill |
| `"blockers"` (literal) | Decision-package format (CONTEXT + GUIDANCE + RECOMMEND + ALTERNATIVES + TO ANSWER per SB-071) | `/blockers` |
| `"build the bridge"` / `"set up L2"` | Read SFIF stage in CONTEXT.md → check M003 (Foundation hardening) tasks | `wiki/backlog/tasks/_index.md` + M003 module page |
| `"install"` / `"run install.sh"` | Confirm dry-run first; SFIF Foundation tasks gate this | `install.sh --dry-run` then `install.sh` |
| `"wizard"` / `"where am I in install"` | State-aware route detection + next-best-actions | `install.sh --wizard` |
| `"granular install"` / `"install partial"` | `--with-group` / `--no-group` per category | `install.sh --profile base --no-group <name>` |
| `"per-project install"` / `"deploy agent brain"` | Sister-project agent-brain deploy | `install.sh --profile project --dest <path>` OR `/install-agent-brain <path>` |
| `"verify state"` / `"verify install"` | Read-only drift detection (16+ checks) | `install.sh --check` |
| `"audit"` / `"10-step integrity check"` | yamls + hooks + blockers + decisions + state files | `/audit` |
| `"run regression tests"` / `"verified-edit"` (Hard Rule 14) | Unified runner across 13 test files — 12 hook + 1 tool (empirically verified 2026-07-03 on `main`) | `python3 -m tools.run-tests` (241/241 aggregate; prior "14 files / 322/322" figure was never in committed history — corrected per Hard Rule 15) |
| `"status"` / `"what's next"` | Show SFIF stage + active mission/focus/impediment + priorities + pending-decision tasks | CONTEXT.md (Active Objective Layer + SFIF + Operator-Pending Decisions tables) |
| `"add Suricata"` / `"PolarProxy"` | M005 territory; check ordering against ccstatusline (M011 ordered before M005) | M005 / M011 module pages |
| `"connect to second brain"` | M007 — `tools.setup --connect-project $HOME --dry-run` first | M007 task pages T038-T043 |
| `"verify second brain knows $HOME"` | `gateway query --backlog`, sister-projects.yaml grep | gateway forwarder (after M007) |
| `"ingest a URL"` | NOT this project's role. Route to second brain (`pipeline fetch` / `wiki_fetch` MCP from /opt). | second brain |
| `"the operator said X"` (verbatim) | Log verbatim to `$HOME/wiki/log/<date>-<slug>.md` BEFORE acting via `/log` command. **NOT** `/opt/.../raw/notes/` — that's the second-brain's own layer; $HOME must not write there. | `/log` slash command |
| `"check pending decisions"` | List `pending-operator-decision` tasks + Operator-Pending Decisions table in CONTEXT.md | `/blockers` + CONTEXT.md |
| `"decisions"` / `"log a decision"` | Append to logbook (40 entries D001-D040) | `/decisions append --title --rationale --reversibility` OR `/decisions list` |
| `"progress"` / `"sync"` | Refresh callout from live state | `/progress` OR `/sync-progress` |
| `"handoff"` / `"checkpoint"` | Snapshot doc to wiki/log/<ts>-handoff.md | `/handoff` |
| `"terminate session"` / `"end session"` | Full status/progress/artifacts/role sweep + handoff doc | `/terminate` |
| `"finish smoothly"` | Forced knowledge-extraction PASS + handoff | `/finish-smoothly` |
| `"claim a task"` | List `not-started` with no `BLOCKED BY` outstanding → operator picks → work it per Done When + stage gate | `tools.tasks claimable` + `/task set <T###>` |
| `"set stamp behavior"` | SB-115 redesign — persistent config | `/stamp-{horizontal,vertical,on,off,auto,status}` |
| `"set mode"` | Operator-choice (never auto-enable per directive 2026-05-05) | `/mode-{pm,architect,dual,clear,status}` |
| `"help"` / `"what commands exist"` | In-session compact cheatsheet | `/help-root` |

## Cross-references

- `<second-brain>/.claude/rules/routing.md` — second brain's full 24-row table + 28-tool MCP catalog. This project consumes from there (after M007 connect).
- `$HOME/CLAUDE.md` — Claude-Code-specific delta + operator-intent summary + 15 Hard Rules.
- `$HOME/AGENTS.md` — universal cross-tool agent contract (canonical envelope, hook firing order, 15 universal Hard Rules).
- `$HOME/BOOTSTRAP.md` — cold-pickup guide (read first).
- [`.claude/rules/README.md`](README.md) — 11 rules with strictness-tier matrix.
- [`.claude/commands/README.md`](../commands/README.md) — 30 slash commands by category (canonical extension of this routing's command rows).
- [`.claude/hooks/README.md`](../hooks/README.md) — 18 hook scripts (10 wired + archive) by event.
- [`tools/README.md`](../../tools/README.md) — 15 Python tools + composition map (canonical extension of this routing's CLI/Tools row).
- [`.claude/rules/trigger-model.md`](trigger-model.md) — unified 8-mechanism signal→action→recovery model.
- [`.claude/rules/loop-cron-lifecycle.md`](loop-cron-lifecycle.md) — when scheduled tasks self-cancel/update.
- `wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md` — sacrosanct verbatim directive governing this routing.md edit pass.
- `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md` — M-E001-1 productive-cycle action vocabulary (every routed mechanism emits one of 9 action types).
