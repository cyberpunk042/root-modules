Clear the active mode — return to the no-mode default.

> Slash-invoked. Operator types `/mode-clear` literally.

## On `/mode-clear`

1. Remove `/root/.claude/active-mode` (or empty it).
   ```bash
   rm -f /root/.claude/active-mode
   ```
2. Acknowledge to the operator: mode cleared; agent now operates per the no-mode default (generic CLAUDE.md / BOOTSTRAP.md baseline; no persona overlay; `/cycle` will report no mode active and prompt to pick one).
3. Mention modes available for re-entry whenever desired.
