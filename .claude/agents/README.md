---
title: ".claude/agents/ — root-modules brain-loaded subagents"
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
tags: [readme, agents, subagents, agent-authored, draft]
---

# `.claude/agents/` — brain-loaded subagents

> **DRAFT v1 — agent-authored 2026-05-06** per SB-095. Operator may revise / promote / replace.

## Summary

Indexes the 3 brain-loaded subagents in `$HOME/.claude/agents/` (root-explorer, root-architect, root-pm-scoper) authored at SB-081. Each subagent has a **mandatory brain-load prompt** in its frontmatter — when spawned via the Agent tool, the first thing it does is read project brain pieces (CLAUDE.md, AGENTS.md, relevant rules), so its output operates FROM the project (per `self-reference.md` framing) not OVER it. **Runtime gap**: subagents are loaded by Claude Code at session-start; new subagents authored mid-session are NOT discovered until session restart (per SB-081 runtime test 2026-05-05). Workaround until restart: use Claude Code's built-in subagents (Explore / general-purpose / Plan / claude-code-guide) with explicit brain-load instructions in the spawn prompt. Custom subagents in this subdir become available after operator-driven session restart.

## The 3 subagents

| Subagent | Brain-load profile | When to spawn |
|---|---|---|
| **[`root-explorer.md`](root-explorer.md)** | Mandatory load: BOOTSTRAP.md + CLAUDE.md + CONTEXT.md + relevant rules; tool subset focused on Read / Glob / Grep / Bash | Open-ended exploration of $HOME (codebase / wiki / state) where the parent agent doesn't want to consume own context; "find files matching X / search for Y across the project" |
| **[`root-architect.md`](root-architect.md)** | Mandatory load: ARCHITECTURE.md + DESIGN.md + methodology.yaml + relevant source-syntheses; tool subset focused on Read / Edit / Write / Bash | Architecture decisions / IaC implementation / design trade-off analysis; "should we use NFQUEUE vs AF_PACKET for the Suricata IPS path?" |
| **[`root-pm-scoper.md`](root-pm-scoper.md)** | Mandatory load: CONTEXT.md + blockers.md + progress.md + decisions.md + _index.md; tool subset focused on Read / Bash | Backlog grooming / decision packaging / scope estimation; "what would it take to land M005 first feature module?" |

## Why brain-loaded subagents (vs cold subagents)

Per SB-081 (operator directive 2026-05-05): *"this is another sidenotes but we can do that the sub-agents are not brainless too"*.

