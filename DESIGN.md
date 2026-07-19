# DESIGN.md — root-modules design pattern rationale

> **Why this shape.** For each major architectural choice in root-modules, the rationale: alternatives considered, why this choice was made, what it costs, what it gains. Distinct from [ARCHITECTURE.md](ARCHITECTURE.md) (the *what + how*) and [SECURITY.md](SECURITY.md) (specific threat protections). DESIGN.md is the *why this and not something else*.

This file is canonical reference material. When operator or future-session agent asks "why is X this way," the answer should be derivable from this file. When making changes that contradict a documented design choice, the change requires re-deriving the rationale here — not silently overriding it.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct)**: when refreshing DESIGN.md, **adding ≠ discarding**. Layer new design subsections at the END (chronological); refresh inline values where empirically drifted; do NOT replace existing Design Principles or Recent design subsections wholesale. Operator-verbatim quote at line 95+ (modules-as-facultative) is sacrosanct — preserve EXACTLY. Design Principles (4 cross-cutting) are doctrinal frame — preserve structure. Anti-Patterns + Trade-offs tables are APPEND-ONLY (existing rows preserved as historical record). Open Design Questions table: mark resolved with D-ID reference (not delete) — preserves provenance per the historical-snapshot-vs-canonical-current discipline.

## Summary

This file documents the design rationale for root-modules's architectural choices. **4 cross-cutting Design Principles** (deny-by-default at every layer · fail-closed where stakes are high / fail-open where stakes are low · markdown-as-IaC · same policy + different runtimes — no-policy-duplication invariant) form the doctrinal frame. **7 specific Specific Design Choices** (stealth bridge · facultative modules · two-layer hooks · methodology copy-and-adapt · auto_connect false · wifi outbound-only · git init at $HOME) realize the principles in concrete shape. **9 Recent design subsections** capture iterations from cycles 41-49 (unified trigger model · verbosity calibration · end-of-cycle stamp · agent-discipline-gate) plus 2026-05-06 additions (brain-inheritance pattern SB-115 · compound+waterfall axes SB-123 · productive-cycle taxonomy M-E001-1 + Hard Rule 14 · Active Objective Layer SB-118+SB-127+SB-124d · doc-update-discipline as design pattern Hard Rule 11). **Anti-Patterns Deliberately Avoided** + **Trade-offs Taken** tables provide negative-space framing. **Open Design Questions** tracks unresolved decisions with D-ID references for closed ones (preserving provenance). Cross-tool universal — every AI tool consuming this project obeys the same design principles via thin adapters.

## Design Principles in Force

The project commits to four cross-cutting design principles. Each is the lens through which the architecture's specific choices are evaluated.

### 1. Deny-by-default at every layer

Where safety is uncertain, refuse. Refusal is recoverable; an undetected dangerous action may not be.

**What it commits to:**
- Endpoint AI agent policy: tool calls that don't pass deny-set + behavior-pattern check refuse, not allow.
- Network bridge: nftables FORWARD chain default-decision is operator-set per threat model (default-accept for inspection-not-firewall, default-drop for firewall posture). Operator-decided.
- Tamper detection: when integrity check is uncertain, refuse every tool call.
- New AI tools: when added to the host, they default-comply with the existing policy (via adapter); they don't get a free pass to opt out.

**What it costs:** false positives — legitimate operations occasionally blocked, requiring operator confirmation or hook adjustment. The cost is borne in operator friction. The benefit is silent dangerous-action prevention.

**Alternatives rejected:** allow-by-default with explicit deny rules (the inverse). Rejected because in an AI-safety context the cost of an undetected dangerous action is asymmetric: a single credential exfiltration costs more than every legitimate-but-blocked operation combined.

### 2. Fail-closed where stakes are high; fail-open where stakes are low

Different failures have different costs. The architecture matches failure mode to cost asymmetry per layer.

**Fail-closed components:**
- Tamper detection (Layer 1) — when safety controls are tampered, refuse every tool call. The cost of allowing tool calls under tampered policy is asymmetrically high.
- Foundation install integrity check — when post-install verification fails, the install is not declared complete. The cost of a half-installed safety envelope is asymmetrically high.

**Fail-open components (configurable per operator's threat model):**
- Suricata IPS NFQUEUE with `bypass` option — when Suricata is down, traffic continues uninspected. The cost of network downtime in an inspection-not-firewall posture is asymmetrically high vs the cost of uninspected traffic during the recovery window.
- PolarProxy free-tier cap — when the cap is reached, decryption stops; forwarding continues. Inspection silently degrades; network keeps working. Operator monitors the divergence rate and provisions paid tier when needed.

**The choice point:** for the Suricata IPS module, operator picks NFQUEUE+bypass (fail-OPEN) vs AF_PACKET copy-mode (fail-CLOSED at L2). The decision is M005 module-design work. Both are valid; the choice depends on the specific threat model + uptime requirements.

**Alternatives rejected:** uniform fail-CLOSED across all layers (would make the project unusable as an inspection-not-firewall appliance because every Suricata crash takes the LAN offline); uniform fail-OPEN across all layers (would make tamper detection toothless because compromise of a hook script would be silently tolerated).

### 3. Markdown-as-IaC

Configuration is markdown files. Methodology, identity, backlog state, hook policy intent, design decisions — all in markdown, all version-controlled, all readable by operator + AI tools without specialized tooling.

**What it commits to:**
- The methodology engine is `wiki/config/methodology.yaml` (YAML, but human-readable + machine-parseable).
- The agent context is `*.md` files at the repo root (this file, AGENTS.md, CLAUDE.md, etc.) — operator and AI tools both read them via standard file I/O.
- Operator directives are `wiki/log/YYYY-MM-DD-*.md` (verbatim, sacrosanct).
- Backlog is hierarchical markdown: epics + modules + tasks at `wiki/backlog/{epics,modules,tasks}/`.
- Architectural decisions are inlined in this file (DESIGN.md); operational decisions logbook lives at [`wiki/governance/decisions.md`](wiki/governance/decisions.md) — **40 entries D001-D040** as of 2026-05-06 evening (refresh via `python3 -m tools.decisions append --title --rationale --reversibility`). DESIGN.md is the architectural curation (a subset focused on architectural design rationale); wiki/governance/decisions.md is the operational source-of-truth (every decision with reversibility + downstream effects).

**What it costs:** loss of structured-database affordances. There's no SQL query for "all tasks where readiness > 50 and parent_module = M005." Searching means grepping. The compensating mechanism is `pipeline post` (in the second brain) which builds indexes + manifest from frontmatter; the project as it exists at $HOME has not yet adopted that mechanism (it's available via the second-brain forwarders after M007 connect).

