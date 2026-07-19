---
name: questions
description: Interactive queue for pending design questions. Surfaces unanswered questions from project docs (SDDs / RFCs / handoffs), drills into one at a time with options + tradeoffs, records the operator's answer by editing the source doc AND appending a chronological decision log entry. Argument shape — `show` (default) | `<selector>` | `solve <selector>` | `solve-all` | `answer <selector> <option>`. Selector — `Q-N` | `first` | `last` | `all` | `N` | `N,M`. Use when the user types /questions or asks to "resolve / answer / decide on the open questions."
---

# /questions — interactive question-resolution layer

Companion to `/view`. Where `/view` *renders* the unanswered queue, `/questions`
**resolves it** — one question at a time, interactively, with the operator's
decision committed to the source doc and to a chronological log.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│   SDD "Open questions" section                                               │
│           │                                                                  │
│           ▼                                                                  │
│   /questions show       ── lists the queue (Q-1 .. Q-N)                      │
│   /questions <sel>      ── solve-mode for that selector                      │
│   /questions answer …   ── fast-path: pick a known option, skip picker       │
│           │                                                                  │
│           ▼                                                                  │
│   AskUserQuestion       ── operator picks A/B/C/D or types Other (free-text) │
│           │                                                                  │
│           ▼                                                                  │
│   SDD inline edit       ── Q-X row becomes "answered (D-NNN) — <decision>"   │
│   docs/decisions.md     ── new D-NNN entry appended (chronological audit log)│
│           │                                                                  │
│           ▼                                                                  │
│   Optional PR           ── operator confirms; agent commits + pushes + PR    │
└──────────────────────────────────────────────────────────────────────────────┘
```

## When to invoke

- User typed `/questions` (any subcommand).
- User said "let's resolve / answer / decide / work through the open questions."
- User said "answer Q-X" or "decide on the dashboard scope" or similar.
- Coming out of `/view` and the user wants to act on the Unanswered section.

## Arguments

| Form | Meaning |
|---|---|
| `/questions` | Default: `show` — render the queue with one-line summaries |
| `/questions show` | Same as above, explicit |
| `/questions <selector>` | Shortcut for `solve <selector>` |
| `/questions solve <selector>` | Enter solving-mode for the selected question(s) |
| `/questions solve` (no selector) | Render queue + ask which to enter (two-hop) |
| `/questions solve-all` | **Alias for `solve all`** — walk every question sequentially. Use this when you know you want to do all of them; saves the no-selector picker hop. |
| `/questions answer <selector> <option>` | Fast-path: pick a known option (A/B/C/D or text) |
| `/questions detail <selector>` | Read-only deep render of one question (mini-RFC) |

### Selector syntax

| Selector | Means |
|---|---|
| `Q-1` (or `Q1`, `1`) | The first question in the rendered queue |
| `Q-3` | The third question |
| `first` | First question |
| `last` | Last question |
| `all` | Walk every unanswered question (one at a time) |
| `N,M` (e.g. `1,3,5`) | Subset by index |

`Q-N` numbering is **render-stable within a session** — the same numbering
`/view`'s Unanswered subsection produced. If `/view` hasn't run, generate it
the same way.

## Project-shape detection

Run in parallel at the start (same detection as `/view`):

1. `ls docs/handoff/*.md docs/review/phase-*/99-findings-ledger.md docs/sdd/*.md`
2. `git log --oneline -10`, `git status --short`
3. `~/.claude/active-questions` (root-modules-style queue if present)

Sources for the queue, by precedence:

- **SDD "Open questions" sections** — primary. Look for `- **Q-X — …**` rows
  not marked answered/closed/shipped/confirmed.
- **SDD impl-status rows** marked `deferred` / `open` / `pending`.
- **Latest handoff doc** — items the handoff flagged as needing user input.
- **`~/.claude/active-questions/<repo>`** if the operator runs the root-modules
  pattern in this repo too.
- **Open GitHub issues** labelled `question` if MCP scope permits.

If the project has **no** doc-shaped questions and the user is asking, treat
the user's prose as a question to register — but in selfdef-shape the queue
is *derived*, not maintained.

## Coexistence with this repo's existing `/questions` command

`cyberpunk042/root-modules` already ships its own slash command at
`.claude/commands/questions.md` — a state-file-backed agent-pending-questions
queue (`$HOME/.claude/active-questions`, Python-tool-driven). That is a
**different SRP** from this skill:

- `.claude/commands/questions.md` — **agent-asks-operator** queue, persistent
  state on operator's home filesystem. Used when the agent has a question
  for the operator and needs it to surface in mode-enforcement banners /
  stamps / pre-compact handoffs.
- `.claude/skills/questions/SKILL.md` (this file) — **design-doc question**
  resolution. Derived from SDDs / RFCs / handoffs. Stateless; reads the
  docs each time. Records decisions in `docs/decisions.md`.

Claude Code may resolve `/questions` to the slash command file first.
When the operator wants this skill specifically, invoke it as `Skill(questions)`
or name it in prose ("resolve the design questions"). If the conflict is
undesirable, rename one of them.

---

## Verb: `show` (default)

Render a compact queue table. Per-row columns:

```
| # | ID    | Source                                  | One-line gist                           | Stakes |
| 1 | SDD-8 | docs/sdd/008…md:46 — D-9                | How to scope dashboard?                 | high   |
| 2 | SDD-7 | docs/sdd/007…md:27 — D-3 deferred        | Terminate-on-revoke for SSE subscribers? | low    |
| 3 | SDD-4 | docs/sdd/004…md — Q-C                    | TracingPolicy signing machinery shape?  | medium |
```

End with a single sentence: "Solve any with `/questions <N>` or `/questions solve all`."

**Stay short**. Show-mode is a launcher, not a detail view. For depth, the
user is expected to drill in.

## Verb: `solve <selector>`

For each selected question, run this loop:

### Step 1 — render the mini-RFC

Same shape as `/view`'s UNANSWERED section, but for ONE question at a time:

```
### Q-N (id) — <Question stated as a question>

**Status**: open | deferred | blocked | waiting on user
**Why it's open**: <2-3 sentences>
**What it gates**: <downstream impact>
**Stakes**: <low | medium | high — why>

**Options**:

  A) <name> — <one-line description>
     • Pros: <upside>
     • Cons: <downside>
     • Effort: S | M | L
     • Risk: low | medium | high

  B) <name>
     ...

**My recommendation**: <Option X — one sentence on why>
**What unblocks**: <what's needed to land a decision>
**Source**: <SDD path>:<line> (Q-X row)
```

Synthesize options from surrounding context if the SDD doesn't enumerate them.
**Always say so** ("options synthesized — correct me if framing's off").

### Step 2 — operator picks

Use the **AskUserQuestion tool** with 2-4 options. Always include the
recommendation as option A. Always allow `Other` for free-text or
"keep deferred + log the rationale."

If the operator picks **Other**, capture the free-text answer verbatim.

### Step 3 — propose the diff

Render the proposed change set:

1. **SDD edit**: show the *before* (Q-X row as-is) and *after* (with
   `**answered (D-NNN)** — <decision>` prepended; original text preserved
   for history).
2. **docs/decisions.md entry**: show the new D-NNN entry to be appended.

Then ask the operator: **"Ship this as a PR, leave it uncommitted, or
cancel?"** via AskUserQuestion (3-option picker).

### Step 4 — apply (only if confirmed)

- If **"Ship as PR"**: create a fresh branch off `main`, apply the edits,
  commit, push, open a draft (or ready-for-review per the repo's standing
  cadence) PR.
- If **"Leave uncommitted"**: apply the edits to the working tree only.
  Operator will commit/PR manually.
- If **"Cancel"**: revert anything provisional; the question stays open.

## Verb: `answer <selector> <option>`

Fast-path. Skip the picker. Operator already knows which option they want.

- `<option>` is the letter `A`/`B`/`C`/`D` from the mini-RFC, or the
  literal text "defer" / "Other: <free text>".
- Agent still produces the mini-RFC (so the rationale is captured) and
  still shows the diff before applying.
- Same Step 3-4 confirm-then-apply flow as `solve`.

## Verb: `detail <selector>`

Read-only. Like `solve <selector>` Step 1, but **no AskUserQuestion**, no
proposed edits. Useful when the operator wants to think before deciding.

---

## File formats

### SDD inline edit pattern

For a Q-X row like:

```
- **Q-C** (TracingPolicy signing shape): deferred. Tracked as
  the F-2026-024 follow-up known gap; a future SDD scopes the
  shared signing machinery between sigma rules and
  TracingPolicies.
```

The agent rewrites it to:

```
- **Q-C** (TracingPolicy signing shape): **answered (D-NNN, 2026-05-15)** —
  inline detached signatures + bundled CA (Option B).
  _Original framing for history_: deferred. Tracked as the F-2026-024
  follow-up known gap; a future SDD scopes the shared signing machinery
  between sigma rules and TracingPolicies.
```

The original context is preserved verbatim — never deleted, only annotated.

### `docs/decisions.md` entry format

Create the file if it doesn't exist with this header:

```markdown
# Decisions log

Chronological audit trail of design-question resolutions. Each `D-NNN`
entry corresponds to an answered question from one of the SDDs (or
similar source doc). Entries are append-only — never edit a past entry,
only append a new one if a decision is revisited.
```

Per entry (appended to the bottom):

```markdown
## D-NNN — YYYY-MM-DD — <one-line summary>

**Decision**: <operator's choice — verbatim if free-text>
**Question**: <full question, copied from source doc>
**Source**: `docs/<source>.md`:<line> (Q-X row)
**Rationale**: <why this beats the alternatives — synthesis + operator commentary>
**Affected items**: <files / future SDDs / impl crates that this touches>
**Reversibility**: fully-reversible | partial | locked
**Linked**: PR #<n> (if shipped)
```

D-NNN numbering: scan existing entries, take max + 1. Start at D-001 if the
file is fresh. Pad to 3 digits.

### Branch + commit + PR naming

When shipping as PR:

- Branch: `claude/questions-D-NNN-<short-slug>`
- Commit: `docs(questions): D-NNN — <decision summary>`
- PR title: `docs(questions): D-NNN — <decision summary>`
- PR body: includes the mini-RFC + the decision + diff summary

---

## Composition with `/view`

When `/view` renders the UNANSWERED section, every question shown there
should be solvable via `/questions <Q-N>` using the same numbering.

- `/view` = the orientation layer (read).
- `/questions` = the resolution layer (read → decide → write).

## Style rules

- **Render-then-pick**. Always show the mini-RFC before the picker.
- **Always include "Other"** in the picker for free-text or "keep deferred."
- **Show the diff before applying**.
- **Never apply edits without confirmation**, even on fast-path `answer`.
- **Preserve original Q-X framing** in the SDD — annotate, don't delete.
- **One question at a time** in interactive solve.
- **No model identifier** in any committed artifact.

## Failure modes to avoid

- Picking for the operator. The operator decides; the agent records.
- Applying SDD edits before confirmation.
- Dropping original Q-X context — the deferred rationale is history.
- Inventing D-NNN numbers that conflict with existing entries.
- Pushing without explicit operator confirmation on the diff.
- Treating `defer` as a non-answer. "Keep deferred + log the rationale"
  IS an answer; it produces a D-NNN entry too.
