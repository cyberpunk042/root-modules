# BOOTSTRAP.md — first-time-here cold-pickup guide

> One page. Get a fresh Claude Code session in `$HOME` from "barely started" to "ready to start operator-driven module work without crashing." Read this BEFORE acting. CLAUDE.md auto-loads; everything else is on-demand.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct)**: when refreshing BOOTSTRAP.md or any sister doc, **adding ≠ discarding**. Layer new content; refresh inline values where empirically drifted (with empirically-verified-YYYY-MM-DD timestamp); do NOT replace existing sections wholesale. Going-to-extremes (SB-082/093 family) recurs when an agent rewrites instead of revises. Sacrosanct: operator-verbatim quotes in Gotchas table (debian 13 · secure an OS · sacrosanct words · slash-vs-prose conflation) preserved EXACTLY.

## Summary

This is the canonical cold-pickup doctrine for fresh Claude Code sessions in `$HOME`. Read order: CLAUDE.md (auto-loaded) → AGENTS.md → CONTEXT.md → README.md → most-recent session log + brain-improvement mandate log → backlog/tasks/_index.md → governance docs. Architecture surfaces (8 mechanisms): 43 slash commands · 3 modes · 18 hook scripts (10 wired matchers across 8 events) · 3 brain-loaded sub-agents · 15 Python tools + MCP server (10 root_* tools) · 2 skills · 11 rules · governance (3 SRP docs + 138-row systemic-bugs tracker + 40 decisions logbook entries). 5 verify-state commands confirm methodology engine + second-brain reachability + identity profile. The **6 pending-operator-decision tasks** snapshot below is a historical reference; **canonical pending decisions live at [CONTEXT.md](CONTEXT.md) Operator-Pending Decisions table** (refreshed 2026-05-06 evening with 13 still-pending including new Epic-pending items SB-104/105/116/117/124b/c). Brain-improvement mandate first-pass (Phase 1 + Phase 2 partial) complete as of 2026-05-06 evening — see § Brain-improvement mandate progress below for what's done / what's pending operator yes-per-file.

## Operating doctrine — read this first

