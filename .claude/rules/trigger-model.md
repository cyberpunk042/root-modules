# $HOME/.claude/rules/trigger-model.md — Unified trigger model (signal → response composition)

> Loaded on demand when designing or debugging anything that fires on a signal: hooks, slash commands, skills, modes, tools, MCP, scheduled tasks. Per operator observation 2026-05-05 (cycle 41): *"somehow its a bit like the hook start and such we can even use commands and then also tools when needed.. sometimes triggered at gates or starts and end or such"*.
>
> **Strictness tier**: Advisory. Designed to inform composition decisions, not enforce a single mechanism. Closes F-eval-11 + SB-070.

## Insight

Hooks, slash commands, skills, modes, tools, MCP, and scheduled tasks all share the same shape:

```
SIGNAL (when does it fire?)  →  ACTION (what does it do?)  →  RECOVERY (what if it fails?)
```

The mechanisms differ in WHO fires the signal, HOW deterministic the action is, and WHAT the recovery loop looks like. Once you see the shape, composition becomes natural.

## The mechanisms compared

| Mechanism | Signal source | Determinism | Composability | Where in $HOME |
|---|---|---|---|---|
| **Hook** | Harness (Claude Code lifecycle: PreToolUse / PostToolUse / SessionStart / PreCompact / PostCompact / SessionEnd) | Logical (block + reason + remediation) | CAN call commands or tools via Bash from within | `$HOME/.claude/hooks/*.sh` (Python) |
| **Slash command** | Operator types `/<name>` literally (or skill invokes via Skill tool) | 100% on invoke (harness executes) | CAN call tools, other commands, or invoke skills | `$HOME/.claude/commands/*.md` |
| **Skill** | Description-match auto-trigger from operator prose (or explicit Skill invocation) | ~70-95% (semantic match) | CAN invoke commands or tools | `$HOME/.claude/skills/<name>/`, `~/.claude/skills/...` |
| **Mode** | State file `$HOME/.claude/active-mode` set by operator (durable across turns) | Affects subsequent cycle behavior; not per-turn | Composes WITH /cycle to define autopilot sequence | `$HOME/.claude/modes/*.md` |
| **Tool** | Agent invokes during reasoning (Read, Bash, Edit, MCP-tool, etc.) | Programmatic (deterministic input → deterministic output) | Most fundamental — hooks/commands/skills all compose tools | `$HOME/tools/*.py` (project-internal) + harness-provided |
| **MCP tool** | Agent invokes via MCP server (deferred-loaded in this session) | Programmatic, structured returns | Same shape as tools; just different transport | `mcp__root-modules__*` |
| **Scheduled task** | Time-trigger (cron) or self-paced (ScheduleWakeup) | Cron-deterministic OR agent-self-paced | Wraps any of the above (e.g. `/loop /cycle`) | `CronCreate`, `ScheduleWakeup` |
| **Sub-agent** | Parent agent invokes via Agent tool with `subagent_type` | Independent context; cold-start | Composes own brain-load + tool subset | `$HOME/.claude/agents/*.md` |

## Three signal-source categories

1. **Harness-deterministic**: hooks (lifecycle events), tools (agent-invoked via deferred-loaded API), scheduled tasks (cron / ScheduleWakeup). The harness fires; the agent receives.
2. **Operator-explicit**: slash commands (`/cycle`), mode-set (`/mode-dual`). Operator types literally; agent runs.
3. **Semantic-match**: skills (description-match auto-trigger). Operator prose; harness picks; agent runs.

The shape is the same — only the firing mechanism differs.

## Three action-determinism tiers