When a parent agent spawns a subagent via the `Agent` tool, the subagent starts with **no project context** by default. For root-modules work (where the project's intelligence lives in CLAUDE.md + AGENTS.md + .claude/rules/), a brainless subagent produces output that drifts from project doctrine — wrong path conventions, wrong tool invocations, wrong methodology framing.

These 3 subagents have **mandatory brain-load prompts** in their frontmatter — when spawned, the first thing they do is read the project's brain pieces. The subagent then operates FROM the project, not OVER it (per `self-reference.md` framing).

## Subagent spawn pattern

```python
# From parent agent (Claude Code session in $HOME or sister-project)
Agent(
  subagent_type="root-explorer",  # one of the 3
  description="Find all files mentioning X in $HOME/wiki/",
  prompt="<the actual task with full context>"
)
```

The subagent's frontmatter dictates which tools it can use + what brain-load is mandatory. The parent agent's spawn prompt is the task; the subagent's brain-load happens automatically before the task runs.

## SB-081 runtime gap (operator-known)

Per 2026-05-05 runtime test:

> Agent tool returned: "Agent type 'root-explorer' not found. Available agents: claude-code-guide, Explore, general-purpose, Plan, statusline-setup". Custom agents at `.claude/agents/` not picked up by current session; needs OPERATOR ACTION = session restart for Claude Code to discover them.

**Status**: structurally fixed (files correct on disk, frontmatter validates). **Runtime gap**: requires session restart for Claude Code to detect new subagents. Not auto-detected mid-session.

**Workaround until session restart**: use Claude Code's built-in subagents (Explore / general-purpose / Plan / claude-code-guide) with explicit brain-load instructions in the spawn prompt. The custom subagents in this subdir become available after session restart.

## Anti-patterns (do not do)

- **Spawn subagent without brain-load** — produces output that drifts from project doctrine
- **Auto-spawn subagents in cycles** — subagent costs context + time; only spawn when parent agent's context budget benefits from delegation
- **Author subagent files mid-session** expecting immediate availability — Claude Code discovers them at session start; mid-session authoring requires session restart
- **Treat subagent output as authoritative** — verify subagent output against canonical sources (per `operating-principles.md` evidence-priority hierarchy)

## Frontmatter convention

Each subagent file has:

```yaml
---
name: <subagent-id>
description: <description-match for selection>
tools:
  - Read
  - Glob
  - Grep
  - Bash
  # ... etc per subagent's tool subset
mandatory_brain_load:
  - BOOTSTRAP.md
  - CLAUDE.md
  - CONTEXT.md
  - .claude/rules/<relevant-rule>.md
---

# Subagent definition (system prompt body)
You are root-explorer / root-architect / root-pm-scoper. Your job is X. ...
```

## Extending — adding a new subagent

When you author a new subagent:

1. Place at `.claude/agents/<name>.md` with the frontmatter convention
2. Define mandatory brain-load (3-5 brain pieces per subagent's specialization)
3. Define tool subset (Read minimal; Edit/Write/Bash if it produces artifacts)
4. Author system prompt body with project framing ("you are operating from root-modules, behave FROM the project not OVER it")
5. **Operator must restart session** for Claude Code to discover the new subagent
6. Update this README's "3 subagents" table
7. Update root README brain-piece counts (subagents count)

## Relationships

- **IMPLEMENTS** [`../rules/self-reference.md`](../rules/self-reference.md) — "behave FROM the project, not OVER it" framing applied at sub-agent layer
- **EXTENDS** [`../rules/trigger-model.md`](../rules/trigger-model.md) — subagent dispatch is one of 8 mechanisms in signal→action→recovery
- **CONSTRAINED BY** SB-081 runtime gap — [`/wiki/governance/systemic-bugs.md`](../../wiki/governance/systemic-bugs.md) — session-restart required for discovery
- **USED BY** parent agent (Claude Code session) via the `Agent` tool with `subagent_type: <name>`
- **PARALLELS** Claude Code's built-in subagents (Explore / general-purpose / Plan / claude-code-guide / statusline-setup) — these custom subagents are domain-specific extensions
- **DERIVED FROM** operator directive 2026-05-05 (SB-081 sub-agents-not-brainless) + 2026-05-06 (brain-improvement mandate)
- Root README — [`/README.md`](../../README.md)

## Cross-references (informal navigation)

Same surface as Relationships above; kept for cold-pickup agents searching for "Cross-references".

### Per-sub-agent reference

| Sub-agent | Tier (model) | Output type | Action vocabulary (M-E001-1) |
|---|---|---|---|
| [`root-explorer`](root-explorer.md) | sonnet | findings + sourced citations | `read-only-audit` |
| [`root-architect`](root-architect.md) | opus | design notes (Question/Constraints/Options/Recommendation/Trade-offs) | `new-artifact` (consumed) OR `read-only-audit` (analysis-only) |
| [`root-pm-scoper`](root-pm-scoper.md) | sonnet | module/task page drafts OR decision packages OR backlog state views | `new-artifact` OR `blocker-surface` OR `read-only-audit` |

### Sister mechanism comparison

| Mechanism | Persona durability | Brain-load timing | Spawn cost |
|---|---|---|---|
| **Mode** ([`/.claude/modes/`](../modes/)) | Operator-set; durable across turns until cleared | Per-prompt via mode-enforcement.sh + facultative auto-injection | None (state-file-mediated) |
| **Sub-agent** (this subdir) | Cold-context per spawn; lifetime = single delegated task | At spawn (mandatory brain-load before answering) | High (own context budget; opus-tier costs more) |
| **Skill** ([`/.claude/skills/`](../skills/)) | Auto-trigger via description-match; ephemeral | At trigger | Low (just an additional file read) |
| **Command** ([`/.claude/commands/`](../commands/)) | Slash-invoked; 100% deterministic | At invocation (harness executes .md template) | Low |

### Brain-improvement mandate

This sub-agent category was authored by SB-081 closure and refined per the 2026-05-06 brain-improvement mandate. Sub-READMEs canonical-extension list per [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md).

### Action emission per Hard Rule 14

When a sub-agent's output is consumed by a parent's `/cycle` fire, the parent's cycle-report last-line `Productive output: <type> — <one-line specific>` MAY cite the sub-agent's contribution (e.g., `Productive output: new-artifact — root-pm-scoper drafted M-N-NN module page; parent applied per operator approval`). See [`wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`](../../wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) for the canonical 9-type vocabulary.
