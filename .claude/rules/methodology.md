# $HOME/.claude/rules/methodology.md — Methodology engine for root-ghostproxy

> Loaded on demand when stage or model selection comes up. CLAUDE.md has the summary; this file is the project-specific delta.
>
> **Strictness tier** (per `operating-principles.md` §3): **Strict** (stage gates ALLOWED/FORBIDDEN per stage are enforced) + **Advisory** (model selection per task_type informs but doesn't strictly bind). Stage boundaries are hard per the `stage-gated` methodology-profile choice — leakage between stages carries security cost for type=root projects.

## Engine location

The methodology engine for this project lives at `$HOME/wiki/config/`:

| File | Profile | Why this profile |
|---|---|---|
| `methodology.yaml` | (engine) | 9 models, 5 stages, ALLOWED/FORBIDDEN per stage, gates. Adapt artifacts/protocols/gate commands per project; keep stage names + ordering + readiness ranges + hierarchy invariants. |
| `sdlc-profile.yaml` | `simplified` | Right-sized for micro scale + solo execution. Avoids ceremony. |
| `domain-profile.yaml` | `infrastructure` | Gate-command + path-pattern overrides for IaC work. |
| `methodology-profile.yaml` | `stage-gated` | Hard ALLOWED/FORBIDDEN per stage. Suits OS-setup where leakage carries security cost. |

All four parse cleanly via `.venv/bin/python -c "import yaml; yaml.safe_load(open('<file>'))"`.

## 5 universal stages (this project's gates)

| Stage | Readiness | ALLOWED | FORBIDDEN | Gate command (project-specific) |
|---|---|---|---|---|
| **document** | 0–25% | wiki page, raw notes | code-file, test-file | Page exists with Summary + gaps identified |
| **design** | 25–50% | design-document, ADR, tech-spec | code-file, test-file | Trade-offs documented; spec reviewed |
| **scaffold** | 50–80% | type-definitions, schema, test-stubs, config-files | implementation, real test assertions | install.sh `--dry-run` runs cleanly without performing real changes; backlog page+module+task structure exists |
| **implement** | 80–95% | implementation, integration-wiring | new test files | install.sh runs end-to-end on a sandbox host; lint passes |
| **test** | 95–100% | test-implementation, test-results | new features | Idempotency invariant holds; integration smoke-test passes |

## Methodology models (selection conditions)

For root-ghostproxy specifically:

| task_type | Model | Selected when |
|---|---|---|
| `milestone` | (group of epics) | v0.2 ai-natural-task-management active alongside v0.1 (introduced 2026-05-06) — 4-level Milestone → Epic → Module → Task hierarchy |
| `epic` | feature-development | Solution not yet known; design required (sfif-rollout, E001 auto-pilot rework, E002 piling-tasks, E003 compound-retention-and-multi-group) |
| `module` | feature-development | Most M### work (M001-M014) |
| `bug` | bug-fix | Restoring correct behavior; no new architecture |
| `refactor` | refactor | Restructure existing IaC without behavior change |
| (wire existing) | integration | Bridge pattern — e.g., `tools.setup --connect-project` integration |
| project-level | project-lifecycle (SFIF) | Macro: Scaffold → Foundation → Infrastructure → Features. Other models nest. |

## Stage-boundary discipline

**Do not ship implementation in a Document task. Do not ship tests as features.** The profile name `stage-gated` is enforcement, not advisory. Per second brain learning (OpenArms Bug 5: scaffold produced 135 lines of business logic — boundary now hard).

## Tools supporting methodology execution (15 Python modules)

Per [tools/README.md](../../tools/README.md) the 15 Python tools at `$HOME/tools/` support methodology execution:

- `tools.cycle` orchestrates cycle status (active mode + stage + blockers + progress + lifecycle signals)
- `tools.tasks` parses backlog tasks; `active show / set / clear` manages cursor (SB-124d); `create under-epic / under-task / from-blocker` for E002 piling-tasks (DRAFT scaffolds)
- `tools.progress` refreshes `wiki/governance/progress.md` callout from live state
- `tools.decisions` manages logbook (40 entries D001-D040)
- `tools.blockers` surfaces operator-decision-pending in DECISION PACKAGE format (per SB-071)
- `tools.run-tests` is the **canonical verifier for `verified-edit` action type** (per Hard Rule 14 / M-E001-1 vocabulary type 2) — 22 test files / 403/403 aggregate (14 hook tests under `.claude/hooks/tests/` + 8 tool tests under `tools/tests/`; empirically verified 2026-07-03 via `HOME=<repo> python3 -m tools.run-tests` on the current `main` tree). The prior "14 files / 322/322" figure was never in committed history per `git ls-tree` — corrected per Hard Rule 15 empirical-count-verification.

## Cross-references

- Full engine reference: `<second-brain>/.claude/rules/methodology.md` (canonical, second brain)
- Engine: `$HOME/wiki/config/methodology.yaml` (this project's local copy)
- Adoption Guide: `<second-brain>/wiki/spine/references/adoption-guide.md`
- [`.claude/rules/README.md`](README.md) — 11 rules with strictness-tier matrix
- [`tools/README.md`](../../tools/README.md) — 15 tools supporting methodology execution
- [`.claude/commands/README.md`](../commands/README.md) — 30 slash commands (incl. /audit, /sync-progress, /decisions, /blockers, /progress, /handoff)
- `wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md` — sacrosanct verbatim directive governing this rule's edit pass
- `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md` — M-E001-1 productive-cycle action vocabulary (Hard Rule 14 — every cycle-fire emits one of 9 action types per stage's allowed outputs)