This project runs under **spec-driven development with strong methodology and standards** (operator directive 2026-05-05, verbatim *"we prone spec driven development and a strong methodology and standards"*). The repo carries the **spec**, not the realized state. `git clone` + `./install.sh` reconstitutes a working host from the spec; runtime state (vendor binaries, hydrated configs, logs, secrets) is regenerated per host, not transferred via git. Two install scopes (per `apply_profile()` in install.sh): `--profile {base|full}` for OS-root install (this dev host's mode), `--profile project --dest <path>` for per-project agent-brain install into a sister project (deploys hooks + commands + rules + agents + modes + skills + tools; disables OS-level ops). Operator-facing entry for project install: `/install-agent-brain <path>` slash command. Full SDD denotation in [README.md](README.md) "Spec-Driven Development" section + [AGENTS.md](AGENTS.md) "Operating Doctrine" section. This frames every action below.

## What this project IS (one sentence)

`root-modules` (renamed from `root-ghostproxy` 2026-07-19 — *"at first and by default a root or home folder upgrader, evolver and secondly you can install supplementary modules like the ghostproxy combo"*, operator verbatim) is the system-AI-safety-setup project at the OS root level: first and by default it upgrades/evolves a root or home folder — secures a Debian 13 host AND configures Claude Code + opencode at root — and secondly it can install supplementary modules like the **ghostproxy combo**: a transparent L2 IPS bridge (Suricata + PolarProxy as facultative modules) between the OPNsense edge and the LAN switch. **type=root, group=operating-system-setup** — scope, not path. Identity is canonical at `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` (second-brain path retains the pre-rename key until renamed there).

## Read order (cold pickup, ~10 minutes)

1. [CLAUDE.md](CLAUDE.md) — auto-loaded. Routing + 15 Hard Rules (incl. Hard Rules 11-15 added 2026-05-06: additive≠discarding · brain-inheritance · chain-operations · productive-cycle taxonomy · empirical-count-verification) + methodology pointer.
2. [AGENTS.md](AGENTS.md) — cross-tool agent contract. Canonical tool-call envelope, no-policy-duplication invariant, hook firing order, 15 universal Hard Rules.
3. [CONTEXT.md](CONTEXT.md) — current SFIF stage, **Active Objective Layer (mission/focus/impediment/priorities/task — SB-118 + SB-127 + SB-124d state files)**, **active milestone v0.2 + 4 epics + 14 modules + 66 atomic tasks** (4-level hierarchy introduced 2026-05-06), verbatim operator directives, pending operator decisions (canonical — 13 still-pending), prioritized next-best moves.
4. [README.md](README.md) — project description, two-capability architecture, principles, ecosystem position. Read for orientation, not action.
5. **[wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)** — sacrosanct verbatim brain-improvement directive 2026-05-06 governing the per-file yes-protocol passes on the brain layer. Read for current iteration framing.
6. **[wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md)** — M-E001-1 productive-cycle action vocabulary DRAFT v2 (9 canonical action types every cycle-fire emits per Hard Rule 14).
7. [wiki/log/2026-05-05-session-architecture-modes-and-determinism-ladder.md](wiki/log/2026-05-05-session-architecture-modes-and-determinism-ladder.md) — comprehensive session log; 6 phases of architecture work; 5 high-leverage knowledge insights.
8. [wiki/backlog/tasks/_index.md](wiki/backlog/tasks/_index.md) — 66 atomic tasks across 14 modules, status snapshot.
9. [wiki/governance/blockers.md](wiki/governance/blockers.md) | [progress.md](wiki/governance/progress.md) | [decisions.md](wiki/governance/decisions.md) | [systemic-bugs.md](wiki/governance/systemic-bugs.md) — operator-facing blockers register + journey view + 40-entry decisions logbook (D001-D040) + 138-row systemic-bugs tracker.

**Subdirectory READMEs** (DRAFT v1, agent-authored 2026-05-06 evening) — canonical-extension navigation aids:
- [tools/README.md](tools/README.md) — 15 Python tools + composition map
- [.claude/commands/README.md](.claude/commands/README.md) — 43 slash commands by category
- [.claude/hooks/README.md](.claude/hooks/README.md) — 18 hook scripts (10 wired + archive) by event
- [.claude/modes/README.md](.claude/modes/README.md) · [.claude/rules/README.md](.claude/rules/README.md) · [.claude/agents/README.md](.claude/agents/README.md) · [.claude/skills/README.md](.claude/skills/README.md) · [templates/README.md](templates/README.md) · [scripts/README.md](scripts/README.md)

Read [ARCHITECTURE.md](ARCHITECTURE.md), [DESIGN.md](DESIGN.md), [TOOLS.md](TOOLS.md), [SKILLS.md](SKILLS.md), [SECURITY.md](SECURITY.md) on demand when work touches their topic.

**Better — invoke `/orient` once.** It deterministically chains the 21-step intel-gathering load (Read brain + verify state + detect mode + emit ORIENT REPORT). 100% per invocation. The SessionStart hook will direct you to it on every fresh session.

Rules (loaded on demand from `$HOME/.claude/rules/`):
- [routing.md](.claude/rules/routing.md) — operator-intent → tool routing for this project
- [methodology.md](.claude/rules/methodology.md) — engine pointer + 5 stages with project-specific gates
- [hook-architecture.md](.claude/rules/hook-architecture.md) — 2-layer hook design + the 14 wired machine-level hook fires across 8 events
- [work-mode.md](.claude/rules/work-mode.md) — solo session pattern + PO approval boundary + status-claim discipline
- [self-reference.md](.claude/rules/self-reference.md) — what $HOME IS + how it relates to the second brain
- [words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) — verbatim quoting rule (operator's own statement)

## Architecture surfaces (the agent layer)

| Surface | Path | Determinism | Purpose |
|---|---|---|---|
| **Slash commands** (**30**) | `.claude/commands/*.md` | 100% on invoke | Operator-driven workflows. `/orient`, `/cycle`, `/mode-{pm,architect,dual,status,clear}`, `/blockers`, `/progress`, `/decisions`, `/log`, `/audit`, `/sync-progress`, `/help-root`, `/handoff`, `/stamp-{horizontal,vertical,on,off,auto,status}` (SB-115 stamp config), `/install-agent-brain`, `/mission`, `/focus`, `/impediment` (SB-118 objective layer), `/priorities` (SB-127 imminent-work hot-queue), `/terminate`, `/finish-smoothly` (session-termination prep), `/task` (**SB-124d active-task cursor + create verbs**), `/questions` (**SB-134 agent-pending Q retention layer**). Per-category index at [.claude/commands/README.md](.claude/commands/README.md). |
| **Modes** (3) | `.claude/modes/*.md` | Operator-enabled persona overlay | PM Scrum Master / DevOps Architect / Dual Expert. Combine with `/loop /cycle` for autopilot. Mode-entry is operator-choice; agent surfaces the option, never auto-enables. Per-mode index + cycle-sequence comparison at [.claude/modes/README.md](.claude/modes/README.md). |
| **Hooks** (**10 wired matchers across 8 events; 17 .sh + 1 .py on disk**) | `.claude/hooks/*.{sh,py}` | ~85% (`additionalContext` JSON; **PreCompact/PostCompact use top-level `systemMessage` per SB-133 envelope fix**) | PreToolUse (3: policy-block, malware-block, opt-write-block) + PostToolUse (1: leak-detector) + SessionStart (2: session-start, session-orient) + UserPromptSubmit (**4-hook compound stack per SB-126**: context-warning, output-discipline-guard with 3 detectors per SB-090/094/120, mode-enforcement per SB-056/117/118/127/129, mindfulness per SB-126/128/131) + PreCompact (1: writes handoff doc) + PostCompact (1: directs /orient + references handoff) + Stop (1: end-of-cycle-stamp per SB-114/115/116-Epic) + SessionEnd (1: summary). Archived hooks (premise-guard / deny-secret-files / stamp-control / integrity.py-not-yet-wired) retained per operator directive 2026-05-06. Regression tests at `.claude/hooks/tests/*.py` + `tools/tests/*.py` (**13 test files / 215/234 aggregate** via `python3 -m tools.run-tests` — 3 partial-fail surfaced for operator-decision: test-mode-enforcement.py 0/0 collection regression, test-end-of-cycle-stamp-diff-suppression.py 21/22, test-questions.py 33/51). Per-hook inventory + WIRED-vs-ARCHIVE labels at [.claude/hooks/README.md](.claude/hooks/README.md). |
| **Sub-agents** (3 brain-loaded) | `.claude/agents/*.md` | Brain-loaded on spawn (project-specific per SB-081) | `root-explorer` (research), `root-architect` (design lens), `root-pm-scoper` (PM scoping) — each starts with mandatory "load brain first" prompts naming CLAUDE.md / rules / state files. Custom subagents NOT discovered until session restart (cycle 47 finding). Per-agent index at [.claude/agents/README.md](.claude/agents/README.md). |
| **Tools** (**15 .py modules + MCP server**) | `tools/*.py` | 100% deterministic non-LLM | `state.py`, `blockers.py`, `progress.py`, `decisions.py` (40 entries D001-D040), `cycle.py`, `tasks.py` (active-task cursor SB-124d + M-E002-1 create verbs), `stamp.py` (SB-115), `objective.py` (SB-118), `priorities.py` (SB-127), `questions.py` (SB-134), `group.py` (Q1 Layer A — chain/group/tree primitive), `run-tests.py` (unified regression runner) — invoked by commands; also exposed via `tools/mcp_server.py` (FastMCP, **10 root_* tools** incl. root_state, root_blockers, root_progress, root_decisions_*, root_objective, root_questions, root_orient) for MCP-aware consumers. Per-tool index at [tools/README.md](tools/README.md). |
| **Skills** (2) | `.claude/skills/<name>/SKILL.md` | ~70-95% description-match auto-trigger | `surface-state` + `surface-blockers` — handle natural-prose equivalents of `/orient` + `/blockers`. Per-skill index at [.claude/skills/README.md](.claude/skills/README.md). |
| **Governance** (3 SRP docs + tracker) | `wiki/governance/*.md` | Read-only views | Operator-facing perspective layer. `blockers.md` + `progress.md` + `decisions.md` (40 entries) + **`systemic-bugs.md` (138-row tracker; max ID SB-138)**. Refresh via `/sync-progress` + `/decisions append`. |
| **Rules files** (11) | `.claude/rules/*.md` | Load-on-demand | Topic-specific guidance. Includes `trigger-model.md` (unified signal→action→recovery model across all 8 mechanism types) + `compound-and-waterfall.md` (SB-123: two-axes design pattern — compound = additive layering at-a-moment; waterfall = sequential cascade event-to-event). Per-rule index + strictness-tier matrix at [.claude/rules/README.md](.claude/rules/README.md). |

## Verify state (commands to run before first work action)

```bash
# 1. confirm methodology engine present + parses
for f in $HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml; do
  <second-brain>/.venv/bin/python -c "import yaml,sys; yaml.safe_load(open('$f')); print('OK $f')"
done

# 2. confirm second-brain reachable
ls <second-brain>/wiki/spine/references/adoption-guide.md

# 3. confirm root-modules registered with second brain
grep -A2 "^  root-modules:" <second-brain>/wiki/config/sister-projects.yaml

# 4. confirm identity profile resolves
ls <second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md

# 5. confirm second-brain agent can orient as sister project
cd <second-brain>/ && \
  <second-brain>/.venv/bin/python -m tools.gateway orient --orient-as sister
```

All five must succeed. If any fail, the session is not in expected state — read the prep log (step 5 of read-order above) before proceeding.

> **Gateway invocation gotcha**: `tools.gateway` lives at `<second-brain>/tools/`. Running `python -m tools.gateway` from `$HOME/` cwd fails with `ModuleNotFoundError`. Always `cd <second-brain>/` first or use `PYTHONPATH=<second-brain>/`. `--orient-as` accepts only `second-brain` / `sister` / `external` — NOT project names.

## Pick a task (workflow)

1. Open [wiki/backlog/tasks/_index.md](wiki/backlog/tasks/_index.md). Find the module the operator points at (or active modules per CONTEXT.md).
2. List `pending-operator-decision` tasks → if operator is available, surface them. **Do not decide them yourself.**
3. List `not-started` tasks with no `BLOCKED BY` outstanding → claim one.
4. Per task page's Done When checklist + the methodology stage gate: complete the task; update status to `done`, readiness=100.
5. After multiple tasks complete, parent module's readiness flows up.

### Honest reality: most not-started tasks have implicit prerequisites

As of 2026-05-06, the 42 not-started tasks have implicit gates beyond just `BLOCKED BY` cross-references:

| Module | Not-started tasks | Implicit gate |
|---|---|---|
| M003 (Foundation) | 6 | Operator decides T011 (greenfield vs extend) first |
| M004 (Infra tooling) | 5 | Operator approves T018 (verifier scope) first |
| M005 (First feature) | 5 | Operator picks T024 (Suricata vs PolarProxy first) first |
| M006 (Pre-connect) | 5 | `$HOME` must be git-init'd (operator T006-territory) |
| M007 (Connect) | 4 | M006 done first |
| M008 (Smoke) | 7 | M007 done first |
| M009 (Worked example) | 4 | Operator decides T051 (reframe) first |
| M010 (auto_connect flip) | 4 | Cooling-off period (≥1 week post-M009) + T058 decision |

**There are no tasks a fresh session can claim unilaterally without operator input.** This is BY DESIGN — the SFIF rollout is operator-supervised. The workflow at this point is: surface the 6 pending decisions, await operator direction, then claim a task.

### The 6 pending-operator-decision tasks (historical snapshot — see CONTEXT.md for current canonical)

> **Historical snapshot** as of 2026-05-05; preserved for posterity. **Canonical pending decisions** live at [CONTEXT.md](CONTEXT.md) Operator-Pending Decisions table (refreshed 2026-05-06 evening with 13 still-pending). D019 (greenfield foundation IaC), D020 (LEAVE-IN-PLACE prior debris), D022/D023/D024 (T012/T013/T014 install.sh GREENLIT) closed several originals. New Epic-pending items added: SB-104/105 line-1 widget shape · SB-116 stamp UX redesign Epic · SB-117 mode-enforcement deeper Epic · SB-124b/c statusline + profile-variants. **Read CONTEXT.md first** for current state; this table below is the as-of-2026-05-05 snapshot.

| ID | Priority | What operator decides | 2026-05-06 status |
|---|---|---|---|
| [T006](wiki/backlog/tasks/T006-prior-debris-reconciliation.md) | P1 | Reconciliation policy for prior $HOME debris (delete / leave / partial preserve) | **DECIDED** D020 (LEAVE-IN-PLACE) |
| [T011](wiki/backlog/tasks/T011-foundation-iac-authoring-approach.md) | P0 | Foundation IaC approach (greenfield vs extend prior debris) | **DECIDED** D019 (GREENFIELD) |
| [T018](wiki/backlog/tasks/T018-operator-approve-verifier-scope.md) | P0 | Verifier scope (which checks, which strictness) | Still pending (M004 verifier-policy work) |
| [T024](wiki/backlog/tasks/T024-operator-picks-first-module.md) | P0 | First feature module (Suricata-first vs PolarProxy-first) | Still pending (M005 operator-driven future-session) |
| [T051](wiki/backlog/tasks/T051-reframe-m009-bidirectional-flow-already-proven.md) | P1 | M009 reframe (bidirectional flow already partially proven) | Still pending (M009) |
| [T058](wiki/backlog/tasks/T058-operator-decides-auto-connect.md) | P2 | auto_connect for sister-projects.yaml (status quo false vs flip true) | Still pending (M010 — after M009 stability) |

## Methodology engine (where to look)

| File | Purpose |
|---|---|
| [wiki/config/methodology.yaml](wiki/config/methodology.yaml) | 9 models, 5 stages, ALLOWED/FORBIDDEN per stage, gates |
| [wiki/config/sdlc-profile.yaml](wiki/config/sdlc-profile.yaml) | simplified (right-sized for micro scale + solo) |
| [wiki/config/domain-profile.yaml](wiki/config/domain-profile.yaml) | infrastructure (gate commands + path patterns) |
| [wiki/config/methodology-profile.yaml](wiki/config/methodology-profile.yaml) | stage-gated (hard ALLOWED/FORBIDDEN boundaries) |

Stage boundaries are hard. Document → design → scaffold → implement → test. Don't ship implementation in a Document task; don't ship tests as features. The profile name `stage-gated` is enforcement, not advisory.

## Second-brain integration (the path back to /opt)

The second brain at `<second-brain>/` holds the canonical identity profile, source-syntheses (Suricata + PolarProxy), super-model, methodology engine, and 16 named models. This project consumes from it; this project contributes back via `gateway contribute`.

- Sister-projects.yaml entry: `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-ghostproxy` (type=root, group=operating-system-setup, auto_connect=false). `auto_connect=false` is intentional friction — type=root projects gate the security envelope, so connection is explicit.
- Adoption Guide: `<second-brain>/wiki/spine/references/adoption-guide.md`. Read it when designing how a methodology layer is rolled into this project.

## Gotchas (will save 30 minutes each)

| Gotcha | Reality |
|---|---|
| **memory folder** | The `~/.claude/memory/` folder is debris from prior session conflation. The operator never directed its use. Don't read from it; don't write to it. |
| **type=root scope-not-path** | The project is type=root regardless of which user installs it. A future jfortin install does not change the project's identity. |
| **prior project debris** | Anything under `$HOME/` not listed in this BOOTSTRAP / brain-file set may be AI debris from a prior aborted session. Don't draw project framing from it. Draw from the verbatim operator directives in `<second-brain>/raw/notes/2026-05-04-*.md`. |
| **Debian 13 reference** | Operator's verbatim *"new machine (non-GUI) debian 13"* is canonical. Don't strip it. |
| **endpoint AI agent safety is in scope** | Operator's verbatim *"secure an OS AND configure claude code and opencode at the root"* — both halves. Don't mark it out-of-scope. |
| **`auto_connect: false` is intentional** | Status quo until operator explicitly flips. Don't propose flip without M010 process. |
| **system python lacks deps** | Use `<second-brain>/.venv/bin/python` for any `tools.*` or YAML loading. System `python3` lacks `yaml` + `youtube-transcript-api`. |
| **slash vs prose conflation** | `/checkin` (slash, literal) → diagnostic; bare `continue` / `resume` → trajectory-continue, no new tool calls. Same pattern for `/distill` vs `evolve`. See `<second-brain>/raw/notes/2026-05-04-rename-continue-conflation-bug-and-similar-conflations.md`. |
| **operator words are sacrosanct** | Quote verbatim. Never paraphrase. Never compress. A question is not a decision. Conversation about a target is not a reject. CLAUDE.md Hard Rule 4. |
| **`$HOME/.gitignore` deny-all + whitelist** | The `.gitignore` is a deny-all (`/*` + `/.*`) with explicit whitelist. As of 2026-05-06 (post install-readiness audit) it whitelists: top-level `README.md`, `LICENSE`, `install.sh`, `uninstall.sh`, `.gitignore`, `.claudeignore`, `.mcp.json`, `open-interfaces.template`, brain files (CLAUDE.md, AGENTS.md, CONTEXT.md, BOOTSTRAP.md, ARCHITECTURE.md, DESIGN.md, TOOLS.md, SKILLS.md, SECURITY.md); `.claude/settings.json` + `.claude/hooks/*.{sh,py}` + `.claude/hooks/tests/*.py`; agent brain dirs (`.claude/{rules,commands,agents,modes}/*.md` + `.claude/skills/*/SKILL.md`); `.config/opencode/{opencode.json, plugin/*.{ts,json,md}}`; entire `wiki/` tree (`config/*.{yaml,md}`, `backlog/{epics,modules,tasks}/*.md`, `log/*.md`); `docs/*.md`; `scripts/{*.sh, README.md, lib/*.sh}`; `tools/*.py`; `templates/*` (per-subdir whitelist for ccstatusline-config + ccstatusline-widgets + systemd-networkd + nftables + wpa_supplicant). `settings.local.json` correctly stays gitignored (per-machine override). |
| **`$HOME/.claude/hooks/*.sh` are Python** | The **17 `.sh` + 1 `.py` files** at `$HOME/.claude/hooks/` are actually Python scripts (`#!/usr/bin/env python3` shebang). Extension is misleading — all run as Python. Currently **10 wired matchers across 8 events** (per `.claude/settings.json`); 4 archived hooks retained per operator directive 2026-05-06: *"label them as archive if they are not usefull anymore. dont necessarily delete them."* — premise-guard.sh / deny-secret-files.sh / stamp-control.sh / integrity.py-not-yet-wired. Per-hook inventory + WIRED-vs-ARCHIVE labels at [.claude/hooks/README.md](.claude/hooks/README.md). |
| **machine-level vs project-level hooks** | Per AGENTS.md two-layer hook architecture: `$HOME/.claude/hooks/` is machine-level (root user envelope); a future `$HOME/$HOME/.claude/hooks/` would be project-level. Machine-level fires first. Currently only machine-level exists. **Path-A collision admonition** (per SB-087): for type=root projects where `$HOME` IS the project root, machine-level and project-level layer paths COINCIDE at file-system level; hooks self-gate via `CLAUDE_PROJECT_DIR` (or cwd fallback) to distinguish "fired in root-modules session" vs "fired in sister-project session opened on this host". |
| **Hard Rules 11-15 (added 2026-05-06)** | Five new universal Hard Rules in CLAUDE.md + AGENTS.md: **Rule 11** additive ≠ discarding (going-to-extremes recurs when agent rewrites instead of revises) · **Rule 12** brain-inheritance pattern ($HOME source-of-truth for operational tooling; /opt second-brain INHERITS / adapts; knowledge flows OTHER direction via gateway contribute) · **Rule 13** chain operations per fire (single-edit-per-cycle is THIN-output anti-pattern) · **Rule 14** productive cycle taxonomy (each cycle MUST emit one of 9 M-E001-1 action types; mandatory cycle-report last-line `Productive output: <type> — <one-line specific>`) · **Rule 15** empirical-count-verification before drift-claim (run programmatic walk + parse before refreshing counts in any brain file). |
| **M-E001-1 productive-cycle action vocabulary** | Per Hard Rule 14 + canonical doc at [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md): each cycle-fire emits one of 9 action types — sb-closure / verified-edit / drift-fix-with-empirical / explicit-standby-with-named-reason / new-artifact / doc-refresh / blocker-surface / operator-directive-register / read-only-audit. THIN standby without named subject is the SB-128 bug. |
| **Active Objective Layer** (SB-118 + SB-127 + SB-124d) | Multi-cycle objective state files at `$HOME/.claude/active-{mission,focus,impediment,priorities,task}` — read by mode-enforcement.sh (banner) + cycle.py (stamp) + mcp_server.py (root_objective MCP tool) + /handoff (handoff doc) + pre-compact.sh (handoff snapshot). Operator-set via `/mission` / `/focus` / `/impediment` / `/priorities` / `/task` slash commands. CONTEXT.md surfaces these inline in its Active Objective Layer section. |

## Pickup-cold runbook (TL;DR for the impatient)

1. `cat $HOME/CLAUDE.md $HOME/CONTEXT.md` → loaded.
2. `cat $HOME/wiki/log/2026-05-05-preparation-session-foundation-scaffolding.md` → know what happened before you.
3. `cat $HOME/wiki/backlog/tasks/_index.md` → know what's next.
4. Run the 4 verification commands above → confirm state.
5. Ask operator which module to work on, or surface the 6 pending-operator-decision tasks.
6. Claim one not-started task; work it per Done When checklist + methodology stage gate.

You are now ready.

## Install wizard (operator-facing)

For a fresh-machine or operator-driven install: `$HOME/install.sh --wizard` prints a state-aware "where you are + what to do next" report. Detects route (curl-bootstrap / post-clone / partial-install / drift / maintenance) + offers prioritized next-best-actions. Safe to run from any state — read-only, no install action. Granular group-level selection via `--with-group <name>` / `--no-group <name>` flags composes with `--profile`. See `install.sh --help` for the full flag/profile/example matrix.

## Brain-improvement mandate progress (2026-05-06 evening — fresh-pickup awareness)

Per operator directive 2026-05-06 (sacrosanct verbatim at [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)): *"you are going to be the one from the external that update the brain of the root project. Claude.md + Agents, and Context and Tools and Skills and Rules and Hooks and every inner piece..."*. The brain layer has been progressively quality-passed via per-file yes-protocol (operator says yes per file with "do not minimize" framing). **Fresh-pickup agent**: the docs you're reading have been refreshed to current empirical state on these dates — read the most-current versions:

| Layer | Files passed | Status |
|---|---|---|
| **Phase 1 — README pass** | README.md (1085 lines) + scripts/README.md (365 lines) + 8 NEW sub-READMEs (tools/ + .claude/{commands,hooks,modes,rules,agents,skills}/ + templates/ — 2559 lines total) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 1 — CLAUDE.md** | 260 lines (+52 additive: doc-update-discipline admonition + Hard Rules 11-15 + 9 sub-README rows + agent-learning section) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 2 — AGENTS.md** | 247 lines (+55 additive: cross-tool universal framing + Hard Rules 11-15 universal + Path-A collision admonition + agent-learning section) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 3 — CONTEXT.md** | 355 lines (+159 additive: Active Objective Layer section + milestone v0.2 + 4 epics structure + Operator-Pending Decisions refactor + Recent Operator Directives append + Recent Work Completed append + agent-learning section) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 4 — TOOLS.md** | 671 lines (+216 additive: Inventory + Currently Available count refresh + 3 section reconciliations + Implemented Python Tools consolidated section + Operator-Intent table expansion + agent-learning section) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 5 — SKILLS.md** | 291 lines (+122 additive: intro framing refresh + 4-mechanism table refresh + Mode-enforcement-vs-Skill section + Cross-tool universal framing + agent-learning section) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 6 — Rules category** | 10 active rules + README.md = 1641 lines (+164 additive across 10 active rules; routing.md MAJOR refresh; Hard Rules 11-15 mapping table in operating-principles.md) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 7 — Hooks category** | 18 hook scripts = 4198 lines (+299 additive comments/docstrings/cross-refs/archive-labels; **NO LOGIC CHANGES**; 3 partial-fail tests surfaced) | ✓ COMPLETE 2026-05-06 evening |
| **Phase 2 file 8 — BOOTSTRAP.md (this file)** | full pass executing now | ✓ in-flight |
| **Phase 2 pending — operator yes-per-file** | ARCHITECTURE.md · DESIGN.md · SECURITY.md (3 top-level docs) + .claude/commands/*.md (43 slash commands) + .claude/modes/*.md (3 modes) + .claude/agents/*.md (3 sub-agents) + .claude/skills/*/SKILL.md (2 skills) + tools/*.py module docstrings (15 tools) | awaiting operator's individual yes per file/category |

**Sub-READMEs are DRAFT v1, agent-authored 2026-05-06 evening per SB-095** (flagged in frontmatter). Operator promotes to `status: active` after fresh-pickup-agent navigability review.

## Agent personal-learning notes (operator-allowed, per directive 2026-05-06)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. Entries are **agent-authored** (per SB-095 — agent-DRAFT, not operator-stated). Operator may revise / promote / remove. Each timestamped + initialed `[agent]`. BOOTSTRAP.md-specific framing — cold-pickup-doctrine lessons.

### 2026-05-06 evening — BOOTSTRAP.md is the cold-pickup operating manual

`[agent]` BOOTSTRAP.md is auto-loaded along with CLAUDE.md/AGENTS.md per Claude Code convention. Fresh sessions read it within the first turn. That makes it THE cold-pickup doctrine — sequential discoverability matters. The Read order section is the canonical sequence; never restructure (only ADD entries). The Pickup-cold runbook (TL;DR) at the bottom is for impatient operators — keep concise; don't bloat with comprehensive content (that's what the body is for).

### 2026-05-06 evening — Architecture surfaces table is the reference cheatsheet

`[agent]` The Architecture surfaces table (Surface / Path / Determinism / Purpose) is what cold-pickup agents reach for to know "what mechanisms exist + how do I use them?". Counts in this table drift quickly; refresh inline values per Hard Rule 15 (empirical-count-verification before drift-claim). When a new mechanism surfaces (sub-READMEs, MCP server, archive pattern, productive-cycle vocabulary), ADD a column or row entry rather than restructure.

### 2026-05-06 evening — Sub-READMEs as canonical-extension navigation aids

`[agent]` Phase 1 of brain-improvement mandate authored 9 sub-READMEs (DRAFT v1 — wiki-schema 9-field compliant + Summary + Relationships sections). These become the canonical per-mechanism index for fresh-pickup navigation. BOOTSTRAP.md should reference them prominently in the Read order + Architecture surfaces table — they give cold-pickup agents the depth dive without bloating BOOTSTRAP.md itself. Pattern: top-level brain file references sub-README; sub-README references back to top-level brain file. Bidirectional.

### 2026-05-06 evening — Historical snapshot vs canonical-current

`[agent]` The 6 pending-operator-decision tasks table at lines 99-108 is a historical snapshot from 2026-05-05; superseded by CONTEXT.md's refactored Operator-Pending Decisions table (13 still-pending). Discipline: when a doc has historical-snapshot tables that drift, do NOT delete the snapshot (operators value provenance) — ADD a "see CONTEXT.md for canonical current state" pointer at the top + per-row "DECIDED Dnnn" or "Still pending" annotations. This preserves provenance while pointing at fresh truth. Same pattern applied to Recent Work Completed in CONTEXT.md (append-only) — historical accuracy is value-add, not waste.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). Not sub-READMEs (per-mechanism canonical indexes). For BOOTSTRAP.md-specific cold-pickup-doctrine lessons that benefit fresh-pickup agents but are too small to warrant their own rule file. Operator promotes to structured artifact when pattern matures.

## Cross-References

### Top-level brain files (10)

| For… | Read |
|---|---|
| Project description + identity + modules + status | [README.md](README.md) |
| Universal cross-tool agent rules + 15 universal Hard Rules | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing + 15 Hard Rules | [CLAUDE.md](CLAUDE.md) |
| Current operational state (Active Objective Layer + SFIF + pending decisions) | [CONTEXT.md](CONTEXT.md) |
| System architecture in depth | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Design pattern rationale | [DESIGN.md](DESIGN.md) |
| Tool reference (operator-facing) | [TOOLS.md](TOOLS.md) |
| Skills directory context | [SKILLS.md](SKILLS.md) |
| Security policy | [SECURITY.md](SECURITY.md) |

### Subdirectory READMEs (9 — DRAFT v1, agent-authored 2026-05-06 evening)

| For… | Read |
|---|---|
| 15 Python tools + composition map | [tools/README.md](tools/README.md) |
| 43 slash commands by category | [.claude/commands/README.md](.claude/commands/README.md) |
| 18 hook scripts (10 wired + archive) by event | [.claude/hooks/README.md](.claude/hooks/README.md) |
| 3 modes + cycle-sequence comparison | [.claude/modes/README.md](.claude/modes/README.md) |
| 11 rules + strictness-tier matrix | [.claude/rules/README.md](.claude/rules/README.md) |
| 3 brain-loaded sub-agents | [.claude/agents/README.md](.claude/agents/README.md) |
| 2 skills + mechanism-choice context | [.claude/skills/README.md](.claude/skills/README.md) |
| 5 install template categories | [templates/README.md](templates/README.md) |
| Deployment + maintenance toolkit | [scripts/README.md](scripts/README.md) |

### Backlog + governance + log

| For… | Read |
|---|---|
| 4-level backlog hierarchy (Milestone → Epic → Module → Task) | [wiki/backlog/](wiki/backlog/) |
| 40-entry decisions logbook (D001-D040) | [wiki/governance/decisions.md](wiki/governance/decisions.md) |
| 138-row systemic-bugs tracker | [wiki/governance/systemic-bugs.md](wiki/governance/systemic-bugs.md) |
| Operator-decision-pending blockers register | [wiki/governance/blockers.md](wiki/governance/blockers.md) |
| Live-state callout | [wiki/governance/progress.md](wiki/governance/progress.md) |
| Operator directives + session logs | [wiki/log/](wiki/log/) |

### Universal cross-cutting rules

| For… | Read |
|---|---|
| Unified 8-mechanism signal→action→recovery model | [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) |
| Compound + waterfall axes (additive layering + sequential cascade) | [.claude/rules/compound-and-waterfall.md](.claude/rules/compound-and-waterfall.md) |
| Context-engineering (auto/pre/on-demand/facultative injection) | [.claude/rules/context-engineering.md](.claude/rules/context-engineering.md) |
| Operating principles (4 core + 11 extension + Hard Rules 11-15 mapping) | [.claude/rules/operating-principles.md](.claude/rules/operating-principles.md) |
| Operator-words sacrosanct + premise-confirmation gate + conditional-clause grammar | [.claude/rules/words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) |
| Hook architecture (2-layer + 3-component design pattern) | [.claude/rules/hook-architecture.md](.claude/rules/hook-architecture.md) |

### Brain-improvement mandate (this work block — 2026-05-06)

| For… | Read |
|---|---|
| Sacrosanct verbatim directive governing the brain-quality passes | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| M-E001-1 productive-cycle action vocabulary DRAFT v2 (9 types) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |
| Decision package log (RESOLVED — sub-READMEs scope) | [wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md](wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md) |

### Second brain (canonical sources)

| For… | Read |
|---|---|
| Identity profile (canonical Goldilocks 9-dim) | `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` |
| Sister-projects.yaml entry | `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-ghostproxy` |
| Suricata + PolarProxy source-syntheses | `<second-brain>/wiki/sources/src-{suricata*,polarproxy,hanke-honeypot-polarproxy-suricata-integration}.md` |
| Adoption Guide | `<second-brain>/wiki/spine/references/adoption-guide.md` |
| Wiki-schema (9 required fields + per-type required sections) | `<second-brain>/wiki/config/wiki-schema.yaml` |
| Operator-verbatim historical reference | `<second-brain>/raw/notes/2026-05-04-*.md` (sacrosanct, primary source for project intent) |
