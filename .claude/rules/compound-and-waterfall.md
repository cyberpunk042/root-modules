# $HOME/.claude/rules/compound-and-waterfall.md — Compound + waterfall: two orthogonal axes for layering and cascading context

> Loaded on demand when designing how state, context, hooks, or directives layer or flow. Per operator directive 2026-05-06: *"This also make me think of the compound and waterfall strategy I talked about once and how it propably fit into hooks and directives and brains files too... I dont mind using more SRP file or updating some or updating and evoluing the current configs and project... it should be compounding."*
>
> **Strictness tier** (per `operating-principles.md`): **Advisory** — informs design judgment for new hooks, state files, brain pieces, render surfaces. Pairs with `trigger-model.md` (signal→action→recovery composition) and `context-engineering.md` (auto/pre/on-demand/facultative injection modes).
>
> **DRAFT v1 (SB-129, 2026-05-06)** per `<second-brain>/wiki/spine/standards/concept-page-standards.md`. Required sections: Summary + Key Insights + Deep Analysis (subsectioned).

## Summary

Compound and waterfall are two orthogonal design axes that shape how the agent's context and behavior come together. **Compound** governs WHAT additively coexists at-a-moment (mode + priorities + mission + focus + impediment + live state visible simultaneously); **waterfall** governs HOW state flows event-to-event (SessionStart → UserPromptSubmit hooks → Stop → PreCompact → PostCompact → /orient). Holding both axes prevents two distinct failure modes: collide (layers replacing instead of stacking) and truncation (earlier state lost downstream).

## Key Insights

