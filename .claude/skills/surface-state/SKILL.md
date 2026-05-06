---
name: surface-state
description: Use this skill when the user asks about the project's current STATE / position / situation in NATURAL prose (not slash commands). Triggers on phrases like "where are we", "what's the state", "what's the current situation", "give me a status update", "where do we stand", "current position", "how are we doing", "what's our progress". Do NOT trigger on /progress, /orient, or /mode-status (those are explicit slash commands the user already invoked deterministically). Do NOT trigger on questions about specific topics like "where is the install.sh" — that's lookup, not state.
disable-model-invocation: false
---

# Surface state — natural-prose progress query

## When to use

User asked about the project's overall state in natural prose. Examples that should fire this:
- "where are we?"
- "what's the state?"
- "give me a status"
- "current situation"
- "how is it going"
- "where do we stand"

Examples that should NOT fire this (use the slash command directly):
- "/progress" → use `/progress` slash command
- "/orient" → use `/orient` slash command  
- "/mode-status" → use `/mode-status` slash command
- "where is the install.sh" → file lookup, not state
- "what does T011 say" → specific task lookup, not state

## What to do

When triggered:

1. Run `/orient` (deterministic 21-step intel-gathering chain) — this loads the brain + emits the structured ORIENT REPORT.
2. If the user wants more specifically the journey view (where + headed + how got here), follow up by reading `/root/wiki/governance/progress.md` (or invoking `/progress` slash command).
3. If active mode is set (per `/orient` step 19-21), reflect that in the response — "you're in PM Scrum Master mode; here's the cycle's view of state."
4. End the response with a one-line "what's next" that's grounded in the 6 pending operator decisions OR the active mode's cycle-next-action — NOT a generic "what would you like to work on?" question.

## Discipline

- Don't fabricate state. Run the tools.
- Don't ask "what specifically did you mean?" — the user said "where are we"; the answer is a project state report.
- Don't repeat content the user can read in BOOTSTRAP.md — answer the question.
- The tools needed are already invoked by `/orient` — don't redo the chain manually.

## Composition

This skill primarily INVOKES `/orient` then layers the prose-friendly answer on top. The slash command is the deterministic load; this skill is the natural-language shim.
