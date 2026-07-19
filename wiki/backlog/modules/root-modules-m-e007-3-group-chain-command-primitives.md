---
title: "M-E007-3 — Group + chain command primitives (slash command wrappers around existing tools.group)"
type: module
status: in-progress
priority: P3
parent_epic: "epic-e007-driver-empowerment-and-input-intent-disambiguation"
parent_milestone: "v0.2-ai-natural-task-management"
sfif_stage: foundation
current_stage: document
readiness: 25
created: 2026-05-07
updated: 2026-05-07
tags: [agent-drafted, m-e002-1-create-verb, e007, group-chain-commands, slash-command-wrapper, gated-on-m-e007-8]
---

# M-E007-3 — Group + chain command primitives

> **Agent-DRAFT v1** (per SB-095, operator-revisable). Created 2026-05-07 cron F57 in autopilot loop. Promoted from Epic E007's M-E007-3 bullet to scope-doc. **Distinct from M-E007-1**: M-E007-1 = INTENT commands (what THIS interaction IS); M-E007-3 = COMPOSITION commands (multi-state-change atomic-or-sequential). **Gated**: command authoring waits for M-E007-8 quality standards landing per Epic E007 risk-mitigation.

## Operator-stated seed (sacrosanct)

> *"I should know very well my command and how to change the mission the focus and etc and or even **multiple things at the same time / group and chain calls** and such."* — 2026-05-07 (Epic E007 founding directive, group/chain clause)

## Mission