1. **Compound and waterfall are orthogonal — both must hold.** A system can compound well but waterfall badly (banner stacks layers but state doesn't survive compaction), or waterfall well but compound poorly (events flow correctly but only one piece visible at a time). Holding both is the design bar.

2. **Compound failure-mode = collide (SB-121).** When layers replace instead of stack — operator-typed message + cron-fire prompt arrive together; agent treats one as primary while ignoring the other. Fix: layers always-render even when empty (SB-082 lesson); each layer has its own additionalContext field; never one-or-another framing.

3. **Waterfall failure-mode = truncation.** Earlier-stage state lost downstream when compaction destroys conversation content. Fix: state in files (`active-mode`, `active-priorities`, tracker, decisions, handoff doc) so post-compact recovery via /orient can reconstruct.

4. **Structure beats content for layer durability.** YAML files / typed fields / declared sections survive compaction; prose corrections don't. Per second-brain Context Engineering Standards: prose=25%, structured tables=60%, hooks=100% compliance for the same rule.

5. **Operator's "should be compounding" is the design principle.** Each layer ADDS to operator-visible context; later layers DO NOT REPLACE earlier ones. Banner shows persona + cycle + priorities + mission + focus + impediment + live state simultaneously.

## Deep Analysis

### The two axes

Two orthogonal design axes shape how the agent's context and behavior come together:

| Axis | What it answers | Failure mode | Example |
|---|---|---|---|
| **Compound** | What layers ADDITIVELY coexist at any given moment? | **Collide** — layers replace instead of stack (SB-121) | Mode + Mission + Focus + Impediment all visible at once in mode-enforcement banner |
| **Waterfall** | How does context flow SEQUENTIALLY through events? | **Truncation** — earlier-stage state is lost downstream | SessionStart → /orient → mode-enforcement per-prompt → /cycle fires → end-of-cycle-stamp → PreCompact → handoff doc → PostCompact → /orient again |

The two are independent: a system can compound well but waterfall badly (state files compose visually, but cycle steps lose state across firings); or waterfall well but compound poorly (each stage is well-defined but only one piece visible at a time).

Good design holds both.

### Compound — what stacks at any moment

The COMPOUND axis answers "what is in operator's view RIGHT NOW".

| Layer | Source | When loaded | Tier | Example value |
|---|---|---|---|---|
| Mode | `$HOME/.claude/active-mode` | SessionStart + per-prompt (mode-enforcement) | persona | `dual-expert` |
| **Priorities** | `$HOME/.claude/active-priorities` | per-prompt + stamp | imminent-work (above PM) | `P1: compound+waterfall coherence` |
| Mission | `$HOME/.claude/active-mission` | per-prompt + stamp | strategic objective | `ship root-ghostproxy MVP — close systemic-bug audit` |
| Focus | `$HOME/.claude/active-focus` | per-prompt + stamp | sub-objective | `iterate hooks/context/engineering quality` |
| Impediment | `$HOME/.claude/active-impediment` | per-prompt + stamp | block on focus | `(none — focus unblocked)` OR specific block |
| Live state | tracker + progress.md | per-prompt (mode-enforcement) | observability | `open SBs: SB-049, SB-105, ...` |
| Mindfulness | `mindfulness.sh` | per-prompt | discipline baseline | 4-clause reminder (SB-126) |
| Persona/cycle | mode-file dynamic parse | per-prompt | persona detail | from `$HOME/.claude/modes/<mode>.md` |
| Per-tool budget | `context-warning.sh` | strategic thresholds | resource tier | % remaining + abs tokens (per SB-119 future) |
| Stamp | `end-of-cycle-stamp.sh` | end-of-turn | full snapshot | Status / Journey / Plan / Priorities / Tracker / Progress / Cursor / Mission / Focus / Impediment |

The order in mode-enforcement banner + stamp render reflects the tier hierarchy: persona (mode) → imminent (priorities) → strategic (mission) → sub-objective (focus) → block (impediment) → observability (live state). Tighter granularity at the top, broader context below.

**Compound principle**: each layer ADDS to operator-visible context; later layers DO NOT REPLACE earlier ones. Banner shows persona + cycle + mission + focus + impediment + live state simultaneously, not one-OR-another.

**Compound failure mode** (SB-121): cron-fire prompt + operator-typed message land in the same turn. Agent treats the second as REPLACING the first, missing that they should COMPOUND (operator-text = primary directive + cron-text = ambient driving-context).

### Waterfall — how context flows event-to-event

The WATERFALL axis answers "where does state come from in the next event".

```
SessionStart hook (session-orient.sh)
  → emits additionalContext directing /orient invocation
    → /orient deterministic 21-step chain runs
      → loads brain pieces + tracker + recent logs + git state
        → emits structured intel report
          → operator engages OR cron fires

UserPromptSubmit (per turn — fires on each operator message AND cron-fire)
  → context-warning.sh (% remaining)
    → output-discipline-guard.sh (premise/escalation detection — high-confidence-only)
      → mode-enforcement.sh (mode + objective + live state)
        → mindfulness.sh (baseline 4-clause reminder)
          → agent processes turn

PreCompact event (context-budget exceeded)
  → pre-compact.sh writes deterministic handoff doc to wiki/log/<ts>-handoff.md
    → compaction collapses prior conversation
      → PostCompact: post-compact.sh emits additionalContext directing /orient + reads recent handoff
        → state recovers via deterministic chain

Stop event (end of turn)
  → end-of-cycle-stamp.sh emits systemMessage stamp
    → stamp surfaces Status/Journey/Plan/Blocked/Progress/Cursor + Mission/Focus/Impediment

SessionEnd
  → session-summary.sh prints summary
```

**Waterfall principle**: each event hands off state to the next via a defined channel (additionalContext / systemMessage / handoff doc / state files). State is durable across cron-fires + compactions because it lives in files (state files + wiki/log/ + tracker) — not just in conversation context.

**Waterfall failure mode** (SB-079/081): PostCompact reliability and sub-agent brain-load — when state-recovery channel breaks, downstream events operate on incomplete context. Tracked separately.

### How they combine

```
                        compound axis (what layers AT THIS MOMENT)
                              ↑
                 mindfulness  ─┤
                 mode-enforce ─┤
                 mission      ─┤
                 focus        ─┤
                 impediment   ─┤
                 live state   ─┤
                              └──────────────────────────────── waterfall axis
                                  (how it flows event-to-event)
                              SessionStart → /orient → UserPromptSubmit (compounds N hooks) → ... → Stop → PreCompact → PostCompact → /orient → ...
```

Every per-prompt event compounds N additionalContext fields (vertical axis), then waterfalls into the next event (horizontal axis).

## Design implications for new mechanisms

When adding a new hook / state file / slash command / brain piece, ask:

| Compound check | Waterfall check |
|---|---|
| Does it ADD to operator's view at the moment it fires? Or does it REPLACE? Replace = bug. | Does it persist state to a durable location (file, tracker) so downstream events can recover it? Or does it live only in conversation? |
| Does it compose with other layers visible at the same moment? Or contradict them? | Does it gracefully handle the prior event being incomplete (PreCompact-then-PostCompact)? |
| Is its render-surface always-rendered (operator-visibility) even when empty? Or conditionally-dropped? Conditional = visibility bug (SB-082 pendulum recurrence pattern). | Does the next event know how to find its output? Or is the output ephemeral? |

## Anti-patterns (closes recurring failure modes)

| Anti-pattern | Failure | Cousin SB |
|---|---|---|
| Treat operator-comment as redirection instead of context-additive | Compound layer collapses; agent abandons prior work | SB-121 collide-not-compound |
| Truncate operator-explicit content under "context-budget courtesy" | Compound layer truncated mid-render | SB-122 |
| Conditionally drop a render row when value empty (e.g., impediment hidden when unset) | Operator can't see the layer state; reads as "missing", not "empty" | SB-082 pendulum (where "shorter" → "removed") |
| State only in conversation, not in file | Waterfall breaks at PreCompact; downstream events lose state | SB-078 (closed by handoff doc), SB-079 |
| Hook fires regardless of mode (when it should be mode-bound) | Compound noise when mode-context not relevant | SB-088 cross-fire-suppress |
| Hook only fires under-pressure (when steady baseline needed) | Waterfall has gaps between trigger conditions | SB-126 mindfulness baseline (closed) |

## Compounding as discipline

Operator's affirmation 2026-05-06: *"it should be compounding"*. This is the design principle behind:

- mode-enforcement banner showing mode + persona + cycle + **priorities** + mission + focus + impediment + live state SIMULTANEOUSLY (not one section per fire)
- Stamp showing 6 ambient rows (Status/Journey/Plan/Tracker/Progress/Cursor) PLUS imminent-work row (Priorities) PLUS 3 objective rows (Mission/Focus/Impediment) — additive, not selective
- 4 UserPromptSubmit hooks emitting separate additionalContext fields (context-warning + output-discipline-guard + mode-enforcement + mindfulness, not competing for one channel)
- Tracker accumulating SBs over time + decisions logbook accumulating D-entries — compound history
- Provenance-tagging within compound layers (operator-stated vs agent-raised) preserves the WHO-said-what dimension across compound entries (closes SB-095 recurrence pattern)

Compounding is the structural answer to *"never lose track or forget to deliver anything within a focus and/or a task"* — every layer remains visible/accessible; nothing falls out as new things land.

## Cross-references

- `trigger-model.md` — signal→action→recovery composition (the mechanism axis: hooks, commands, skills, modes, tools, scheduled tasks)
- `context-engineering.md` — auto/pre/on-demand/facultative context-injection modes (the timing axis)
- `hook-architecture.md` — 14-hook lifecycle (the waterfall topology)
- `loop-cron-lifecycle.md` — when self-paced loops cancel/update (compound + waterfall both hold across cron-fires)
- `operating-principles.md` principle #11 — systemic-fix priority within the loop (the loop is itself a compound discipline)
- `words-are-sacrosanct.md` — premise-confirmation gate (operator-words are the seed of compound layers; never displaced by agent-construction)

## Operator-verbatim primary source

- 2026-05-06 (this rule's seed): *"This also make me think of the compound and waterfall strategy I talked about once and how it propably fit into hooks and directives and brains files too..."* + *"it should be compounding"*
- Cousin: 2026-05-06 *"clearly register this and consider it greatly"*
