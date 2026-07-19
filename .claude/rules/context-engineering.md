# $HOME/.claude/rules/context-engineering.md — Context engineering: auto/pre/on-demand/facultative injection modes

> Loaded on demand when designing how an agent gets context (which file, which timing, which mechanism). Per operator directive 2026-05-05.
>
> **Strictness tier**: Advisory (per `operating-principles.md`). Designed to inform judgment, not enforce a single approach. Each context-loading decision is evaluated per its case.
>
> **DRAFT v1 (SB-129, 2026-05-06)** per `<second-brain>/wiki/spine/standards/concept-page-standards.md` — Summary + Key Insights + Deep Analysis subsectioned. Quality bar: `<second-brain>/wiki/spine/standards/model-standards/model-context-engineering-standards.md`.

## Summary

Context engineering is the discipline of designing what information reaches an AI agent — at what timing, in what structure, at what depth. This rule defines four orthogonal injection modes (auto / pre / on-demand / facultative) that map content-types to delivery channels in root-modules. Pairs with `compound-and-waterfall.md` (compound axis = which layers coexist at-a-moment) and `trigger-model.md` (signal→action→recovery composition).

## Key Insights

1. **Injection mode determines reliability tier.** Auto-injection (CLAUDE.md auto-load) is most reliable; pre-injection (/orient deterministic chain) is 100% on invoke; on-demand depends on triggers firing; facultative depends on operator opt-in. Match content criticality to mode reliability.

2. **Context compaction destroys content but preserves structure.** Prose corrections vanish; YAML files / typed fields / declared sections survive. Design state-bearing content as files (not conversation), so post-compact recovery via /orient can reconstruct.

3. **Same content, different mode, different cost.** Critical content as on-demand = agent forgets to load. Auto-inject everything = context bloat + cache miss + cost. The right mode for the right content.

4. **Compound axis populates context window per fire.** The four modes orthogonally fill the compound stack (`compound-and-waterfall.md`) — auto at SessionStart, pre on each prompt via hooks, on-demand when topic surfaces, facultative per active mode.

5. **Operator-explicit content MUST NOT be self-capped.** Per SB-122 closure: agent self-truncating mode-enforcement banner / persona voice / objective layer for "budget courtesy" dismisses operator-authored directives at injection moment — the very thing context engineering preserves.

## Deep Analysis

### The four context-injection modes

Per operator directive 2026-05-05: *"with proper context engineering and facultative auto or pre-injection modes and the autocomplete & prompt engineering knowlegde too."*

| Mode | When content lands in context | Where used in $HOME |
|---|---|---|
| **Auto-injection** | Without agent action — system-level | SessionStart hook output (additionalContext JSON) → CLAUDE.md auto-load → AGENTS.md auto-load |
| **Pre-injection** | Agent proactively loads BEFORE responding to user — agent action triggered by directive | `/orient` deterministic 21-step chain runs Reads + Bashes |
| **On-demand** | Loaded only when topic comes up — reactive | `.claude/rules/<topic>.md` per-topic loading via CLAUDE.md routing entries |
| **Facultative** | Configurable per mode/context — opt-in/opt-out | Mode-specific brain pieces (loaded only in active mode); `.claudeignore` excludes from auto-context; per-cycle reads vary per mode |

### Choosing the right mode for a piece of content

| Content type | Recommended mode | Why |
|---|---|---|
| Universal hard rules (operator words sacrosanct, etc.) | Auto + Pre (both) | Must be in context every turn; agent can't operate correctly without |
| Project identity (what this project IS) | Auto-injection (CLAUDE.md auto-load) | Foundational; cheap; needed every turn |
| Topic-specific rules (hook-architecture, methodology, etc.) | On-demand | Avoids context bloat; load when topic comes up |
| Active state (current SFIF stage, blockers, progress) | Pre-injection (/orient command) | Needs to be FRESH each session; deterministic pre-load |
| Sub-deliverables (sources, lessons, patterns) | Facultative | Load when relevant; avoid blanket inclusion |
| Operator-verbatim directives ($HOME iteration) | Pre-injection (`$HOME/wiki/log/<latest>.md` read by /orient + /cycle) + Sacrosanct retention | Primary source for $HOME iteration; must be quoted verbatim if relevant |
| Operator-verbatim directives (PRIOR sessions, historical) | On-demand (`/opt/.../raw/notes/2026-*.md` read for project-history context) | Read-only citation source; do NOT write back |
| Mode-specific persona | Facultative (per active mode) | Only loaded when the mode is active |

### Anti-patterns

| Anti-pattern | Why bad |
|---|---|
| Auto-inject everything ("just load it all") | Context bloat → cache miss → cost increase → agent confusion |
| Rely on agent-natural-association for critical content | Agents miss connections under context pressure; deterministic pre-injection more reliable |
| Pre-inject content that's the same every session and doesn't need refresh | Wastes per-session bandwidth; auto-inject in CLAUDE.md instead |
| On-demand load for content that's needed every turn | Agent forgets to load; rule-driven on-demand only works when triggers are reliable |
| Facultative without clear opt-in/opt-out signal | Operator/agent doesn't know if it loaded |
| Self-cap on operator-explicit content (per SB-122) | "Budget courtesy" truncation of mode-enforcement banner / persona voice / objective layer dismisses operator-authored directives at the moment of injection — the very thing context-engineering should preserve |
| Conditionally drop a render row when value empty | Operator can't see the layer state; reads as "missing", not "empty" — visibility ≠ presence (see SB-082 pendulum recurrence pattern) |

### Composition with compound axis (SB-123 cross-reference)