Wrap the existing `tools.group` chain/group/tree primitive (Q1 Layer A canonical taxonomy from second-brain `wiki/domains/automation/research-pipeline-orchestration.md` per operator's 2026-04-08 vision) with operator-driver-friendly **slash commands** (`/group` + `/chain`) so operator can multi-state-change in one prompt without typing CLI args.

**Distinction from M-E007-1**:
- M-E007-1 = input-intent declaration (`/comment`, `/sidenote`, `/target-now`, `/compound-add`)
- M-E007-3 = state-change composition (`/group` for atomic batch, `/chain` for sequential)
- Together: M-E007-1 says WHAT the input is; M-E007-3 says HOW to apply state changes if multiple

## Scope (in-scope vs out-of-scope)

| In-scope | Out-of-scope |
|---|---|
| `.claude/commands/group.md` slash command authoring | Re-implementing `tools.group` (already exists at `tools/group.py` per Q1 Layer A) |
| `.claude/commands/chain.md` slash command authoring | Implementing tree-of-operations (operator-pending per E003 compound-retention Epic) |
| Composition with M-E007-1 input-intent flags (e.g. `/group --intent target-now --mission X --focus Y`) | Implementing intent-flags before M-E007-1 commands land |
| Operator-pick: command names (`/group` vs `/batch` vs `/atomic`; `/chain` vs `/sequence` vs `/pipeline`) | Naming-bikeshedding without operator decision |
| Per-command frontmatter per M-E007-8 S2 | Bypassing M-E007-8 standard (commands earn their place) |
| Manual page per M-E007-5 S3 (≥3 verbs warrants per-command manual) | Master manual section (M-E007-4 scope) |
| Test coverage: hook-test verifying group atomicity + chain sequential-with-fail-mid | Replacing `tools/tests/test-group.py` (22 cases, already passing) |

## Operator-stated 2 patterns (sacrosanct)

| Pattern | Operator's literal | Semantic |
|---|---|---|
| **group** | *"group calls"* | Atomic multi-state-change. All-or-nothing — if any sub-operation fails, all rolled back (or operator-decides via flag). Example: `/group set --mission "X" --focus "Y" --priorities "P1,P2,P3"`. |
| **chain** | *"chain calls and such"* | Sequential multi-state-change. Can fail mid-chain; subsequent steps may be skipped or attempted-anyway-with-warning per flag. Example: `/chain mission "X" -> focus "Y" -> priorities-add "Z"`. |

## Agent-proposed extensions (DRAFT v1, agent-flagged per SB-095)

| Extension | Operator-pick rationale | M-E007-8 S1 score |
|---|---|---|
| `/tree` for tree-of-operations | Operator's literal *"chains which make tree of operations"* hints at this | 4/5 (distinct + operator-stated + composes + use-cases); but heavy-weight, possibly E003-Epic-scope |
| `--rollback-on-fail` flag for `/group` | Atomic semantics need explicit rollback control | 3/5 (composes + use-cases + distinct from default) |
| `--continue-on-fail` flag for `/chain` | Sequential semantics need explicit fail-handling | 3/5 (composes + use-cases) |
| `--dry-run` flag for both | Preview changes before applying | 4/5 (all 5 except no-alias since `--dry-run` is convention) |

## Composition with existing `tools.group` (Q1 Layer A)

Per F-history: `tools.group` shipped 2026-05-06 with chain/group/tree composition primitive (16 tests). The CLI signature (per `tools.group --help`):

```
tools.group <verb> [--type group|chain|tree] [--rollback-on-fail] [--dry-run] [...]
```

Slash commands map to CLI flags:

| Slash command | CLI invocation |
|---|---|
| `/group set --mission "X" --focus "Y"` | `python3 -m tools.group apply --type group --rollback-on-fail --ops "objective set --mission X" "objective set --focus Y"` |
| `/chain mission "X" -> focus "Y"` | `python3 -m tools.group apply --type chain --ops "objective set --mission X" "objective set --focus Y"` |
| `/group --dry-run ...` | `python3 -m tools.group apply --dry-run ...` (preview only) |

This composition fits per M-E007-8 S1 criterion 3 (composes with existing tools — strongly satisfied).

## Composition with M-E007-1 input-intent commands

Per M-E007-1 page's "Composition with group/chain primitives" section: input-intent commands compose as flags:

- `/group --intent target-now --mission "X" --focus "Y"` → atomic group with target-now intent (current-fire action)
- `/group --intent compound-add --mission-extend "X" --focus-extend "Y"` → atomic group adding to compound state
- `/chain --intent waterfall-add /focus "X" -> /priorities-add "Y"` → sequential chain with waterfall-add intent

Implementation: `--intent <intent>` flag is parsed AT command-dispatch level; passed through to underlying tool calls.

## Implementation sequencing (per Epic E007 risk-mitigation)

**M-E007-8 quality standards rule MUST land FIRST** (gating per Epic E007 risk-mitigation). Per-command authoring pattern (when M-E007-8 lands):

1. Author `.claude/commands/group.md` per M-E007-8 S2 (frontmatter description ≤80 chars: "Atomic multi-state-change command — all-or-nothing batch via tools.group group-mode"; argument-hint pattern; body sections + ≥2 examples)
2. Author `.claude/commands/chain.md` per same standard
3. If `/tree` extension adopted: `.claude/commands/tree.md`
4. Cross-reference graph per M-E007-6 (group/chain `composes_with: objective, focus, mission, priorities, tasks`)
5. Manual page per M-E007-5 S3 (group + chain meet criterion 1 + 2 — ≥3 verbs + non-obvious arg interactions)
6. Test: hook-test verifying group atomicity + chain sequential semantics + intent-flag-passthrough

## Done When (M-E007-3 module-level)

- [ ] M-E007-8 quality standards rule landed (gating dependency)
- [ ] Operator review of `/group` + `/chain` command names + agent-proposed extensions
- [ ] Decision logbook entry capturing operator-name + extensions adopted (D-XXX)
- [ ] `.claude/commands/group.md` authored per M-E007-8 S2
- [ ] `.claude/commands/chain.md` authored per M-E007-8 S2
- [ ] Cross-reference graph updated per M-E007-6 (composes_with field on objective/mission/focus/priorities)
- [ ] Manual pages per M-E007-5 S3 (group + chain warrant manuals — ≥3 args with non-obvious interactions)
- [ ] Hook-test coverage: group atomicity + chain sequential-with-fail-mid + intent-flag-passthrough; existing `tools/tests/test-group.py` 22 cases preserved + extended for slash-command-wrapper layer
- [ ] Empirical: 1+ session shows operator using `/group` or `/chain` deliberately + AI dispatching tools.group correctly

## Dependencies

- **Hard**: `tools.group` (Q1 Layer A — already exists; this module wraps it, doesn't reinvent)
- **Hard**: M-E007-8 quality standards rule (gating per Epic E007 risk-mitigation)
- **Hard**: M-E007-1 input-intent commands (composition target — `--intent` flag passthrough)
- **Hard**: Operator review of command names + agent-proposed extensions (operator-pick scope)
- **Soft**: M-E007-4 master manual (where group/chain documented for operator-driver journey)
- **Soft**: M-E007-6 cross-reference graph (composes_with population)
- **Soft**: Epic E003 compound-retention-and-multi-group (cousin substrate; tree-extension may live there if heavyweight)

## Risk + caveats

| Risk | Mitigation |
|---|---|
| Naming collision (`/group` may conflict with existing CLI verb) | M-E007-8 S5 anti-pollution rejection trigger #1 — enumerate existing namespace before authoring; alternative names: `/batch` / `/atomic` / `/multi` |
| Slash command becomes thin wrapper that adds no value over CLI | M-E007-8 S1 criterion 4 (documented use cases) + S5 trigger "doesn't compose with /group or /chain" — must demonstrate operator-friendliness gain over `python3 -m tools.group apply ...` |
| Atomicity semantics ambiguous (does `/group` truly rollback all sub-ops on any failure?) | Document per-command behavior in M-E007-5 manual; default = rollback-on-fail per atomic semantics; operator can flag --no-rollback |
| Chain failure semantics (do subsequent steps skip or attempt) | Default = skip-after-fail (fail-fast); flag `--continue-on-fail` for opposite behavior |
| Intent-flag passthrough complexity | M-E007-1 must land FIRST so intent-flags are well-defined before /group / /chain consume them |

## Connects to

- Epic E007 (parent): `wiki/backlog/epics/epic-e007-driver-empowerment-and-input-intent-disambiguation.md`
- Sister M-E007-1 (input-intent — composition target): `wiki/backlog/modules/root-modules-m-e007-1-input-intent-commands-taxonomy.md`
- Sister M-E007-8 (gating quality standards): `wiki/backlog/modules/root-modules-m-e007-8-anti-pollution-quality-standards.md`
- Sister M-E007-4 (master manual)
- Sister M-E007-6 (cross-reference graph)
- `tools/group.py` (existing primitive — Q1 Layer A canonical taxonomy)
- `tools/tests/test-group.py` (existing 22 tests — preserved + extended)
- Cousin Epic E003 compound-retention-and-multi-group (substrate Epic; tree-extension may live there)
- `.claude/rules/compound-and-waterfall.md` (substrate — compound axis = group; waterfall axis = chain)
- Sacrosanct seed: operator's *"group and chain calls and such"* clause + *"chains which make tree of operations"* hint
