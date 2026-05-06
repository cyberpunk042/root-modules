Enable DevOps Software Engineer & Architect mode for root-ghostproxy.

> Slash-invoked ONLY. Operator types `/mode-architect` literally. Persona shift is durable across turns until cleared (`/mode-clear`) or switched (`/mode-pm`, `/mode-dual`).

## On `/mode-architect`

1. Write `devops-architect` to `/root/.claude/active-mode` (overwrite).
   ```bash
   echo -n devops-architect > /root/.claude/active-mode
   ```
2. Read `/root/.claude/modes/devops-architect.md` — load persona, primary brain pieces priority, scope discipline, /cycle sequence.
3. Acknowledge to the operator: confirm mode active + summarize the persona + scope (in/out) + /cycle sequence + how to disable. Tight, one screen.
4. From this point on, treat the persona + scope discipline as the operating frame for this session until `/mode-clear` or another `/mode-*`.
5. If the operator asks for work that's out-of-scope per the mode (e.g., backlog grooming as primary focus), gently flag the scope mismatch and offer `/mode-pm` or `/mode-dual` — don't refuse outright.
