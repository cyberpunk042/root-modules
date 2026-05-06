---
description: Forced knowledge-extraction PASS into smart documents + handoff. Different from /handoff (snapshot only) and /terminate (status update sweep) — this command forces lessons/patterns/decisions/super-models capture into the wiki BEFORE any handoff. Operator: "do exactly what is asked without question like a command allow."
argument-hint: (none)
---

# /finish-smoothly — knowledge-extraction-first session close

Operator-invoked when ending a session where REAL KNOWLEDGE was produced and must NOT be lost. Unlike `/handoff` (snapshot only) and `/terminate` (status update sweep), this command FORCES the agent to extract lessons / patterns / decisions / super-model awareness into smart wiki documents BEFORE writing the handoff.

> Operator directive 2026-05-06 verbatim: *"a /finish-smoothly that would not aim to just drop a handoff but really be forced first to extract knowledges into smart documents / artifacts. to rmember the super-models and the important modesl to follow and to do exactly what is asked without question like a command allow."*

The phrase "command allow" = operator's explicit instruction to execute without debate. This command is OPERATOR-ALLOWED — agent runs the extraction sweep deterministically. NO asking "should I extract X?" or "is it worth it?" — extract everything that surfaced.

## Distinction from existing commands

| Command | What it does | When |
|---|---|---|
| `/handoff` | Snapshot doc only | Quick state capture mid-loop |
| `/terminate` | Status/progress/role update sweep + handoff | Session ending; operator wants comprehensive state |
| `/finish-smoothly` | **Forced knowledge extraction into wiki** + handoff | Session ending AND knowledge produced; capture-or-lose moment |

## Steps when operator invokes `/finish-smoothly`

The extraction is NOT optional. Each step writes to the wiki even if the content seems thin.

### Step 1 — Lessons learned (forced)

Scan this session for FAILURES (operator-corrections, agent-mistakes, dead-ends taken) and SUCCESSES (patterns that worked, frameworks that landed). For each:
- Author/append a draft lesson at `$HOME/wiki/lessons/01_drafts/<date>-<slug>.md` per the lesson schema (frontmatter: type=lesson, status=draft, confidence, sources, tags)
- One lesson per discrete pattern observed
- Operator-verbatim quotes preserved sacrosanct

If genuinely nothing surfaced: write a meta-lesson "session yielded no new lessons; capture rationale why" — NEVER skip the step.

### Step 2 — Patterns captured (forced)

Identify any reusable patterns (architectural shapes, hook patterns, testing patterns, prompt patterns) emerging from this session. For each:
- Author at `$HOME/wiki/patterns/01_drafts/<slug>.md` (or `<second-brain>/wiki/patterns/01_drafts/` if cross-project)
- Reference the lessons that led to the pattern
- Mark maturity=seed (only operator confirms growing/mature/canonical later)

### Step 3 — Decisions registered (forced)

For every decision made this session (operator-confirmed choices, architectural picks, scope changes, open-question resolutions):
- `python3 -m tools.decisions append --title "..." --rationale "..." --reversibility partial|locked|fully-reversible`
- Include the operator's exact words that made it a decision (sacrosanct)
- If none: state "no new decisions this session" in the handoff (rare — most sessions produce at least one)

### Step 4 — Super-model + important-models awareness

Per operator: *"to remember the super-models and the important models to follow"*. Document any new knowledge gained about:
- The 16 named methodology models (per `<second-brain>/wiki/spine/references/model-registry.md`)
- The 4 governing principles (P1/P2/P3/P4)
- The super-model (`<second-brain>/wiki/spine/super-model/super-model.md`)
- This-project's identity profile + Goldilocks dimensions

Write the awareness summary to the handoff under "Model awareness gained this session". If nothing new: explicitly state "no new model-awareness; existing models remain canonical."

### Step 5 — Sister-project knowledge contribution (when applicable)

If this session produced lessons/patterns relevant to the second brain (cross-project knowledge), prepare a `gateway contribute` payload:
- `python3 -m tools.gateway contribute --type lesson|pattern|remark --title "..." --content "..."` (after M007 lands and connection is real; pre-M007: write the payload to a stub file at `$HOME/wiki/log/<ts>-pending-contribution-*.md` for later)

### Step 6 — Backlog state flips

Any task/module/epic that progressed this session: ensure status field reflects (in-progress → done; not-started → in-progress; etc.). Update readiness fields. Surface ones that should-have-changed-but-didn't for operator confirmation.

### Step 7 — Comprehensive handoff doc

Write `$HOME/wiki/log/<ts>-finish-smoothly-handoff.md` with:
- ALL `/handoff`-shape sections (active mode/task/objective/priorities/cycle/blockers/recent-logs/git-state/recovery-instructions)
- PLUS: list of lessons drafted (step 1)
- PLUS: list of patterns drafted (step 2)
- PLUS: list of decisions appended (step 3)
- PLUS: model awareness summary (step 4)
- PLUS: pending-contributions to second brain (step 5)
- PLUS: backlog flips (step 6)

### Step 8 — Surface to operator

One brief summary message:
- "Knowledge-extraction sweep complete: <N> lessons, <M> patterns, <K> decisions, <Q> backlog flips, <P> pending second-brain contributions."
- Path of the finish-smoothly-handoff doc
- Suggest possible next: "/compact, /terminate, close session, or stand by."

## "Command allow" semantics (operator-instruction-priority mode)

Operator's directive includes *"do exactly what is asked without question like a command allow"*. This means:

- Steps 1–8 execute IN ORDER, without agent-side debate or "is this worth it?" gating
- "Empty" output is acceptable per step (e.g., "no new lessons" is a valid result IF the agent honestly searched + found nothing; not a way to skip)
- Operator-verbatim quotes are SACROSANCT — preserve verbatim per `words-are-sacrosanct.md`
- The agent does NOT ask the operator mid-execution "should I continue with step N?" — runs all 8

## What `/finish-smoothly` is NOT

- Not a `/compact` invocation
- Not a way to discard / skip extraction (the FORCED-pass IS the point)
- Not a substitute for `/handoff` mid-loop (use `/handoff` for snapshots; this is for END-of-session)
- Not a substitute for `/terminate` (use `/terminate` if no significant knowledge; this command is heavier)

## Composition

- After `/finish-smoothly`, operator may invoke `/compact` knowing the wiki absorbed the knowledge first
- Pairs with PreCompact hook: PreCompact captures STATE; `/finish-smoothly` captures KNOWLEDGE — different layers
- For `/loop /cycle` autopilot sessions, `/finish-smoothly` at end captures the cycle's distilled-down learning

## When to invoke

- End of a session that produced new lessons / patterns / architectural insights
- After a substantive iteration arc (multi-cycle work) where knowledge accumulated
- Before close-and-reopen if the session yielded operator-correction-driven lessons
- When the wiki should absorb what was learned, not just recover the state
- Operator wants the AI's session-end work to PROTECT the knowledge from compact-summarization loss
