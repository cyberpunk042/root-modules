---
title: "M-E007-8 — Anti-pollution + quality standards rule (gates M-E007-1 through M-E007-7 — commands earn their place)"
type: module
status: in-progress
priority: P3
parent_epic: "epic-e007-driver-empowerment-and-input-intent-disambiguation"
parent_milestone: "v0.2-ai-natural-task-management"
sfif_stage: foundation
current_stage: document
readiness: 25
created: 2026-05-07
updated: 2026-05-07
tags: [agent-drafted, m-e002-1-create-verb, e007, quality-standards, anti-pollution, gating-module]
---

# M-E007-8 — Anti-pollution + quality standards

> **Agent-DRAFT v1** (per SB-095, operator-revisable). Created 2026-05-07 in autopilot loop fire post-Epic E007 authoring. Promoted from Epic E007's M-E007-8 bullet to scope-doc form. **Strategic placement**: Epic E007's own risk-mitigation (per E007 page Risk + caveats table) requires this module to land BEFORE M-E007-1 commands, so commands earn their place against the standard rather than proliferating.

## Operator-stated seed (sacrosanct)

> *"with the right tools and explained and no polution or low standard of commands and documentation and manuals and also tools I guess"* — 2026-05-07 (Epic E007 founding directive, last clause)

> *"with the proper set of commands and manuals a Driver is well more equiped and the AI too"* — 2026-05-07 (Epic E007 founding directive, prior clause naming the WHY)

## Mission

Author a quality-standards rule that establishes:
1. **When to add a new command** vs extend an existing one (proliferation criterion)
2. **Per-command documentation minimum** (frontmatter fields + body sections required)
3. **Manual quality bar** (when does a command warrant a per-command manual page; when does the index suffice)
4. **Tools quality bar** (when does a CLI tool warrant a top-level `tools/<name>.py` vs sub-module of an existing tool)
5. **Anti-pollution guardrails** (what TRIGGERS rejection of a new command/tool/manual proposal)

The standard becomes the **gating reference** for all future M-E007-1 through M-E007-7 work + retrospective audit of existing 43-44 slash commands + 15 tools + manuals.

## Scope (in-scope vs out-of-scope)

| In-scope | Out-of-scope |
|---|---|
| Authoring `.claude/rules/command-quality-standards.md` (the standard) | Auditing existing 43+ commands for compliance (separate sub-Epic if needed) |
| Cross-reference to second-brain `wiki/spine/standards/` (Concept-Page-Standards, model-standards) | Replacing or duplicating second-brain standards |
| Frontmatter schema requirements per command type | Implementing schema validation tool |
| Manual-vs-no-manual decision criteria | Authoring all per-command manual pages (M-E007-5 scope) |
| Anti-pollution test patterns (e.g. "would this command compose with `/group`?") | Implementing automated pollution-detection tool |
| Operator-driver perspective: "is this command discoverable + intuitive?" | Replacing `routing.md` (routing handles operator-intent → mechanism dispatch; this standard governs WHAT counts as a valid command) |

## Standard sketches (DRAFT v1, agent-flagged per SB-095)

### S1 — When to add a new command (proliferation criterion)

Proposed new command MUST satisfy at LEAST 3 of the following:

1. **Distinct semantic intent** — operationally distinct from any existing command (verb + object pair not represented)
2. **Operator-stated need** — operator literally named a need (sacrosanct quote), or agent-DRAFT proposal accepted by operator
3. **Composes with existing tools** — invocation chains existing `tools.<x>` or composes with other commands via `/group` or `/chain` (M-E007-3 primitives)
4. **Documented use cases** — at least 2 concrete usage scenarios in command's `.md` body
5. **No alias-only justification** — not just a shortcut for an existing command (unless the alias closes a UX gap operator named)

If <3 of 5 satisfied → reject; either extend existing command OR refine proposal.

### S2 — Per-command documentation minimum

Each `.claude/commands/<name>.md` MUST contain:

| Field | Where | Minimum content |
|---|---|---|
| `description` (frontmatter) | YAML | One-line, ≤80 chars, action-verb-led |
| `argument-hint` (frontmatter, where applicable) | YAML | If command takes args: enum or pattern |
| Heading | Body | `# /<command-name>` |
| Mission | Body | One paragraph: WHAT this command does |
| Usage examples | Body | ≥1 concrete operator-typed example |
| Cross-references | Body | "Related: /<other-command>" or "Composes with: tools.<x>" |
| (For sub-feature commands) Companion link | Body | `/stamp-on` ↔ `/stamp-off` pattern |

### S3 — Manual quality bar

A command warrants a per-command manual page (`wiki/manuals/<command>/manual.md` per M-E007-5) when:

1. Operator-driver workflow involves >3 sequential invocations to achieve common goal
2. Command takes 3+ arguments with non-obvious interactions
3. Command composes with other commands in non-obvious ways
4. Command has multiple verbs (`/task` add/show/clear/set; `/questions` 12 verbs; `/priorities` 8 verbs) — these benefit from per-verb examples beyond the index