**What it gains:** every artefact is human-readable + AI-readable + diff-able + version-controlled with no special tooling. The operator can edit any file with a text editor. The AI tools see the same data the operator sees. There is no opaque database where state can drift from the operator's view.

**Alternatives rejected:** structured-database-backed configuration (TOML, SQLite, dedicated config service). Rejected because the cost of opacity vs the gain in queryability is asymmetric for this project's micro-scale + solo-operator + scaffold-tier maturity.

### 4. Same policy, different runtimes (no-policy-duplication invariant)

Cross-AI-tool consistency is structural, not coincidental. The agent-safety policy is defined once at the OS-root level; every AI tool obeys it through its own extension mechanism via thin adapters.

**What it commits to:**
- Single source of truth for the deny-set, the behavior-pattern check, the leak-detection patterns, and the hook scripts.
- Per-AI-tool adapters are thin — they map the tool's native envelope to the canonical envelope and dispatch to the same hook scripts.
- Adding a new AI tool means writing the adapter; it does NOT mean re-authoring the policy.

**What it costs:** the canonical envelope shape is constrained — it has to support every AI tool's hook event semantics in a single envelope. This may be lowest-common-denominator in some cases.

**What it gains:** policy drift across AI tools is structurally prevented. There is no "Claude Code says X but opencode says Y" failure mode. Operator's threat model is encoded once, enforced everywhere.

**Alternatives rejected:** per-tool policy with pairwise reconciliation. Rejected because policy drift is the highest-cost failure mode in a multi-AI-tool environment — an attacker exploits the most-permissive tool, and the operator may not realize which tool is most-permissive at any given moment.

## Specific Design Choices

### Stealth bridge (transparent L2) vs routing firewall

**Choice:** transparent L2 bridge — the box is L3-invisible to endpoints on the inspected segment.

**Alternatives considered:** L3 router/firewall (the box has IPs on both sides + does L3 NAT/forwarding); transparent proxy at L7 only (no L2/L3 control, just proxies HTTP-like protocols); span-port mirroring (passive; cannot block, only observe).

**Why stealth bridge:**
- Endpoints don't see "an extra hop" — networks behave as if root-modules weren't there. Reduces operator-side configuration ripple (no DHCP changes, no gateway changes, no L3 route changes).
- Provides inline control (drop/reject) in addition to inline observation. Span-port mirroring gives observation but not control.
- L3 routing/firewall would require IPs on both sides + would announce the box's presence. The "ghost" half of the project name commits to the L3-invisibility property.

**What it costs:** more complex bridge configuration; specific Linux network configuration required (kernel bridge, hardware offload disabling for inline inspection).

### Modules-as-facultative vs modules-as-required

**Choice:** Suricata + PolarProxy + future modules are **facultative**. The foundation runs without them.

**Alternatives considered:** modules required for the project to be functional (e.g. Suricata mandatory at install time); modules tightly coupled (PolarProxy presupposes Suricata).

**Why facultative:**
- Operator-stated: *"first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed."* Operator's design intent is explicit incrementalism.
- The endpoint AI agent safety + the bridge are useful standalone (a transparent bridge appliance with Claude+opencode hardening is a coherent setup even with zero modules).
- Module work is operator-driven future-session work. Foundation should not gate on module completion.
- License-tier considerations (PolarProxy free-tier cap) make some modules optional anyway — making them facultative architecturally avoids a forced upgrade path.

**What it costs:** the architectural integration interfaces (NFQUEUE slot, dummy-interface slot, eve.json output sink) must exist whether modules are installed or not, so that adding a module is a clean composition rather than an architectural retrofit.

**What it gains:** modular incremental rollout per operator's intent; lower-friction first-time install; clean failure isolation between layers.

### Two-layer hook architecture (machine-level + project-level)

**Choice:** safety policy lives at the OS-root level (machine-level), not at any individual project's `.claude/` level. Project-level layers can ADD restrictions but not subtract from machine-level.

**Alternatives considered:** project-level only (each project owns its safety policy); machine-level only (no project-level overrides); single-level with per-project namespace.

**Why two-layer:**
- The operator's safety policy is **about the host**, not about any one project. Endpoints on the LAN are protected regardless of which project a Claude Code session is opened in. A project-only safety policy would only protect that project's sessions.
- Sister projects on the same host inherit root-modules's machine-level policy uniformly. This is *the point* of root-modules as a system-AI-safety setup — the host's policy posture is consistent across all AI agent sessions.
- Project-level layers can ADD restrictions (a project can say "in addition to machine-level, also deny X for sessions in this project"). They cannot WEAKEN the machine-level set. This preserves operator's safety-floor while giving projects flexibility to be stricter.

**What it costs:** a session in any sister project is constrained by root-modules's deny-set. If the operator works in another project on the same host and a tool call is denied by root-modules's machine-level rules, that sister project's work is constrained.

**What it gains:** uniform safety floor across the host. The threat model is enforced regardless of which project the operator is currently working in.

### Methodology adoption (copy + adapt vs pointer)

**Choice:** copy + adapt. The methodology engine + 3 chosen profiles are local copies in `$HOME/wiki/config/`.

