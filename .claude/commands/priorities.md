# /priorities

Manage active-priorities imminent-work queue (`$HOME/.claude/active-priorities`). Top-priorities = items that take precedence over PM-decision-tier work (real blockers / Epic-pending / behavioral). Operator-authored hot-list. Surfaces in mode-enforcement banner + stamp + (when wired) statusline.

Usage from operator: `/priorities <verb> [args]`

Verbs:
- `add <text>`            → append at lowest priority
- `show`                  → display numbered list (P1, P2, ...)
- `clear`                 → empty the list
- `remove <N>`            → drop priority N (1-based)
- `promote <N>`           → move priority N up one rank
- `demote <N>`            → move priority N down one rank
- `set <text>`            → replace entire list (semicolon-separated for multi)
- `insert <N> <text>`     → insert at position N, shifting rest down (SB-130)
- `update <N> <text>`     → replace text at position N without touching others (SB-130)

Dispatch on `$ARGUMENTS`:

If `$ARGUMENTS` starts with `add `       → run `python3 -m tools.priorities add $REMAINING`
If `$ARGUMENTS` is `show` or empty       → run `python3 -m tools.priorities show`
If `$ARGUMENTS` is `clear`               → run `python3 -m tools.priorities clear`
If `$ARGUMENTS` starts with `remove `    → run `python3 -m tools.priorities remove $N`
If `$ARGUMENTS` starts with `promote `   → run `python3 -m tools.priorities promote $N`
If `$ARGUMENTS` starts with `demote `    → run `python3 -m tools.priorities demote $N`
If `$ARGUMENTS` starts with `set `       → run `python3 -m tools.priorities set $REMAINING`

Then report tool stdout to operator. Brief — one line per priority.
