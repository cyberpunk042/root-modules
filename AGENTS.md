# AGENTS.md — root-ghostproxy (universal cross-tool agent context)

> **Cross-tool universal context** for this project. Read by Claude Code, opencode, Codex CLI, Copilot CLI, Gemini CLI, Cursor, and any other tool that supports the [AGENTS.md standard](https://agents-standard.org). Claude Code reads this **AND** [CLAUDE.md](CLAUDE.md); other tools read only this file.
>
> **Tight + pointer-based by design** — this file references canonical sources rather than re-stating their content. Project description is in [README.md](README.md). Claude-Code-specific routing is in CLAUDE.md. Threat model + protections are in [SECURITY.md](SECURITY.md). This file holds the **cross-tool agent contract** — the rules that bind every AI tool running in / consuming this project, regardless of which AI tool it is.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct, cross-tool universal)**: when ANY AI tool improves AGENTS.md / CLAUDE.md / sister docs, **adding ≠ discarding**. Layer new content onto prior content; refresh inline values where empirically drifted (with empirical-verification command output inline); do NOT replace existing sections wholesale unless the operator explicitly directs. Going-to-extremes (SB-082/093 family) recurs across AI tools when an agent rewrites instead of revises. The lesson is universal — opencode / Codex / Cursor / Gemini agents face the same trap. Cycle action vocabulary: see `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md` (M-E001-1 DRAFT v2 — 9 canonical action types every AI tool's cycle skill should emit).

## What This Project Is (one paragraph)

root-ghostproxy is a **system AI safety setup project**. IaC that turns a Linux host (target: Debian 13) into a transparent L2 inspection bridge with optional inspection modules, AND configures the OS-root level AI agent safety policy so every AI tool running on the host obeys the same deny-by-default safety contract. Position: between an OPNsense edge firewall and the LAN switch. Modules (Suricata IDS/IPS, PolarProxy TLS termination) layer on facultatively. type=`root`, group=`operating-system-setup`. Sister project of the research-wiki second brain at `<second-brain>/`. Currently barely started — foundation in progress. See [README.md](README.md) for the comprehensive project description + architecture vision + module detail.

## Operating Doctrine — Spec-Driven Development

Every AI tool consuming this project operates under **spec-driven development with a strong methodology and standards** (operator directive 2026-05-05). This is the doctrinal frame that determines what the agent ships and what it doesn't.

| Lives in repo (spec — must persist across hosts) | Lives only at runtime (state — regenerated per host) |
|---|---|
| Brain files (CLAUDE.md, AGENTS.md, BOOTSTRAP.md, README.md, CONTEXT.md, ARCHITECTURE.md, DESIGN.md, TOOLS.md, SKILLS.md, SECURITY.md) | Hydrated configs with secrets, runtime logs, vendor binaries |
| `$HOME/.claude/rules/*.md` (agent-context spec) | Session histories, file-history backups, leak-detector outputs |
| `$HOME/wiki/config/*.yaml` (methodology engine spec) | Vendor source trees, downloaded archives |
| `$HOME/wiki/backlog/{epics,modules,tasks}/*.md` (project-management spec) | `.env`, `.credentials.json`, `qr.code`, auth tokens |
| `install.sh` + `uninstall.sh` (spec-realizer scripts) | Bridge-interface live state, suricata.log, polarproxy intercept logs |
| `.gitignore` (deny-all + spec-whitelist) | Suricata + PolarProxy installations, ATS rules, daemon state |

**Implications for every AI tool:**

1. **Don't ship realized state into the repo.** When the tool generates a hydrated config or downloads a vendor binary, that artifact does NOT belong under git. The spec that GENERATED it does.
2. **Add to the spec, not to the runtime.** New vendor (e.g., a new IDS rule source): add a vendor-manifest entry + integrity hash + install method to the spec. Don't paste vendor source into the project tree.
3. **The .gitignore is fail-safe toward denial.** New folders/files are denied by default. Whitelist explicitly when authoring spec; let runtime artifacts stay denied.
4. **Replays are the truth-test.** A fresh `git clone` + `./install.sh` should produce a working host. If it can't, the spec is incomplete.

Operator's named impact areas (verbatim 2026-05-05): *"executions, outputs, quality, reliability, tracability, operability, observability, project management, progress tracking, LLM Wiki enforment, compatibility exploitation."* Every cross-tool action is evaluated against these.

## The Cross-Tool Agent Contract

When ANY AI tool (Claude Code, opencode, Codex, Copilot, Cursor, Gemini, future tools) runs on a host where root-ghostproxy is installed, it operates inside the project's safety envelope. The envelope has structural properties every tool obeys:

### Single source of truth for safety policy

There is **one** safety policy on the host, defined at the OS-root level. Every AI tool consults the same policy through its own extension mechanism. **No tool duplicates the policy** — no per-tool deny lists, no per-tool hook regex, no per-tool credential-pattern config. Adding a new AI tool means writing a thin adapter that mirrors the policy hooks under that tool's plugin/extension SDK; the policy itself is not re-authored.

This is the **no-policy-duplication invariant.** Operator's verbatim project framing names this property: a shared source so cross-AI-tool consistency is structural, not coincidental.

### Tool-call envelope (canonical contract)

Per-tool extension mechanisms differ in surface but converge on a common envelope shape for tool-call decisions. The canonical envelope (Claude Code's PreToolUse hook input) is:

```json
{
  "session_id": "<session-id>",
  "tool_name": "<Tool>",
  "tool_input": { ... tool-specific args ... },
  "hook_event_name": "PreToolUse"
}
```

When other AI tools (e.g. opencode) run hooks via their plugin SDKs, the bridge plugin maps their native names to the canonical envelope (e.g. opencode's `bash` → `Bash`, `read` → `Read`, etc.) and invokes the same hook scripts with this exact stdin contract. The hook returns a JSON decision:

```json
{
  "permissionDecision": "allow" | "deny" | "ask",
  "permissionDecisionReason": "<human-readable reason>",
  "systemMessage": "<optional message surfaced to user>"
}
```

Every AI tool on the host emits + consumes this envelope shape. **The envelope is the cross-tool integration interface.**

### Hook firing order (every tool)

Every tool call from every AI tool fires hooks in this order:

1. **Tamper-detection sentinel** runs first. If safety controls are missing/disabled/eroded, every subsequent step refuses. Fail-closed.
2. **Pre-tool-call policy hooks** — credential-file blocker + behavior-pattern blocker + any operator-curated additions. Each receives the canonical envelope, returns a decision.
3. **Tool executes** if all pre-hooks allowed.
4. **Post-tool-call output hooks** — leak-detector + any operator-curated post-processing. Output is scanned for credential-shaped patterns; detections logged + alerted.
5. **Session lifecycle hooks** run on session events: SessionStart (banner + integrity check + project-priming directive to invoke `/orient`); UserPromptSubmit (4-hook compound stack per SB-126: **context-warning** with absolute-token thresholds <50k/<25k/<10k per SB-119 + **output-discipline-guard / agent-discipline-gate** per SB-108 with 3 detectors — premise-construction-risk SB-090 + operator-escalation SB-094 + conditional-clause-grammar SB-120 — + **mode-enforcement** per SB-056 with dynamic mode-file parsing + live-state cross-reference + frequency-control SB-117 + **mindfulness** baseline 7-clause reminder per SB-126/SB-128/SB-131 — all four compound separate `additionalContext` fields per prompt); PreCompact (writes deterministic state snapshot to `wiki/log/<ts>-pre-compact-handoff.md` BEFORE compaction summarizes context away — emits **top-level `systemMessage`** per SB-133 envelope schema fix, NOT `hookSpecificOutput` envelope); PostCompact (directs agent to invoke `/orient` + reference the most-recent pre-compact handoff doc — same SB-133 top-level `systemMessage` envelope); Stop (end-of-cycle-stamp per SB-114/SB-115/SB-116-Epic-pending: persistent-config-driven status stamp via `systemMessage`; layout horizontal/vertical, enabled on/off/auto via slash commands `/stamp-*`); SessionEnd (deny/leak count summary).

This order is invariant across AI tools. Claude Code calls these hooks natively; opencode runs them via the bridge plugin. The hook scripts themselves are the same code, invoked from different runtimes.

**Regression tests** at `.claude/hooks/tests/*.py` (12 hook test files) + `tools/tests/*.py` (1 tool test — test-group.py) verify hook + tool regex/logic changes don't introduce false-positives (which silently block legitimate work) or false-negatives (which silently let attacks through). Aggregate **241/241 passing — empirically verified 2026-07-03** via `HOME=<repo> python3 -m tools.run-tests` on the current `main` tree. (NOTE per Hard Rule 15: an earlier "322/322 across 14 files (9 hook + 5 tools)" figure was in the docs but never in committed history — `git ls-tree` shows this tree only ever carried 11-12 hook test files and, until 2026-07-03, no `tools/tests/`; the current empirical count is authoritative.) Run via `python3 -m tools.run-tests` — the unified regression runner. Run before claiming any hook fix done (P4 — Declarations Aspirational Until Verified).

### Two-layer hook architecture

There are TWO places hooks can live:

| Layer | Path | Scope | Owner |
|---|---|---|---|
| **Machine level** | `~/.claude/settings.json` + `~/.claude/hooks/*` | Fires on every tool call from every Claude-Code-protocol-compatible tool on the host, in every project. | **root-ghostproxy** (this project). |
| **Project level** | `<project>/.claude/settings.json` + `<project>/.claude/hooks/*` | Fires on tool calls in sessions opened in `<project>` only. | The project itself (e.g. each sister project may have its own). |

**Order: machine-level fires BEFORE project-level.** The machine-level layer cannot be overridden by a project-level layer's allow rules (machine deny is final). Project-level can ADD restrictions but not subtract from the machine-level set.

> **Path-A collision admonition (per SB-087 closure 2026-05-05)**: for **type=root projects** where `$HOME` IS the project root (root-ghostproxy on the canonical install user `root`, where `~/.claude/settings.json` and `<project>/.claude/settings.json` are the same physical file via `readlink -f`), the machine-level and project-level layers COINCIDE at the file system level. Hooks self-gate via `CLAUDE_PROJECT_DIR` env var (or cwd fallback) to distinguish "fired in root-ghostproxy session" vs "fired in sister-project session opened on this host". Sister sessions silently pass-through (exit 0) for hooks scoped to root-ghostproxy. Per SB-088 fix, all root-authored hooks now check this gate. Cross-tool implication: opencode + other AI tools running on the host emit the same `CLAUDE_PROJECT_DIR` (or equivalent project-dir signal in stdin JSON) so cross-tool hooks self-gate consistently.

Every AI tool obeys this two-layer architecture. **It is a property of the host, not a property of any single project.**

## Identity (Goldilocks 9-dimension — abbreviated)

| Dimension | Value | Layer |
|---|---|---|
| Type | `root` | Stable |
| Group | `operating-system-setup` | Stable |
| Domain | Infrastructure | Stable |
| Phase | scaffold + partial-foundation | State |
| Scale | micro | State |
| Execution mode | solo | Consumer/Task default |
| SDLC profile | simplified | Consumer/Task default |
| PM Level | L1 | Consumer/Task default |
| Trust tier | operator-supervised | Consumer/Task default |

Full identity profile (canonical): `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md`.

## Mission (operator verbatim)

> *"I am able to start a session in the $HOME project and am able to start working on the two vendors & modules integrations and following the methodology with the wiki LLM and everything"*

> *"its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network. its aiming to secure an OS and configure claude code and opencode at the root with all the safety needed. it will do this and it will also offer in the future to for instance we use this machine or another [new] one. So its not just an IPS its a system AI safety setup project and the IPS tools (suricata and [polarproxy]) as modules."*

> *"first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed"*

Source: `<second-brain>/raw/notes/2026-05-04-prepare-root-ghostproxy-as-sister-type-root-group-operating-system-setup.md` and `<second-brain>/raw/notes/2026-05-04-custom-tailored-model-group-moe-intelligence-layer-and-root-ghostproxy-pain-point.md`. (Both in the second-brain's own raw-notes layer.)

## Pointers — where canonical content lives

| Resource | Where | Purpose |
|---|---|---|
| **Project description + architecture vision + identity** | [README.md](README.md) | Project front door. What root-ghostproxy IS, the architecture vision, the modules-as-facultative framing, current state, build order, methodology layer, sister-project status. |
| **Claude Code-specific routing + hard rules** | [CLAUDE.md](CLAUDE.md) | Operator-intent → tool/command routing for Claude Code in this project, methodology pointer, Claude-specific hard rules. |
| **Current operational state** | [CONTEXT.md](CONTEXT.md) | Active SFIF stage, active modules, recent operator directives, next-best moves. Changes turn-to-turn. |
| **System architecture in depth** | [ARCHITECTURE.md](ARCHITECTURE.md) | Topology, components, hook flow, module integration interfaces, failure modes, recovery. |
| **Tool reference** | [TOOLS.md](TOOLS.md) | Per-script details (when install + verifier scripts exist). |
| **Design pattern rationale** | [DESIGN.md](DESIGN.md) | Why deny-by-default, why fail-closed integrity, why two-layer hooks, why facultative modules, why methodology adoption. |
| **Security policy** | [SECURITY.md](SECURITY.md) | Threat model + layer-by-layer protections + fail-closed invariants + escalation + audit + limitations. |
| **Skills directory context** | [SKILLS.md](SKILLS.md) | Where skills live, conventions, when to use each. |
| **Methodology engine** | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) | 9 models, 5 universal stages, ALLOWED/FORBIDDEN per stage, gate commands, end conditions. |
| **Chosen profiles** | [wiki/config/sdlc-profile.yaml](wiki/config/sdlc-profile.yaml) (`simplified`), [wiki/config/domain-profile.yaml](wiki/config/domain-profile.yaml) (`infrastructure`), [wiki/config/methodology-profile.yaml](wiki/config/methodology-profile.yaml) (`stage-gated`) | Per-project methodology adaptation. |
| **Backlog (4-level hierarchy: Milestone → Epic → Module → Task — introduced 2026-05-06)** | [wiki/backlog/](wiki/backlog/) | Active milestone v0.2 ai-natural-task-management (alongside v0.1) + 4 active epics (sfif-rollout + E001 auto-pilot rework + E002 piling-tasks + E003 compound-retention-and-multi-group) + 14 modules + 66 atomic tasks. |
| **Governance — SRP-separated docs** | [wiki/governance/](wiki/governance/) | `blockers.md` (operator-decision-pending), `decisions.md` (40 entries D001-D040, full audit trail), `progress.md` (live-state callout refreshed via `/sync-progress`), `systemic-bugs.md` (138-row tracker; max ID SB-138; 1 historical duplicate; per-bug status + verification evidence). |
| **Log** | [wiki/log/](wiki/log/) | Operator directives verbatim, session logs, completion notes, decision packages, design notes. |
| **Identity profile (canonical)** | `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` | Full Goldilocks 9-dimension profile. |
| **Sister-projects.yaml entry** | `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-ghostproxy` | Registration with second brain. |
| **Source-syntheses (in second brain)** | `<second-brain>/wiki/sources/src-{suricata,polarproxy,suricata-install-quickstart,suricata-ips-mode-linux,suricata-yaml-config,hanke-honeypot-polarproxy-suricata-integration}.md` | Module design references. |
| **Adoption Guide** | `<second-brain>/wiki/spine/references/adoption-guide.md` | The strictly-defined sister-project adoption process. |
| **Second brain (when --connect-project has been run)** | `.mcp.json` `mcpServers.research-wiki` + `tools/gateway.py` + `tools/view.py` forwarders | Programmatic + CLI access to second-brain methodology + standards + lessons + patterns. |
| **Universal cross-cutting rules** (cross-tool relevant — every AI tool benefits) | [.claude/rules/compound-and-waterfall.md](.claude/rules/compound-and-waterfall.md) | Two orthogonal axes: compound (additive layers at-a-moment) + waterfall (state flows event-to-event); failure modes (collide / truncation); SB-123 closure |
| **Universal cross-cutting rules** | [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) | Unified signal→action→recovery composition across hooks/commands/skills/modes/tools/MCP/scheduled-tasks/sub-agents — applies to ALL AI tool runtimes |
| **Universal cross-cutting rules** | [.claude/rules/context-engineering.md](.claude/rules/context-engineering.md) | Four orthogonal context-injection modes: auto / pre / on-demand / facultative — applies to any AI tool's context-loading discipline |
| **MCP root-ghostproxy server (cross-tool consumable)** | [.mcp.json](.mcp.json) + `tools/mcp_server.py` | **10 root_* tools** exposing project state to ANY MCP-aware AI client: root_state, root_blockers, root_progress, root_decisions_{list,get,verify,next_id}, root_objective (SB-118+SB-127 — mission/focus/impediment/priorities), root_questions (SB-134 — agent-pending Q queue), root_orient + 1 additional. Empirically verified count 2026-05-06 evening. |
| **Subdirectory READMEs** (DRAFT v1 — agent-authored 2026-05-06 evening per brain-improvement mandate; cross-tool relevant — every AI tool consuming this project benefits) | One per indexed subdir, each wiki-schema 9-field compliant + Summary + Relationships sections |
| Tools (15 Python modules) | [tools/README.md](tools/README.md) |
| Slash commands (44 commands by category — empirically verified 2026-05-07 cron F50 via `ls .claude/commands/*.md \| wc -l = 45 .md files − 1 README.md = 44 commands`; +1 since 2026-05-06 reflects /stamp-deltas-{on,off} per T067) | [.claude/commands/README.md](.claude/commands/README.md) |
| Hooks (18 hook scripts; 10 wired matchers + archive) | [.claude/hooks/README.md](.claude/hooks/README.md) |
| Modes (3 modes + cycle-sequence comparison) | [.claude/modes/README.md](.claude/modes/README.md) |
| Rules (11 rules + strictness-tier matrix) | [.claude/rules/README.md](.claude/rules/README.md) |
| Subagents (3 brain-loaded subagents) | [.claude/agents/README.md](.claude/agents/README.md) |
| Skills (2 skills + mechanism-choice context) | [.claude/skills/README.md](.claude/skills/README.md) |
| Templates (5 install template categories) | [templates/README.md](templates/README.md) |
| Scripts (deployment + maintenance toolkit) | [scripts/README.md](scripts/README.md) |
| **Brain-improvement mandate log** (sacrosanct verbatim directive — governs the doc-update pass that produced this version of AGENTS.md) | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| **Productive-cycle action vocabulary** (M-E001-1 DRAFT v2 — 9 canonical types every AI tool's cycle skill emits) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |

## Universal Hard Rules (cross-tool — all AI tools obey)

These rules apply regardless of which AI tool is operating. They are NOT Claude-Code-specific (those are in CLAUDE.md). They are NOT project-management-style rules (those are in CONTEXT.md). They are **structural invariants of the agent contract** in this project.

| # | Rule | Why |
|---|---|---|
| 1 | **Deny-by-default at every layer.** When a tool call's safety is uncertain, refuse — never silently allow. Refusal is recoverable; an undetected dangerous action may not be. | The project IS a security envelope. The default for safety-uncertain inputs is deny. |
| 2 | **Tamper detection precedes every tool call.** Before honoring any tool call, verify the safety controls are intact. If they are not, refuse every call until restored. | Safety controls being silently disabled is the failure mode tamper detection exists to prevent. |
| 3 | **Cross-AI-tool consistency: same policy, different runtimes.** When a new AI tool is added (e.g. Codex, Cursor, Gemini), wire it into the existing policy via a thin adapter that mirrors hooks under the new tool's SDK. **Do not duplicate** the policy regex / deny lists / hook logic per tool. | No-policy-duplication invariant. Multiple parallel policies drift; one source-of-truth doesn't. |
| 4 | **Operator words are sacrosanct — quote verbatim, never paraphrase.** When the operator's framing shapes a rule, decision, artefact, or threat-model entry, quote them verbatim. The agent's role is to preserve the operator's reasoning chain, not to compress it. **Log path: `$HOME/wiki/log/<YYYY-MM-DD>-<slug>.md`** (NOT `<second-brain>/raw/notes/` — second-brain has its own contribute channel; project iteration directives stay in `$HOME/`). Use `/log` slash command. | The operator's words define the project. Compression is loss. Path discipline (added 2026-05-05): writes from project agent into the second-brain are forbidden — second-brain is its own. |
| 5 | **Don't conflate the prior $HOME debris with the project's authoritative state.** The $HOME directory contains AI-debris from a prior session (a README, install.sh, hooks, integrity.py, opencode bridge plugin). Operator considers them not authoritative. The project's own implementation will be authored by the methodology-driven flow. Read operator-verbatim sources for project intent, not the prior debris. | Conflating prior debris with authoritative state has produced multiple wasted iterations. |
| 6 | **Auto-memory at `~/.claude/projects/-root/memory/` (if it exists from a prior session) is debris.** Operator verbatim: *"I DO NOT WANT TO USE THE FUCKING MEMORY FOLDER... I NEVER FUCKING TALKED ABOUT IT."* Do NOT reference it. Do NOT load anything from it. | Operator-stated rejection. |
| 7 | **Methodology stage boundaries are hard.** ALLOWED/FORBIDDEN per stage in `wiki/config/methodology.yaml` is enforced. Don't ship implementation in a Document-stage task. Don't ship code in a Design-stage task. Stage transitions require the gate command to pass. | Stage-gated methodology profile is the chosen process style. Hard boundaries are by design (per the methodology-profile choice for type=root: leakage between stages carries security cost). |
| 8 | **Modules are facultative.** Don't conflate "the project" with "the project + modules." Base install (foundation) is functional standalone. Don't fail a foundation gate because a module isn't installed. | Operator's verbatim. |
| 9 | **Two-layer hook architecture: machine-level fires before project-level.** root-ghostproxy owns the machine-level layer. Don't add a project-level config that overrides machine-level deny rules. | Architectural invariant. |
| 10 | **Status claims must inline the verification command's output.** "Done" / "verified" / "complete" without command output in the same response is a P4 violation. Run the verifying command, paste the output, then claim. | Principle 4 (Declarations Aspirational Until Verified) — load-bearing for type=root projects where unverified safety claims are dangerous. |
| 11 | **Adding ≠ discarding when updating cross-tool agent context.** Every AI tool consuming this project obeys: when improving AGENTS.md / CLAUDE.md / sister docs, layer new content onto prior content; refresh inline values where empirically drifted; do NOT replace existing sections wholesale unless the operator explicitly directs. Going-to-extremes (SB-082/093 family) recurs across AI tools when an agent rewrites instead of revises. The lesson is universal — opencode / Codex / Cursor / Gemini agents face the same trap. Codified in admonition near the top of this file + sister doc CLAUDE.md + README.md. | Operator-corrected this exact pattern in 2026-05-06 evening session ("Why are you not able to just do normal improvements instead of causing regression"). The lesson: deletion-because-newer-canonical-exists is regression; addition-of-pointer-to-newer-canonical is improvement. Cross-tool universal because the trap exists for every AI tool's doc-update work. |
| 12 | **Brain-inheritance pattern is universal cross-tool.** $HOME (root-ghostproxy) is the source-of-truth for **operational tooling** (hooks, slash commands, tools/*.py, settings.json wiring conventions, ANSI-fence rendering patterns, statusline widgets, mode-enforcement banner shape). /opt second-brain INHERITS / adapts these patterns. **Knowledge** flows the OTHER direction (root-ghostproxy → second brain via `gateway contribute` after M007 connect). Any AI tool authoring at $HOME contributes to operational tooling that propagates to /opt; any AI tool authoring at /opt contributes to knowledge that flows from second-brain to root-ghostproxy via consume-not-duplicate pattern. | SB-115 closure (operator-corrected agent's "/opt has its own hook, separate from $HOME's" framing). Operator verbatim: *"WTF WHY WOULD YOU SAY second-brain is different ?? you are the root retart... second-brain take everything from you...."* Cross-tool universal — applies to whichever AI tool authors operational tooling at $HOME. See `.claude/rules/self-reference.md` "Bidirectional inheritance" section. |
| 13 | **Chain operations per fire (universal cross-tool pattern).** Coherent multi-edit per cycle is the substance pattern for every AI tool's autopilot loop; single-edit-per-cycle is the THIN-output anti-pattern (SB-128 family). A SB closure typically pulls along (1) tracker row update + (2) structural fix (rule/hook/code/test) + (3) regression-test addition + (4) cross-references in related docs + (5) decisions-logbook entry. Treating these as 5 cycles is wasteful; treating them as 1 chain-fire is the operator's stated pattern. Cross-tool — applies to opencode session iteration, Codex-cli session iteration, any AI tool's loop. | Operator directive 2026-05-06 verbatim: *"sometimes we should also have chain operations and groups calls with potentially chains which make tree of operations.. like updating multiple thing like project file and cursor / ecosystem files and such and whatnot"*. Closes SB-131. Universal because the substance/THIN distinction is tool-agnostic. |
| 14 | **Productive cycle taxonomy (universal cross-tool action vocabulary).** Each cycle-fire from any AI tool MUST emit one of the 9 canonical action types from M-E001-1 vocabulary: **sb-closure / verified-edit / drift-fix-with-empirical / explicit-standby-with-named-reason / new-artifact / doc-refresh / blocker-surface / operator-directive-register / read-only-audit**. Mandatory: cycle report's last line ends with `Productive output: <type> — <one-line specific>`. THIN standby without named subject is the SB-128 bug. Canonical sources: `.claude/hooks/mindfulness.sh` clause #6 (4 operator-canonical types) + `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md` (M-E001-1 DRAFT v2 with 5 agent-extension types). | Operator directive 2026-05-06 verbatim: *"I am talking about the fact it bugs.. that it does a little thing sometimes even noting and do a weird statement and stop... thats what I was talking about, not the cron feature itself"*. Closes SB-128(b)+(c). Universal because the action vocabulary is tool-agnostic; defines what counts as productive across any AI tool's autopilot loop. |
| 15 | **Empirical-count-verification before drift-claim (universal cross-tool).** Before refreshing counts (decisions / SBs / tools / commands / hooks / rules / tests / modules / tasks) in any cross-tool brain file, run a programmatic walk + parse the source-of-truth files; do NOT compound prior counts with current cycle's deltas. Compounding errors is a recurring drift source across AI tools. Inline an "empirically verified YYYY-MM-DD" timestamp next to refreshed values. | This session's 6 distinct count drifts in CLAUDE.md alone (some originating from prior sessions across multiple AI tools). Cross-tool universal because the discipline is tool-agnostic — opencode / Codex / Cursor agents all face count-drift if no empirical-verification step. |

## Working Contract

Operator drives, AI is the horse. Each artefact is operator-reviewed before it lands. Iteration: AI drafts → operator reviews → operator approves or revises → AI executes. No bundling. No "while I'm at it" extras.

Operator-decided actions need explicit operator authorization before execution. Examples:
- Editing the safety policy (`~/.claude/settings.json`, `~/.claude/hooks/*`)
- Editing methodology files (`wiki/config/methodology.yaml`, profile yamls)
- Running `tools.setup --connect-project $HOME` for real (not --dry-run)
- Module install/uninstall
- Network bridge configuration changes

Low-impact iterations within an authorized work block (e.g. "iterate on this file") proceed via execute → present → operator iterates. The /loop skill instantiates the iterate-execute-present cycle.

## Agent personal-learning notes (cross-tool, operator-allowed)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. The notes below are **agent-authored** (per SB-095 — flagged as agent-DRAFT, not operator-stated content) and reflect cross-tool meta-lessons distilled across multiple AI-tool-driven sessions on this project. Operator may revise / promote / remove. Each entry timestamped + initialed `[agent]`.

### 2026-05-06 evening — universal cross-tool framing for project-level brain content

`[agent]` AGENTS.md is the cross-tool universal context — read by Claude Code, opencode, Codex, Copilot, Gemini, Cursor + future AGENTS.md-standard-compliant tools. Lessons codified here MUST be tool-agnostic. When mirroring a Claude-Code lesson into AGENTS.md, reframe with universal-applicability emphasis:

- ❌ "Claude Code reflexively rewrites instead of revising" → too tool-specific
- ✓ "Every AI tool's doc-update work faces the going-to-extremes trap (SB-082/093 family); opencode / Codex / Cursor / Gemini agents are equally susceptible"

The Hard Rules 11-15 are written this way — they cite the underlying universal pattern, not just the Claude-Code instance that surfaced it.

### 2026-05-06 evening — pointers vs duplication discipline

`[agent]` AGENTS.md is **tight + pointer-based by design**. When tempted to add a long explanation here, ask: does this need to be in EVERY AI tool's universal context, or can it live in a topic rule (`.claude/rules/<topic>.md`) or a sub-README? AGENTS.md is the HOT PATH for cross-tool context; it gets every AI tool's per-prompt context budget. Bloating it is expensive across the entire ecosystem.

The Pointers table is the anti-bloat mechanism — point at canonical source, don't duplicate it. Every cross-reference in this file should ideally fit in one row of the Pointers table; only the Universal Hard Rules + the Cross-Tool Agent Contract (no-duplication invariant + tool-call envelope + hook firing order + two-layer hook architecture) earn dedicated sections in AGENTS.md.

### 2026-05-06 evening — Path-A collision lesson

`[agent]` Type=root projects (where `$HOME` IS the project root) collide the machine-level and project-level layer paths at the file-system level. Hooks must self-gate via `CLAUDE_PROJECT_DIR` (or equivalent project-dir signal in stdin JSON for AI tools that don't set the env var). Sister-project-aware hooks check this gate; without it, a $HOME-authored hook fires inappropriately into sister-project sessions opened on the same host. Cross-tool relevance: every AI tool running on a host where root-ghostproxy is installed should emit/consume the project-dir signal consistently.

This pattern (SB-087/SB-088 closures) is universal — any future type=root project (under jfortin or other install user) will face the same collision.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). For cross-tool meta-lessons that benefit fresh-pickup agents (any AI tool) but are too small / cross-cutting / agent-perspective to warrant their own rule file. Operator promotes to structured artifact (universal rule, principle, lesson) when pattern matures.

## Session Bootstrap (for any AI tool)

When a fresh session opens in `$HOME`:

1. Read this file (AGENTS.md) and any tool-specific layer (e.g. CLAUDE.md for Claude Code).
2. Read [README.md](README.md) for project vision + identity.
3. Read [CONTEXT.md](CONTEXT.md) for current operational state.
4. If second-brain connection is live (M007 has run): query the second brain for methodology / standards / lessons relevant to the work.
5. Otherwise: review [wiki/backlog/](wiki/backlog/) directly.

For Claude Code specifically, see [CLAUDE.md § Session Bootstrap](CLAUDE.md#session-bootstrap).

## Second Brain Connection

<!-- SECOND-BRAIN-CONNECTION -->
<!-- This block is injected by `python3 -m tools.setup --connect-project $HOME/` (run from `<second-brain>/`).
     The injected variant per type/group resolution: `ROOT_OS_SETUP` for this project (type=root + group=operating-system-setup).
     Setup.py prefers AGENTS.md as the injection target with CLAUDE.md as fallback.
     Use --dry-run to preview before applying. Until the connection is run, this is a placeholder marker; the block content is generated by setup.py:_render_brain_pointer_block. -->
<!-- SECOND-BRAIN-CONNECTION-END -->
