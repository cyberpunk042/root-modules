Surface the blockers register — items requiring operator input, with full context.

> Slash-invoked. Operator types `/blockers` literally. Read-only — does not modify state.

## On `/blockers`

1. Read `$HOME/wiki/governance/blockers.md` in full.
2. Re-verify the blocker count is current — check active modules / pending-operator-decision tasks against the register; flag any drift.
3. Present the register to the operator:
   - Group by priority (P0 / P1 / P2)
   - For each: ID, title, why-it-blocks, what-the-decision-is, options, affected items
   - Don't paraphrase the context — present what's in `blockers.md` faithfully
   - End with: count + which one most needs attention next (judgment call based on priority + downstream blockage)
4. Stand by for operator's decision. Do NOT decide for them.

## When `/blockers` is most useful

- Start of a session if no `/cycle` has run yet
- After resolving a blocker (re-render to see the updated state)
- When the operator asks "what's pending" or similar prose (don't auto-invoke from prose; the explicit `/blockers` is the trigger)
- Within `/cycle` if the active mode is `pm-scrum-master` or `dual-expert`

## What `/blockers` is NOT

- Not a task-claiming workflow (use `/cycle` per active mode)
- Not a decision-applier (operator decides; agent applies after operator's explicit decision)
- Not a progress report (use `/progress` for that)
- Not a decisions audit trail (use `/decisions` for that)

## Operations on the blocker register (when operator wants to mutate)

Per operator directive 2026-05-05, `tools.blockers` exposes operations beyond reading:

```bash
cd /root
python3 -m tools.blockers list                              # IDs only
python3 -m tools.blockers get B001                          # full body
python3 -m tools.blockers next-id                           # next B###
python3 -m tools.blockers add --title ... --priority P0 \\
    --why ... --context ... --decision ... --affects ...    # append a new B###
python3 -m tools.blockers update B001 --status resolved     # mutate fields
python3 -m tools.blockers resolve B001 \\
    --decision-id D019 --resolution "..."                   # mark resolved
```

Operations write to `wiki/governance/blockers.md`. After resolving, ALSO append the corresponding D### entry via `tools.decisions append --linked-blocker B001 ...` (different SRP per the governance design).

When operator says: "log a new blocker that ..." or "update B001's status" or "resolve B003 — operator picked X" — agent invokes the appropriate `tools.blockers` subcommand.
