# BOOTSTRAP.md — first-time-here cold-pickup guide

> One page. Get a fresh Claude Code session in `/root` from "barely started" to "ready to start operator-driven module work without crashing." Read this BEFORE acting. CLAUDE.md auto-loads; everything else is on-demand.

## Operating doctrine — read this first

This project runs under **spec-driven development with strong methodology and standards** (operator directive 2026-05-05, verbatim *"we prone spec driven development and a strong methodology and standards"*). The repo carries the **spec**, not the realized state. `git clone` + `./install.sh` reconstitutes a working host from the spec; runtime state (vendor binaries, hydrated configs, logs, secrets) is regenerated per host, not transferred via git. Two install scopes (per `apply_profile()` in install.sh): `--profile {base|full}` for OS-root install (this dev host's mode), `--profile project --dest <path>` for per-project agent-brain install into a sister project (deploys hooks + commands + rules + agents + modes + skills + tools; disables OS-level ops). Operator-facing entry for project install: `/install-agent-brain <path>` slash command. Full SDD denotation in [README.md](README.md) "Spec-Driven Development" section + [AGENTS.md](AGENTS.md) "Operating Doctrine" section. This frames every action below.

## What this project IS (one sentence)

`root-ghostproxy` is the system-AI-safety-setup project at the OS root level: it secures a Debian 13 host AND configures Claude Code + opencode at root, AND runs a transparent L2 IPS bridge (Suricata + PolarProxy as facultative modules) between the OPNsense edge and the LAN switch. **type=root, group=operating-system-setup** — scope, not path. Identity is canonical at `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md`.

## Read order (cold pickup, ~10 minutes)

1. [CLAUDE.md](CLAUDE.md) — auto-loaded. Routing + hard rules + methodology pointer.
2. [AGENTS.md](AGENTS.md) — cross-tool agent contract. Canonical tool-call envelope, no-policy-duplication invariant, hook firing order.
3. [CONTEXT.md](CONTEXT.md) — current SFIF stage, active epic + 13 modules, verbatim operator directives, 6 pending operator decisions, prioritized next-best moves.
4. [README.md](README.md) — project description, two-capability architecture, principles, ecosystem position. Read for orientation, not action.
5. [wiki/log/2026-05-05-session-architecture-modes-and-determinism-ladder.md](wiki/log/2026-05-05-session-architecture-modes-and-determinism-ladder.md) — comprehensive session log; 6 phases of architecture work; 5 high-leverage knowledge insights.
6. [wiki/backlog/tasks/_index.md](wiki/backlog/tasks/_index.md) — 61 atomic tasks across 13 modules, status snapshot.
7. [wiki/governance/blockers.md](wiki/governance/blockers.md) | [progress.md](wiki/governance/progress.md) | [decisions.md](wiki/governance/decisions.md) — operator-facing blockers register + journey view + decisions logbook (SRP-separated; 594 lines combined).

Read [ARCHITECTURE.md](ARCHITECTURE.md), [DESIGN.md](DESIGN.md), [TOOLS.md](TOOLS.md), [SKILLS.md](SKILLS.md), [SECURITY.md](SECURITY.md) on demand when work touches their topic.

**Better — invoke `/orient` once.** It deterministically chains the 21-step intel-gathering load (Read brain + verify state + detect mode + emit ORIENT REPORT). 100% per invocation. The SessionStart hook will direct you to it on every fresh session.

Rules (loaded on demand from `$HOME/.claude/rules/`):
- [routing.md](.claude/rules/routing.md) — operator-intent → tool routing for this project
- [methodology.md](.claude/rules/methodology.md) — engine pointer + 5 stages with project-specific gates
- [hook-architecture.md](.claude/rules/hook-architecture.md) — 2-layer hook design + the 7 wired machine-level hook events
- [work-mode.md](.claude/rules/work-mode.md) — solo session pattern + PO approval boundary + status-claim discipline
- [self-reference.md](.claude/rules/self-reference.md) — what /root IS + how it relates to the second brain
- [words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) — verbatim quoting rule (operator's own statement)

## Architecture surfaces (the agent layer)

| Surface | Path | Determinism | Purpose |
|---|---|---|---|
| **Slash commands** (15) | `.claude/commands/*.md` | 100% on invoke | Operator-driven workflows. `/orient`, `/cycle`, `/mode-{pm,architect,dual,status,clear}`, `/blockers`, `/progress`, `/decisions`, `/log`, `/audit`, `/sync-progress`, `/help-root`, `/handoff` |
| **Modes** (3) | `.claude/modes/*.md` | Operator-enabled persona overlay | PM Scrum Master / DevOps Architect / Dual Expert. Combine with `/loop /cycle` for autopilot. Mode-entry is operator-choice; agent surfaces the option, never auto-enables. |
| **Hooks** (9 wired across 6 events) | `.claude/hooks/*.{sh,py}` | ~85% (`additionalContext` JSON) | PreToolUse (3: policy-block, malware-block, opt-write-block) + PostToolUse (1: leak-detector) + SessionStart (2: session-start, session-orient) + PreCompact (1: writes handoff doc) + PostCompact (1: directs /orient + references handoff) + SessionEnd (1: summary). Regression tests at `.claude/hooks/tests/*.py`. |
| **Sub-agents** (3 brain-loaded) | `.claude/agents/*.md` | Cold-context | `root-explorer` (research), `root-architect` (design lens), `root-pm-scoper` (PM scoping) — each starts with mandatory "load brain first" prompts naming CLAUDE.md / rules / state files. Custom subagents NOT discovered until session restart (cycle 47 finding). |
| **Tools** (4 + MCP server) | `tools/*.py` | 100% deterministic non-LLM | `state.py`, `blockers.py`, `progress.py`, `decisions.py` — invoked by commands; also exposed via `tools/mcp_server.py` (FastMCP, 6 tools) for MCP-aware consumers |
| **Skills** (2) | `.claude/skills/<name>/SKILL.md` | ~90-95% description-match auto-trigger | `surface-state` + `surface-blockers` — handle natural-prose equivalents of `/orient` + `/blockers` |
| **Governance** (3 SRP docs) | `wiki/governance/*.md` | Read-only views | Operator-facing perspective layer. Refresh via `/sync-progress` + `/decisions append`. |
| **Rules files** (10) | `.claude/rules/*.md` | Load-on-demand | Topic-specific guidance. Includes `trigger-model.md` (unified signal→action→recovery model across all 8 mechanism types — see DESIGN.md). |

## Verify state (commands to run before first work action)

```bash
# 1. confirm methodology engine present + parses
for f in $HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml; do
  <second-brain>/.venv/bin/python -c "import yaml,sys; yaml.safe_load(open('$f')); print('OK $f')"
done

# 2. confirm second-brain reachable
ls <second-brain>/wiki/spine/references/adoption-guide.md

# 3. confirm root-ghostproxy registered with second brain
grep -A2 "^  root-ghostproxy:" <second-brain>/wiki/config/sister-projects.yaml

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

As of 2026-05-05 end of preparation, the 40 not-started tasks have implicit gates beyond just `BLOCKED BY` cross-references:

| Module | Not-started tasks | Implicit gate |
|---|---|---|
| M003 (Foundation) | 6 | Operator decides T011 (greenfield vs extend) first |
| M004 (Infra tooling) | 5 | Operator approves T018 (verifier scope) first |
| M005 (First feature) | 5 | Operator picks T024 (Suricata vs PolarProxy first) first |
| M006 (Pre-connect) | 5 | `/root` must be git-init'd (operator T006-territory) |
| M007 (Connect) | 4 | M006 done first |
| M008 (Smoke) | 7 | M007 done first |
| M009 (Worked example) | 4 | Operator decides T051 (reframe) first |
| M010 (auto_connect flip) | 4 | Cooling-off period (≥1 week post-M009) + T058 decision |

**There are no tasks a fresh session can claim unilaterally without operator input.** This is BY DESIGN — the SFIF rollout is operator-supervised. The workflow at this point is: surface the 6 pending decisions, await operator direction, then claim a task.

### The 6 pending-operator-decision tasks (surface these first)

| ID | Priority | What operator decides |
|---|---|---|
| [T006](wiki/backlog/tasks/T006-prior-debris-reconciliation.md) | P1 | Reconciliation policy for prior /root debris (delete / leave / partial preserve) |
| [T011](wiki/backlog/tasks/T011-foundation-iac-authoring-approach.md) | P0 | Foundation IaC approach (greenfield vs extend prior debris) |
| [T018](wiki/backlog/tasks/T018-operator-approve-verifier-scope.md) | P0 | Verifier scope (which checks, which strictness) |
| [T024](wiki/backlog/tasks/T024-operator-picks-first-module.md) | P0 | First feature module (Suricata-first vs PolarProxy-first) |
| [T051](wiki/backlog/tasks/T051-reframe-m009-bidirectional-flow-already-proven.md) | P1 | M009 reframe (bidirectional flow already partially proven) |
| [T058](wiki/backlog/tasks/T058-operator-decides-auto-connect.md) | P2 | auto_connect for sister-projects.yaml (status quo false vs flip true) |

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
| **`$HOME/.claude/hooks/*.sh` are Python** | The 6 files at `$HOME/.claude/hooks/` named `*.sh` are actually Python scripts (`#!/usr/bin/env python3` shebang). Extension is misleading but `policy-block`, `malware-block`, `leak-detector`, `session-start`, `session-summary`, `deny-secret-files` all run as Python. Wired in `$HOME/.claude/settings.json`. Status pending T006 — they exist + fire but are not yet operator-confirmed canonical. |
| **machine-level vs project-level hooks** | Per AGENTS.md two-layer hook architecture: `$HOME/.claude/hooks/` is machine-level (root user envelope); a future `$HOME/$HOME/.claude/hooks/` would be project-level. Machine-level fires first. Currently only machine-level exists. |

## Pickup-cold runbook (TL;DR for the impatient)

1. `cat $HOME/CLAUDE.md $HOME/CONTEXT.md` → loaded.
2. `cat $HOME/wiki/log/2026-05-05-preparation-session-foundation-scaffolding.md` → know what happened before you.
3. `cat $HOME/wiki/backlog/tasks/_index.md` → know what's next.
4. Run the 4 verification commands above → confirm state.
5. Ask operator which module to work on, or surface the 6 pending-operator-decision tasks.
6. Claim one not-started task; work it per Done When checklist + methodology stage gate.

You are now ready.
