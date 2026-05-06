---
description: Manage the active-task cursor — show current, set to a different task ID (validates against backlog), clear. State persists at $HOME/.claude/active-task; consumed by /handoff + pre-compact.sh handoff doc.
argument-hint: [show | set <T###> | clear]
---

# /task — manage the active-task cursor

State file: `$HOME/.claude/active-task` (one task ID, e.g. `T012`).

The active-task layer is the **backlog cursor** — distinct from mission/focus/impediment (objective layer per SB-118) and priorities (imminent-work tier per SB-127). It tracks "which backlog task am I executing right now". `/handoff` and the PreCompact hook both read it to preserve cursor across compaction.

## Behavior by argument

| Argument | Action |
|---|---|
| (no args) or `show` | Print the current active task ID + drill-down (status, priority, module, stage, readiness, Done When count, BLOCKED BY). |
| `set <T###>` | Set active task to the given ID. Refuses if the ID is not present in `$HOME/wiki/backlog/tasks/`. |
| `clear` | Empty the state file. |

## Steps

Run the dispatch:

```bash
ARG="$ARGUMENTS"
case "$ARG" in
  ""|"show") /opt/devops-solutions-information-hub/.venv/bin/python -m tools.tasks active show ;;
  "clear")   /opt/devops-solutions-information-hub/.venv/bin/python -m tools.tasks active clear ;;
  set\ *)    /opt/devops-solutions-information-hub/.venv/bin/python -m tools.tasks active ${ARG} ;;
  *)         echo "usage: /task [show | set <T###> | clear]"; exit 2 ;;
esac
```

Then briefly confirm to the operator what was done.

## Composition

- After `/task set T###`, the next `/handoff` and any PreCompact-hook fire will preserve the new cursor in their handoff docs.
- `/task show` complements `/orient` (which lists pending decisions) by showing the currently-claimed work.
- For backlog drill-down beyond the current cursor: `tools.tasks list / get / claimable` (no slash command needed — those are read-only queries).

## When to invoke

- Before starting work on a different task than the one currently shown.
- After completing a task, to clear or advance the cursor.
- During orient/handoff sweeps to verify the cursor still reflects reality.

## Cross-references

- `tools/tasks.py` `active` subcommand (the backing logic)
- `$HOME/.claude/commands/handoff.md` (reads active-task into handoff doc)
- `$HOME/.claude/hooks/pre-compact.sh` (reads active-task for pre-compact snapshot)
- `$HOME/.claude/commands/mission.md` / `focus.md` / `impediment.md` (objective layer — per-cycle/multi-cycle objectives, NOT the same as the backlog cursor)
- `$HOME/.claude/commands/priorities.md` (imminent-work tier — operator's hot-queue, NOT the backlog cursor)
- SB-124d audit (commands-at-all-levels): every logical state file should have a slash command equivalent.
