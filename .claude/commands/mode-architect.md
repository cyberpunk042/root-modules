Enable DevOps Software Engineer & Architect mode for root-modules.

> Slash-invoked ONLY. Operator types `/mode-architect` literally. Persona shift is durable across turns until cleared (`/mode-clear`) or switched (`/mode-pm`, `/mode-dual`).

## On `/mode-architect`

1. Write `devops-architect` to `$HOME/.claude/active-mode` (overwrite).
   ```bash
   echo -n devops-architect > $HOME/.claude/active-mode
   ```
2. Read `$HOME/.claude/modes/devops-architect.md` — load persona, primary brain pieces priority, scope discipline, /cycle sequence.
3. Acknowledge to the operator: confirm mode active + summarize the persona + scope (in/out) + /cycle sequence + how to disable. Tight, one screen.
4. From this point on, treat the persona + scope discipline as the operating frame for this session until `/mode-clear` or another `/mode-*`.
5. If the operator asks for work that's out-of-scope per the mode (e.g., backlog grooming as primary focus), gently flag the scope mismatch and offer `/mode-pm` or `/mode-dual` — don't refuse outright.

## Cross-references

- **Canonical command index**: [`.claude/commands/README.md`](README.md) (Tier 1 — `/mode-architect` is one of three persona-mode entry points)
- Persona mode file (loaded into context on entry): [`.claude/modes/devops-architect.md`](../modes/devops-architect.md)
- Companion mode commands: [`/mode-pm`](mode-pm.md) (PM lens) · [`/mode-dual`](mode-dual.md) (both lenses) · [`/mode-clear`](mode-clear.md) (return to no-mode default) · [`/mode-status`](mode-status.md) (read current mode)
- State file: `$HOME/.claude/active-mode` (durable across turns; mode-entry is operator-choice per directive 2026-05-05)
- Composes with: [`/cycle`](cycle.md) — Architect cycle sequence: `/orient` → `/progress` → architecture review → implementation progress scan → stage gate check
- Stage-gate awareness per [`.claude/rules/methodology.md`](../rules/methodology.md) — Architect cycle reads `methodology.yaml` to flag work outside the SFIF stage's allowed outputs
- Surfaces in: mode-enforcement banner (per-prompt) · /handoff and /terminate handoff docs · pre-compact.sh handoff
- **M-E001-1 productive-cycle action vocabulary**: this command emits **`operator-directive-register`** action type per Hard Rule 14
- Brain-improvement mandate: [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)
