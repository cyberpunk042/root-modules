Write a strong handoff document at `$HOME/wiki/log/<ts>-handoff.md` capturing in-flight state — same format as the auto-PreCompact handoff, but operator-invocable on demand.

> Slash-invoked. Operator types `/handoff` literally. Use cases: before stepping away from the session, before /compact, before session close, before context-restart, or any time the operator wants a deterministic snapshot of where we are.
>
> Writes-only, no operator-confirm gate (it's a snapshot doc, not a state mutation).

## Why this command exists

Per operator directive 2026-05-05 (cycle 41): *"we should have added a hook that should have realize as we get closer to the context limit that we need to prepare for compact and do a strong handoff document and register our knowledge and learnings before we are forced to compact or such... should be ready by that point and keep the handoff up to date as we continue or trigger ourself the compact if logical.. not before the limit for no reason though"*.

The PreCompact hook (`$HOME/.claude/hooks/pre-compact.sh`) auto-fires on compaction. But:
- Agent CAN'T self-trigger compact (Claude Code constraint per claude-code-guide research cycle 41)
- Operator may want to step away BEFORE compaction without being forced into compact
- Operator may want a handoff at any logical break-point

`/handoff` lets the operator capture the snapshot manually whenever they want.

## On `/handoff`

1. **Read in-flight state** (same gathering as pre-compact.sh):
   ```bash
   ts=$(date +"%Y-%m-%d-%H%M%S")
   handoff_path="$HOME/wiki/log/${ts}-handoff.md"
   active_mode=$(cat $HOME/.claude/active-mode 2>/dev/null || echo "(none)")
   active_task=$(cat $HOME/.claude/active-task 2>/dev/null || echo "(none)")
   ```

2. **Run state-collecting tools**:
   ```bash
   <second-brain>/.venv/bin/python -m tools.cycle --json
   <second-brain>/.venv/bin/python -m tools.blockers --json
   ls -t $HOME/wiki/log/*.md | head -5
   git -C /root status --short
   ```

3. **Compose handoff doc** at `$HOME/wiki/log/<ts>-handoff.md`:

   ```markdown
   # Handoff — <timestamp>

   > Operator-triggered via `/handoff`. Snapshot of in-flight state for cold-pickup recovery.

   ## Active mode
   <active-mode>

   ## Active task
   <active-task>

   ## Cycle state (tools.cycle --json)
   ```json
   <cycle output>
   ```

   ## Blockers state (tools.blockers --json)
   ```json
   <blockers output>
   ```

   ## Recent logs (last 5 by mtime)
   <ls -t output>

   ## Git state
   ```
   <git status output>
   ```

   ## What we were doing (free-form, agent fills)

   <Last 1-2 cycle's deliverables, current cursor, what's next>

   ## What the operator asked for (verbatim, last directive)

   <Quote from most recent log file>

   ## Recovery instructions for cold-pickup agent

   1. Run `/orient` to reload brain
   2. Read this handoff to recover in-flight state
   3. Read most-recent $HOME/wiki/log/ entry for last operator directive
   4. ASK operator: "Pre-handoff we were at <task> in <mode>; cycle was at <cycle-N> driving <SB-pick>. Continue or shift?"
   ```

4. **Confirm to operator**: "Handoff written to <path>. Cold-pickup agent can read this after /orient to recover state."

## What `/handoff` is NOT

- Not a /compact replacement (only operator types /compact; agent can't self-trigger)
- Not an automatic save (operator-invoked only; PreCompact hook does the auto-case)
- Not a state mutation (just a snapshot file)
- Not a session-summary (use `$HOME/wiki/log/<date>-cycles-N-M-summary.md` for batch summaries)

## Composition

- With `/orient`: cold-pickup recovery flow is `/orient` (reload brain) + read most-recent handoff (recover in-flight state)
- With `/loop /cycle`: operator can run `/handoff` between cycles to snapshot mid-loop progress
- With pre-compact.sh: same doc shape; PreCompact auto-writes; `/handoff` operator-writes
- With post-compact.sh: post-compact.sh references the most-recent `*-handoff.md` (PreCompact-written OR operator-written) in its additionalContext

## When to invoke

- Before stepping away from an active session
- Before close-and-reopen (e.g., to test new `.claude/agents/` discovery — cycle 47 finding)
- Before context approaches compaction (operator awareness; agent can't see context-%)
- After a substantive batch of work, to capture for audit + future cold-pickup
- When the loop has accumulated several cycles' findings — checkpoint moment
