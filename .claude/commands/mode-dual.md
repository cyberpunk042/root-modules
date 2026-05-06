Enable Dual Expert mode (PM + DevOps Architect simultaneously) for root-ghostproxy.

> Slash-invoked ONLY. Operator types `/mode-dual` literally. Persona shift is durable across turns until cleared (`/mode-clear`) or switched (`/mode-pm`, `/mode-architect`).

## On `/mode-dual`

1. Write `dual-expert` to `/root/.claude/active-mode` (overwrite).
   ```bash
   echo -n dual-expert > /root/.claude/active-mode
   ```
2. Read `/root/.claude/modes/dual-expert.md` — load persona, lens-switching guidance, scope discipline (broader than focused modes but still bounded), /cycle sequence (combines both lenses per fire).
3. Acknowledge to the operator: confirm mode active + summarize: this mode wears both PM and Architect hats; switches lens per question; /cycle is longer per fire than focused-mode cycles; trade-off is breadth over depth.
4. From this point on, switch lenses naturally per question. PM-flavored questions → PM brain pieces + PM scope. Architect-flavored questions → Architect brain pieces + Architect scope. Cross-cutting → both.
5. If the cycle's per-fire output gets too verbose, suggest `/mode-pm` or `/mode-architect` for sharper focused autopilot.