> **DRAFT MARKER (SB-129, 2026-05-06)**: section was append-edited without compile/restructure pass. Per operator directive: needs second-brain-informed quality engineering before treating as canonical.

The four injection modes (auto / pre / on-demand / facultative) populate the COMPOUND axis from `compound-and-waterfall.md`. Each prompt's context window is a compound stack; injection mode determines which layers compound at-a-moment:

| Layer (compound rank) | Source | Injection mode |
|---|---|---|
| Persona (mode + voice) | mode-enforcement banner | Pre + Facultative (mode-conditional) |
| Priorities (imminent) | mode-enforcement banner | Pre |
| Mission · Focus · Impediment | mode-enforcement banner | Pre |
| Mindfulness baseline | mindfulness banner | Pre + Facultative (mode-conditional) |
| Live state (ambient) | mode-enforcement LIVE STATE | Pre |
| Operator-prompt content | UserPromptSubmit | Auto |
| Mode files (deeper detail) | Read on demand | On-demand |

The hook layer composes these. **Prompt engineering** in this project = author the per-hook content (banner clauses, persona voice, cycle steps) so each layer compounds without colliding. Anti-pattern: hooks emit competing or redundant content that crowds context.

**Operator-empirical evaluator** for this composition: the mode-enforcement banner output. If the agent can read all 6 mindfulness clauses + 10 voice qualities + cycle steps + priorities + mission/focus/impediment + live state in one prompt without confusion, the compound is well-engineered.

### Mode → context profile mapping

Each mode in `$HOME/.claude/modes/` defines a "primary brain pieces" list — the FACULTATIVE auto-injection profile for that mode. When the operator enables a mode, the agent treats that profile as "should-be-loaded-pre-cycle" priority.

| Mode | Primary brain pieces | Auto/Pre/On-demand |
|---|---|---|
| PM Scrum Master | CONTEXT.md, blockers.md, progress.md, decisions.md, _index.md | Pre-injection on `/cycle` |
| DevOps Architect | ARCHITECTURE.md, DESIGN.md, methodology.yaml, source-syntheses | Pre-injection on `/cycle` |
| Dual Expert | Both (lens-switched per question) | Pre-injection on `/cycle` |

The `.claude/active-mode` state file + `/orient` step 19-21 jointly drive this — when a mode is active, /orient detects + loads the mode's primary brain pieces.

### Autocomplete + prompt engineering knowledge (operator framing)

Operator's directive: *"the autocomplete & prompt engineering knowlegde too."*

These belong in the second brain (cross-project knowledge resource); $HOME consumes them via `gateway query` or `wiki_search` MCP.

For $HOME specifically:
- **Autocomplete metadata** in command frontmatter would empower harness-side completion (F011 future-decision; not currently consumed)
- **Prompt engineering** as content lives in second brain; agents reach for it when authoring prompts (e.g., refining a skill description for better trigger-match)

When `$HOME` agent needs autocomplete or prompt-engineering knowledge: query the second brain via `wiki_search` MCP. Don't duplicate in $HOME.

### Frontmatter parameters as empowerment (related)

Per operator: *"using the parameters block of a markdown it can help with a lot of things including empowering or enabling tools and tooling."*

Backlog frontmatter (status, priority, parent_module, current_stage, readiness, sfif_stage) drives `tools.progress` + `tools.blockers`. This IS the parameters-as-empowerment pattern in action.

Future: enrich command + skill + mode frontmatter with tool-consumable fields (composes_tools, composes_commands, applies_when_mode, argument_schema, cooldown). F011 / F009 territory.

## Composition with other rules

- `routing.md` — operator-intent → tool routing (where to inject)
- `methodology.md` — stage-specific allowed/forbidden content (what to inject when)
- `hook-architecture.md` — auto-injection mechanics (how the harness delivers)
- `loop-cron-lifecycle.md` — when context-load fires per cycle
- `operating-principles.md` — strictness graduation (when to enforce a context rule vs leave advisory)

## Cross-references

- Operator directive: `<second-brain>/raw/notes/2026-05-05-thorough-review-context-engineering-versatility-and-network-spec-note.md`
- Co-evolution lesson: `/opt/.../wiki/lessons/01_drafts/second-brain-and-projects-co-evolve-never-finished-doctrine.md`
- BOOTSTRAP.md (the read-order surfaces context-injection sequencing)
- `.claude/rules/compound-and-waterfall.md` — sister rule: WHEN/HOW to think about layered context (compound axis = additive coexistence) vs flowed context (waterfall axis = sequential cascade); the four injection modes here populate the compound stack
- `.claude/rules/trigger-model.md` — sister rule: signal→action→recovery composition across 8 mechanisms (hooks/commands/skills/modes/tools/MCP/scheduled-tasks/sub-agents)
- [`.claude/rules/README.md`](README.md) — 11 rules with strictness-tier matrix
- [`.claude/hooks/README.md`](../hooks/README.md) — UserPromptSubmit 4-hook compound stack (per-prompt context injection mechanism)
- [`.claude/commands/README.md`](../commands/README.md) — 30 slash commands (each emits action types per M-E001-1 vocabulary)
- [`.claude/skills/README.md`](../skills/README.md) — 2 description-match auto-trigger skills (auto-injection mode for skill workflows)
- `wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md` — sacrosanct verbatim directive governing this rule's edit pass
- **`wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`** — M-E001-1 productive-cycle action vocabulary (9 types). Per-fire context-emission discipline — every cycle's compound-stack injects context AND emits one canonical action type (Hard Rule 14 in CLAUDE.md/AGENTS.md). The action vocabulary is the universal cross-tool consumption interface for context-injected workflows.
