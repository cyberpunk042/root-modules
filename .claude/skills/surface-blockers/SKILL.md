---
name: surface-blockers
description: Use this skill when the user asks about pending decisions, blockers, or what needs THEIR input in NATURAL prose (not slash commands). Triggers on phrases like "what's blocking us", "what needs my input", "what decisions are pending", "what do you need from me", "what am I gating", "what's stuck waiting on me", "what should I decide next". Do NOT trigger on /blockers (operator already invoked deterministically). Do NOT trigger on questions about specific tasks like "what is T011" — that's a task-page lookup. Do NOT trigger on "what's blocking T032" type queries — that's a dependency lookup, not the operator-input register.
disable-model-invocation: false
---

# Surface blockers — natural-prose pending-decisions query

## When to use

User asked about what needs their input / what's blocking forward motion / what's waiting on them. Examples that should fire this:
- "what's blocking us?"
- "what needs my input"
- "what do you need from me"
- "what am I gating right now"
- "what should I decide next"
- "what's stuck waiting on me"
- "give me the pending list"

Examples that should NOT fire this:
- "/blockers" → use the slash command directly (more deterministic)
- "what is T011" → task-page Read
- "what's blocking T032" → dependency lookup (different scope)
- "what's blocking the deploy" → not a /root governance question

## What to do

When triggered:

1. Run `/blockers` (reads `/root/wiki/governance/blockers.md` + cross-checks live state via `python3 -m tools.blockers`).
2. Present the active blockers in priority order (P0 first; P0 unblocks the active SFIF stage; P1/P2 unblock specific paths).
3. For each blocker, surface ENOUGH context that the operator can answer without needing follow-up clarification:
   - The decision being asked
   - The clear options available (with implications per option)
   - What it affects (downstream tasks/modules)
4. End with a one-line recommendation on which one to address NEXT (judgment call based on priority + downstream blockage), but explicitly leave the decision to the operator.
5. Do NOT decide for the operator. Per `.claude/rules/words-are-sacrosanct.md`: a question is not a decision.

## Discipline

- Per operator's verbatim concern (2026-05-05): "I dont receive dumb questions too" — surface the blocker WITH FULL CONTEXT. The operator should be able to answer from the surface alone, not need to read 3 task pages first.
- Don't paraphrase the blocker's substance — quote what's in `blockers.md` faithfully.
- Don't stop at "there are 6 pending decisions" — surface AT LEAST the highest-priority 1-2 in detail, with options.

## Composition

This skill primarily INVOKES `/blockers`. The slash command is the deterministic surface; this skill is the natural-language shim that handles when the operator phrases the request as prose.
