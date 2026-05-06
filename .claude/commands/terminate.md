---
description: Strong + high-standard session-termination preparation — handoff doc + comprehensive status/progress/artifacts/role updates before operator decides next (compact / something else / nothing). Different from /handoff (snapshot only) by enforcing the full-update sweep.
argument-hint: (none)
---

# /terminate — strong session-termination prep

Operator-invoked when preparing to end / pause / pivot a session. Goes BEYOND `/handoff` (which is a snapshot doc only) by running the full-update sweep operator named: progress, status, artifacts segments + contributions, AI's role + responsibilities (especially mode-specific) — THEN writes the handoff doc.

After completion, operator decides next: `/compact`, switch context, close session, or nothing. `/terminate` does NOT itself compact, close, or take any irreversible action.

> Operator directive 2026-05-06 verbatim: *"a strong and high standard handoff objective and critical documents / artifacts... the AI tried to update the status of things the progress, the artifacts segments and contributions, his role responsabilities, especially when in modes."*

## Distinction from existing commands

| Command | What it does | When |
|---|---|---|
| `/handoff` | Snapshot of in-flight state to a single doc | Before stepping away / mid-loop checkpoint |
| `/terminate` | **Full-update sweep** + handoff doc | Before ending/pausing/pivoting a session |
| `/finish-smoothly` | Forced knowledge-extraction PASS + handoff | Before ending session AND wanting lessons/patterns/decisions captured to wiki |

## Steps when operator invokes `/terminate`

1. **Sync progress** — invoke `/sync-progress` (re-derives `wiki/governance/progress.md` from live state).

2. **Refresh decisions logbook** — scan this session for any decisions made (operator-confirmed choices, architectural picks, scope changes). For each: append to `wiki/governance/decisions.md` via `python3 -m tools.decisions append --title "..." --rationale "..."`. If none new: state "no new decisions this session."

3. **Update systemic-bugs tracker** — for any SB structurally-fixed or verified during this session, ensure tracker rows reflect (status + fix evidence + verification). Surface uncertainties for operator review; do NOT mark "verified" without evidence inline.

4. **Document role + responsibilities (mode-aware)** — write a brief role/responsibility note to the handoff covering:
   - Current `active-mode` (PM / Architect / Dual / no-mode) + persona scope
   - Mode's lens applied this session (what was emphasized)
   - Active mission/focus/impediment (SB-118 objective layer)
   - Specific responsibilities the agent took during this session

5. **Inventory artifacts + contributions** — list deliverables produced this session:
   - Files authored / modified / deleted (from git status + diff)
   - Wiki pages added (lessons, patterns, decisions, raw notes, modules, tasks)
   - Hooks / commands / tools / rules added or changed
   - Tests added / passing
   - Backlog state changes (modules / tasks status flips, readiness updates)

6. **Write the handoff doc** — same shape as `/handoff` (`$HOME/wiki/log/<ts>-terminate-handoff.md`) but with sections 4 + 5 above appended:
   - Active mode / task / objective (mission · focus · impediment) / priorities
   - Cycle + blockers state JSON
   - Recent logs (last 5 by mtime)
   - Git state (uncommitted view)
   - **Role + responsibilities** (per step 4)
   - **Artifacts + contributions** (per step 5)
   - **Decisions made this session** (per step 2)
   - **Systemic bugs touched** (per step 3)
   - Recovery instructions for cold-pickup agent

7. **Surface to operator**:
   - Path of the terminate-handoff doc
   - One-paragraph summary of what was captured
   - Suggest possible next actions (NOT prescriptive): "Possible next: `/compact` (ends session via summarization), close session, switch context, or just stand by."

## What `/terminate` is NOT

- Not a `/compact` invocation — agent can't self-compact (Claude Code constraint); operator types `/compact` if desired.
- Not a session close — the session continues until operator closes the harness.
- Not a state mutation — only writes the handoff doc + appends to logbook (no destructive action).
- Not a "discard" — full state is captured before any operator-driven termination.

## Composition

- After `/terminate`, operator may immediately invoke `/compact` (if context-tight) or `/finish-smoothly` (if knowledge-extraction is wanted) or just close.
- Pairs with PreCompact hook: `/terminate` then `/compact` produces TWO snapshots (one operator-rich from /terminate, one auto from PreCompact hook). Both readable by post-compact `/orient`.

## When to invoke

- Before ending a long session
- Before pivoting to substantially different work
- Before context approaches compact + you want richer-than-PreCompact-snapshot state
- After a major-deliverable batch — checkpoint with full role + artifact attribution
- When the operator wants to capture "where the AI was" comprehensively, not just "what state is in flight"