**Alternatives considered:** pointer-only (root-modules references the second brain's methodology config without copying); per-project local engine with no second-brain link.

**Why copy + adapt:**
- The Adoption Guide step 1 prescribes copy + adapt: artifacts, gate commands, commit scope, directory paths are project-specific variables; stage names + ordering + readiness ranges + hierarchy are ecosystem-wide invariants. Copying enables adaptation; pointer-only freezes the project to the second brain's exact gate commands.
- Operator-stated build order: *"all this and the wiki LLM and methodology goes before the modules."* The methodology layer needs to be in place + adaptable per project before module work begins. Pointer-only would require ongoing second-brain availability for every methodology operation.
- root-modules is type=root + group=operating-system-setup; some methodology gates (e.g. "lint passes" as a stage gate) need translation into infrastructure-specific equivalents (e.g. `./install.sh --dry-run` returns `unchanged` per file). Copy + adapt enables these translations.

**What it costs:** drift risk — the local methodology may fall behind the second brain's evolution. Mitigation: re-copy the engine + profiles when the second brain publishes a methodology update; only adaptations remain project-local.

**What it gains:** the project owns its methodology layer + adapts gates per-domain; doesn't require live connection to the second brain for stage-gate operations.

### Sister-project registration with `auto_connect: false`

**Choice:** root-modules is registered in the second brain's `sister-projects.yaml` with `auto_connect: false`. Connection requires explicit `--connect-project $HOME` invocation by the operator.

**Alternatives considered:** `auto_connect: true` (auto-hookup on `tools.setup` runs); not registered at all (no integration, no methodology-driven cross-project flow).

**Why `auto_connect: false`:**
- type=root projects gate the security envelope of the host. Auto-connect would bypass the operator's explicit-authorization step.
- The friction-by-design of `auto_connect: false` is intentional: integration requires a deliberate operator command. This is appropriate for a project that owns the machine-level safety policy.
- M010 (the auto_connect flip decision module) provides the operator-decision point to revisit this default after M009 stability is proven.

**What it costs:** operator must run `--connect-project` explicitly per host. Multi-host deployments require N explicit runs (one per host). This is acceptable given root-modules is currently single-host.

**What it gains:** explicit-authorization gate; consistent with the project's deny-by-default principle (the connection is a state change to $HOME, so it requires explicit operator input).

### Wifi as outbound-only management

**Choice:** the management wifi interface is configured as outbound-only — wifi client to operator's existing secure SSID, no inbound services bind.

**Alternatives considered:** wifi as inbound management (SSH on the wifi); wifi as access point (root-modules serves a wireless network alongside the inspection bridge); no management interface (console-only).

**Why outbound-only:**
- The bridge is L3-invisible to inspected-segment endpoints. The wifi gives the box itself internet access (apt updates, threat-intel feeds, AI APIs, outbound web) without exposing services on the inspected segment.
- Inbound management would expose attack surface on a security-sensitive appliance. The operator's threat model values minimal attack surface on the host itself.
- Console-only would lose operator's ability to update the host without physical access. The wifi gives outbound updates while preserving console-only-recovery for the worst case.
- AP mode (offering a wireless network) was operator-deferred per the prior session memory: typical wifi cards (e.g. RTL8821CE on rtw88) lack stable AP support; out-of-tree drivers are flaky. Deferred until AP-capable hardware is in place.

**What it costs:** operator has only a one-way diagnostic channel (logs + status reports out via wifi); inbound debugging is console-only.

**What it gains:** minimal attack surface on the appliance itself; outbound updates work normally; recovery story preserves console as the always-available fallback.

### `git init` at $HOME (deny-all + whitelist .gitignore)

**Choice:** the repo is structured to be `git init`'d at `$HOME` itself. The `.gitignore` is deny-all + whitelist — only curated config files visible to git; everything else in $HOME stays local.

**Alternatives considered:** repo at `$HOME/<projectname>` (conventional sub-directory); repo at `/etc/root-modules` (system-level, not user-level).

**Why git init at $HOME:**
- Files installed by the project live in `$HOME/.claude/` and `$HOME/.config/opencode/` — these are SUB-PATHS of `$HOME`. A repo at `$HOME/<projectname>` would not naturally contain them; the install would have to copy from one location to another.
- A repo at `$HOME` directly contains the install destinations as part of the tree. The `.gitignore` deny-all + whitelist means only the curated files are tracked; the rest of `$HOME` (sessions, transcripts, history, ssh, env, credentials) stays local.
- This is the type=root scope-not-path property in concrete form: the repo IS the home directory; the home directory IS the operating-system-setup target.

**What it costs:** unusual repo layout — operators familiar with `cd ~/projectname && git status` would expect that pattern. This pattern is `cd ~ && git status`.

**What it gains:** install + repo are the same tree; no copy-from-repo-to-install indirection; `.gitignore` whitelist is the security gate that prevents accidental publishing of secrets.

## Anti-Patterns Deliberately Avoided

| Anti-pattern | Why we avoid | What we do instead |
|---|---|---|
| **Per-tool deny lists** | Drift across AI tools; an attacker exploits the most-permissive tool. | One source of truth, multiple adapters (no-policy-duplication invariant). |
| **Allow-by-default with deny rules** | Asymmetric cost — undetected dangerous action vs blocked legitimate operation. | Deny-by-default at every layer. |
| **Silent fail (refuse without telling the operator)** | Operator can't recover what they don't know failed. | Every refusal logs reason + (where useful) bypass mechanism. The hook architecture pattern requires reason + remediation + bypass. |
| **Tamper detection without integrity verification of the sentinel itself** | An attacker who compromises the sentinel can simulate "all OK." | The sentinel is integrity-protected (its size + checksum is part of the verification). Editing the sentinel itself triggers a check failure on next run. |
| **Modules tightly coupled to foundation** | Module installation gates on foundation hooks; module uninstall would break foundation. | Modules are facultative; foundation runs standalone; module integration interfaces are explicit slots, not implicit dependencies. |
| **Pointer-only methodology (no local copy)** | Project gates on second-brain availability for every methodology operation. | Copy + adapt per Adoption Guide step 1. |
| **Single-tier safety policy (no machine-level / project-level distinction)** | Project-level only doesn't cover sister-project sessions; machine-level only is too rigid for project-specific additions. | Two-layer architecture; machine-level fires first; project-level adds restrictions. |
| **Auto-connect for type=root projects** | Bypasses operator's explicit-authorization gate for projects that gate the security envelope. | `auto_connect: false`; explicit `--connect-project` invocation. |
| **Hardcoded interface device names** | Hosts vary; `enp2s0` on one host is `eth0` on another. | Configuration uses role-based names (upstream-eth, lan-eth, management-wifi); device names are install-time mappings. |
| **AI tools authored their own per-tool policy files** | Drift; multiple sources of truth. | The bridge plugin pattern: one canonical envelope, adapters per AI tool. |
| **Modules required at install time** | Forces operator into full install; loses incrementalism. | Facultative; first-install can have zero modules. |
| **Going-to-extremes pendulum (SB-082/093)** | Each correction triggers full-opposite swing; never adjusts by single dimension. Recurs across cycles when not structurally prevented. | Hard Rule 11 (additive ≠ discarding) + going-to-extremes pre-flight check (operating-principles.md #12b: state dimension + V_old + check for opposite-extreme; if yes, don't ship). |
| **Synthetic-test-claimed-as-verified (SB-091)** | Agent crafts test inputs matching its own model; runs test; claims "verified" without realizing test inputs were crafted to confirm the model. P4 violation. | Real-session diag-log evidence required for "verified" status on lifecycle code. Synthetic tests confirm structural fix only — behavioral-verification claim requires empirical (operator-confirmed or real-session captured). |
| **Platform-blame framing for own model errors (SB-110)** | When fix doesn't render as expected, default-attribute to "platform renders that way" without operator-empirical or diag-log evidence. Removes bug from agent's domain prematurely. | Evidence-priority hierarchy (operating-principles.md #5 extension): tier 1 operator-empirical > tier 2 diag-log > tier 3 subagent-research > tier 4 agent-inference. State the tier behind any platform-behavior claim; default-attribute is tier 4 inference. |
| **Architectural-vs-functional substitution (SB-111)** | Operator's directive specifies a mechanism ("I NEED IT WIRED" = a hook); agent proposes functionally-equivalent alternative ("agent emits inline") as if it satisfies the directive. | Treat outcome-equivalence ≠ directive-equivalence. Operator's choice of mechanism is part of the directive, not decoration. If named mechanism is impossible, surface that explicitly with evidence; don't substitute silently. |
| **Hallucinated artifacts gaining reality (SB-095)** | Agent invents an artifact (file, command, draft, hypothetical); subsequent cycles cite it as a real operator-known thing. | Hard Rule 4 (operator-words sacrosanct) + agent-drafted artifacts MUST be flagged as agent-DRAFT at every reference (frontmatter or body header); never treat as operator-known unless operator explicitly acknowledges. |

### Unified trigger model (signal → action → recovery)

Per `.claude/rules/trigger-model.md` (cycle 49). Insight: hooks, slash commands, skills, modes, tools, MCP, scheduled tasks, and sub-agents all share the same shape — `SIGNAL → ACTION → RECOVERY`. They differ in WHO fires the signal, HOW deterministic the action is, and WHAT the recovery loop looks like.

Three signal-source categories: **harness-deterministic** (hooks fire on lifecycle; tools fire when agent invokes), **operator-explicit** (slash commands), **semantic-match** (skills auto-trigger on prose).

Three action-determinism tiers: **programmatic** (tools/MCP — same input → same output), **scripted** (hooks/commands — 100% reliable when harness executes), **generative** (skills/modes/sub-agents — ~70-95% generative compliance).

Picking the right mechanism is per cost-of-false-positive vs cost-of-false-negative. Hard security gates → hooks (logical) or `permissions.deny` (deterministic). Persona shifts across turns → modes. Delegated research without context bloat → sub-agents. Recurring autopilot → scheduled task wrapping a slash command.

### Verbosity calibration discipline (anti-pendulum)

Per cycles 41-43 statusline UX iterations + SB-082 (extremes pendulum recurring). When correcting an over-A behavior, agent default is over-correct to over-B. Counter-pattern: **render-and-measure-both-extremes-and-pick-middle** before shipping any calibration. Settled rule of thumb for this project: full-word labels, compact ratio values (e.g. `Bugs: 13/7` not `SB:13/6` and not `SystemicBugs: 13 open · 6 recurring`). Every future calibration re-reads this section first to verify intent.

### End-of-cycle stamp delivery (Stop hook + systemMessage + ```ansi fence)

**Choice:** Stop hook fires `python3 -m tools.cycle --ansi-horizontal` (or `--ansi-fence`), output wrapped in ```ansi-fenced ANSI escapes, delivered via top-level `{"systemMessage": stamp}` JSON.

**Alternatives considered (all empirically rejected during SB-107 oscillation):** `hookSpecificOutput.additionalContext` for Stop event (rejected by Claude Code schema; renders as raw JSON-text); plain stdout no JSON (Stop stdout is dropped); `additionalContext` top-level (same JSON-text rendering); ```diff fence (operator-confirmed renders red/green only — limited palette); inline Bash `tools.cycle --color` output (works but only when agent generates a tool call; not "naturally" emitted by hook).

**Why systemMessage + ```ansi fence:** systemMessage is the only valid display channel for Stop hook per Claude Code schema. ```ansi fence renders embedded ANSI escapes as actual colors in operator's UI (red/green/yellow/blue/magenta/cyan/dim/bold). Persisted-config-driven (per `tools/stamp.py` + 6 `/stamp-*` slash commands + `$HOME/.claude/stamp-config.json`) instead of prompt-marker (failed empirically — markers sometimes not detected by Stop hook because UserPromptSubmit didn't fire in time, per SB-115).

**Default-hide-when-no-mode**: stamp.enabled=auto → render only when `$HOME/.claude/active-mode` is non-empty. When in no-mode state, operator must `/stamp-on` to opt in. Reflects operator's preference: stamp is autopilot-context tool, not always-on noise.

**What it costs:** Stop hook output position is "start of next operator turn" not "end of current agent turn" — Claude Code platform constraint. Operator confirmed acceptable when /stamp-* config delivers expected layout.

**What it gains:** persistent config (operator preference survives session restart); deterministic mechanism (slash-command writes to file, hook reads file — no race condition); /opt second-brain can inherit by consuming the same `tools/stamp.py` rather than maintaining a divergent copy (per SB-115 architectural correction — pending /opt-side propagation). DRAFT-quality per SB-116 UX redesign Epic placeholder.

### Agent-discipline-gate detection (UserPromptSubmit hook for runtime SB-090/094 enforcement)

**Choice:** combined `output-discipline-guard.sh` UserPromptSubmit hook detects high-confidence premise-construction-risk (SB-090 family) + operator-escalation (SB-094) patterns + **conditional-clause grammar (SB-120 — added 2026-05-06)**; emits single-line concise banner via `additionalContext` only when triggered; silent on routine prompts.

**Alternatives considered:** rule-text-only fixes in `.claude/rules/*.md` (SB-113 meta showed they don't hold under load — patterns recur); two separate UserPromptSubmit hooks (premise-guard + output-discipline-guard); 24-line verbose banner per detection (operator complained as too noisy).

**Why combined + single-line + high-confidence-only:** rule-text covers the discipline at design time, but runtime requires hook-detection layer. Multiple banners on same UserPromptSubmit would compete with each other. Single hook with **3 detection paths** (premise + escalation + conditional-clause) shares scaffolding. Single-line banner avoids visual noise. High-confidence-only triggers (enumerative observation, observational adjective, pronoun + state-adjective, ≥2 escalation markers, conditional-clause + immediate-imperative co-occurrence) avoid false-positive fatigue (premise-guard's prior failure mode — fired on every "?").

**What it costs:** ~85% generative compliance (agent reads banner; may or may not act on it). False negatives on ambiguous patterns (e.g. some pronoun-contractions still missed).

**What it gains:** deterministic detection of the highest-recurrence patterns. Banner appears in operator's UI as visible alarm — operator catches non-compliance even if agent ignores the nudge. Closes the SB-113 meta gap for hook-detectable patterns.

### Brain-inheritance pattern ($HOME source-of-truth + /opt INHERITS for operational tooling; knowledge flows OTHER direction)

**Choice (SB-115 closure 2026-05-06):** `$HOME` (root-modules) is the source-of-truth for **operational tooling** — hooks, slash commands, tools/*.py, settings.json wiring conventions, ANSI-fence rendering patterns, statusline widgets, mode-enforcement banner shape. `/opt` second-brain INHERITS / adapts these patterns. **Knowledge** (lessons, sources, sister-project profiles, methodology updates, decisions, principles) flows the OTHER direction (root-modules → second brain via `gateway contribute` after M007 connect).

**Alternatives considered:** $HOME and /opt as independent peers (each maintains own operational tooling — drift inevitable); /opt as source-of-truth + $HOME inherits (inverts the type=root scope-not-path property — operational tooling lives where the operating-system-setup project IS, not at the second-brain hub).

**Why this asymmetric inheritance:**
- $HOME is type=root + group=operating-system-setup — root-level operational tooling lives here as canonical. The second brain consumes operational patterns, not authors them.
- /opt second brain is the knowledge hub — its job is methodology + sources + lessons + patterns. Knowledge flow is /opt → consumers, but operational tooling flow is $HOME → /opt + sister projects.
- Operator-corrected the agent's "/opt has its own hook, separate from $HOME's" framing (SB-115 instance) — *"WTF WHY WOULD YOU SAY second-brain is different ?? you are the root retart... second-brain take everything from you...."* The framing is asymmetric inheritance, not peer-to-peer.

**What it costs:** when $HOME's hook evolves (e.g., SB-115 redesign of stamp config from prompt-marker to slash-command + persistent JSON), /opt's parallel hook needs explicit propagation — not automatic. Cross-project sync is operator-coordinated, not agent-automatic.

**What it gains:** clear ownership — when the question is "who owns this pattern?", the answer follows the inheritance arrow. No drift between ostensibly-equivalent operational tooling at $HOME and /opt; /opt tracks $HOME improvements deliberately. Codified at hot-path layer in CLAUDE.md / AGENTS.md **Hard Rule 12** for every-prompt enforcement.

### Compound + waterfall axes (two orthogonal design axes for layered context + state-flow)

**Choice (SB-123 closure 2026-05-06):** `.claude/rules/compound-and-waterfall.md` formalizes two orthogonal design axes that govern how state, context, hooks, and directives layer or flow: **compound** (additive layers at-a-moment — mode + priorities + mission + focus + impediment + live state visible simultaneously in mode-enforcement banner) AND **waterfall** (state flows event-to-event — SessionStart → UserPromptSubmit hooks → Stop → PreCompact → PostCompact → /orient).

**Alternatives considered:** single-axis design (only-compound — misses event-flow; only-waterfall — misses simultaneous-layering); ad-hoc per-feature design (no unified framework — drift across hooks/state-files).

**Why two orthogonal axes:**
- Failure modes are distinct: **compound failure = collide** (layers replacing instead of stacking; SB-121 cron-prompt + operator-typed-prompt collide); **waterfall failure = truncation** (earlier-stage state lost downstream; SB-078 / SB-079 PreCompact / PostCompact reliability).
- Holding both axes prevents both failure modes. New hooks, state files, brain pieces, render surfaces all evaluated per: "does it ADD to operator's view at-a-moment?" (compound check) AND "does it persist state to durable location for next event?" (waterfall check).
- Operator directive 2026-05-06: *"This also make me think of the compound and waterfall strategy I talked about once and how it propably fit into hooks and directives and brains files too... it should be compounding"*.

**What it costs:** more design surface to consider per new mechanism; documentation discipline required.

**What it gains:** structural prevention of compound-collide (SB-121) + waterfall-truncation (SB-078/079) failure classes. Cross-references with [`.claude/rules/trigger-model.md`](.claude/rules/trigger-model.md) (mechanism axis) and [`.claude/rules/context-engineering.md`](.claude/rules/context-engineering.md) (timing axis) to provide a 3-axis design space.

### Productive-cycle action vocabulary (M-E001-1 — Hard Rule 14 — universal cross-tool ACTION layer)

**Choice (SB-128(b)+(c) closure 2026-05-06):** `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md` defines 9 canonical action types every cycle-fire emits — `sb-closure / verified-edit / drift-fix-with-empirical / explicit-standby-with-named-reason / new-artifact / doc-refresh / blocker-surface / operator-directive-register / read-only-audit`. Mandatory cycle-report last-line: `Productive output: <type> — <one-line specific>`. Codified at hot-path layer as **Hard Rule 14** in CLAUDE.md / AGENTS.md.

**Alternatives considered:** per-tool action vocabularies (Claude Code emits one set, opencode emits another — drift); no vocabulary (cycle-fire substance is implicit — SB-128 thin-output bug recurs); lighter vocabulary (4 operator-canonical from mindfulness clause #6 only — incomplete; some cycle-emissions don't fit any of the 4).

**Why 9-type vocabulary + mandatory last-line + cross-tool universal:**
- 4 operator-canonical types (mindfulness clause #6) cover SB closure / verified-edit / drift-fix / explicit-standby — but couldn't classify all real fires per empirical 13-fire validation (e.g. /audit run was unclassified — read-only-audit added as type 9).
- 5 agent-extension types (new-artifact / doc-refresh / blocker-surface / operator-directive-register / read-only-audit) flagged as agent-DRAFT per SB-095 — operator-revisable.
- THIN standby without named subject is the SB-128 bug — the vocabulary structurally forbids "thin standby" (it's not in the list) — SB-099 abdication-as-freeze becomes structurally impossible if cycle MUST emit one of the 9.
- Cross-tool universal — every AI tool's cycle skill emits the same vocabulary; consistent action layer regardless of which AI tool fires the cycle.

**What it costs:** vocabulary is DRAFT v2 — operator-revisable; future iterations may add/remove/rename types. Cycle-report last-line is overhead per fire (one line of structured output).

**What it gains:** structurally prevents SB-128 thin-output recurrence; cross-tool consistency at action layer; operator can audit cycle output per-fire by checking the last-line declaration; fits the unified trigger-model (signal → action → recovery) — this is the **action** layer.

### Active Objective Layer state files (SB-118 + SB-127 + SB-124d)

**Choice (2026-05-06):** Multi-cycle objective tracking **ABOVE** active-task cursor — state files at `$HOME/.claude/active-{mission,focus,impediment,priorities,task}` managed by `tools/{objective,priorities,tasks}.py` + slash commands `/mission` / `/focus` / `/impediment` / `/priorities` / `/task`. Read by mode-enforcement.sh (banner) + cycle.py (stamp) + mcp_server.py (root_objective MCP tool) + /handoff (handoff doc) + pre-compact.sh (handoff snapshot).

**Alternatives considered:** active-task cursor only (single-layer — operator can't track multi-cycle objective beyond current task); embedded objective in every doc (drift across docs); single state file with multiple sections (hard to update per-layer).

**Why 5 separate state files at increasing granularity:**
- **Mission** (multi-cycle objective): operator-set; survives across many cycles; e.g. "ship root-modules MVP — close systemic-bug audit + advance M003 Foundation gate"
- **Focus** (sub-objective within mission): operator-set; survives across cycles; e.g. "iterate hooks/context/engineering quality + mission+focus build"
- **Impediment** (block on focus, comes-and-goes): comes-and-goes per cycle; e.g. "(none — focus unblocked)" or specific blocker
- **Priorities** (imminent-work tier ABOVE PM blockers — SB-127): operator's hot-queue; verbs add/show/clear/remove/promote/demote/set/insert/update for fluid management
- **Task** (current backlog cursor — SB-124d): single ID like "T012"; pre-compact.sh + /handoff read this for state preservation
- Granularity matters because each layer has different update frequency + different durability + different consumer set.
- Operator directives 2026-05-06: *"this make me think if we dont also need a current mission and a current focus... we can even add impediment.. this is another sub-level from a focus that is blocked for example"* + *"my new STP file which would contain a list with task-and/or-focus combo with priotities that should be identified as the imminent work, even before the PM work"*.

**What it costs:** 5 state files to manage; operator must learn 5 verb-vocabularies (`/mission set` vs `/focus set` vs `/impediment set` vs `/priorities add/promote/demote/insert/update` vs `/task set`).

**What it gains:** rich objective layer surfaced consistently across mode-enforcement banner + stamp + MCP server + handoff doc + pre-compact snapshot. Operator can ad-hoc reorganize priorities (insert / update / promote without losing other entries) per SB-130. Cycle skills + cron-fire iterations can pick top priority deterministically.

### Doc-update-discipline as design pattern (additive ≠ discarding — Hard Rule 11)

**Choice (Hard Rule 11 codification 2026-05-06):** When updating any agent-context doc (CLAUDE.md / AGENTS.md / sister docs / sub-READMEs), the discipline is **additive** — layer new content; refresh inline values where empirically drifted (with empirically-verified-YYYY-MM-DD timestamp); do NOT replace existing sections wholesale unless operator explicitly directs. Codified at hot-path layer as Hard Rule 11 in CLAUDE.md / AGENTS.md for every-prompt-context-budget enforcement.

**Alternatives considered:** "rewrite to current state" pattern (lose historical provenance + go-to-extremes pendulum SB-082/093 recurrence); "freeze the doc; never update" (drift accumulates indefinitely); "operator decides every change" (slow + bottlenecks operator).

**Why additive ≠ discarding:**
- Operator-corrected this exact pattern in 2026-05-06 evening session: *"Why are you not able to just do normal improvements instead of causing regression and we need to revert.. if you had done your update properly that would not have happened..."* The lesson: deletion-because-newer-canonical-exists is regression; addition-of-pointer-to-newer-canonical is improvement.
- Going-to-extremes pendulum (SB-082/093 family) recurs when an agent rewrites instead of revises. Pattern: agent sees drift between an existing section and a newer canonical → reflex is to REPLACE the section. Operator catches: replacement loses content + introduces new bugs; addition of cross-reference is the right move.
- Historical provenance is value-add, not waste. Recent Operator Directives table + Recent Work Completed table + ADR table + Operator-Pending Decisions table all use append-only discipline preserving historical accurate-as-of-its-time entries.

**What it costs:** docs grow over time (line counts increase). Per Hard Rule 15 (empirical-count-verification before drift-claim), inline values ARE refreshed; structure is preserved.

**What it gains:** structural prevention of going-to-extremes pendulum (SB-082/093 family). Historical provenance preserved across all append-only sections. Cross-tool universal — every AI tool's doc-update work obeys this discipline.

## Trade-offs Taken (vs Alternatives)

| Choice | Alternative considered | Why this one wins for root-modules |
|---|---|---|
| Deny-by-default | Allow-by-default | AI safety context: cost of undetected dangerous action >> cost of false-positive friction |
| Fail-closed (tamper) + Fail-open (Suricata bypass option) | Uniform fail-mode | Different layers have different cost asymmetries; matched per-layer is correct |
| Markdown-as-IaC | Structured-database config | Human + AI readability + diff-ability outweighs query expressiveness at this project's micro scale |
| No-policy-duplication | Per-tool policies | Cross-AI-tool drift is the worst failure mode in multi-AI environments |
| Stealth L2 bridge | L3 router | Reduces operator-side L3 reconfiguration; the "ghost" property is project intent |
| Facultative modules | Required modules | Operator-stated incrementalism + license-tier flexibility |
| Two-layer hooks | Single-tier | Sister-project sessions on the same host inherit safety policy uniformly |
| Methodology copy + adapt | Pointer-only | Project owns gates per domain; doesn't gate on live second-brain availability |
| `auto_connect: false` for type=root | `auto_connect: true` | Friction-by-design appropriate for security-envelope projects |
| Wifi as outbound-only management | Inbound SSH on wifi | Minimal attack surface on a security-sensitive appliance |
| `git init` at $HOME | Repo at `$HOME/<projectname>` | Install destinations are sub-paths of $HOME; repo IS the home directory |
| **Additive ≠ discarding** (Hard Rule 11) | Replace-and-rewrite pattern | Going-to-extremes pendulum (SB-082/093) prevention; historical provenance preserved across all append-only sections; cross-tool universal lesson |
| **Brain-inheritance pattern** ($HOME → /opt for operational tooling) | Peer-projects framing (independent maintenance) | Clear ownership; no drift between ostensibly-equivalent operational tooling; operator-corrected this exact pattern (SB-115) |
| **Chain operations per fire** (Hard Rule 13) | Single-edit-per-cycle | THIN-output anti-pattern (SB-128 family) prevention; substance pattern is multi-edit per fire that pulls along tracker + structural fix + regression-test + cross-references + decisions-logbook entry |
| **Empirical-count-verification before drift-claim** (Hard Rule 15) | Compound prior counts with current cycle's deltas | Compounding errors is recurring drift source across AI tools (SB-129 quality-recompile + ad-hoc count drift across multiple brain files); programmatic walk + parse before refreshing any count |
| **Productive-cycle taxonomy** (Hard Rule 14 — M-E001-1 vocabulary cross-tool) | Per-tool action vocabularies | Cross-tool drift prevention; structural impossibility of THIN standby (SB-128); 9 canonical action types every cycle-fire emits regardless of which AI tool fires |

## Open Design Questions (resolved + still-unresolved)

> **Historical-snapshot-vs-canonical-current discipline**: questions resolved are marked with D-ID reference (preserves provenance). Still-unresolved + new pending questions are listed below the resolved set. Canonical operational pending decisions live at [CONTEXT.md](CONTEXT.md) Operator-Pending Decisions table (refreshed 2026-05-06 evening with 13 still-pending including new Epic-pending items).

### Resolved (with D-ID + date)

| Question | Resolution | D-ID |
|---|---|---|
| Foundation IaC authoring approach | **GREENFIELD** (not extend prior debris) | D019 (2026-05-05) |
| Cleanup of prior $HOME debris | **LEAVE-IN-PLACE** (cleanup orthogonal/deferred) | D020 (2026-05-05) |
| install.sh greenfield authored (scaffold-stage stub) | + prior debris backed up | D022 (2026-05-05) |
| Network bridge configuration tool | **systemd-networkd** (per `--mode {bridge/endpoint/hybrid/auto}` flag decoupled from `--profile`; orthogonal composition) | D023 (2026-05-05) |
| install.sh implement-stage advance | **GREENLIT** (T012/T013/T014); real-execute = operator-driven future-session run | D024 (2026-05-05) |

### Still unresolved (require operator decision or future-session investigation)

| Question | Blocks | Notes |
|---|---|---|
| Suricata IPS mode failopen choice | M005 (Suricata-first path) | NFQUEUE+bypass (fail-OPEN) vs AF_PACKET copy-mode (fail-CLOSED at L2). Different threat models support different choices. |
| Project-internal verifier language | M004 | Python (aligns with `integrity.py` if extended) vs shell (aligns with install.sh + hooks). |
| Pre-commit vs CI integration | M004 | Pre-commit catches local-only drift; CI catches drift on every git push. Both possible, both have setup cost. |
| First module choice | M005 | Suricata-first ("passive before active") vs PolarProxy-first ("de-risk cert distribution first"). Operator decides per priority. |
| PolarProxy bypass list policy | M005 (PolarProxy path) | Default chrome-bypass list + operator additions vs operator-curated from scratch. |
| eBPF integration | Phase-2 | If/when AF_PACKET multi-thread + eBPF load balancing is needed for throughput beyond ~Gigabit. |
| Active response capability | Phase-3 | Operator-decision: should root-modules be able to actively respond (rewrite flows, inject responses, honeypot specific destinations)? |
| Multi-host deployment shape | Phase-2 | How many hosts? Each independent or coordinated? Configuration-management mechanism (Ansible / Salt / NixOS / direct git pull)? |
| FORWARD/OUTPUT nftables policy (T013) | M003 bridge data path closure | Default-accept vs default-drop FORWARD on the bridge; threat-model question. |
| Line-1 widget restoration shape (SB-104/105) | ccstatusline UX | Revert SB-103/SB-104 OR different shape (drafted aidlc-context-header.sh widget pending operator direction) |
| Stamp UX redesign Epic scope (SB-116) | Stamp UX maturity | Mechanism works (SB-114/115 closure); UX design quality DRAFT-tier; full Epic-level redesign awaiting operator scope |
| Mode-enforcement deeper Epic scope (SB-117) | Mode-enforcement maturity | Mechanism present (SB-056 closure); Epic-level engineering depth + per-mode tuning awaiting operator scope |
| Statusline + profile-variants design (SB-124b/c) | Statusline UX | Operator-coordinated; tight real-estate; profile-variants config schema (minified/normal/extended) awaiting operator direction |
| Productive-cycle vocabulary action-selection logic (M-E001-2) | Auto-pilot rework Epic | M-E001-1 vocabulary spec landed (DRAFT v2 — 9 types); M-E001-2 selection logic (which action to pick when multiple fit) awaits operator scope direction |
| Compound-retention layer mechanism (M-E003-1) | E003 epic | Single state file vs per-category retention layer; operator Q2 decision pending |

## Agent personal-learning notes (operator-allowed, per directive 2026-05-06)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. Entries are **agent-authored** (per SB-095 — agent-DRAFT, not operator-stated). Operator may revise / promote / remove. Each timestamped + initialed `[agent]`. DESIGN.md-specific framing — design-rationale-doc lessons.

### 2026-05-06 evening — DESIGN.md is the WHY (rationale), not the WHAT (architecture) or WHO/WHEN (state)

`[agent]` Three sister docs slice the same project from different angles: ARCHITECTURE.md = *what + how* (technical depth — topology / components / data flow / failure modes); SECURITY.md = *what protects against what* (specific threat protections); DESIGN.md = *why this and not something else* (alternatives considered + costs + gains). Don't duplicate. When a design choice touches architecture (e.g., "two-layer hooks"), the rationale lives in DESIGN.md; the implementation lives in ARCHITECTURE.md; the threat-model justification lives in SECURITY.md (if applicable).

### 2026-05-06 evening — Recent design subsections are append-only (chronological extension)

`[agent]` The Recent design subsections (originally 4 — unified trigger model · verbosity calibration · end-of-cycle stamp · agent-discipline-gate; extended 2026-05-06 with 5 more — brain-inheritance + compound+waterfall + productive-cycle taxonomy + Active Objective Layer + doc-update-discipline) are chronologically extended. Discipline: ADD new subsections at the END after the existing ones; never reorder; never modify existing subsections (they're operator-confirmed design rationale). New design choices that operator confirms become new subsections; agent-DRAFT design proposals stay in agent-personal-learning-notes (this section) until operator promotes them.

### 2026-05-06 evening — Anti-Patterns + Trade-offs tables are append-only

`[agent]` Both tables accumulate over project lifetime. Existing rows are operator-confirmed lessons. Discipline: APPEND new rows at the END (preserving the structural symmetry of the tables — anti-patterns: what we avoid + why + what we do instead; trade-offs: choice + alternative + why this one wins). Don't restructure or remove rows. The historical-provenance value of these tables is high — operators reference them when asking "have we considered X before?".

### 2026-05-06 evening — Open Design Questions table — mark resolved with D-ID, don't delete

`[agent]` When an Open Design Question is resolved (per D-ID in the decisions logbook), the right move is to MOVE the entry from "Still unresolved" to "Resolved (with D-ID)" sub-table and add the D-ID + resolution. Don't delete — preserves the historical context (someone may want to know why a particular question was asked + how it was answered). The historical-snapshot-vs-canonical-current discipline applies: DESIGN.md curates architectural rationale; CONTEXT.md tracks operational pending-decisions live state. Both layers preserved.

### 2026-05-06 evening — Hard Rules 11-15 are operationalization of design principles

`[agent]` The 4 cross-cutting Design Principles (deny-by-default · fail-closed/open · markdown-as-IaC · no-policy-duplication) are the doctrinal frame. CLAUDE.md + AGENTS.md Hard Rules 11-15 (additive ≠ discarding · brain-inheritance · chain-operations · productive-cycle taxonomy · empirical-count-verification) are the OPERATIONALIZATION at hot-path layer for every-prompt-context-budget enforcement. Doctrinal frame in DESIGN.md is read on-demand (when designing); hot-path Hard Rules in CLAUDE.md/AGENTS.md fire every prompt. Layered enforcement: design at slow-thoughtful tier; runtime at fast-reflex tier.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). Not ARCHITECTURE.md (technical depth) or SECURITY.md (specific threat protections). For DESIGN.md-specific design-rationale-doc lessons that benefit fresh-pickup agents but are too small to warrant their own design subsection. Operator promotes to structured artifact (new design subsection / new anti-pattern row / new trade-off row) when pattern matures.

## Cross-References

### Top-level brain files (10)

| For… | Read |
|---|---|
| What the project is + identity + modules + status | [README.md](README.md) |
| Cold-pickup orientation | [BOOTSTRAP.md](BOOTSTRAP.md) |
| System topology + components + data flow + module integration interfaces (the WHAT + HOW; DESIGN.md is the WHY) | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Threat model + protections + fail-closed invariants (the WHAT-PROTECTS-AGAINST-WHAT; DESIGN.md is the WHY) | [SECURITY.md](SECURITY.md) |
| Tool reference (when scripts exist) | [TOOLS.md](TOOLS.md) |
| Cross-tool agent contract + 15 universal Hard Rules (incl. Hard Rules 11-15 hot-path operationalization of Design Principles) | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing + 15 Hard Rules | [CLAUDE.md](CLAUDE.md) |
| Current operational state (Active Objective Layer + SFIF + pending decisions) | [CONTEXT.md](CONTEXT.md) |
| Skills directory context (skill-vs-command-vs-hook decision matrix) | [SKILLS.md](SKILLS.md) |

### Subdirectory READMEs (9 — DRAFT v1, agent-authored 2026-05-06 evening)

| For… | Read |
|---|---|
| Per-tool composition map + state-file architecture (operational implementation of design principles) | [tools/README.md](tools/README.md) |
| 30 slash commands by category | [.claude/commands/README.md](.claude/commands/README.md) |
| 18 hook scripts (10 wired + archive) by event — implementation of two-layer hook architecture | [.claude/hooks/README.md](.claude/hooks/README.md) |
| 3 modes + cycle-sequence comparison | [.claude/modes/README.md](.claude/modes/README.md) |
| 11 rules + strictness-tier matrix | [.claude/rules/README.md](.claude/rules/README.md) |
| 3 brain-loaded sub-agents | [.claude/agents/README.md](.claude/agents/README.md) |
| 2 skills + mechanism-choice context | [.claude/skills/README.md](.claude/skills/README.md) |
| 5 install template categories | [templates/README.md](templates/README.md) |
| Deployment + maintenance toolkit | [scripts/README.md](scripts/README.md) |

### Universal cross-cutting rules (operationalization of design principles)

| For… | Read |
|---|---|
| **Compound + waterfall axes** (the design pattern documented in this DESIGN.md as a Recent design subsection) | [.claude/rules/compound-and-waterfall.md](.claude/rules/compound-and-waterfall.md) |
| **Unified 8-mechanism signal→action→recovery model** (mechanism axis — complement to compound + waterfall) | [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) |
| Context-engineering (auto/pre/on-demand/facultative injection — timing axis) | [.claude/rules/context-engineering.md](.claude/rules/context-engineering.md) |
| Hook architecture rule (2-layer + 3-component design pattern + bypass mechanism per hook) | [.claude/rules/hook-architecture.md](.claude/rules/hook-architecture.md) |
| Operating principles (4 core + 11 extension + Hard Rules 11-15 mapping) | [.claude/rules/operating-principles.md](.claude/rules/operating-principles.md) |
| Operator-words sacrosanct + premise-confirmation gate + conditional-clause grammar | [.claude/rules/words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) |
| Self-reference (what $HOME IS + bidirectional inheritance pattern with /opt second-brain) | [.claude/rules/self-reference.md](.claude/rules/self-reference.md) |

### Brain-improvement mandate (this work block — 2026-05-06)

| For… | Read |
|---|---|
| Sacrosanct verbatim directive governing the brain-quality passes | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| **M-E001-1 productive-cycle action vocabulary DRAFT v2** (Hard Rule 14 — 9 canonical action types) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |
| Decision package log (RESOLVED — sub-READMEs scope) | [wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md](wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md) |

### Backlog + governance + log

| For… | Read |
|---|---|
| Methodology engine (canonical) | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| **40-entry decisions logbook (D001-D040)** — operational source-of-truth for ADR rationale | [wiki/governance/decisions.md](wiki/governance/decisions.md) |
| **138-row systemic-bugs tracker** — pattern-recurrence + closure record | [wiki/governance/systemic-bugs.md](wiki/governance/systemic-bugs.md) |

### Second brain (canonical sources)

| For… | Read |
|---|---|
| Second brain Adoption Guide (the strictly-defined sister-project adoption process) | `<second-brain>/wiki/spine/references/adoption-guide.md` |
| SFIF model canonical | `<second-brain>/wiki/spine/models/quality/model-sfif-architecture.md` |
| Markdown-as-IaC model canonical | `<second-brain>/wiki/spine/models/agent-config/model-markdown-as-iac.md` |
| Operator-verbatim project framing | `<second-brain>/raw/notes/2026-05-04-prepare-root-ghostproxy-as-sister-type-root-group-operating-system-setup.md`, `2026-05-04-custom-tailored-model-group-moe-intelligence-layer-and-root-ghostproxy-pain-point.md` |