Otherwise: the index entry in `.claude/commands/README.md` + the command's own `.md` body suffices.

### S4 — Tools quality bar

A new tool at `tools/<name>.py` MUST satisfy at LEAST 3 of the following:

1. **Single Responsibility** — clearly one domain (state / blockers / progress / decisions / etc.)
2. **CLI-composable** — exposes meaningful args / verbs that compose with other tools
3. **Empirical-state-grounded** — reads canonical state file or live system, doesn't fabricate
4. **Test-coverable** — testable without LLM call; deterministic input → deterministic output
5. **Operator-discoverable** — listed in `tools/README.md` + `routing.md` if operator-relevant

If <3 of 5 → extend existing tool as sub-module / new verb instead.

### S5 — Anti-pollution guardrails (rejection triggers)

REJECT a new command / tool / manual proposal if:

| Trigger | Rationale |
|---|---|
| Same semantic verb as existing (e.g. another "show" command for already-shown content) | Use existing |
| Closes a gap that exists ONLY because existing command is poorly documented | Fix the doc instead |
| Adds a parallel invocation path that doesn't compose with `/group` or `/chain` | Doesn't earn its place in compound architecture |
| Manual page that just paraphrases the command's `.md` body | Add to body or skip |
| Tool that operates on data already covered by existing tool | Extend existing |
| New command introduced WITHOUT cross-reference to ≥1 existing command | Orphan; will drift |
| Frontmatter `description` paraphrases the title (zero added information) | Lazy authoring; rewrite |

## Done When (M-E007-8 module-level)

- [ ] Standard rule authored at `.claude/rules/command-quality-standards.md` per S1-S5 sketches above (or operator-revised)
- [ ] Cross-references to second-brain `wiki/spine/standards/` (M007 dependency for full citation)
- [ ] Existing 43-44 slash commands retrospective audit (sample 5-10; document compliance gaps)
- [ ] Existing 15 tools retrospective audit (sample; document compliance gaps)
- [ ] M-E007-1 (commands), M-E007-4 (master manual), M-E007-5 (per-command manuals) gated on this module's rule landing first
- [ ] Operator review of standard + adoption decision (decision logbook entry)
- [ ] Lessons captured at `wiki/lessons/01_drafts/anti-pollution-command-standards.md` for second-brain promotion candidate

## Dependencies

- **Hard**: Epic E007 page (parent — establishes the WHY)
- **Hard**: `.claude/rules/operating-principles.md` (strictness graduation — this standard inherits the tier framework)
- **Soft**: M007 second-brain connect (for cross-referencing `wiki/spine/standards/` Concept-Page-Standards + model-standards)
- **Soft**: `.claude/rules/iterative-evolution-pathway.md` D7 artifact-preparation triggers (this module exemplifies "operator-named quality bar → standards doc" trigger)
- **Composes with**: `.claude/rules/words-are-sacrosanct.md` (operator-stated need is one of S1's 5 criteria)
- **Cousins**: `<second-brain>/wiki/spine/standards/concept-page-standards.md` (paragraph standards inherit this pattern)

## Risk + caveats

| Risk | Mitigation |
|---|---|
| Standard becomes bureaucratic gate that slows legitimate command additions | Standard's own first-pass criterion is "operator-stated need = sufficient"; agent-proposed needs more justification |
| Retrospective audit reveals existing commands fail the standard | Don't auto-deprecate; surface gaps; operator decides per-command (preserve precedent of "small-fixes-OK") |
| New commands authored before this standard lands escape the gate | Sequencing: Epic E007 page explicitly says M-E007-8 lands FIRST. Risk only materializes if this module is bypassed. |
| Standard duplicates second-brain `wiki/spine/standards/` content | Cross-reference, don't duplicate; this standard is project-LOCAL view of universal patterns. |
| Anti-pollution rejection triggers too strict (false-rejects legitimate work) | S5 triggers are guidance-tier; operator can override with explicit acceptance (sacrosanct directive trumps standard) |

## Connects to

- Epic E007 (parent): `wiki/backlog/epics/epic-e007-driver-empowerment-and-input-intent-disambiguation.md`
- Sister modules in E007: M-E007-1 commands taxonomy (gated on this) · M-E007-4 master manual (cites this standard) · M-E007-5 per-command manuals (S3 governs which warrant manuals)
- Cousin Epic E006 module M-E006-8 AIDLC/SDLC/methodology integration synthesis (overlap — both define standards layers)
- `.claude/rules/iterative-evolution-pathway.md` D7 artifact-preparation
- `.claude/rules/operating-principles.md` (strictness graduation tier framework — this standard's S1-S5 are tier-Advisory by default; operator can promote to Strict per command)
- `.claude/commands/README.md` (current 43-44 commands index — retrospective audit target)
- `tools/README.md` (current 15 tools index — retrospective audit target)
- `<second-brain>/wiki/spine/standards/concept-page-standards.md` (canonical quality-bar reference; this module inherits)
