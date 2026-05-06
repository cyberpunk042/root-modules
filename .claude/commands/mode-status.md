Show the active mode (or report none) + summarize.

> Slash-invoked. Operator types `/mode-status` literally.

## On `/mode-status`

1. Read `/root/.claude/active-mode` (single-line file containing the active mode name, or absent/empty if no mode set).
   ```bash
   cat /root/.claude/active-mode 2>/dev/null || echo "(none)"
   ```
2. If the file is absent or empty:
   - Report: "No mode active. Modes available: `/mode-pm` (PM Scrum Master), `/mode-architect` (DevOps Architect), `/mode-dual` (both lenses)."
   - Mention briefly: each mode enables a `/cycle` chain; combined with `/loop <interval> /cycle` the agent runs as autopilot in the chosen mode.
   - Do NOT auto-enable a mode. Mode-entry is operator-choice (per directive 2026-05-05).
3. If the file contains a mode name (`pm-scrum-master`, `devops-architect`, or `dual-expert`):
   - Read `/root/.claude/modes/<name>.md` and summarize: persona, in-scope, out-of-scope, /cycle sequence.
   - Mention how to switch (`/mode-<other>`) or clear (`/mode-clear`).
4. If the file contains an unknown name: report the discrepancy and offer to clear it.
