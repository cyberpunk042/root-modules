# SKILLS.md — root-modules skills directory

> Skills directory context for this project. Where skills live, conventions for authoring, when skills are appropriate vs other extension mechanisms (commands, hooks, sub-agents, tools, MCP, scheduled-tasks, modes — see [`.claude/rules/trigger-model.md`](.claude/rules/trigger-model.md) for the unified 8-mechanism signal→action→recovery framing). **Phase-2 has begun** for this project — 2 project-authored skills exist (`surface-state` + `surface-blockers`); the canonical per-skill index lives at [`.claude/skills/README.md`](.claude/skills/README.md) (DRAFT v1, agent-authored 2026-05-06 evening). This SKILLS.md is the operator-facing usage view + cross-mechanism design context.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct, applies to extension-mechanism reference files too)**: when refreshing SKILLS.md, **adding ≠ discarding**. Layer new content onto prior content; refresh inline values where empirically drifted; do NOT replace existing sections wholesale. Per Hard Rule 11 (additive≠discarding) the going-to-extremes pattern (SB-082/093 family) recurs when an agent rewrites instead of revises. Operator-verbatim conflation lesson at lines 132-140 is sacrosanct from second-brain `<second-brain>/raw/notes/2026-05-04-rename-continue-conflation-bug-and-similar-conflations.md` — preserve exactly.

## Summary

