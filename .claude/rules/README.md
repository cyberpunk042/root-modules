---
title: ".claude/rules/ — root-modules on-demand topic rules"
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
  - id: operating-principles-strictness-graduation
    type: rule
    file: operating-principles.md
tags: [readme, rules, agent-authored, draft]
---

# `.claude/rules/` — on-demand topic rules

> **DRAFT v1 — agent-authored 2026-05-06** per SB-095. Operator may revise / promote / replace.

## Summary

Indexes the 11 rule files in `$HOME/.claude/rules/` with strictness tier (advisory / enforced / strict / deterministic) + when-loaded matrix (auto / pre / on-demand / facultative per `context-engineering.md`). Rules are **on-demand-loaded by topic** — CLAUDE.md auto-loads on session start; topic-specific rules load when that topic surfaces. This pattern keeps total context budget bounded (11 rules × 200-300 lines each is too much to auto-load every session). Each rule declares its strictness tier explicitly so agents know whether the rule informs judgment (advisory) or must hold (strict). Rules cross-cut commands / hooks / modes / tools / brain files — they are the project's discipline layer.

## The 11 rules — strictness tier + when-loaded

Strictness tiers per [`operating-principles.md`](operating-principles.md) §3:
- **Aspirational** — target; not yet achievable
- **Advisory** — informs judgment; agent applies discretion
- **Enforced** — hook/verifier catches violations; auto-blocks or auto-corrects
- **Deterministic** — encoded in script; same input → same output
- **Strict** — always must hold; violation is a project-level issue

| Rule | Strictness | When loaded | One-line summary |
|---|---|---|---|
| **[`compound-and-waterfall.md`](compound-and-waterfall.md)** | Advisory | Designing layered context / event-flow | Two orthogonal axes: compound (additive layers at-a-moment) + waterfall (state flows event-to-event); failure modes (collide / truncation); SB-123 closure |
| **[`context-engineering.md`](context-engineering.md)** | Advisory | Designing how an agent gets context | Four orthogonal injection modes: auto / pre / on-demand / facultative; matches content-criticality to mode-reliability |
| **[`hook-architecture.md`](hook-architecture.md)** | Strict (2-layer invariant) + Enforced (3-component pattern) + Advisory (status notes) | Designing or debugging a hook | 2-layer architecture (machine-level fires before project-level) + 3-component design pattern (insertion + reason + remediation) + bypass mechanism per hook |
| **[`loop-cron-lifecycle.md`](loop-cron-lifecycle.md)** | Advisory (autonomous-cancellation permission) + Enforced (refined triggers) | When a loop/cron is firing AND agent considers cancellation/modification | The hard ruling: agent may autonomously cancel/update only when scenario applies + currently true + mode supports it + action logged + reported to operator |
| **[`methodology.md`](methodology.md)** | Strict (stage gates) + Advisory (model selection) | When stage or model selection comes up | 5 universal stages (document → design → scaffold → implement → test) + 9 methodology models + ALLOWED/FORBIDDEN per stage |
| **[`operating-principles.md`](operating-principles.md)** | Strict (the 4 core principles) + Advisory (extension principles) | When making a judgment call about strictness / flexibility / safety | The 4 core principles + 14 extension principles (research-first, comments-don't-deroute, preliminary-only, empirical-verification, $HOME scope, don't-freeze, going-to-extremes, sacrosanct-words, iteration-circuit-breaker, no-hallucinated-artifacts, abdication-as-freeze, evidence-priority hierarchy, ...) |
| **[`routing.md`](routing.md)** | Advisory | When operator intent is ambiguous | Operator-intent → tool routing table (24 rows) + mechanism selection (commands vs hooks vs MCP vs CLI) |
| **[`self-reference.md`](self-reference.md)** | Strict ($HOME vs /opt distinction) | When agent needs to understand project identity + relationship to second brain | What this project IS (system AI safety setup IaC) + bidirectional inheritance ($HOME source-of-truth for operational tooling; /opt second brain inherits) |
| **[`trigger-model.md`](trigger-model.md)** | Advisory | Designing or debugging anything that fires on a signal (hooks, commands, skills, modes, tools, MCP, scheduled tasks) | Unified signal→action→recovery composition; 8 mechanisms × 3 signal-source categories × 3 action-determinism tiers |
| **[`words-are-sacrosanct.md`](words-are-sacrosanct.md)** | Strict (verbatim quoting) | EVERY message — operator words are sacrosanct | Quote operator verbatim; never paraphrase/dilute/summarize; conflation forbidden; premise-confirmation gate (SB-090); conditional-clause grammar (SB-120) |
| **[`work-mode.md`](work-mode.md)** | Strict (PO approval boundary) + Advisory (output discipline) | Solo session pattern + behavioral discipline | Default operation mode; sacrosanct verbatim quoting; additive-not-destructive; output discipline under pressure (SB-094); behavioral rules; PO approval boundary; status-claim verification |

