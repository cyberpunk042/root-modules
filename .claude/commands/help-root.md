Show all 26 root-ghostproxy slash commands with one-line description + when-to-use.

> Slash-invoked. Operator types `/help-root` literally. Read-only. Distinct from Claude Code's built-in `/help` (which lists harness-level commands).

## On `/help-root`

Print the table below faithfully. Don't paraphrase. Operator uses this for command discovery and onboarding.

```
═════════════════════════════════════════════════════════════════════════
ROOT-GHOSTPROXY — SLASH COMMAND CHEATSHEET
═════════════════════════════════════════════════════════════════════════

ORIENTATION + STATE (use first in any new session):
  /orient            Deterministic 21-step intel-gathering chain. Reads brain
                     + verifies state + detects mode + emits ORIENT REPORT.
                     Run on first turn of every fresh session (the SessionStart
                     hook directs the agent to this automatically).

GOVERNANCE (read-only views):
  /blockers          Surface the operator-input register from
                     wiki/governance/blockers.md (B001-B006 active +
                     F-items future).
  /progress          Show current SFIF stage + journey + path traveled
                     (wiki/governance/progress.md).
  /decisions         Audit trail of decisions made (wiki/governance/decisions.md).
                     Supports `/decisions append <decision>` to record.

MODES (operator-choice persona overlay; combine with /loop /cycle for autopilot):
  /mode-pm           Enable PM Scrum Master mode (backlog + decisions + status).
  /mode-architect    Enable DevOps Software Engineer & Architect mode
                     (design + IaC + hooks + vendor manifests).
  /mode-dual         Enable Dual Expert mode (both lenses; switches per question).
  /mode-status       Show currently-active mode (or report none).
  /mode-clear        Clear active mode (return to no-mode default).

CYCLE (mode-aware autopilot):
  /cycle             Run one cycle of the active mode's autopilot sequence.
                     Reads $HOME/.claude/active-mode + dispatches the mode's
                     /cycle chain. Wrap with /loop <interval> /cycle for
                     recurring autopilot.

UTILITY:
  /log <directive>   Log an operator directive verbatim to $HOME/wiki/log/
                     (sacrosanct primary source for $HOME iteration).
  /audit             Run 10-step integrity check (yamls parse, hooks compile,
                     blockers in sync, decisions verify, etc.).
  /sync-progress     Re-derive progress.md Current-position callout from
                     live state; show diff; apply on operator confirmation.
  /handoff           Write strong handoff document at $HOME/wiki/log/<ts>-handoff.md
                     capturing in-flight state — usable before compact / pause /
                     session-restart / sister-project context-shift.
  /help-root         Show this cheatsheet.

STAMP CONTROL (per SB-114/115 — DRAFT, see SB-116 UX Epic):
  /stamp-horizontal  Set stamp render layout = horizontal (compact 6-line).
  /stamp-vertical    Set stamp render layout = vertical (stacked sections).
  /stamp-on          Force stamp always-render (overrides default-hide-no-mode).
  /stamp-off         Disable stamp globally.
  /stamp-auto        Default: render only when active-mode set (mode-conditional).
  /stamp-status      Show current stamp config (layout + enabled).

OBJECTIVE LAYER (per SB-118 — multi-cycle objective tracking):
  /mission           Manage active-mission state file (multi-cycle objective).
                     Verbs: set <text> | clear | show. Surfaces in mode-enforcement
                     banner + stamp.
  /focus             Manage active-focus state file (sub-objective within mission).
                     Verbs: set <text> | clear | show.
  /impediment        Manage active-impediment state file (block on focus when stuck).
                     Verbs: set <text> | clear | show. Empty = focus unblocked.

PRIORITIES LAYER (per SB-127 — imminent-work hot-queue, surfaces ABOVE PM tier):
  /priorities        Manage active-priorities list (operator-authored top-priorities).
                     Verbs: add <text> | show | clear | remove <N> |
                     promote <N> | demote <N> | set <semicolon-sep>.

INSTALL:
  /install-agent-brain  Deploy $HOME agent brain (settings + hooks + rules +
                        commands + agents + modes + skills + tools) into a
                        sister project (operator-opt-in propagation).

SUMMARY:
  Total: 26 commands (15 governance/cycle/mode + 6 stamp config + 3 objective + 1 priorities + 1 install).
  Hook directs to /orient on every fresh session.
  PostCompact directs to /orient again after compaction.
  Modes deliver autopilot via /loop /cycle.
  Stamp config persisted at $HOME/.claude/stamp-config.json.
═════════════════════════════════════════════════════════════════════════

For deeper detail per command, Read the file:
  $HOME/.claude/commands/<command-name>.md

Skills (auto-trigger via natural prose):
  surface-state      Auto-fires on "where are we" / "what's the state" prose;
                     runs /orient.
  surface-blockers   Auto-fires on "what's blocking" / "what needs my input"
                     prose; runs /blockers.

Tools (deterministic non-LLM Python; commands compose them):
  python3 -m tools.state          State (mode + git + reachability)
  python3 -m tools.blockers       Blocker drift check vs governance/blockers.md
  python3 -m tools.progress       Compute live SFIF + module + task readiness
  python3 -m tools.decisions      List/get/verify/append D### entries
  python3 -m tools.cycle          Cycle dispatch + status block (--diff-fence /
                                  --ansi-fence / --ansi-horizontal modes)
  python3 -m tools.tasks          Per-task drill-down (list/get/claimable)
  python3 -m tools.stamp          Stamp config (configure layout/enabled)

MCP server (when wired via .mcp.json):
  root_state           root_blockers              root_progress
  root_decisions_list  root_decisions_get         root_decisions_verify
  root_decisions_next_id  root_orient (composite)
═════════════════════════════════════════════════════════════════════════
```

## When `/help-root` is most useful

- First time using the project (onboarding)
- Forgetting which command does what
- Comparing mode-* commands or governance commands at a glance
- Sub-agents that need to discover available commands without reading 26 separate files

## What `/help-root` is NOT

- Not the harness `/help` (that's Claude Code's built-in)
- Not a substitute for reading the per-command file when implementing
- Not deterministic execution — it's a discovery surface