This file documents the skills layer of root-modules's extension architecture. Skills are **~70-95% deterministic** workflows that auto-trigger when operator prose matches the skill's description (per Claude Code's description-match dispatch — and similar mechanisms in opencode / Codex / Cursor / Gemini per cross-tool AGENTS.md framing). Less reliable than slash commands (100% on literal `/<name>` invoke) but useful for high-level workflows that should fire automatically on conversational language. The project currently has **2 committed skills** (`surface-state`, `surface-blockers`) at `.claude/skills/<name>/SKILL.md`, plus user-level harness-provided skills (loop, schedule, claude-api, etc.). The canonical per-skill index is [`.claude/skills/README.md`](.claude/skills/README.md); this SKILLS.md provides decision matrix (when to author skill vs command vs hook vs sub-agent), authoring conventions, conflation-pattern lessons (slash-vs-prose), and future-skill candidates. **Skills compose with active-mode** (per SB-117 + mode-enforcement.sh) and **emit M-E001-1 productive-cycle action types** (per Hard Rule 14) — see Mode-enforcement vs Skill section below.

## Skills, Commands, Hooks, Sub-agents (4 of 8 extension mechanisms)

Per the second brain's `model-skills-commands-hooks.md` + this project's [`.claude/rules/trigger-model.md`](.claude/rules/trigger-model.md), AI tools (Claude Code in particular; cross-tool per AGENTS.md universal framing) support multiple extension mechanisms with different determinism levels and trigger semantics. The 4 most-relevant for skills-context discussion (the full 8 — adding modes / tools / MCP / scheduled-tasks — covered at trigger-model.md):

| Mechanism | Determinism | Trigger | Use when (counts as of 2026-05-06 evening) |
|---|---|---|---|
| **Hook** | Logical (block + reason + remediation) | Tool-call lifecycle event (PreToolUse / PostToolUse / SessionStart / UserPromptSubmit / PreCompact / PostCompact / Stop / SessionEnd) | Structural enforcement: rule MUST hold at this point. **10 wired matchers across 8 events** in this project (17 .sh + 1 .py on disk; archived hooks retained per operator directive). |
| **Command** | **100% deterministic** | Operator types `/<name>` literally | Workflow with predictable steps, operator-driven, no auto-trigger needed. **30 commands** in this project at `.claude/commands/*.md`. |
| **Skill** | **~70-95% deterministic** | Auto-triggered by description-match on operator prose | Workflow where auto-trigger is desirable. **2 local skills** (surface-state, surface-blockers) at `.claude/skills/<name>/SKILL.md` + user-level harness-provided skills (loop, schedule, claude-api, etc.). |
| **Sub-agent** | **Brain-loaded on spawn** (project-specific per SB-081 — distinct from generic cold-context) | Parent agent invokes via Agent tool with `subagent_type` | Delegated research with own brain-load + tool subset. **3 brain-loaded sub-agents** in this project (root-explorer / root-architect / root-pm-scoper) — each has mandatory brain-load prompts naming CLAUDE.md / AGENTS.md / relevant rules. Per-sub-agent index at [`.claude/agents/README.md`](.claude/agents/README.md). |

The full 8-mechanism universal framing — adding **modes** (`.claude/modes/*.md` — durable state-file per active-mode setting), **tools** (15 .py modules at `tools/` — see [TOOLS.md](TOOLS.md) + [tools/README.md](tools/README.md)), **MCP tools** (10 root_* tools via `tools/mcp_server.py` — programmatic transport), **scheduled-tasks** (cron + ScheduleWakeup wrapping any of the above) — lives at [`.claude/rules/trigger-model.md`](.claude/rules/trigger-model.md). Skills are 1 of 8; this file focuses on skills with cross-references to the rest.

For root-modules:
- **Hooks** are the foundation's safety envelope + project-priming + compaction lifecycle + per-prompt compound stack. **10 wired matchers across 8 events** (UserPromptSubmit hosts 4-hook compound stack per SB-126: context-warning + output-discipline-guard + mode-enforcement + mindfulness). 8 hook regression test files at `.claude/hooks/tests/` + 5 tools test files = 13 test files / 215/234 aggregate. Per-hook inventory at [`.claude/hooks/README.md`](.claude/hooks/README.md).
- **Commands** are operator-typed slash commands for project workflows. **30 commands** (`/orient`, `/cycle`, `/mode-{pm,architect,dual,status,clear}`, `/blockers`, `/progress`, `/decisions`, `/log`, `/audit`, `/sync-progress`, `/help-root`, `/handoff`, `/stamp-{horizontal,vertical,on,off,auto,status}` SB-115, `/install-agent-brain`, `/mission`, `/focus`, `/impediment` SB-118, `/priorities` SB-127, `/terminate`, `/finish-smoothly`, `/task` SB-124d, `/questions` SB-134). Per-category index at [`.claude/commands/README.md`](.claude/commands/README.md).
- **Skills** are auto-triggered workflows. **`surface-state`** (auto-fires on "where are we" prose → `/orient`) + **`surface-blockers`** (auto-fires on "what's blocking" prose → `/blockers`) at `.claude/skills/<name>/SKILL.md`. Plus user-level harness-provided skills (loop, schedule, etc.). Per-skill index at [`.claude/skills/README.md`](.claude/skills/README.md).
- **Sub-agents** are **brain-loaded** delegated workers (project-specific per SB-081 — root-modules's 3 sub-agents have mandatory brain-load prompts; distinct from generic cold-context Agent-tool framing). 3 at `.claude/agents/*.md`. Runtime gap: session-restart required for Claude Code to discover newly-authored sub-agents (per SB-081 runtime test 2026-05-05).

## Currently Available Skills

| Skill | Path | Description-match trigger | What it does | Composes |
|---|---|---|---|---|
| `surface-state` | `.claude/skills/surface-state/SKILL.md` | "where are we" / "what's the state" / "current state" / "give me an overview" / "orient me" — conversational state-summary requests | Routes to `/orient` deterministic 21-step chain (Read brain + verify state + structured ORIENT REPORT) | `/orient` slash command (the deterministic chain skill composes onto) |
| `surface-blockers` | `.claude/skills/surface-blockers/SKILL.md` | "what's blocking" / "are we blocked" / "pending decisions" / "operator decisions needed" / "what needs my input" — conversational blocker-surfacing requests | Routes to `/blockers` slash command (decision-package format: CONTEXT + GUIDANCE + RECOMMEND + ALTERNATIVES + TO ANSWER per SB-071) | `/blockers` slash command |

**Description-match discipline**: trigger string quality determines skill reliability — vague descriptions produce false-positives or false-negatives. Per the Skill vs Slash Command conflation lesson below, descriptions must NOT match prose words that have established trajectory-language meaning ("continue", "evolve", "review" — these are trajectory-language for the agent's current track, NOT workflow triggers).

Plus user-level / harness-provided skills (`loop`, `schedule`, `claude-api`, audit, cycle, mode-*, blockers, progress, decisions, log, handoff, help-root, etc.) — see `/help-root` for the full project surface.

**Cross-reference**: per-skill canonical index at [`.claude/skills/README.md`](.claude/skills/README.md) (DRAFT v1, agent-authored 2026-05-06 evening) — covers description-match discipline + skill-vs-command-vs-hook decision matrix + future-skill candidates + extension guide.

## Skills Directory (current state — 2 skills authored)

The 2 committed project-authored skills live at:

```
$HOME/.claude/skills/
  <skill-name>/
    skill.md      # SKILL.md format (frontmatter + instructions + trigger)
    (other files)
```

Each skill is a directory under `$HOME/.claude/skills/` containing a `skill.md` file with:

- Frontmatter: `name`, `description` (used for auto-trigger matching), `tools` (which AI tools the skill is available to)
- Body: instructions for the AI tool when the skill is auto-triggered

## When a Skill Is Appropriate (vs Command, vs Hook)

Decision matrix:

| Question | If yes → | If no → |
|---|---|---|
| Does the workflow need auto-trigger from operator prose? | Skill or hook | Command |
| Is the workflow a tool-call-time decision (allow/deny/ask)? | Hook | Skill or command |
| Is the workflow an operator-typed explicit invocation? | Command | Skill or hook |
| Does the workflow have predictable scripted steps the operator wants on-demand? | Command | Skill |
| Does the workflow have variable shape that the agent should reason about? | Skill | Command |
| Does the rule MUST hold at this point (not "should remember")? | Hook | Skill or command |

For root-modules specifically:

| Workflow | Mechanism | Why |
|---|---|---|
| Tamper detection on every tool call | **Hook** (PreToolUse) | Must run before every call; rule must hold at this point |
| Deny-set check on credential paths | **Hook** (PreToolUse) | Must run before tool executes; rule must hold |
| Leak detection on tool output | **Hook** (PostToolUse) | Must run after every tool output; rule must hold |
| Session-start integrity self-check | **Hook** (SessionStart) | Must run at session start; rule must hold |
| Operator typing `/verify-foundation` to run M003 gate | **Command** (planned) | Operator-typed; deterministic scripted steps |
| Operator typing `/audit-deny-set` to inspect policy state | **Command** (planned) | Same |
| Auto-triggered "ingest a Suricata-related URL" workflow when operator says "ingest <url>" | **Skill** (none planned for this project — ingestion is a second-brain concern, not this project's) | (n/a here — would route through second brain after M007) |
| Auto-triggered "audit deny-set" when operator says "audit" or "is the policy intact" | **Skill** (potentially, M004+) | Auto-trigger gives low-friction operator UX; description-match is reliable for these terms |

The current verdict (refreshed 2026-05-06 evening): most-leveraged workflows for root-modules at the current implement-stage tier are **hooks** (10 wired matchers in foundation safety envelope + per-prompt compound stack) and **commands** (30 operator-driven slash commands across orient/cycle/modes/stamp/objective/backlog/audit/install categories). **Skills Phase-2 has begun** — 2 committed (surface-state, surface-blockers) validate the auto-trigger-from-operator-prose value proposition. Future skills (4 illustrative candidates below) are operator-decision Phase-2+ additions where auto-trigger adds low-friction operator UX — for example, methodology-routing skills that auto-trigger when operator references a specific workflow shape.

## Skill Authoring Conventions (when skills are added)

When a skill is authored for this project, it follows these conventions:

### File layout

```
$HOME/.claude/skills/<skill-name>/skill.md
```

One directory per skill. The `skill.md` file is the canonical form. Additional files (templates, scripts referenced by the skill) live alongside `skill.md` in the same directory.

### Frontmatter

```yaml
---
name: <skill-name>
description: <one-sentence description used for auto-trigger matching>
tools:
  - Read
  - Bash
  - Edit
  # ... only the tools the skill actually needs
---
```

The `description` field is the auto-trigger signal. Quality matters — the description must be specific enough to fire on the right operator prose AND general enough to fire on operator prose that varies in phrasing.

### Body

```markdown
# <Skill name>

<one-paragraph context: when this skill applies, why it exists>

## When to use

<bulleted list of operator prose patterns that should trigger this skill>

## Steps

<numbered list of steps the agent follows when the skill auto-triggers>

## Done When

<checklist of completion criteria>
```

### Naming

- Skill names use kebab-case: `audit-deny-set`, `verify-foundation-gate`.
- Skills do NOT shadow commands. If a slash command exists with the same intent, the skill name should be different (e.g. command `/verify-foundation` + skill `audit-policy-state` for prose-triggered variant).

### Determinism caveat

Skills are ~70% deterministic. The auto-trigger fires based on description-match against operator prose, which is non-deterministic. **Don't use a skill when the workflow MUST run** — use a hook for that.

## Skill vs Slash Command (the conflation pattern to avoid)

Per `<second-brain>/raw/notes/2026-05-04-rename-continue-conflation-bug-and-similar-conflations.md`, prose-vs-slash conflation is a documented failure mode in the second brain ecosystem. The lesson:

- **Slash commands** (`/checkin`, `/distill`, `/healthcheck`, etc.) are operator-invoked LITERALLY. They fire only when the operator types the slash + name verbatim.
- **Bare prose** ("continue", "evolve", "review") is **trajectory language** for the agent's current track, NOT a workflow trigger. Don't conflate these.
- **Skills** auto-trigger on description-match. Their descriptions should NOT match prose words that have established trajectory-language meaning. A skill description like "trigger on 'continue'" would conflate with the operator's bare "continue" trajectory-language.

For root-modules: if + when skills are added, their descriptions are written carefully to avoid matching trajectory-language phrases. The second brain has renamed three slash commands (`/continue` → `/checkin`, `/review` → `/healthcheck`, `/evolve` → `/distill`) precisely to break this conflation. Future root-modules slash commands + skills should follow the same discipline.

## Mode-enforcement vs Skill (compose, don't conflict)

> Skills compose with the active-mode layer (per SB-117 + `mode-enforcement.sh` UserPromptSubmit hook). Understanding the composition prevents "is this skill or mode behavior?" confusion.

| Layer | Trigger | Scope | Persistence |
|---|---|---|---|
| **Skill** (`.claude/skills/<name>/SKILL.md`) | Auto-trigger on description-match against operator's CURRENT prompt | Single-prompt response shape | None — skill fires per-matching-prompt |
| **Active-mode** (`.claude/active-mode` state file: pm-scrum-master / devops-architect / dual-expert / empty) | Operator-set via `/mode-pm` `/mode-architect` `/mode-dual` `/mode-clear` | Multi-cycle persona + cycle-step routing | Durable across turns; persists to state file |
| **Mode-enforcement hook** (`mode-enforcement.sh` UserPromptSubmit) | Per-prompt when active-mode set | Injects `additionalContext` banner with persona + cycle steps + live-state | Per-prompt (read fresh each fire) |

**Composition rules:**

- **Skills fire INDEPENDENTLY of active-mode** — `surface-state` auto-triggers on "where are we" prose regardless of which mode is active.
- **Active-mode shapes the FOLLOW-UP behavior after the skill routes** — e.g., `surface-state` routes to `/orient`; `/orient` is mode-aware (reads active-mode + applies mode-specific cycle steps).
- **Mode-enforcement banner runs alongside skill execution** — skill's auto-trigger doesn't suppress the banner; both contribute to the prompt's compound stack (per SB-126 + `compound-and-waterfall.md`).

**Anti-pattern (do NOT do)**: author a skill that REPLACES mode-aware behavior. Skills should compose existing mechanisms (slash commands, mode files), not duplicate or override them. Per Hard Rule 14 (productive-cycle taxonomy), skills emit M-E001-1 action types; the action type emitted may differ per active-mode but the skill itself should not encode mode-specific logic.

## Cross-tool universal framing

> Skills mechanism is **cross-tool universal** per AGENTS.md framing. Every AI tool (Claude Code, opencode, Codex, Cursor, Gemini + future AGENTS.md-standard tools) supports skill-equivalent description-match dispatch via its own extension SDK. The `.claude/skills/<name>/SKILL.md` format is Claude Code's surface; opencode + others have parallel mechanisms with different file conventions but same semantic role.

For root-modules specifically:
- **Skill files at `.claude/skills/`** are read by Claude Code natively.
- **opencode bridge plugin** (`$HOME/.config/opencode/plugin/claude-bridge.ts`) maps opencode's plugin-trigger events to the same canonical envelope; skill-equivalent dispatch in opencode would route through its plugin SDK with the bridge translating.
- **Cross-tool consistency invariant** (per AGENTS.md Hard Rule 3): skill descriptions are written to be tool-agnostic (no Claude-Code-specific phrasing) so the same skill conceptually applies regardless of which AI tool fires it.

The unified 8-mechanism signal→action→recovery model at [`.claude/rules/trigger-model.md`](.claude/rules/trigger-model.md) covers all extension-mechanism categories cross-tool.

## Future Skill Candidates (operator-decision; 2 skills currently committed)

> The 2 currently-committed skills (`surface-state`, `surface-blockers`) are documented above. The illustrative candidates below are NOT committed — they're future-decision examples to anchor the skills concept in concrete project workflows. Skill addition is operator-decided Phase-2+ work.

If skills are added later, candidates include:

| Candidate skill | Auto-trigger description | Steps |
|---|---|---|
| `audit-policy-state` | "Operator wants to know whether the safety policy is intact + audit deny-set count + verify hooks" | 1. Run integrity check; 2. Run deny-set count audit; 3. Run hook executable audit; 4. Report findings |
| `prepare-module-design` | "Operator is starting design work for a new inspection module" | 1. Read M005 module page; 2. Pull source-synthesis pages from second brain; 3. Capture sample test pcap; 4. Outline design doc structure |
| `verify-foundation-gate` | "Operator wants to verify the M003 Foundation gate" | 1. `./install.sh --dry-run`; 2. Integrity check; 3. git audit; 4. Report green/red |
| `verify-bridge-topology` | "Operator wants to confirm bridge is up + L3-invisible" | 1. `brctl show`; 2. `ip link`; 3. nftables INPUT chain check; 4. Report state |

**None of these are committed.** They are examples to anchor the skills concept in concrete project workflows. Skill addition is operator-decided Phase-2+ work.

## Agent personal-learning notes (operator-allowed, per directive 2026-05-06)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. Entries below are **agent-authored** (per SB-095 — flagged as agent-DRAFT). Operator may revise / promote / remove. Each timestamped + initialed `[agent]`. SKILLS.md-specific framing — skills-mechanism reference-file lessons.

### 2026-05-06 evening — "Future-tense" framing trap when reference files outlive their initial-state authoring

`[agent]` SKILLS.md was authored when zero project skills existed; the file's intro framing ("**Future-tense** for this project... no project-authored skills exist yet") was accurate at that time. By 2026-05-06 evening, 2 skills had been committed but the intro was never refreshed. Pattern: reference files written in initial-state framing accumulate "this is future" language that becomes stale as features mature.

**Discipline**: when reviewing a brain reference file in any subsequent session, scan for "future-tense" / "planned" / "will be" framings + verify against current empirical state (per Hard Rule 15 empirical-count-verification). When state has advanced past the framing, REFRESH the framing inline (per Hard Rule 11 — additive, not destructive). Do NOT delete future-decision design-intent content; it's still useful as candidate-for-later context.

### 2026-05-06 evening — SKILLS.md vs `.claude/skills/README.md` role distinction

`[agent]` Two files cover the skills layer with different focuses:
- **SKILLS.md** (this file, root level) — operator-facing usage view + cross-mechanism design context. Decision matrix (skill vs command vs hook vs sub-agent). Authoring conventions. Conflation lessons. Future-skill candidates with rationale. Mode-enforcement-vs-Skill composition rules.
- **[`.claude/skills/README.md`](.claude/skills/README.md)** (subdir level, DRAFT v1 2026-05-06 evening) — per-skill canonical index. Description-match trigger details per skill. Skill-vs-command-vs-hook decision matrix. Future-skill candidates table. Extension guide.

These are NOT redundant — they serve different audiences. SKILLS.md answers "WHEN should I author a skill (vs other mechanism)?"; `.claude/skills/README.md` answers "WHAT skills exist + how do I author one?". Both reference the canonical second-brain `model-skills-commands-hooks.md`.

### 2026-05-06 evening — Skills compose with modes (anti-conflation rule)

`[agent]` The Mode-enforcement-vs-Skill section codifies a non-obvious composition rule: skills fire independently of active-mode; mode shapes follow-up behavior. Easy regression: authoring a skill that encodes mode-specific logic (e.g., "if active-mode = pm-scrum-master, route to X; else route to Y"). DON'T DO THIS — the skill auto-triggers on prose-match; the mode-aware routing happens DOWNSTREAM in the slash command (e.g., `/orient` reads active-mode + applies mode-specific cycle steps). Skills compose by ROUTING, not by encoding mode-conditional logic.

### 2026-05-06 evening — productive-cycle vocabulary skills mapping

`[agent]` Per Hard Rule 14 (M-E001-1 vocabulary): each cycle-fire emits one of 9 action types. Skills are one mechanism that emits action types; the mapping varies per skill:

- `surface-state` skill → routes to `/orient` → emits `read-only-audit` action type (M-E001-1 type 9)
- `surface-blockers` skill → routes to `/blockers` → emits `blocker-surface` action type (M-E001-1 type 7)
- Future `audit-policy-state` skill → would route to `/audit` → emits `read-only-audit`
- Future `prepare-module-design` skill → would route to module work → emits `new-artifact` (M-E001-1 type 5)

The action-type-vocabulary mapping is consistent across mechanisms (commands emit the same types as skills as hooks); skills are just the auto-trigger surface.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). Not `.claude/skills/README.md` (per-skill index). For SKILLS.md-specific extension-mechanism reference lessons that benefit fresh-pickup agents but are too small to warrant their own rule file. Operator promotes to structured artifact when pattern matures.

## Cross-References

### Top-level brain files (10)

| For… | Read |
|---|---|
| Project description + identity + modules + status | [README.md](README.md) |
| Cold-pickup orientation | [BOOTSTRAP.md](BOOTSTRAP.md) |
| Tools (per-script reference) | [TOOLS.md](TOOLS.md) |
| System architecture in depth (incl. hook flow) | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Design pattern rationale (incl. why hooks vs commands vs skills) | [DESIGN.md](DESIGN.md) |
| Security policy (threat model + fail-closed enforcement) | [SECURITY.md](SECURITY.md) |
| Cross-tool agent contract + canonical envelope + universal Hard Rules | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing + 15 Hard Rules | [CLAUDE.md](CLAUDE.md) |
| Current operational state | [CONTEXT.md](CONTEXT.md) |

### Subdirectory READMEs (9 — DRAFT v1, agent-authored 2026-05-06 evening)

| For… | Read |
|---|---|
| **Per-skill canonical index** (canonical extension of SKILLS.md) | [.claude/skills/README.md](.claude/skills/README.md) |
| 30 slash commands by category | [.claude/commands/README.md](.claude/commands/README.md) |
| 18 hook scripts (10 wired + archive) by event | [.claude/hooks/README.md](.claude/hooks/README.md) |
| 3 modes + cycle-sequence comparison (skills compose with modes) | [.claude/modes/README.md](.claude/modes/README.md) |
| 11 rules + strictness-tier matrix | [.claude/rules/README.md](.claude/rules/README.md) |
| 3 brain-loaded sub-agents | [.claude/agents/README.md](.claude/agents/README.md) |
| 15 Python tools (skills compose with tools via slash commands) | [tools/README.md](tools/README.md) |
| 5 install template categories | [templates/README.md](templates/README.md) |
| Deployment + maintenance toolkit | [scripts/README.md](scripts/README.md) |

### Universal cross-cutting rules

| For… | Read |
|---|---|
| **Unified 8-mechanism signal→action→recovery model** (skills are 1 of 8) | [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) |
| Compound + waterfall axes (skills populate compound axis per-prompt) | [.claude/rules/compound-and-waterfall.md](.claude/rules/compound-and-waterfall.md) |
| Context-engineering (auto/pre/on-demand/facultative injection — skills are auto-trigger) | [.claude/rules/context-engineering.md](.claude/rules/context-engineering.md) |
| **Hard Rule 14 (productive-cycle taxonomy)** — skills emit M-E001-1 action types | [CLAUDE.md](CLAUDE.md) Rule 14 + [AGENTS.md](AGENTS.md) Rule 14 |
| Hard Rules 11-13 + 15 (additive≠discarding, brain-inheritance, chain-operations, empirical-count-verification) | [CLAUDE.md](CLAUDE.md) + [AGENTS.md](AGENTS.md) |
| Operator-words sacrosanct + premise-confirmation gate + conditional-clause grammar | [.claude/rules/words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) |
| Strictness graduation (advisory / enforced / strict / deterministic) | [.claude/rules/operating-principles.md](.claude/rules/operating-principles.md) |

### Brain-improvement mandate (this work block — 2026-05-06)

| For… | Read |
|---|---|
| Sacrosanct verbatim directive governing this SKILLS.md edit pass | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| M-E001-1 productive-cycle action vocabulary DRAFT v2 (9 types — skills emit these) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |

### Second brain (canonical sources)

| For… | Read |
|---|---|
| Skills/Commands/Hooks model (canonical) | `<second-brain>/wiki/spine/models/agent-config/model-skills-commands-hooks.md` |
| Three-Layer Agent Context Architecture (canonical) | `<second-brain>/wiki/patterns/01_drafts/three-layer-agent-context-architecture.md` |
| Prose-vs-slash conflation lesson (canonical, sacrosanct) | `<second-brain>/raw/notes/2026-05-04-rename-continue-conflation-bug-and-similar-conflations.md` |
| Markdown-as-IaC model (skills are one Markdown layer) | `<second-brain>/wiki/spine/models/agent-config/model-markdown-as-iac.md` |
