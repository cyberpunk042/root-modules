Show the decisions logbook — audit trail of decisions made.

> Slash-invoked. Operator types `/decisions` literally. Read-only by default; can append a new entry on operator instruction.

## On `/decisions`

1. Read `$HOME/wiki/governance/decisions.md` in full.
2. Present the audit trail:
   - Tabular summary (ID, date, decision summary, reversibility) — for skim
   - On-demand-expandable details per entry (operator can ask "explain D012")
   - Counts: total decisions; by reversibility (locked / partial / fully-reversible)
3. Highlight any decisions that are RECENT (this session) so operator can see what's just been recorded.
4. Stand by.

## On `/decisions append <decision>` (operator instruction)

When operator asks to record a new decision (e.g., "/decisions append: I picked greenfield for B001"):

1. Construct a new D### entry following the format in `decisions.md`:
   - ID: next D### in sequence
   - Date: today
   - Decision: operator's words verbatim (sacrosanct)
   - Operator's verbatim: full operator quote
   - Rationale: ask operator if they want one captured + record verbatim
   - Affected items: derived from the linked blocker
   - Reversibility: ask operator (default: fully-reversible unless otherwise specified)
   - Downstream effects: document expected fallout
   - Linked blocker: B### the decision resolves
2. Append to `decisions.md`.
3. Move the matching B### entry in `blockers.md` from "active" to "resolved" (with a brief link to D###).
4. Refresh `progress.md` if the decision changes any module/task status.
5. Confirm to operator: D### appended; B### resolved; progress refreshed.

## What `/decisions` is NOT

- Not the blockers register (use `/blockers`)
- Not the progress view (use `/progress`)
- Not a freeform log — entries follow the format. Audit trail integrity matters.
- Not a place for prose-only entries — every D### needs ID + date + decision + operator-verbatim (if applicable) + rationale + affected + reversibility + downstream

## Cross-references handled by this command

- When asked "what was the rationale for X" — find the D### + present the rationale + operator-verbatim
- When asked "is X reversible" — find the D### + present the reversibility field
- When asked "what depends on D###" — search `decisions.md` for downstream chains + `progress.md` for active state
