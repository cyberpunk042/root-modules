# CLAUDE.md — root-ghostproxy (Claude Code delta)

> Claude Code-specific operating context for this project. Universal cross-tool rules + the shared agent contract live in [AGENTS.md](AGENTS.md). Project description + architecture vision + identity full-text live in [README.md](README.md).
>
> **Cold pickup?** Read [BOOTSTRAP.md](BOOTSTRAP.md) first — one-page first-time-here guide with read-order, state-verification commands, gotchas.

This file is auto-loaded by Claude Code at session start. It defines the operator-intent routing table for THIS project, the methodology layer pointer (per Adoption Guide step 5), and the Claude-Code-specific hard rules. It does **not** re-state content that belongs in AGENTS.md (universal cross-tool rules) or in README.md (project description) or in the methodology engine (`wiki/config/methodology.yaml`). It points at those, then adds Claude-specific delta.

## Identity (Goldilocks — abbreviated)

| Dimension | Value | Layer |
|---|---|---|
| Type | `root` | Stable |
| Group | `operating-system-setup` | Stable |
| Domain | Infrastructure | Stable |
| Phase | scaffold + partial-foundation | State |
| Scale | micro | State |
| Execution mode | solo (default) | Consumer/Task |
| SDLC profile | simplified (default) | Consumer/Task |
| PM Level | L1 (default) | Consumer/Task |
| Trust tier | operator-supervised (default) | Consumer/Task |

Stable rows are project-level invariants. State rows track SFIF stage. Consumer/Task rows are session-overridable defaults — a consumer (the agent in a given session) can pick different ones per task. Full identity profile (canonical): `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md`.

## Methodology

This project uses the second brain's stage-gate methodology, copied + adapted per the Adoption Guide (`<second-brain>/wiki/spine/references/adoption-guide.md`). Four config files in [wiki/config/](wiki/config/):

| File | Profile | Why this profile for root-ghostproxy |
|---|---|---|
| [`wiki/config/methodology.yaml`](wiki/config/methodology.yaml) | (engine) | 9 methodology models, 5 universal stages, ALLOWED/FORBIDDEN per stage, gate-command slots, end conditions. Adapt artifacts/protocols/gate commands per project; keep stage names + ordering + readiness ranges + hierarchy invariants. |
| [`wiki/config/sdlc-profile.yaml`](wiki/config/sdlc-profile.yaml) | `simplified` | Right-sized for micro scale + solo execution. Avoids ceremony that suits team-scale projects. |
| [`wiki/config/domain-profile.yaml`](wiki/config/domain-profile.yaml) | `infrastructure` | Gate-command + path-pattern overrides specific to infrastructure work (vs knowledge / code / docs). |
| [`wiki/config/methodology-profile.yaml`](wiki/config/methodology-profile.yaml) | `stage-gated` | Hard stage boundaries. ALLOWED/FORBIDDEN outputs per stage are enforced. Suits OS-setup work where leakage between stages (e.g. shipping implementation in a Document-stage task) carries security cost. |

### 5 Universal Stages

| Stage | Readiness | ALLOWED | FORBIDDEN | Gate command (this project) |
|---|---|---|---|---|
| **document** | 0–25% | wiki-page, raw notes, research notes | code-file, test-file | Page exists with Summary + gaps identified |
| **design** | 25–50% | design-document, ADR, tech-spec, type sketches IN docs | code-file, test-file | Spec reviewed; trade-offs documented |
| **scaffold** | 50–80% | type-definitions, schema, test-stubs, config-files | implementation, real test assertions | For IaC: `install.sh` exists and runs `--dry-run` cleanly without performing real changes; backlog page+module+task structure exists in `wiki/backlog/` |
| **implement** | 80–95% | implementation, integration-wiring, config | new tests | For IaC: `install.sh` runs and the box reaches the target state on first run; lint passes |
| **test** | 95–100% | test-implementation, test-results | new features | For IaC: idempotent re-run is no-op; integrity verifications return OK; end-to-end smoke (a packet routed through the bridge, observed by inspection if module is installed) passes |

