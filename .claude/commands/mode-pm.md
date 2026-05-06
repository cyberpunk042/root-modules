Enable PM Scrum Master mode for root-ghostproxy.

> Slash-invoked ONLY. Operator types `/mode-pm` literally. Persona shift is durable across turns until cleared (`/mode-clear`) or switched (`/mode-architect`, `/mode-dual`).

## On `/mode-pm`

1. Write `pm-scrum-master` to `/root/.claude/active-mode` (overwrite). One line, no trailing whitespace.
   ```bash
   echo -n pm-scrum-master > /root/.claude/active-mode
   ```
2. Read `/root/.claude/modes/pm-scrum-master.md` — load persona, primary brain pieces priority, scope discipline, /cycle sequence.
3. Acknowledge to the operator: confirm mode active + summarize the persona + scope (in/out) + /cycle sequence + how to disable. Tight, one screen.
4. From this point on, treat the persona + scope discipline as the operating frame for this session until `/mode-clear` or another `/mode-*`.
5. If the operator asks for work that's out-of-scope per the mode (e.g., implementation), gently flag the scope mismatch and offer `/mode-architect` or `/mode-dual` — don't refuse outright; the operator can override.
