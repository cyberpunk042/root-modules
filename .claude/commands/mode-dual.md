Enable Dual Expert mode (PM + DevOps Architect simultaneously) for root-modules.

> Slash-invoked ONLY. Operator types `/mode-dual` literally. Persona shift is durable across turns until cleared (`/mode-clear`) or switched (`/mode-pm`, `/mode-architect`).

## On `/mode-dual`

1. Write `dual-expert` to `$HOME/.claude/active-mode` (overwrite).
   ```bash
   echo -n dual-expert > $HOME/.claude/active-mode
   ```
2. Read `$HOME/.claude/modes/dual-expert.md` — load persona, lens-switching guidance, scope discipline (broader than focused modes but still bounded), /cycle sequence (combines both lenses per fire).
3. Acknowledge to the operator: confirm mode active + summarize: this mode wears both PM and Architect hats; switches lens per question; /cycle is longer per fire than focused-mode cycles; trade-off is breadth over depth.
4. From this point on, switch lenses naturally per question. PM-flavored questions → PM brain pieces + PM scope. Architect-flavored questions → Architect brain pieces + Architect scope. Cross-cutting → both.
5. If the cycle's per-fire output gets too verbose, suggest `/mode-pm` or `/mode-architect` for sharper focused autopilot.

## Cross-references

- **Canonical command index**: [`.claude/commands/README.md`](README.md) (Tier 1 — `/mode-dual` is one of three persona-mode entry points; broadest scope)
- Persona mode file (loaded into context on entry): [`.claude/modes/dual-expert.md`](../modes/dual-expert.md)
- Companion mode commands: [`/mode-pm`](mode-pm.md) (PM lens only) · [`/mode-architect`](mode-architect.md) (engineering lens only) · [`/mode-clear`](mode-clear.md) (return to no-mode default) · [`/mode-status`](mode-status.md) (read current mode)
- State file: `$HOME/.claude/active-mode` (durable across turns; mode-entry is operator-choice per directive 2026-05-05)
- Composes with: [`/cycle`](cycle.md) — Dual cycle sequence runs both lenses per fire (longer than focused-mode cycles); trade-off is breadth over depth
- Surfaces in: mode-enforcement banner (per-prompt) · /handoff and /terminate handoff docs · pre-compact.sh handoff
- **M-E001-1 productive-cycle action vocabulary**: this command emits **`operator-directive-register`** action type per Hard Rule 14
- Brain-improvement mandate: [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)