**Stage rules:**
- "Continue" advances within the CURRENT stage. NEVER skip ahead to a later stage.
- One commit per stage. Don't advance without the gate passing.
- ALLOWED/FORBIDDEN are hard constraints, not suggestions.
- Stage boundaries are enforced by the methodology engine + (when M004 lands) the project-internal verifier.

**Backlog hierarchy:** Epic → Module → Task. Readiness flows up. Status flows up. You work on tasks, not epics directly.

**Active epic:** [SFIF Rollout + Second-Brain Integration](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md). Modules M001–M014 (incl. M011 ccstatusline, M012 vendor mapping, M014 pipelock preliminary). See [README.md](README.md) Backlog section for the full Stream 1 / Stream 2 breakdown.

## Operator-Intent Routing Table (Claude-Code-specific)

> Slash commands (`/checkin`, `/distill`, etc.) are operator-invoked LITERALLY. Bare prose like "continue" / "evolve" / "review" is trajectory-language for the agent's current track, NOT a workflow trigger. Don't conflate.

### Foundation operations (when foundation IaC exists)

| Operator says... | Run |
|---|---|
| `"verify install"` / `"is install OK"` | `cd $HOME && ./install.sh --dry-run` (no changes; previews what install would do — `unchanged` per file = currently consistent) |
| `"reinstall"` / `"re-apply policy"` / `"refresh install"` | `cd $HOME && ./install.sh` (idempotent; backs up out-of-sync files) |
| `"check integrity"` / `"is the policy intact"` / `"is the box trusted"` | Run the foundation's integrity check; expected: returns OK or specific failure reason inlined |
| `"audit safety policy"` / `"audit deny-set count"` | Run the foundation's deny-set audit script; should report count above the operator-set threshold |
| `"hooks audit"` / `"verify enforcement scripts"` | Verify the foundation's enforcement scripts are present, executable, and not suspicious-size; expected: all present, exit 0 |
| `"git audit"` / `"is anything leaking through gitignore"` | `cd $HOME && git status` and `cd $HOME && git ls-files` — only whitelisted files should appear (per `.gitignore` deny-all + whitelist invariant) |
| `"list policy backups"` | `ls -la $HOME/.* 2>/dev/null \| grep ghostproxy.bak` (per the install's backup-on-conflict pattern) |
| `"view leak log"` | When foundation has a leak-detection log: `cat <leak-log-path>` |
| `"verify foundation gate"` | M003 gate verification: dry-run install + check-install + integrity check + git audit, all green |

### Network bridge operations (when foundation network config exists)

| Operator says... | Run |
|---|---|
| `"verify bridge"` | `sudo brctl show <bridge-name>` — confirm both ethernet members listed |
| `"verify wifi outbound-only"` | `sudo nft list table filter` — confirm INPUT chain on management wifi drops everything except established/related |
| `"check bridge interfaces"` | `ip link show <upstream-eth> <lan-eth> <bridge-name>` — confirm UP, no errors |
| `"smoke a packet through the bridge"` | Send a test packet from one LAN side to the other, confirm it crosses |

### Module operations (when modules are installed — operator-driven future-session work)

| Operator says... | Run |
|---|---|
| `"suricata canary"` / `"smoke suricata"` | `sudo tail -f /var/log/suricata/fast.log &` then `curl http://testmynids.org/uid/index.html` — expect alert on SID 2100498 (per `wiki/sources/src-suricata-install-quickstart.md`) |
| `"suricata stats"` | `sudo tail -f /var/log/suricata/stats.log` |
| `"suricata alerts JSON"` | `sudo tail -f /var/log/suricata/eve.json \| jq 'select(.event_type=="alert")'` |
| `"polarproxy CA path"` | When PolarProxy is installed: `--certhttp <port>` exposes the CA over HTTP for client retrieval; `cat /usr/local/share/polarproxy.cer` (or operator-configured path) |
| `"polarproxy decryption rate"` | When PolarProxy is installed: monitor TLS sessions seen vs decrypted (free-tier failopen alert signal) |
| `"build a module"` / `"add suricata"` / `"add polarproxy"` | Read [wiki/backlog/modules/root-ghostproxy-m005-first-specialized-feature-module.md](wiki/backlog/modules/root-ghostproxy-m005-first-specialized-feature-module.md). Operator-driven future-session work. Modules are facultative; the foundation does NOT require them. |

### Second-brain operations (after M007 connect runs)

| Operator says... | Run |
|---|---|
| `"orient"` / `"orient to second brain"` | `python3 -m tools.gateway orient` (forwarder dispatches into `<second-brain>/`) |
| `"browse second brain"` | `python3 -m tools.view spine` |
| `"second brain methodology"` / `"how do I X"` | `python3 -m tools.gateway query --model <name>` (replaces `<name>` with feature-development / bug-fix / research / etc.) |
| `"second brain search"` / `"is there a lesson on X"` | `python3 -m tools.view search "<query>"` |
| `"second brain compliance check"` | `python3 -m tools.gateway compliance` (project's adoption-tier check) |
| `"second brain health"` | `python3 -m tools.gateway health` |
| `"contribute lesson"` / `"contribute correction"` / `"share what we learned"` | `python3 -m tools.gateway contribute --type {lesson,correction,remark} --title "..." --content "..."` |
| `"timeline"` / `"recent activity"` | `python3 -m tools.gateway timeline --scope root-ghostproxy --since 7d` |

### Backlog operations

| Operator says... | Run |
|---|---|
| `"status"` / `"what's next"` | Read [CONTEXT.md](CONTEXT.md) — active SFIF stage + active modules + next-best moves. |
| `"backlog"` / `"tasks"` / `"show me the work"` | List `$HOME/wiki/backlog/{epics,modules,tasks}/` and report current `status` + `priority` + `current_stage` for each. |
| `"start work on M00X"` | Read the module page, check dependencies, ensure stage is correct per methodology, begin in the CURRENT stage. |
| `"log <directive>"` / verbatim quote | Write `$HOME/wiki/log/YYYY-MM-DD-<slug>.md` BEFORE acting. |
| `"add task"` | Create `$HOME/wiki/backlog/tasks/T<NNN>-<slug>.md` with full frontmatter (status, parent_module, current_stage, readiness). |

## Hard Rules (Claude-Code-specific to root-ghostproxy)

These rules apply on top of the universal rules in [AGENTS.md](AGENTS.md) and the operator-stated invariants. They are NOT duplicates of AGENTS.md — they are Claude-Code-deltas.

| # | Rule | Why |
|---|---|---|
| 1 | **Status claims must inline the verification command's output.** "Done" / "verified" / "regathered" / "complete" without the command output in the SAME response is a P4 violation. Run the verifying command, paste the output, then claim. | The second brain's Principle 4 (Declarations Aspirational Until Verified) applies to agent self-reports too. P4 is load-bearing for type=root projects where unverified safety claims are dangerous. |
| 2 | **Don't edit safety policy without re-verifying tamper detection passes after.** Editing settings/hooks/integrity scripts without running the integrity check afterward risks fail-closing every subsequent tool call until restored. The integrity check is the verifier — run it after edits, inline the output. | Tamper detection is fail-closed. Editing without verifying is exactly the failure mode it's meant to catch. |
| 3 | **Don't try to bypass `malware-block`-style protections by editing the protection itself.** When a legitimate operation is blocked, the hook prints the bypass instruction. Use the published bypass mechanism (env-var prefix, designated install paths, etc.); don't reach into the hook script and weaken it. | The hook protecting itself is the design. Editing it weakens the security envelope for everyone using the host. |
| 4 | **Modules (Suricata, PolarProxy) are facultative.** Don't conflate "the project" with "the project + modules." Base install (foundation) is functional standalone. A "full install" deploys all modules; a partial install runs without them. Don't fail a foundation gate because a module isn't installed. | Operator's verbatim: *"first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed."* |
| 5 | **Two-layer hook architecture is invariant: machine-level fires before project-level.** This project owns the machine-level layer. Don't add a project-level `.claude/` config that overrides machine-level deny rules. Don't expect machine-level enforcement to be optional. | Operator's verbatim: *"secure an OS and configure claude code and opencode at the root with all the safety needed."* The machine-level layer enforces uniformly across all sister-project sessions on the host. |
| 6 | **Methodology stage boundaries are hard.** ALLOWED/FORBIDDEN per stage in `wiki/config/methodology.yaml` is enforced. Don't ship implementation in a Document-stage task. Don't ship code in a Design-stage task. Stage transitions require the gate command to pass. | Stage-gated methodology profile is the chosen process style. Hard boundaries are by design (per the methodology-profile choice for type=root: leakage between stages carries security cost). |
| 7 | **URL ingestion routes through the second brain (after connection).** This project does NOT ingest URLs at OS level — defer to the second brain's pipeline (after M007 connect). The second brain's whole principle is to consume articles + youtube videos for synthesis; root-ghostproxy is not that pipeline. | Architectural division of labor: the wiki ingests; root-ghostproxy CONSUMES the wiki's syntheses for module-design work. Forbids inversion. |
| 8 | **Don't confuse the prior $HOME debris with the project's authoritative state.** The $HOME directory contains AI-debris from a prior session (a README, install.sh, hooks, integrity.py, opencode bridge plugin). The operator considers them not authoritative — *"I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST."* The project's own implementation will be authored by the methodology-driven flow. Don't read those files for project intent; consult the operator-verbatim sources (raw notes + this README + sister-projects.yaml entry + identity-profile). | Conflating prior debris with authoritative state has produced multiple wasted iterations. |
| 9 | **The forwarders + .mcp.json land via `--connect-project` from the second brain side.** Don't author them by hand at $HOME. The connection mechanism is `python3 -m tools.setup --connect-project $HOME` from the second brain. Run it from there, not at $HOME. The connect script supports `--dry-run` for preview. | Single source of truth for the connection logic. Hand-authored forwarders drift from the canonical implementation. |
| 10 | **Auto-memory at `~/.claude/projects/-root/memory/` (if it exists from a prior session) is debris.** Operator verbatim: *"I DO NOT WANT TO USE THE FUCKING MEMORY FOLDER... I NEVER FUCKING TALKED ABOUT IT."* Do NOT reference it. Do NOT load anything from it. The project's authoritative content is in `$HOME/wiki/`, `$HOME/*.md`, and the second-brain references. | Operator-stated rejection of an artefact a prior AI session created without authorization. |

## Working Contract (with the operator)

Operator drives, AI is the horse. Each artefact is operator-reviewed before it lands. Iteration: AI drafts → operator reviews → operator approves or revises → AI executes. No bundling. No "while I'm at it" extras.

For high-impact changes (anything touching the foundation, the modules, the methodology files, the agent-context files), the contract is **propose → approve → execute**. For low-impact changes within an authorized work block (e.g. "iterate on this file") the contract is **execute → present → operator iterates**. The /loop skill instantiates the iterate-execute-present cycle.

## Pointers to Depth

| For… | Read |
|---|---|
| Project front door + vision + architecture summary + identity + modules + current state | [README.md](README.md) |
| Universal cross-tool agent rules + shared agent contract | [AGENTS.md](AGENTS.md) |
| Current operational state (active SFIF stage + active modules + recent operator directives + next-best moves) | [CONTEXT.md](CONTEXT.md) |
| System architecture in depth (topology, hook flow, module integration interfaces, failure modes) | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Tool reference (when install + verifier + module-install scripts exist) | [TOOLS.md](TOOLS.md) |
| Design pattern rationale (why deny-by-default, why fail-closed, why two layers, why facultative modules, why methodology adoption) | [DESIGN.md](DESIGN.md) |
| Security policy (threat model, layer-by-layer protections, fail-closed invariants, escalation, audit, limitations) | [SECURITY.md](SECURITY.md) |
| Skills directory context | [SKILLS.md](SKILLS.md) |
| Identity profile (Goldilocks 9-dimension full) | `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` |
| Methodology engine | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| Active epic | [wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md) |
| Modules M001–M010 | [wiki/backlog/modules/](wiki/backlog/modules/) |
| Operator directives + session logs | [wiki/log/](wiki/log/) |
| Source-syntheses for Suricata + PolarProxy + Hanke integration (in second brain) | `<second-brain>/wiki/sources/src-suricata*.md`, `src-polarproxy.md`, `src-hanke-honeypot-polarproxy-suricata-integration.md` |
| Adoption Guide (the strictly-defined sister-project adoption process) | `<second-brain>/wiki/spine/references/adoption-guide.md` |

## Session Bootstrap

When a fresh Claude Code session opens in `$HOME`:

1. Auto-loaded: this CLAUDE.md, [AGENTS.md](AGENTS.md), and (per Claude Code convention) any other root-level project context.
2. Read [BOOTSTRAP.md](BOOTSTRAP.md) — one-page cold-pickup guide with read-order, 5 verify commands, immediately-claimable tasks, gotchas.
3. Read [README.md](README.md) for project vision + identity.
4. Read [CONTEXT.md](CONTEXT.md) for current operational state.
5. If second-brain connection is live (M007 has run): `cd <second-brain>/ && <second-brain>/.venv/bin/python -m tools.gateway orient --orient-as sister` for context-aware orientation. (Note: `tools` package lives in the second-brain venv; running from `$HOME/` cwd fails with `ModuleNotFoundError`. `--orient-as` accepts only `second-brain`/`sister`/`external`.)
6. Otherwise: review [wiki/backlog/](wiki/backlog/) directly for the active epic + modules + tasks.

## Rules Files (load on demand from `.claude/rules/`)

Topic-specific rules loaded when work touches their domain. Per Claude Code convention these are not auto-loaded but read when relevant:

| File | Load when |
|---|---|
| [.claude/rules/routing.md](.claude/rules/routing.md) | Operator intent is ambiguous; need to map prose → tool/MCP/CLI |
| [.claude/rules/methodology.md](.claude/rules/methodology.md) | Stage selection, model selection, ALLOWED/FORBIDDEN per stage |
| [.claude/rules/hook-architecture.md](.claude/rules/hook-architecture.md) | Designing/debugging hooks; 14 wired machine-level hook fires across 8 events (PreToolUse, PostToolUse, SessionStart, UserPromptSubmit, PreCompact, PostCompact, Stop, SessionEnd) |
| [.claude/rules/work-mode.md](.claude/rules/work-mode.md) | Solo-session pattern, PO approval boundary, status-claim discipline |
| [.claude/rules/self-reference.md](.claude/rules/self-reference.md) | Confused about $HOME vs second brain; identity questions |
| [.claude/rules/words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) | About to summarize/paraphrase the operator (don't); about to log a directive |
| [.claude/rules/loop-cron-lifecycle.md](.claude/rules/loop-cron-lifecycle.md) | Considering autonomous cancellation/update of a loop or cron; mode-cycle deciding whether to self-terminate |
| [.claude/rules/operating-principles.md](.claude/rules/operating-principles.md) | Designing/calibrating a control's strictness; blocking/refusing something; making judgment calls about flexibility vs strictness |
| [.claude/rules/context-engineering.md](.claude/rules/context-engineering.md) | Designing how an agent gets context (auto/pre/on-demand/facultative injection); enriching frontmatter for tool empowerment |
| [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) | Designing or debugging anything that fires on a signal: hooks, slash commands, skills, modes, tools, MCP, scheduled tasks, sub-agents — unified signal→action→recovery model |
| [.claude/rules/compound-and-waterfall.md](.claude/rules/compound-and-waterfall.md) | Designing how state, context, hooks, or directives layer (compound axis = additive coexistence) or flow event-to-event (waterfall axis = sequential cascade); pairs with trigger-model.md + context-engineering.md |

## Project Surfaces (the agent's operating layers)

| Surface | Path | Determinism | Notes |
|---|---|---|---|
| Slash commands (28) | [.claude/commands/](.claude/commands/) | 100% on invoke | `/orient`, `/cycle`, `/mode-{pm,architect,dual,status,clear}`, `/blockers`, `/progress`, `/decisions`, `/log`, `/audit`, `/sync-progress`, `/help-root`, `/handoff`, `/stamp-{horizontal,vertical,on,off,auto,status}` (6 SB-115), `/install-agent-brain`, `/mission`, `/focus`, `/impediment` (3 SB-118), `/priorities` (SB-127 imminent-work), `/terminate`, `/finish-smoothly` (operator-authored 2026-05-06 session-termination prep) |
| Modes (3) | [.claude/modes/](.claude/modes/) | Operator-picks (durable) | PM Scrum Master / DevOps Architect / Dual Expert. State at `.claude/active-mode`. Combine with `/loop /cycle` for autopilot. |
| Hooks (13 wired) | [.claude/hooks/](.claude/hooks/) | ~85% (additionalContext JSON) | session-orient + post-compact direct agent to `/orient`; security envelope (policy-block + malware-block + opt-write-block + leak-detector); pre-compact handoff snapshot; UserPromptSubmit context-warning + agent-discipline-gate + mode-enforcement; Stop end-of-cycle-stamp; session-summary on end. |
| Tools (12 .py + MCP) | [tools/](tools/) | 100% non-LLM | `state, blockers, progress, decisions, cycle, tasks, stamp, objective, priorities, run-tests` Python modules + `mcp_server` exposes 7 MCP tools (read-only) at `tools/mcp_server.py` + `_paths` helper. Wired via `.mcp.json`. `run-tests` is unified regression runner (159/159 aggregate across 9 test files). |
| Skills (2) | [.claude/skills/](.claude/skills/) | ~90-95% description-match | `surface-state` (auto-fires on "where are we" prose → `/orient`); `surface-blockers` (auto-fires on "what's blocking" prose → `/blockers`). |
| Governance (3 SRP docs) | [wiki/governance/](wiki/governance/) | Read-only views | `blockers.md`, `progress.md`, `decisions.md`. SRP-separated. Refresh via `/sync-progress` + `/decisions append`. |
| MCP server (root-ghostproxy) | [.mcp.json](.mcp.json) + tools/mcp_server.py | 100% per call | 7 tools: root_state, root_blockers, root_progress, root_decisions_{list,get,verify,next_id}, root_objective (SB-118+SB-127 — mission/focus/impediment/priorities), root_orient. Uses `/opt/.../venv/bin/python` (mcp pkg). |

## Second Brain Connection (placeholder)

<!-- SECOND-BRAIN-CONNECTION -->
<!-- This block is injected by `python3 -m tools.setup --connect-project $HOME/ --dry-run` (preview) or the same command without --dry-run (apply), run from `<second-brain>/`.
     Variant per type/group resolution: `ROOT_OS_SETUP` for this project (type=root + group=operating-system-setup).
     Setup.py prefers AGENTS.md as the injection target with CLAUDE.md as fallback.
     Until the connection is run, this is a placeholder marker; the block content is generated by setup.py:_render_brain_pointer_block. -->
<!-- SECOND-BRAIN-CONNECTION-END -->
