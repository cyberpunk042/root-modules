Enable PM Scrum Master mode for root-modules.

> Slash-invoked ONLY. Operator types `/mode-pm` literally. Persona shift is durable across turns until cleared (`/mode-clear`) or switched (`/mode-architect`, `/mode-dual`).

## On `/mode-pm`

1. Write `pm-scrum-master` to `$HOME/.claude/active-mode` (overwrite). One line, no trailing whitespace.
   ```bash
   echo -n pm-scrum-master > $HOME/.claude/active-mode
   ```
2. Read `$HOME/.claude/modes/pm-scrum-master.md` — load persona, primary brain pieces priority, scope discipline, /cycle sequence.
3. Acknowledge to the operator: confirm mode active + summarize the persona + scope (in/out) + /cycle sequence + how to disable. Tight, one screen.
4. From this point on, treat the persona + scope discipline as the operating frame for this session until `/mode-clear` or another `/mode-*`.
5. If the operator asks for work that's out-of-scope per the mode (e.g., implementation), gently flag the scope mismatch and offer `/mode-architect` or `/mode-dual` — don't refuse outright; the operator can override.

## Cross-references

- **Canonical command index**: [`.claude/commands/README.md`](README.md) (Tier 1 — `/mode-pm` is one of three persona-mode entry points)
- Persona mode file (loaded into context on entry): [`.claude/modes/pm-scrum-master.md`](../modes/pm-scrum-master.md)
- Companion mode commands: [`/mode-architect`](mode-architect.md) (engineering lens) · [`/mode-dual`](mode-dual.md) (both lenses) · [`/mode-clear`](mode-clear.md) (return to no-mode default) · [`/mode-status`](mode-status.md) (read current mode)
- State file: `$HOME/.claude/active-mode` (durable across turns; mode-entry is operator-choice per directive 2026-05-05)
- Composes with: [`/cycle`](cycle.md) — `/cycle` reads active-mode each fire to dispatch the mode-specific cycle sequence; mode change mid-loop changes the cycle on the next fire
- Surfaces in: mode-enforcement banner (per-prompt persona + cycle steps + voice + state) · /handoff and /terminate handoff docs · pre-compact.sh handoff
- **M-E001-1 productive-cycle action vocabulary**: this command emits **`operator-directive-register`** action type per Hard Rule 14 (mode-entry is an operator-confirmed persona shift)
- Brain-improvement mandate: [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)
