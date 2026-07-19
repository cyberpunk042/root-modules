Show all 44 root-modules slash commands with one-line description + when-to-use.

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
  /audit             Run 12-step integrity check (yamls parse, hooks compile,
                     blockers in sync, decisions verify, objective + priorities
                     state files, compound+waterfall coverage scan).
  /sync-progress     Re-derive progress.md Current-position callout from
                     live state; show diff; apply on operator confirmation.
  /help-root         Show this cheatsheet.

OPERATOR-AUTHORITY SESSION-CONTROL (operator-typed; not auto-invoked by agent):
  /handoff           Write strong handoff document at $HOME/wiki/log/<ts>-handoff.md
                     capturing in-flight state — usable before compact / pause /
                     session-restart / sister-project context-shift.
  /terminate         Strong + high-standard session-termination prep —
                     handoff doc + comprehensive status/progress/artifacts/
                     role updates before operator decides next.
  /finish-smoothly   Forced knowledge-extraction PASS into smart documents
                     + handoff. Captures lessons/patterns/decisions/super-
                     models to wiki BEFORE handoff.

STAMP CONTROL (per SB-114/115/116/136 + T067 highlight-deltas):
  /stamp-horizontal  Set stamp render layout = horizontal (compact 6-line).
  /stamp-vertical    Set stamp render layout = vertical (stacked sections).
  /stamp-on          Force stamp always-render (overrides default-hide-no-mode).
  /stamp-off         Disable stamp globally.
  /stamp-auto        Default: render only when active-mode set (mode-conditional).
  /stamp-status      Show current stamp config (layout + enabled).
  /stamp-deltas-on   Enable per-row [Δ]/[+] delta highlighting (T067 / SB-136).
  /stamp-deltas-off  Disable delta highlighting (back to plain stamp).

STATUSLINE PROFILES (per SB-124b/c — ccstatusline 5-tier ladder + 2 narrow variants):
  /statusline-focus            t1 minified 1-line (deep-coding mode).
  /statusline-base             t2 telemetry 2-line.
  /statusline-standard         t2-lean 2-line.
  /statusline-project          t3 project-aware basic 2-line.
  /statusline-intermediary     t3-work mid-tier AIDLC 3-line.
  /statusline-full-aidlc       t4 full AIDLC planning 3-line.
  /statusline-full-aidlc-narrow t4-narrow variant for narrow terminals (~90 chars).
  /statusline-aidlc-stamp-full t5 review/audit 4-line (architecture-grouped v3).
  /statusline-aidlc-stamp-full-narrow  t5-narrow variant (~110 chars).
  /statusline-list             Enumerate available profiles.
  /statusline-status           Read currently-active profile.
  /statusline-switch <name>    Named-tier dispatch (alternative to per-tier shortcuts).

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
                     promote <N> | demote <N> | set <semicolon-sep> |
                     insert <N> <text> | update <N> <text>  (SB-130).

QUESTIONS LAYER (per SB-134 — agent-pending-questions retention; E003 compound retention):
  /questions         Manage active-questions queue (agent-authored input-needed).
                     Verbs: add | show | clear | remove <N> | answer <N> |
                     promote <N> | demote <N> | set | update <N> <text> |
                     insert <N> <text> | detail <N> [<text>] | solve [selector].

TASK CURSOR (per SB-124d + M-E002-1 piling-tasks vocabulary, E002 Epic):
  /task              Manage active-task cursor + create tasks under hierarchy.
                     Verbs: show | set <T###> | clear |
                     create under-epic --epic <slug> --title <text> |
                     create under-task --task <T###> --title <text> |
                     create from-blocker --blocker <SB-NNN|B###> --title <text>.

INSTALL:
  /install-agent-brain  Deploy $HOME agent brain (settings + hooks + rules +
                        commands + agents + modes + skills + tools) into a
                        sister project (operator-opt-in propagation).

SUMMARY (empirically counted 2026-05-07; per Hard Rule 15):
  Total: 44 commands across 13 categories:
    - 1 orient + 1 cycle (orient + autopilot dispatch)
    - 5 mode-* (PM / Architect / Dual / status / clear)
    - 3 governance read-only (blockers / progress / decisions)
    - 4 utility (log / audit / sync-progress / help-root)
    - 3 operator-authority session-control (handoff / terminate / finish-smoothly)
    - 8 stamp-* (6 config + 2 deltas T067)
    - 3 objective layer (mission / focus / impediment per SB-118)
    - 1 priorities (SB-127 imminent-work hot-queue)
    - 1 questions (SB-134 agent-pending retention)
    - 1 task (SB-124d cursor + M-E002-1 create verbs)
    - 1 install (install-agent-brain — sister-project propagation)
    - 12 statusline-* (5-tier ladder + narrow variants + 3 meta)

  Hook directs to /orient on every fresh session.
  PostCompact directs to /orient again after compaction.
  Modes deliver autopilot via /loop /cycle.
  Stamp config persisted at $HOME/.claude/stamp-config.json.
  Active statusline profile at ~/.config/ccstatusline/active-profile.
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
  root_decisions_next_id  root_objective           root_questions
  root_orient (composite — incl. questions per SB-134)
═════════════════════════════════════════════════════════════════════════
```

## When `/help-root` is most useful

- First time using the project (onboarding)
- Forgetting which command does what
- Comparing mode-* commands or governance commands at a glance
- Sub-agents that need to discover available commands without reading 44 separate files

## What `/help-root` is NOT

- Not the harness `/help` (that's Claude Code's built-in)
- Not a substitute for reading the per-command file when implementing
- Not deterministic execution — it's a discovery surface

## Cross-references

- **Canonical command index**: [`.claude/commands/README.md`](README.md) (Tier 1 utility — `/help-root` is the human-readable cheatsheet; README.md is the agent-readable categorized index)
- All 44 commands referenced inline in the cheatsheet body (empirically verified 2026-05-07 per Hard Rule 15)
- Skills referenced: [`.claude/skills/`](../skills/) (surface-state, surface-blockers — auto-trigger via natural prose)
- Tools referenced: [`tools/`](../../tools/) (state, blockers, progress, decisions, cycle, tasks, stamp, objective, priorities, questions, ...)
- MCP server: [`tools/mcp_server.py`](../../tools/mcp_server.py) — 10 root_* tools surfaced via `.mcp.json` wiring (per SB-124d)
- **M-E001-1 productive-cycle action vocabulary**: this command emits **`read-only-audit`** action type per Hard Rule 14 (discovery surface; no state mutation)
- Brain-improvement mandate: [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)
