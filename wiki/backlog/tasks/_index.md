---
title: "root-modules tasks"
type: index
status: active
created: 2026-05-04
updated: 2026-05-05
---

# Tasks — atomic work units across all modules

Naming: `T<NNN>-<slug>.md`. Sequence is per-project (T001 onwards). Per Adoption Guide: tasks are the atomic units that go through stages. Readiness flows up to module, module to epic.

Each task page has frontmatter (status, priority, parent_module, parent_epic, current_stage, readiness, sfif_stage, created/updated dates, sources, tags), Description (1+ paragraphs), Done When (atomic checkboxes), Dependencies, Relationships.

**Optional hierarchy fields (M-E002-2 schema extension, agent-DRAFT 2026-05-06 per Milestone v0.2 — gated on operator scope confirmation before tool wiring; existing tasks unchanged)**:

- `parent_task: T<NNN>-<slug>` — declares this task is a sub-task of another task (multi-level nesting per operator: *"task-sub-task"*)
- `parent_blocker: SB-<NNN>` or `parent_blocker: B<NNN>` — declares this task spawned from a blocker (per operator: *"task based on blockers"*)
- `parent_milestone: <slug>` — declares direct task→milestone laddering (rare; default ladder is parent_module → parent_epic → parent_milestone)

Schema-only at this point. No tools/commands consume them yet. Future task-creation verbs (M-E002-1) will populate them. See [Milestone v0.2](../milestones/v0.2-ai-natural-task-management.md) "Suggested evolution" section.

## Coverage by module (66 atomic tasks across 14 modules)

### Stream 2 — Pure SFIF Project Base

| Module | Range | Pages | Description |
|---|---|---|---|
| **M001 — CLAUDE.md + AGENTS.md** | T001-T006 | 6 | AGENTS.md scope + authoring; CLAUDE.md scope + authoring; operator review; prior-debris reconciliation |
| **M002 — Methodology layer decision** | T007-T010 | 4 | Trade-off decision (local copy chosen); CLAUDE.md methodology section; copy yamls; document decision |
| **M003 — Foundation hardening** | T011-T017 | 7 | Foundation IaC approach decision; install.sh; network bridge config; endpoint AI safety policy; post-install verification; idempotency invariants; foundation gate |
| **M004 — Infrastructure tooling** | T018-T023 | 6 | Verifier scope; verify-policy.py authoring; pipeline wiring (pre-commit/CI); smoke-test verifier; document in CLAUDE.md; M003 no-regression check |
| **M011 — ccstatusline custom widget** | T063-T066 | 4 | Per F-eval-6 (PRELIMINARY scaffold): wrapper invocation pattern; per-mode profile; widget set; deployment docs. Operator visually verified cycle 43. |
| **M012 — Vendor mapping + install + auto-detect** | (atomic pending) | 0 | Per F-eval-7 / D023: orthogonal axes (profile + mode); install.sh updated; atomic task pages pending operator. |
| **M013 — Agent modes architecture** | (atomic deferred) | 0 | Mostly Phase 1 implemented (3 modes + cycle skill + autopilot loop). Atomic tasks deferred per operator. |
| **M014 — luckyPipewrench/pipelock prelim** | (atomic gated on M007) | 0 | Per F-eval-7: preliminary scope complete; atomic tasks gated on M007 connect. |
| **M005 — First feature module** | T024-T030 | 7 | Operator picks Suricata/PolarProxy first; follow-up source-syntheses (done); test pcap; design doc; install integration; smoke-test; operator end-to-end validation |

### Stream 1 — Second-Brain Integration

| Module | Range | Pages | Description |
|---|---|---|---|
| **M006 — Pre-connect verification** | T031-T037 | 7 | AGENTS.md exists check; clean git state; capture pre-connect state; read setup.py collision behavior; dry-run from second brain; pre-connect snapshot; assemble audit log |
| **M007 — Connect to second brain** | T038-T043 | 6 | Read setup.py impl; verify type=root handling (done — patched); run --connect-project for real; inspect 4 artefacts; commit atomic; rollback policy on failure |
| **M008 — Smoke test from inside** | T044-T050 | 7 | Open fresh session; time-to-orient ≤ 60s; gateway orient; view spine; MCP tool; failure-mode test (brain unreachable); document M008 results |
| **M009 — Worked example** | T051-T056 | 6 | Reframe operator-decision; execute chosen flow demo; verify second brain knows root-modules (done); MCP sister-project tool; gateway timeline --scope; document proof |
| **M010 — auto_connect flip decision** | T057-T061 | 5 | Cooling-off period (≥1 week); operator decides flip; apply if yes; document if no; close SFIF rollout epic |

## Status snapshot

Live counts via `python3 -m tools.progress --json` (refresh on demand). As of 2026-05-06:

| Status | Count |
|---|---|
| `done` | 18 |
| `in-progress` | 7 |
| `pending-operator-decision` | 0 (decisions in sync per `tools.blockers --check`) |
| `not-started` | 41 |
| **Total** | **66** |

## Workflow

A future Claude Code session in $HOME picks up work as follows:

1. Read [CONTEXT.md](../../../CONTEXT.md) for current SFIF stage + active modules.
2. List `pending-operator-decision` tasks → if operator is available, surface them for decision.
3. List `not-started` tasks with no `BLOCKED BY` outstanding → claim one to work on.
4. Per task page's `Done When` checklist + methodology stage gate: complete the task; update status to `done` + readiness=100.
5. After multiple tasks complete, parent module's readiness flows up; when all parent module's tasks are done, module status → done.
6. When all modules of an epic are done, run [T061](T061-close-sfif-rollout-epic.md) to close the epic.

## Methodology

Each task respects the methodology engine: [`../../config/methodology.yaml`](../../config/methodology.yaml) + chosen profiles (simplified SDLC, infrastructure domain, stage-gated methodology). Stage boundaries (document → design → scaffold → implement → test) are hard. ALLOWED/FORBIDDEN per stage is enforced.

## Cross-references

- Active epic: [SFIF Rollout + Second-Brain Integration](../epics/sfif-rollout-and-second-brain-integration.md)
- All 14 module pages: [../modules/](../modules/)
- Operator log: [../../log/](../../log/)

## Cross-project tasks

Tasks added by sister projects via the cross-project channel (operator-granted). Triage these as you would any other task; move into module-scoped sections once accepted.

| Task | Title | Source | Added |
|---|---|---|---|
| T066 | Pre-publish readiness review + post-publish checkout workflow verification | from /opt second-brain | 2026-05-05 |