1. **Programmatic (deterministic)**: tools, MCP tools, /tools/*.py CLI scripts. Same input → same output. Use for: state queries, mutations, computations.
2. **Scripted (logical)**: hooks (block + reason + remediation), slash commands (when invoked, the harness executes the .md template; 100% reliable). Use for: enforcement, workflows.
3. **Generative (semantic)**: skills, modes, sub-agents. Agent compliance is ~70-95%. Use for: persona shifts, contextual behavior, judgment-required tasks.

## Composition patterns

### Hook → Command
A hook's additionalContext can direct the agent to invoke a command. Generative compliance (~85% reliable). E.g., `session-orient.sh` directs `/orient`; `post-compact.sh` directs `/orient` + read pre-compact handoff.

### Command → Tool
A command's body invokes tools (Read, Bash, etc.) deterministically when the harness executes the .md template. E.g., `/orient` calls Read 21 times; `/audit` runs 10 deterministic checks via Bash.

### Skill → Command
A skill's body can invoke a command via the Skill tool (e.g., `surface-state` → `/orient`). Same generative-compliance constraint as hook→command, but description-matched signals.

### Command → Sub-agent
A slash command can spawn a sub-agent (Agent tool) for delegated research with its own tool subset + brain-load profile.

### Mode → Cycle
Mode state file is read by `/cycle` skill each fire; cycle behavior changes per mode. The mode itself doesn't run anything — it modulates the cycle's content.

### Scheduled task → Anything
`/loop` + `ScheduleWakeup` wrap any of the above for repeated firing. The wrapper is just another signal-source layer.

## Anti-patterns

| Anti-pattern | Why bad |
|---|---|
| Conflating signal-source and action-determinism | A hook (signal=lifecycle) emits additionalContext (action=generative). Don't expect 100% reliability from a generative action just because the signal was deterministic. |
| Re-implementing logic across mechanisms | If a check belongs in 3 places (hook + cycle + skill), put it in a tool and have all 3 call the tool. Don't duplicate in the message format. |
| Using a generative mechanism for security enforcement | Skills/sub-agents are semantic — operator words can be paraphrased. Hard security gates belong in hooks (logical) or `permissions.deny` (deterministic). |
| Stuffing too much into a single mechanism | If a slash command takes 3 args + 5 conditional branches, split into multiple slash commands or a tool. |
| Operator-typed slash commands for every action | Some things should auto-fire (hooks); some should auto-invoke on prose (skills); some need operator-explicit (slash). Pick per cost-of-false-positive. |

## Decision matrix — picking the mechanism

| You want to... | Use | Why |
|---|---|---|
| Block dangerous tool calls | **Hook** (PreToolUse) | Logical enforcement; agent can't bypass |
| Surface state on operator prose | **Skill** (description-match) | Auto-trigger; but operator-explicit `/<name>` always works as fallback |
| Run a deterministic chain on demand | **Slash command** | 100% deterministic on invoke; readable in source |
| Compute a derived value | **Tool / MCP tool** | Programmatic; composable by anything |
| Persona shift across multiple turns | **Mode** | Durable state file; affects /cycle behavior |
| Recurring autopilot | **Scheduled task** wrapping a slash command | Cron OR ScheduleWakeup wraps `/cycle`-equivalent |
| Delegate research without context bloat | **Sub-agent** | Cold context; own tool subset; own brain-load profile |
| Bridge to external system | **MCP tool** | Structured returns; cross-process; standardized |

## How this rule was synthesized

Operator observation cycle 41: *"somehow its a bit like the hook start and such we can even use commands and then also tools when needed.. sometimes triggered at gates or starts and end or such"*.

Pattern recognized: signal-source × action-determinism × composability matrix. All 8 mechanisms compose along the SIGNAL → ACTION → RECOVERY axis. F-eval-11 in-progress (since cycle 14 design sketch); SB-070 in-progress (scalable signal-pattern direction); both close with this rule.

## Action layer — M-E001-1 productive-cycle vocabulary (the unified ACTION the 8 mechanisms emit)

The signal→action→recovery model has 3 phases. SIGNAL is mechanism-specific (8 mechanisms documented above). RECOVERY is mechanism-specific (per-mechanism failure modes). **ACTION is universal** — every mechanism's action emission maps to one of 9 canonical action types from the **M-E001-1 productive-cycle vocabulary** (DRAFT v2 at `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`):

| # | Action type | Emitted-by examples |
|---|---|---|
| 1 | `sb-closure` | Cycle skill / commands updating tracker |
| 2 | `verified-edit` | `tools.run-tests` confirms edit + inline regression output |
| 3 | `drift-fix-with-empirical` | Doc/state alignment with grep/Read evidence inline |
| 4 | `explicit-standby-with-named-reason` | Loop self-cancel per L4-refined trigger (`loop-cron-lifecycle.md`); cycle reports concrete blocker |
| 5 | `new-artifact` | Slash command authors new file (flagged agent-DRAFT per SB-095) |
| 6 | `doc-refresh` | Brain-file count refresh with empirically-verified-YYYY-MM-DD timestamp |
| 7 | `blocker-surface` | `/blockers` command emits decision-package format (per SB-071) |
| 8 | `operator-directive-register` | `/log` command writes verbatim to `wiki/log/` |
| 9 | `read-only-audit` | `/audit` command runs 10-step integrity check; `/orient` emits orient report |

**Universal cross-tool framing** (per AGENTS.md Hard Rule 14): every AI tool's cycle skill (Claude Code, opencode, Codex, Cursor, Gemini, etc.) MUST emit one canonical action type per fire. Mandatory cycle-report last-line: `Productive output: <type> — <one-line specific>`. THIN standby without named subject is the SB-128 bug.

This action layer **closes the unified trigger model loop** — the 8 mechanisms differ in SIGNAL but converge on the same ACTION vocabulary. Cross-mechanism consistency is structural.

## Cross-references

- Hooks: `.claude/rules/hook-architecture.md` (2-layer, 3-component pattern: insertion+reason+remediation)
- Routing: `.claude/rules/routing.md` (operator-intent → mechanism pick)
- Loop lifecycle: `.claude/rules/loop-cron-lifecycle.md` (when self-paced loops cancel/update; cycle content shifts but always emits one action type)
- Methodology: `.claude/rules/methodology.md` (stage-gates use commands + hooks + tools jointly)
- Operating principles: `.claude/rules/operating-principles.md` (strictness graduation per mechanism)
- Context engineering: `.claude/rules/context-engineering.md` (auto/pre/on-demand/facultative injection — applies to mechanism choice too)
- Compound + waterfall: `.claude/rules/compound-and-waterfall.md` (orthogonal axes — what layers ADDITIVELY at-a-moment vs how state flows event-to-event; the trigger model is one mechanism within the compound stack)
- [`.claude/rules/README.md`](README.md) — 11 rules with strictness-tier matrix
- [`.claude/hooks/README.md`](../hooks/README.md) · [`.claude/commands/README.md`](../commands/README.md) · [`.claude/skills/README.md`](../skills/README.md) · [`.claude/modes/README.md`](../modes/README.md) · [`.claude/agents/README.md`](../agents/README.md) · [`tools/README.md`](../../tools/README.md) — per-mechanism canonical indexes (DRAFT v1 — agent-authored 2026-05-06 evening)
- `wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md` — sacrosanct verbatim directive governing this rule's edit pass
- **`wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`** — M-E001-1 action vocabulary (the unified ACTION layer documented above)
- CLAUDE.md / AGENTS.md **Hard Rule 14** — productive-cycle taxonomy (mandatory cycle-report last-line `Productive output: <type>`)
