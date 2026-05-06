# AGENTS.md — root-ghostproxy (universal cross-tool agent context)

> **Cross-tool universal context** for this project. Read by Claude Code, opencode, Codex CLI, Copilot CLI, Gemini CLI, Cursor, and any other tool that supports the [AGENTS.md standard](https://agents-standard.org). Claude Code reads this **AND** [CLAUDE.md](CLAUDE.md); other tools read only this file.
>
> **Tight + pointer-based by design** — this file references canonical sources rather than re-stating their content. Project description is in [README.md](README.md). Claude-Code-specific routing is in CLAUDE.md. Threat model + protections are in [SECURITY.md](SECURITY.md). This file holds the **cross-tool agent contract** — the rules that bind every AI tool running in / consuming this project, regardless of which AI tool it is.

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
5. **Session lifecycle hooks** run on session events: SessionStart (banner + integrity check + project-priming directive to invoke `/orient`); UserPromptSubmit (context-window warning + agent-discipline-gate per SB-108: high-confidence premise-construction-risk + operator-escalation detection + mode-enforcement per SB-056: dynamic mode-file parsing + live-state cross-reference per-prompt reminder when active-mode set); PreCompact (writes deterministic state snapshot to `wiki/log/<ts>-pre-compact-handoff.md` BEFORE compaction summarizes context away); PostCompact (directs agent to invoke `/orient` + reference the most-recent pre-compact handoff doc); Stop (end-of-cycle-stamp per SB-114/SB-115: persistent-config-driven status stamp via `systemMessage`; layout horizontal/vertical, enabled on/off/auto via slash commands `/stamp-*`); SessionEnd (deny/leak count summary).

This order is invariant across AI tools. Claude Code calls these hooks natively; opencode runs them via the bridge plugin. The hook scripts themselves are the same code, invoked from different runtimes.

**Hook regression tests** at `.claude/hooks/tests/*.py` verify hook regex changes don't introduce false-positives (which silently block legitimate work) or false-negatives (which silently let attacks through). Run before claiming any hook fix done.

### Two-layer hook architecture

There are TWO places hooks can live:

| Layer | Path | Scope | Owner |
|---|---|---|---|
| **Machine level** | `~/.claude/settings.json` + `~/.claude/hooks/*` | Fires on every tool call from every Claude-Code-protocol-compatible tool on the host, in every project. | **root-ghostproxy** (this project). |
| **Project level** | `$HOME/.claude/settings.json` + `$HOME/.claude/hooks/*` | Fires on tool calls in sessions opened in `<project>` only. | The project itself (e.g. each sister project may have its own). |

**Order: machine-level fires BEFORE project-level.** The machine-level layer cannot be overridden by a project-level layer's allow rules (machine deny is final). Project-level can ADD restrictions but not subtract from the machine-level set.

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
| **Backlog** | [wiki/backlog/](wiki/backlog/) | Active epic + 14 modules + 66 atomic tasks. |
| **Log** | [wiki/log/](wiki/log/) | Operator directives verbatim, session logs, completion notes. |
| **Identity profile (canonical)** | `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` | Full Goldilocks 9-dimension profile. |
| **Sister-projects.yaml entry** | `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-ghostproxy` | Registration with second brain. |
| **Source-syntheses (in second brain)** | `<second-brain>/wiki/sources/src-{suricata,polarproxy,suricata-install-quickstart,suricata-ips-mode-linux,suricata-yaml-config,hanke-honeypot-polarproxy-suricata-integration}.md` | Module design references. |
| **Adoption Guide** | `<second-brain>/wiki/spine/references/adoption-guide.md` | The strictly-defined sister-project adoption process. |
| **Second brain (when --connect-project has been run)** | `.mcp.json` `mcpServers.research-wiki` + `tools/gateway.py` + `tools/view.py` forwarders | Programmatic + CLI access to second-brain methodology + standards + lessons + patterns. |

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

## Working Contract

Operator drives, AI is the horse. Each artefact is operator-reviewed before it lands. Iteration: AI drafts → operator reviews → operator approves or revises → AI executes. No bundling. No "while I'm at it" extras.

Operator-decided actions need explicit operator authorization before execution. Examples:
- Editing the safety policy (`~/.claude/settings.json`, `~/.claude/hooks/*`)
- Editing methodology files (`wiki/config/methodology.yaml`, profile yamls)
- Running `tools.setup --connect-project $HOME` for real (not --dry-run)
- Module install/uninstall
- Network bridge configuration changes

Low-impact iterations within an authorized work block (e.g. "iterate on this file") proceed via execute → present → operator iterates. The /loop skill instantiates the iterate-execute-present cycle.

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