## How rules compose with other layers

| Layer | Where the rule applies |
|---|---|
| **Hooks** (`/.claude/hooks/`) | `hook-architecture.md` defines the design pattern — 3-component invariant; bypass mechanism per hook |
| **Commands** (`/.claude/commands/`) | `routing.md` defines operator-intent → command mapping; `methodology.md` defines stage-gate awareness |
| **Modes** (`/.claude/modes/`) | `loop-cron-lifecycle.md` defines mode-dependent autonomous-cancellation gating |
| **Tools** (`/tools/`) | `methodology.md` ALLOWED/FORBIDDEN per stage gates what tools can produce |
| **Brain files** (CLAUDE.md, AGENTS.md, etc.) | `self-reference.md` defines what this project IS + how it relates to /opt; `context-engineering.md` defines auto/pre/on-demand/facultative injection per content-type |
| **State files** (`active-mode`, `active-priorities`, etc.) | `compound-and-waterfall.md` defines compound axis (state files compound into each banner) + waterfall axis (state survives compaction) |

## Loading discipline — auto vs on-demand

| Loading mode | Where used | Examples |
|---|---|---|
| **Auto-loaded** | CLAUDE.md (project-level auto-load) + AGENTS.md | Hard rules, identity, routing summary |
| **On-demand by topic** | THIS subdir | Per-rule when topic comes up (designed for context-economy) |
| **Pre-loaded** (deterministic) | `/orient` 21-step chain | Brain pieces deterministically loaded each session |
| **Facultative** | Mode-specific brain pieces | Loaded only when active-mode is set |

The on-demand pattern (this subdir) keeps total context budget bounded — 11 rules × ~200-300 lines each = too much to auto-load every session. Topic-loading reaches the right rule when the topic surfaces.

## Rule-design conventions

Every rule file in this subdir follows:

1. **Frontmatter**: title + on-demand-load trigger ("Loaded on demand when X comes up")
2. **Strictness tier**: declared explicitly (per `operating-principles.md` §3)
3. **Operator-verbatim quotes** when the rule originates from operator directive — sacrosanct, preserved
4. **Cross-references** at bottom — to canonical sources in /opt second brain + sister rules in $HOME
5. **Anti-patterns table** when applicable — what NOT to do, with evidence

## Extending — adding a new rule

When you author a new rule:

1. Place at `.claude/rules/<topic>.md`
2. Frontmatter declares load trigger
3. Strictness tier explicit
4. Cross-reference from CLAUDE.md routing if the rule changes operator-intent dispatch
5. Cross-reference from `routing.md` if it adds a new mechanism
6. Update this README's "11 rules" table
7. Update root README brain-piece counts (rules count)

## Anti-patterns (do not do)

- **Auto-load every rule** — context budget bloats; agent confuses; cache misses; cost increases
- **Replace existing rule wholesale** — additive ≠ destructive; layer new content on prior content
- **Author rule without strictness-tier declaration** — operator-empirical of "is this advisory or strict?" is part of the rule
- **Cross-reference only one direction** — bidirectional cross-references (this rule ← → that rule) catch drift

## Relationships

- **CONSTRAINS** [`../commands/README.md`](../commands/README.md) + [`../hooks/README.md`](../hooks/README.md) + [`../modes/README.md`](../modes/README.md) + [`../../tools/README.md`](../../tools/README.md) — rules govern how all other layers operate
- **DERIVED FROM** operator directives across 2026-04-24 / 2026-05-04 / 2026-05-05 / 2026-05-06 sessions (sacrosanct verbatim quotes preserved per-rule)
- **EXTENDS** [CLAUDE.md](../../CLAUDE.md) — auto-loaded brain hot-path; rules are on-demand depth
- **PARALLELS** [`<second-brain>/.claude/rules/`](../../README.md#sister-project-of-the-research-wiki-second-brain) — sister projects have parallel rule patterns; canonical lives at second brain
- **USES** [operating-principles.md](operating-principles.md) — strictness graduation defines per-rule tier
- Root README — [`/README.md`](../../README.md)

## Cross-references (informal navigation)

Same surface as Relationships above; kept for cold-pickup agents searching for "Cross-references".
