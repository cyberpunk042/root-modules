# root-modules

> **Fresh session?** Read [BOOTSTRAP.md](BOOTSTRAP.md) first — one-page cold-pickup guide.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct)**: when improving this README or any sister doc, **adding ≠ discarding**. Layer new content onto prior content; refresh inline values where empirically drifted (with empirical-verification command output inline); do NOT replace existing sections wholesale unless the operator explicitly directs. Going-to-extremes (SB-082/093 family) recurs when an agent rewrites instead of revises. Cycle taxonomy: see `$HOME/.claude/commands/cycle.md` "Productive cycle taxonomy" + `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md` (M-E001-1 DRAFT v2 — 9 action types) + `.claude/hooks/mindfulness.sh` clause #6 (4 canonical types).

**A root / home folder upgrader and evolver, with installable supplementary modules.** First and by default, root-modules is Infrastructure-as-Code that upgrades and evolves a root or home folder — idempotent install path, agent brain (hooks + rules + commands + modes + tools), methodology layer, endpoint AI agent safety at the OS-root level. Secondly, supplementary modules can be installed on top — like the **ghostproxy combo**: a transparent L2 inspection bridge sitting inline between an edge firewall (OPNsense) and the first switch on the LAN, with Suricata for signature-based IDS/IPS and PolarProxy for TLS termination, for deeper visibility into AI-related network traffic crossing the host.

> **Renamed 2026-07-19** — operator directive (verbatim, sacrosanct): *"root-ghostproxy has just been renamed into root-modules. lets update the repo as such. its at first and by default a root or home folder upgrader, evolver and secondly you can install supplementary modules like the ghostproxy combo."* The prior project name `root-ghostproxy` now names the network-inspection **module combo** (ghost bridge + proxy inspection), not the project. Historical records (`wiki/log/`, `docs/SESSION-*`, operator-verbatim quotes) retain the old name — sacrosanct + additive-not-discarding. Directive log: [wiki/log/2026-07-19-rename-root-modules-directive.md](wiki/log/2026-07-19-rename-root-modules-directive.md).

> "its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network... So its not just an IPS its a system AI safety setup project and the IPS tools (suricata and [polarproxy]) as modules" — operator, 2026-05-04
>
> "first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed" — operator, 2026-05-04
>
> "even in a user such as jfortin install too.. since its an operating system IaC project, even in a user such as jfortin it would remain a root-type project" — operator, 2026-05-04

## What This Is

root-modules is an Infrastructure-as-Code project that takes a Linux host (target: Debian 13, the operator's confirmed base distribution per the verbatim *"new machine (non-GUI) debian 13"*) and, per the 2026-07-19 rename directive, is *"at first and by default a root or home folder upgrader, evolver"* — and *"secondly you can install supplementary modules like the ghostproxy combo"*. The system-AI-safety-setup scope below remains: the foundation (upgrader/evolver half) carries the endpoint AI agent safety; the ghostproxy combo (module half) carries the network inspection. Operator's original framing of the project, verbatim (2026-05-04):

> *"its a new type of project but its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network. its aiming to **secure an OS and configure claude code and opencode at the root with all the safety needed**. it will do this and it will also offer in the future to for instance we use this machine or another [new] one. So its not just an IPS its a system AI safety setup project and the IPS tools (suricata and [polarproxy]) as modules."*

That single quote names two distinct capability halves:

- **Endpoint AI agent safety (core).** Configure Claude Code + opencode at the OS-root level with the safety controls needed for AI agents running on the host. This is the endpoint half of "system AI safety" — locking down what AI agents on the box can do.
- **Network inspection (modules).** Transparent L2 bridge between the OPNsense edge firewall and the first switch on the LAN, with Suricata (IDS/IPS) and PolarProxy (TLS termination) as facultative inspection modules. This is the network half — observing and (optionally) controlling what AI traffic crosses the LAN.

Both halves together = "system AI safety setup." Neither alone is the project. The operator's framing is that AI safety has to be addressed at both the endpoint where agents run AND the network where agent traffic flows.

The project is **multi-host capable by design.** Per the operator: *"it will do this and it will also offer in the future to for instance we use this machine or another [new] one."* The intent is that root-modules is portable IaC — the same setup deployable to a new machine when the operator brings a new host online.

The project is **type=root** because what it configures is the operating system itself. The "root" descriptor is a scope claim, not an install-path claim. Even installed under a non-root user account (the operator gave the example of `jfortin install too`), the project remains type=root because what it touches is system-level: AI agent policy at the endpoint, network configuration at the bridge layer, kernel-level packet handling, system services, security policy. group=operating-system-setup further classifies it within a class of projects whose purpose is to set up an operating system from scratch as opposed to add a layer on top of an already-configured one.

The project is at present **barely started** (operator's verbatim framing, 2026-05-04). Neither capability half is operational yet:

- **Endpoint AI agent safety:** the actual operator-authored Claude+opencode hardening config has not been written by this project's methodology-driven flow. The `$HOME` directory does contain prior-session AI artefacts (a README, an `install.sh`, hooks, `integrity.py`, an opencode bridge plugin) that attempted this scope, but the operator considers those artefacts AI debris from a prior session that is not authoritative — *"I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST"* — and they are not part of this project's authoritative state. The project's own authored implementation of the endpoint hardening is part of the future work.
- **Network inspection (modules):** transparent bridge install path does not yet exist as IaC. Suricata module is not yet integrated. PolarProxy module is not yet integrated.

What exists right now is the project's foundational scaffolding: identity registered with the second brain, methodology layer adopted from the second brain, backlog scaffolded with the active rollout epic + 14 modules, and the agent-context files (this README, plus CLAUDE.md, AGENTS.md, CONTEXT.md, and the secondary depth files) being authored. The actual implementation work — install scripts, systemd units, nftables rules, Claude+opencode hardening config (operator-authored from scratch, not extending the prior debris), Suricata configuration, PolarProxy deployment — is downstream of this foundation and most of it is operator-driven future-session work, not work this README's authoring conversation handles.

## The Naming: Ghost + Proxy (now the module combo's name)

> **Since the 2026-07-19 rename**, "ghostproxy" is no longer the project name — the project is **root-modules**. "Ghostproxy" survives as the name of the network-inspection **module combo** (the transparent bridge + Suricata + PolarProxy stack, per the operator's *"supplementary modules like the ghostproxy combo"*). The section below explains what the ghostproxy name encodes; it now applies to that combo.

The ghostproxy name encodes architectural intent.

**Ghost** refers to the transparent L2 bridge property: the box sits inline on the data path but has no IP address on the inspected segment. Endpoints on the LAN do not see it as a network hop; they see what looks like a direct connection to the OPNsense edge. From an L3 perspective the box is invisible. This is the standard "stealth bridge" deployment for inline inspection appliances and it is the architectural posture this project commits to.

**Proxy** refers to the TLS termination capability that the PolarProxy module enables. When PolarProxy is installed, the box becomes a transparent forward proxy for TLS streams crossing it: the proxy intercepts the encrypted stream, terminates and decrypts it, re-encrypts toward the destination, and emits the cleartext to a downstream consumer (typically Suricata) for inspection. Without the PolarProxy module, the box is not a proxy in any sense — just a passive L2 bridge. The "proxy" half of the name is conditional on the module being installed.

Together: **ghostproxy** = a stealth (L3-invisible) inline appliance that becomes a TLS proxy when its inspection modules enable that capability. The name captures both halves of what the module combo is designed to be at full installation.

## The AI Safety Thesis

Why does this project exist as a distinct thing rather than being "yet another transparent IPS appliance with a hardened OS layered on top"?

The operator's framing is that AI agents have become a category of computing where safety has to be addressed at TWO points: the **endpoint** where agents run + the **network** where agent traffic flows. Both points matter; neither alone is sufficient. root-modules addresses both, which is what makes it a "system AI safety setup project" rather than a generic IPS or a generic OS-hardening project.

### Endpoint half — AI agents running on the host

AI agents on a workstation or server are programs that take instructions from prompts and execute tool calls. Their security characteristics are unlike traditional applications:

- **Tool calls are the action surface.** An AI agent's effects are produced through tool calls (Read, Write, Bash, WebFetch, etc.). Whether an action is dangerous depends on the tool + the input. A `Bash` call to `cat /etc/passwd` is benign for inspection but malicious if its output gets exfiltrated. A `Read` call on `~/.env` is malicious regardless of intent. The endpoint policy layer needs to inspect *every tool call* against a deny-set and a behavior-pattern check.

- **Prompt injection turns instructions into commands.** Adversarial input embedded in tool outputs (a web page, a file, a search result) can hijack the agent's reasoning toward attacker-chosen actions. The endpoint policy can't prevent the model from being fooled, but it can prevent the model's resulting tool calls from causing real damage — deny credential reads, deny suspicious filesystem writes, deny exfil-shaped network calls, ask-for-confirmation on installs/sudo/cron.

- **Multi-AI-tool environments compound the attack surface.** Claude Code, opencode, Codex, Cursor, Gemini — each AI tool has its own runtime, its own policy mechanism, its own configuration. Without a shared policy source of truth, each tool has a different posture and the union of their behaviors is unpredictable. The foundation's design intent is a **shared policy source** that all installed AI tools obey through their respective extension mechanisms, so deny rules + behavior checks are not duplicated across tool runtimes — defined once at the OS-root level, enforced by every tool. The exact configuration shape (which file paths hold the policy, which extension API each tool uses to read it) is a Foundation-tier implementation decision authored by the project's methodology-driven flow.

- **Tamper resistance matters.** Once an attacker compromises an agent, the natural next step is to disable the agent's safety controls. The foundation's design intent is **fail-closed tamper detection**: if the policy source is missing, if hooks are disabled, if the deny-set is eroded below a known-safe threshold, if any required enforcement script is missing or non-executable, the system refuses every subsequent tool call until restored. That's the OS-level stop-gap when the agent itself can no longer be trusted. The exact tamper-detection mechanism is an authored implementation decision, not a foundational invariant.

### Network half — AI traffic crossing the LAN

AI agents and AI services have become a meaningful category of network traffic, and that category has its own safety characteristics that generic security tooling does not address well. Specifically:

- **AI agents make outbound calls.** Agents running on developer workstations, on personal devices, in home labs, in self-hosted services — they call out to LLM provider APIs (Anthropic, OpenAI, Google, etc.), MCP servers, tool-use endpoints, web sites they choose to fetch, code-execution sandboxes. Some of those calls are authorized; some are not. A network-position inspection appliance gives the operator ground truth on what's actually being called.

- **LLM traffic carries data the operator may not want leaving the LAN.** Prompts can include local file contents, environment variables, secrets, internal docs, and personal information. Model outputs can include data exfiltrated from the LAN or sensitive content the operator does not want broadcast. Inspecting LLM API traffic at the network layer catches what endpoint policies miss.

- **Prompt-injection-shaped traffic is detectable in patterns.** Adversarial prompts targeting agents follow recognizable shapes (instruction overrides, role-confusion patterns, unusual encoding, exfil-instruction-shaped content). Signature rules tuned for these patterns turn an IPS into an AI-safety surveillance layer.

- **Agent-action chains can be traced through traffic.** When an agent decides to perform a multi-step action (fetch X → process → call Y → write Z), the steps generate observable traffic that can be correlated post-hoc to understand what the agent did. The bridge is the natural correlation point because every step crosses it.

- **TLS encryption hides most of this.** Modern AI traffic is universally TLS-wrapped. Without TLS termination, an inspection appliance sees only TLS handshake metadata (SNI, JA3 fingerprint, certificate chain, protocol version) — useful for some signature rules but not for content inspection. The PolarProxy module exists to provide content-level visibility into TLS streams; it pairs with Suricata in the canonical pattern of: PolarProxy decrypts → emits cleartext PCAP-over-IP → Suricata reads from a dummy network interface fed by tcpreplay.

### The two halves complement each other

Endpoint policy catches "what the agent CAN do at the OS level"; network policy catches "what the agent IS doing in flight + what's coming back." A compromised agent that bypasses endpoint policy still has to send traffic — the bridge sees it. An agent whose traffic looks legitimate but whose endpoint actions are malicious (filesystem reads, persistence) — endpoint policy sees it. Either layer alone is incomplete; both layers together is the "system AI safety setup."

The same machinery applied to a generic security context (block known-bad IPs, match CVE patterns, alert on shellcode signatures) would be a generic IPS appliance. Applied to AI-related traffic + AI-agent endpoint behavior (LLM endpoints, agent traffic patterns, prompt-injection patterns, model-output exfil patterns, AI tool-call surface, fail-closed tamper detection, cross-AI-tool shared policy) it becomes a system AI safety setup. The hardware + machinery is the same; the policy lens + the cross-cutting endpoint+network coverage is what defines why this project exists as distinct.

## Position in the Network

```
   ┌──────────┐     ┌────────────┐     ┌──────────────────┐     ┌────────────────┐
   │ Internet │ ─→  │ OPNsense   │ ─→  │  root-modules │ ─→  │  first switch  │ ─→ LAN endpoints
   │          │     │ edge FW    │     │  (transparent    │     │                │     (workstations,
   │          │     │            │     │   L2 bridge)     │     │                │      AI agents,
   └──────────┘     └────────────┘     └──────────────────┘     └────────────────┘      services)
                                                ↕
                                       (modules optionally
                                        inspect / decrypt
                                        traffic in flight)
                                                │
                                                │
                                                ↓
                                       management wifi
                                       outbound-only
                                       management channel
                                       to operator network
```

The box has three network interfaces, each with a defined role:

| Interface | Role | L3 visible? |
|---|---|---|
| upstream-facing ethernet | One side of the bridge — typically the side facing OPNsense (upstream) | No (bridge member) |
| LAN-facing ethernet | Other side of the bridge — typically the side facing the LAN switch (downstream) | No (bridge member) |
| management wifi | Outbound-only management — wifi client to the operator's existing secure SSID, used for apt updates, threat-intel feeds, AI APIs, outbound web. NO inbound services on this interface. | Yes (host's own management IP) |

The two ethernet interfaces are members of a Linux bridge (typically `br0`) that forwards Ethernet frames in both directions. Endpoints on the LAN see what looks like a direct connection to OPNsense; OPNsense sees a direct connection to the LAN. The box is L3-invisible to both.

The wifi interface gives the box itself internet access and management visibility without exposing any services on the inspected segment. The firewall posture on the management wifi is **outbound-only**: input drops everything except established/related, output accepts. SSH and other management protocols are not bound to this interface; recovery in the worst case is through the local console.

This topology is what makes the project a "ghost" in the sense the name implies. It is also what makes the modules' inspection visible only to the box itself — endpoints on the LAN have no way to know whether the bridge is a passive forwarder or an active inspector.

Specific interface device names (e.g. `enp2s0` / `enp4s0` / `wlp3s0`, or `eth0` / `eth1` / `wlan0`, or others) depend on the host's hardware and udev naming. The architecture is described above in role terms; the concrete device-name mapping is a host-specific configuration item resolved at install time, not a project-level invariant.

## Identity (Goldilocks 9-Dimension)

The Goldilocks identity protocol from the second brain (`<second-brain>/wiki/domains/cross-domain/methodology-framework/project-self-identification-protocol.md`) defines nine dimensions that a project answers about itself in order to right-size its process. root-modules answers them as follows:

Per the second brain's **Consumer-Property Doctrine** (`execution-mode-is-consumer-property-not-project-property` lesson): some Goldilocks dimensions are **stable project properties** (true regardless of who's working on the project at any moment); others are **consumer/task properties** (defaults the consumer — the agent in a given session — can override). The table below marks each dimension's layer.

| Dimension | Layer | Value | Rationale |
|---|---|---|---|
| **Type** | Stable | `root` | The project configures the operating system — endpoint AI agent policy, network bridge config, system services, security envelope. Even when installed under a non-root user account, the scope of what the project changes is system-level. Type encodes the SCOPE of changes, not the install path. |
| **Group** | Stable | `operating-system-setup` | Within the `type=root` class, this project is specifically about turning a fresh OS into a configured-to-purpose host (rather than, say, adding an application layer on top of an already-configured host). **Group is a purpose-class axis**, distinct from Domain (technology axis). A project answers both: what tech is it (Domain) AND what's its purpose-class (Group). |
| **Domain** | Stable | Infrastructure | The project is infrastructure work — IaC, networking, system services, security tooling — as opposed to knowledge work, application code work, or research. **Domain is a technology axis** (TypeScript / Python / Infrastructure / Knowledge / etc.), distinct from Group (purpose-class). |
| **Phase** | State (mutable) | scaffold + partial-foundation | At time of writing the methodology layer + backlog scaffold + sister-project registration are in place (scaffold), and the agent-context files are being authored (also scaffold). The transparent-bridge install path itself does not exist (foundation is partial — pending). Phase changes as the project matures; this is the SFIF stage indicator. |
| **Scale** | State | micro | Single host. One physical box. Not a fleet. The project's full lifecycle plays out on a single machine. Scale would graduate if root-modules were ever deployed across multiple hosts simultaneously (operator's multi-host portability is intent, not yet realized). |
| **Execution mode** | Consumer/Task (default) | solo | Default is solo (one operator, one agent, conversation-driven). A future-session consumer could override to autonomous (operator authorizes a long-running task) or semi-autonomous (review gates per stage). The PROJECT supports any of these; the SESSION picks one. |
| **SDLC profile** | Consumer/Task (default) | simplified | Default is simplified (right-sized for micro + solo). Will graduate to default profile when Infrastructure-tier tooling lands and ceremony pays off. A consumer can override per session if a specific work block warrants tighter (or looser) ceremony. |
| **PM Level** | Consumer/Task (default) | L1 | Default is L1 (no harness, no fleet, single operator, markdown-tracked backlog). L0 = "no backlog at all"; L2 = cross-project coordination; L3 = full PM tooling. Consumer can override per session. |
| **Trust tier** | Consumer/Task (default) | operator-supervised | Default is operator-supervised. Approval gates apply to: endpoint-safety configuration, hook configuration, network-bridge changes, anything touching the upstream OPNsense relationship. The PROJECT requires operator-supervised for any non-trivial change; the consumer can request narrower scopes per session (e.g. "for this task only, autonomous on the README"). |

The full identity profile is the canonical source of truth for these dimensions and lives in the second brain at `<second-brain>/wiki/ecosystem/project_profiles/root-modules/identity-profile.md`.

### Path Semantics for type=root Projects

A type=root project's repo IS the user's home directory — the `.git` directory lives at `$HOME/.git`, not at `$HOME/<projectname>/.git`. This holds regardless of which user account owns the install:

| Install user | Homedir | Repo root |
|---|---|---|
| `root` | `$HOME` | `$HOME` (this machine) |
| `jfortin` | `/home/jfortin` | `/home/jfortin` (`.git` at `/home/jfortin/.git`) |
| any user | `~` | `~` (the homedir itself is the repo root) |

In `sister-projects.yaml`, the canonical form is `path: ~/` — Path.expanduser resolves at runtime per user. Root-type projects sit at `$HOME` directly, not at `$HOME/<projectname>`. This is what makes the project remain `type=root` regardless of install user (per the operator's logic: *"WHy root ? since it could have been jfortin install too.. since its an operating system IaC project, even in a user such as jfortin it would remain a root-type project"*).

### Path placeholders in this documentation

To keep docs portable across install users, two placeholders appear throughout:

| Placeholder | Resolves to |
|---|---|
| `$HOME/` | The project root on your machine — `$HOME` for canonical `type=root` install (Path A), or wherever you cloned the repo (Path B). |
| `<second-brain>/` | The research-wiki second brain on your machine — typically `$HOME/devops-solutions-information-hub/` for non-root install, or `/opt/devops-solutions-information-hub/` for the canonical dev-host install. The `RM_SECOND_BRAIN_ROOT` env var overrides (legacy `RGP_SECOND_BRAIN_ROOT` still honored, pre-2026-07-19 name); auto-detection chain is documented in `$HOME/scripts/mcp-launcher.sh`. |

When you read `$HOME/wiki/log/<date>-<slug>.md` in a doc, mentally substitute the path that matches your install. Code/scripts already auto-resolve via `Path.home()` + env-var fallback chains — no manual substitution needed at runtime.

## What Makes root-modules Distinct (vs Other Sisters)

The other four projects in the ecosystem (OpenArms, OpenFleet, AICP, devops-control-plane) are conventional sister projects with their own `$HOME/<projectname>` directory and project-internal scope. root-modules is structurally different:

| Property | root-modules | Other sisters |
|---|---|---|
| **Repo location** | `$HOME` itself (`git init` at the home directory) | `$HOME/<projectname>` (separate subdirectory per project) |
| **Install side-effects** | Writes to `$HOME/.claude/`, `$HOME/.config/opencode/`, system services. The install REACHES OUTSIDE the project directory by design. | Self-contained in the project's own directory. Install does not touch other parts of the filesystem. |
| **Two-layer hook architecture** | **Owns the machine-level hook layer** (`$HOME/.claude/settings.json` + `$HOME/.claude/hooks/*`). These fire on every tool call BEFORE any project-level layer in any other project. | Each has its own project-level `.claude/` (if any) — but no project-level layer overrides root-modules's machine-level deny rules. |
| **Cross-AI-tool scope** | Spans Claude Code AND opencode via the shared bridge plugin. One policy source of truth, two AI agent runtimes obeying it. | Each project is single-AI-tool-focused (own CLAUDE.md, own conventions). |
| **SFIF state** | scaffold + partial-foundation (barely started); foundation IaC pending | Generally Production phase (mature, used daily) |
| **Modules** | Has the modules concept (Suricata, PolarProxy facultative add-ons) | No equivalent module concept |
| **Multi-host design intent** | Portable IaC by design: *"this machine or another [new] one"* | Typically run on operator's primary developer machine; not designed for multi-host deployment |

The two-layer hook architecture point is load-bearing for the ecosystem: because root-modules installs at `$HOME` and configures `~/.claude/`, its hooks fire on tool calls in **all** Claude Code sessions on the host — including sessions opened in other sister projects. A LAN endpoint where root-modules is installed has its endpoint-AI-safety policy enforced uniformly across every AI-agent session, regardless of which project that session is operating in. This is what distinguishes "machine-level safety policy" (root-modules's job) from "project-level conventions" (every sister project's own `.claude/` directory, when present).

> **Brain inheritance pattern** (operator directive 2026-05-06, SB-115 closure): `$HOME` is the **source-of-truth for operational tooling** (hooks, slash commands, tools/*.py, settings.json wiring conventions, ANSI-fence rendering patterns, statusline widgets, mode-enforcement banner shape). `/opt/devops-solutions-information-hub/` (the second brain) **inherits / adapts** these patterns, not the reverse. When `$HOME`'s hook evolves (e.g., SB-115 redesign of stamp config from prompt-marker to slash-command + persistent JSON), `/opt`'s parallel hook should track the improvement, not maintain a divergent copy. Anti-pattern: framing $HOME and /opt as independent peers when /opt is structurally a consumer of $HOME's operational layer. Knowledge contributions flow the OTHER direction (root-modules → second brain via `gateway contribute`); see [.claude/rules/self-reference.md](.claude/rules/self-reference.md) "Bidirectional inheritance" section for the layered table.

## Architecture: Layered

The project is built in three independent layers. The foundation is required (it's the IaC + bridge + management envelope). The two module layers are facultative (they add inspection capabilities; the foundation runs without them).

```
                                        ┌──────────────────────────────────┐
                                        │  Layer 3 — TLS Inspection        │
                                        │  PolarProxy module (facultative) │  ← decrypt + re-encrypt
                                        │                                  │     emit cleartext PCAP
                                        └──────────────────────────────────┘
                                                       ↓ (cleartext)
                                        ┌──────────────────────────────────┐
                                        │  Layer 2 — IDS/IPS               │
                                        │  Suricata module (facultative)   │  ← signature-match
                                        │                                  │     alert + drop
                                        └──────────────────────────────────┘
                                                       ↓ (verdicts)
   ┌────────────────────────────────────────────────────────────────────────┐
   │  Layer 1 — Foundation                                                   │
   │  - Endpoint AI agent safety (Claude Code + opencode at OS-root level)   │
   │  - Transparent L2 bridge (two ethernet interfaces as members)           │
   │  - Outbound-only management (wifi interface)                            │
   │  - System services (systemd units for the bridge + management +         │
   │                     endpoint-safety integrity check)                    │
   │  - Network configuration (ifupdown / netplan / systemd-networkd)        │
   │  - IaC bootstrap (install path that turns a fresh host into this,       │
   │                   portable to any new host per operator's intent)       │
   │  - Methodology layer (wiki/config/methodology.yaml + 3 profiles)        │
   │  - Backlog + log scaffold (wiki/backlog/, wiki/log/)                    │
   │  - Sister-project integration with second brain (when authorized)       │
   └────────────────────────────────────────────────────────────────────────┘
                                                       ↑
                                            Host OS (Linux — Debian 13 confirmed)
```

The foundation is functional standalone. A box with just the foundation installed is a transparent bridge with no inspection — useful for stealth deployment, segment isolation, or as a baseline before module rollout. Adding Suricata gives the box IDS/IPS without TLS visibility. Adding PolarProxy gives the box TLS visibility but only fed to a downstream consumer (typically Suricata). The two modules together are the canonical AI-safety inspection stack.

This layering makes the project's growth incremental. The operator's intent is captured in a directive verbatim:

> "first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed"

A "full install" deploys all three layers. A partial install runs the foundation alone, or the foundation plus one module. The architecture explicitly supports the intermediate states.

## The Foundation

The foundation is the always-required layer. It contains everything that turns a fresh Linux host into a system-AI-safety-setup-tier host: endpoint AI agent safety + transparent inspection bridge + methodology/sister-project plumbing. It does NOT include the inspection modules — those come later.

Foundation responsibilities:

| Responsibility | Description |
|---|---|
| **Endpoint AI agent safety (core)** | Configure Claude Code + opencode at the OS-root level with the safety controls operator wants for AI agents running on the host. Per operator's verbatim: *"secure an OS and configure claude code and opencode at the root with all the safety needed."* This is the endpoint half of system AI safety. The actual configuration (deny-set patterns, hook scripts, integrity check, opencode bridge mechanism) is authored by the project's methodology-driven flow, not extended from prior $HOME debris. |
| **Network topology** | Configure the two ethernet interfaces as members of a Linux bridge (typically `br0`). Bring up the wifi as outbound-only management. Set the bridge MTU, disable hardware offloads (GRO/LRO/TSO) that interfere with downstream inspection, configure the wifi as a client to a known SSID. |
| **Stealth posture** | The bridge has no IP on the inspected segment. The wifi has the only L3-visible IP. The host is L3-invisible to LAN endpoints; recovery in the worst case is via the local console. |
| **System services** | systemd units for the bridge (auto-bringup at boot, auto-recovery on link flap), for the management wifi, for any post-install verification scripts, for the endpoint-safety integrity check. |
| **Idempotent install** | A single install command takes a fresh Linux host and brings it to foundation-tier state (both endpoint safety + network topology). Re-running the install on an already-configured host is a no-op. Multi-host portability is a foundation requirement per operator: *"it will do this and it will also offer in the future to for instance we use this machine or another [new] one."* |
| **Methodology layer** | The second brain's stage-gate methodology copied into `wiki/config/`. Adapted per the Adoption Guide: artifacts, gate commands, commit scope, directory paths are project-specific variables; stage names, ordering, readiness ranges, hierarchy rules are kept as ecosystem-wide invariants. |
| **Backlog + log scaffold** | The directory structure for epics, modules, tasks, and operator log entries. Indexed and ready to receive work. |
| **Sister-project integration capability** | The agent-context files (this README, CLAUDE.md, AGENTS.md, CONTEXT.md, ARCHITECTURE.md, TOOLS.md, DESIGN.md, SECURITY.md, SKILLS.md) populated with project-real content so the connection mechanism (`tools.setup --connect-project $HOME` from the second brain) finds a target it can integrate with. |
| **Identity declaration** | `<second-brain>/wiki/config/sister-projects.yaml` has the entry. `<second-brain>/wiki/ecosystem/project_profiles/root-modules/identity-profile.md` has the full Goldilocks profile. The project is registered with the second brain. |

What the foundation does **not** include (and what is therefore not part of the always-required base):

- Suricata. Suricata is a facultative module (Layer 2 of the layered architecture).
- PolarProxy. PolarProxy is a facultative module (Layer 3 of the layered architecture).
- AI-specific Suricata rule sets. Those layer onto the Suricata module when it's installed.
- TLS-firewall ruleset for PolarProxy. That layers onto the PolarProxy module when it's installed.
- Per-AI-tool extensions beyond Claude Code + opencode (e.g. Codex, Cursor, Gemini). The foundation's endpoint-safety scope is operator-named: Claude Code + opencode. Other AI tooling would be additional modules at install time.

## The Modules — Facultative

Two inspection modules are named in the project's vision. Both are facultative — the operator decides at install time which (if any) to deploy. Both are installed by IaC (not hand-deployed) once their respective module work lands.

### Suricata (IDS/IPS Module)

**Role.** Inline signature-based detection on the bridge data path. Suricata ingests packets crossing the bridge, matches them against a rule set, and either alerts (IDS mode) or drops (IPS mode) flows that match malicious or AI-policy-violating patterns. Suricata also emits structured event logs (the canonical eve.json output) that downstream tooling (Filebeat, Loki, custom log shippers) can consume.

**Sourcing.** The Suricata module's design is informed by source-synthesis pages already produced in the second brain during the foundation's preparation:

- `<second-brain>/wiki/sources/src-suricata.md` — Layer 0 README + repo metadata
- `<second-brain>/wiki/sources/src-suricata-install-quickstart.md` — Layer 1 install paths (PPA / Debian / source build), suricata.yaml HOME_NET + interface examples, the canary alert SID 2100498 + curl testmynids.org pattern
- `<second-brain>/wiki/sources/src-suricata-ips-mode-linux.md` — Layer 1 the 5 IPS modes (NFQUEUE+iptables, NFQUEUE+nftables, AF_PACKET, DPDK, Netmap), failopen via nftables `bypass`, the **br0-vs-AF_PACKET-IPS architectural decision** that root-modules must explicitly resolve at module-design time
- `<second-brain>/wiki/sources/src-suricata-yaml-config.md` — Layer 1 suricata.yaml master config navigation (22 sub-sections + 8 sub-chapters), action-order semantics, EVE JSON, threading, hardening

**Architectural decisions deferred to module-design time.** The Suricata IPS Mode synthesis flags a load-bearing architectural choice for root-modules specifically:

- **Phase-1 path:** keep the Linux bridge `br0`, use NFQUEUE on the FORWARD chain with the `bypass` option for failopen. Simpler. Failopen behavior: when Suricata is down, traffic flows uninspected (network keeps working).
- **Phase-2 path:** retire the kernel bridge, use AF_PACKET IPS mode with the two ethernet interfaces paired via `copy-mode: ips`. Tighter integration. Failopen behavior: when Suricata is down, the copy stops and packets pile up at the NIC (fail-CLOSED at L2).

This decision belongs in the Suricata module's design doc, not in this README. The decision needs to be made before the module's install path is authored.

**Status.** Not installed. Not yet integrated. Module page: [wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md](wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md). Operator-driven future-session work.

### PolarProxy (TLS Inspection Module)

**Role.** Transparent TLS termination + re-encryption. PolarProxy intercepts TLS streams on the bridge data path, decrypts them using a dynamically generated CA (or an operator-supplied CA), re-encrypts toward the destination, and emits the cleartext as PCAP-over-IP or rotated PCAP files. The cleartext is consumed by Suricata via a Linux dummy interface fed by `tcpreplay` (the canonical Suricata + PolarProxy integration pattern).

**Sourcing.** The PolarProxy module's design is informed by:

- `<second-brain>/wiki/sources/src-polarproxy.md` — Layer 0 from the Netresec product page. Captures PolarProxy's 8 modes of operation (Transparent Forward, Reverse, TLS Termination, Transparent In-Line, mTLS, SOCKS, HAProxy, HTTP CONNECT) plus the TLS Firewall mode (rule-driven). Captures license tiers (free up to 10 GB / 10 000 sessions / 10 000 rule-matches per day; paid tiers L1 / L2 / L3 / Offline). Captures three routing patterns (gateway-side iptables REDIRECT; separate-machine DNAT; client-side OUTPUT redirect). Captures CA distribution requirements (clients must trust the proxy's CA; OS-level + browser-level + AD GPO + Android cert pinning bypass + iOS trust settings).
- `<second-brain>/wiki/sources/src-hanke-honeypot-polarproxy-suricata-integration.md` — Layer 1 Hanke's master's-thesis honeypot writeup. The canonical PolarProxy → Suricata integration pattern: dummy network interface (`ip link add polarproxytls type dummy`) + PolarProxy's `--pcapoverip` listener + `tcpreplay -i polarproxytls -t -` bridging the PCAP-over-IP socket to the dummy interface + Suricata's af-packet config listing the dummy interface as a capture source.

**Architectural decisions deferred to module-design time.**

- **Mode choice.** For root-modules's bridge topology, the natural mode is Transparent Forward Proxy with a TLS-firewall ruleset (so banking / healthcare / chrome-pinned domains bypass decryption while inspectable destinations are decrypted). The 7 other modes are out-of-scope for this appliance.
- **CA distribution.** PolarProxy's dynamic CA must be installed as a trusted root on every LAN endpoint whose traffic is decrypted, OR root-modules's threat model accepts that untrusted-CA endpoints will see cert errors.
- **License tier.** The free tier (10 GB / 10 000 sessions / 10 000 rule-matches per day) caps inspection volume. Past the cap, PolarProxy fails OPEN — keeps forwarding TLS but stops decrypting. Operational monitoring needs to alert on the rate of TLS sessions seen vs decrypted, divergence after the cap is the signal.

**Status.** Not installed. Not yet integrated. Operator-driven future-session work, ordered by the operator after the Suricata module (typical pattern is passive-before-active = Suricata-first; PolarProxy-first is also valid if cert distribution is the higher-uncertainty risk to de-risk first).

### Future Modules + Extensibility

The architecture is intentionally extensible. The two named modules (Suricata, PolarProxy) cover the IDS/IPS + TLS-decrypt inspection base. Future modules might layer on additional capabilities:

- **eBPF-based traffic classification** — Linux eBPF programs that tag flows with custom classifications (e.g. "this flow is to an LLM provider," "this flow is suspected exfil") for downstream rule-matching by Suricata.
- **AI-specific signature feeds** — curated rule sets for prompt injection patterns, model-output exfil patterns, agent-action chains. Distinct from generic ET Open / ET Pro / Talos rule sets.
- **Per-flow audit logging** — beyond Suricata's eve.json, a dedicated audit channel that captures per-AI-flow metadata (model identified, prompt characteristics, output classification) for forensic review.
- **Active response capability** — a controlled bypass mode where root-modules can rewrite flows, inject responses, or honeypot specific destinations as part of an active defense.

These are not committed work; they are the kind of extensibility the modular architecture supports. Each future module would have its own module page, its own design doc, its own facultative install option.

## Current State (Barely Started)

The project is at the **scaffold + partial-implement** SFIF stage. Concretely, this means:

> **Note (added cycle 62, 2026-05-05; refreshed 2026-05-06 post-handoff iteration; refreshed 2026-05-06 evening under /loop with empirical re-verification)**: the "barely started" framing comes from operator's verbatim 2026-05-04 directive (preserved sacrosanct in section "Operator Directives Captured This Session"). Substantial scaffolding has landed since: **14 modules + 66 atomic tasks + 4 epics (E001 auto-pilot rework / E002 piling-tasks / E003 compound-retention / sfif-rollout) + 1 milestone (v0.2)** + 9-10 top-level brain files + **40 decisions logbook entries** (latest D040 captures the Q1-Q4 self-elevation closure) + `install.sh` dry-run-passing + **17 `.sh` hook scripts on disk; 10 wired matchers across 8 events** (PreToolUse / PostToolUse / SessionStart / UserPromptSubmit / PreCompact / PostCompact / Stop / SessionEnd) — unwired hook scripts retained as archive per operator directive 2026-05-06 *"label them as archive if they are not usefull anymore. dont necessarily delete them"* + 9 custom statusline widgets (operator visually verified) + aidlc-objective.sh widget (SB-124b — agent-drafted, not yet wired) + **3 brain-loaded subagents** + trigger-model.md + compound-and-waterfall.md unified rules (the 10th and 11th rule files) + ccstatusline integration + deployment scripts at $HOME/scripts/ + **8 hook regression test files** + tools regression suite at .claude/hooks/tests/ + tools/tests/ + **30 slash commands** (incl. /stamp-* config + /install-agent-brain + /mission /focus /impediment SB-118 + /priorities SB-127 + /terminate /finish-smoothly + /task SB-124d + /questions SB-134) + **15 deterministic Python tools** (state/blockers/progress/decisions/cycle/tasks/stamp+density/objective/priorities/questions/+helpers) + MCP server with root_objective tool + **138-row systemic-bugs tracker (max ID SB-138; 1 historical duplicate ID)**. The project-lifecycle macro stage is still scaffold (foundation gate met for `install.sh --dry-run`; T012 advance to implement-stage GREENLIT per D024 — execute is operator-driven future-session work).
>
> **Counts verified empirically 2026-05-06 evening** by `/opt/.../.venv/bin/python` walking `tools/`, `.claude/{commands,hooks,rules,modes,agents,skills}/`, `wiki/backlog/{epics,modules,tasks,milestones}/`, `wiki/governance/{decisions.md,systemic-bugs.md}` + `.claude/settings.json`. Drift between this paragraph and the earlier "What exists right now" table is structural; refresh both when one is updated.

### What exists right now (refreshed 2026-05-06 evening — counts verified empirically)

| Artefact | Status | Where |
|---|---|---|
| Identity registered with the second brain | Complete | `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-modules` (type=root, group=operating-system-setup, auto_connect=false) |
| Identity profile in the second brain | Complete | `<second-brain>/wiki/ecosystem/project_profiles/root-modules/identity-profile.md` (full Goldilocks 9-dimension) |
| Methodology engine | Copied from second brain | `$HOME/wiki/config/methodology.yaml` |
| SDLC profile | `simplified` | `$HOME/wiki/config/sdlc-profile.yaml` |
| Domain profile | `infrastructure` | `$HOME/wiki/config/domain-profile.yaml` |
| Methodology profile | `stage-gated` | `$HOME/wiki/config/methodology-profile.yaml` |
| Active epic | `SFIF Rollout + Second-Brain Integration (2026-05)` | `$HOME/wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md` |
| 14 module pages | M001–M014 across Stream 2 SFIF base + Stream 1 second-brain integration + ccstatusline + pipelock | `$HOME/wiki/backlog/modules/root-modules-m{001..014}-*.md` |
| 66 atomic task pages | Per-module breakdowns | `$HOME/wiki/backlog/tasks/T*.md` |
| 4 epic pages + 1 milestone | sfif-rollout (active) + E001 auto-pilot-rework + E002 piling-tasks + E003 compound-retention; milestone v0.2 ai-natural-task-management active alongside v0.1 | `$HOME/wiki/backlog/epics/*.md` + `wiki/backlog/milestones/*.md` |
| Source-synthesis pages (Suricata + PolarProxy) | 6 pages in second brain | `<second-brain>/wiki/sources/src-{suricata*,polarproxy,hanke-honeypot-polarproxy-suricata-integration}.md` |
| **`install.sh`** (foundation installer) | Authored, implement-stage, readiness 98% — `--dry-run` + `--check` + `--profile {base\|full\|project\|interactive}` + `--mode {bridge\|endpoint\|hybrid\|auto}` + per-op toggles. shellcheck PASS. | `$HOME/install.sh` |
| **Per-project install** (`--profile project`) | Deploys agent brain (settings + hooks + rules + commands + agents + modes + skills + tools) to a sister project; OS-level ops disabled in this profile | `$HOME/install.sh --profile project --dest <path>` OR `/install-agent-brain <path>` slash command |
| **Network bridge config templates** | systemd-networkd .netdev + .network templates | `$HOME/templates/systemd-networkd/*.{netdev,network}` |
| **Management wifi (outbound-only)** | wpa_supplicant template + nftables INPUT-drop ruleset + idempotent /etc/nftables.conf include + systemd unit enable | `$HOME/templates/{wpa_supplicant,nftables}/` |
| **Integrity sentinel** | SHA256 baselines for safety-policy artefacts; `op_install_integrity_sentinel` registers; `op_verify` + `integrity_check()` validate | `$HOME/.claude/integrity.json` (per host) |
| **Post-install verification** | `install.sh --check` runs 16+ checks: settings.json parses, hooks executable, integrity match, opencode bridge, br0 UP, wifi config + ruleset + table loaded + service enabled, brain-piece counts | `$HOME/install.sh --check` |
| **Agent context files** (10) | README + CLAUDE.md, AGENTS.md, BOOTSTRAP.md, CONTEXT.md, ARCHITECTURE.md, TOOLS.md, DESIGN.md, SKILLS.md, SECURITY.md | `$HOME/*.md` |
| **30 slash commands** | /orient, /handoff, /cycle, /stamp-{on,off,auto,horizontal,vertical,status}, /mode-{pm,architect,dual,clear,status}, /blockers, /progress, /decisions, /audit, /sync-progress, /log, /help-root, /install-agent-brain, /mission, /focus, /impediment, /priorities, /terminate, /finish-smoothly, **/task** (SB-124d cursor + create verbs), **/questions** (SB-134 retention) | `$HOME/.claude/commands/*.md` |
| **3 brain-loaded subagents** | root-explorer, root-architect, root-pm-scoper | `$HOME/.claude/agents/*.md` |
| **3 modes** | PM Scrum Master, DevOps Architect, Dual Expert | `$HOME/.claude/modes/*.md` |
| **2 skills** | surface-state, surface-blockers (description-match auto-trigger) | `$HOME/.claude/skills/<name>/SKILL.md` |
| **11 rules** | routing, methodology, hook-architecture, work-mode, self-reference, words-are-sacrosanct, operating-principles, loop-cron-lifecycle, trigger-model, context-engineering, **compound-and-waterfall** | `$HOME/.claude/rules/*.md` |
| **Hooks** (10 wired matchers across 8 events; 17 .sh files on disk — non-wired hooks retained as archive) | PreToolUse, PostToolUse, SessionStart, UserPromptSubmit (4 hooks: context-warning + output-discipline-guard + mode-enforcement + mindfulness — compound stack per SB-126), PreCompact, PostCompact, Stop, SessionEnd | `$HOME/.claude/hooks/*.{sh,py}` |
| **8 hook regression test files** | policy-block, malware-block, opt-write-block, mode-enforcement, mindfulness, context-warning, **output-discipline-guard** (SB-090/094/120 detector triple), test-priorities | `$HOME/.claude/hooks/tests/*.py` |
| **15 deterministic Python tools** | state, blockers, progress, decisions, cycle, tasks (incl. active-task cursor SB-124d), stamp, mcp_server, _paths, objective (SB-118 mission/focus/impediment), priorities (SB-127), questions (SB-134 retention), run-tests, + 2 helpers | `$HOME/tools/*.py` |
| **Stamp control** | Persistent config (layout horizontal/vertical, enabled on/off/auto) + 6 slash commands + UserPromptSubmit marker hook | `$HOME/.claude/stamp-config.json` + `$HOME/tools/stamp.py` + `$HOME/.claude/hooks/stamp-control.sh` |
| **ccstatusline integration** | 13 custom widgets + 5 profiles + wrapper + switch-profile.sh | `$HOME/templates/ccstatusline-{config,widgets}/` |
| **Decisions logbook** | **40 entries** (D001-D040), full audit trail | `$HOME/wiki/governance/decisions.md` |
| **Systemic-bugs tracker** | **138-row register; max ID SB-138; 1 historical duplicate ID; per-bug status + verification evidence** | `$HOME/wiki/governance/systemic-bugs.md` |
| **Backlog + log + governance dirs** | Full structure | `$HOME/wiki/{backlog/{epics,modules,tasks},log,governance,lessons}/` |
| **Bootstrap scripts** | install-from-curl, checkout-{a,b}, mcp-launcher, merge-from-backup | `$HOME/scripts/*.sh` |

### What does not yet exist (or is operator-decision-pending)

| Missing | Status | Why deferred |
|---|---|---|
| Bridge FORWARD/OUTPUT nftables rules | Operator-decision pending (T013) | Threat-model question: default-accept vs default-drop FORWARD policy |
| Suricata module integration (M005) | Module not authored | Facultative module — operator-driven future-session work |
| PolarProxy module integration | Module not authored | Facultative module |
| AI-specific Suricata rule sets | Module-level work, downstream of Suricata install |  |
| Test pcap captures (canary threat / benign HTTPS) | Module-level smoke testing | Downstream of module installs |
| Idempotency invariant test (T016) | Separate task | T016 covers test-stage assertions for install_file's "unchanged" path |

### What was prior-session debris (now considered not part of the project)

The prior session's AI work left the following at `$HOME/`:

- A README describing a hardened Claude Code + opencode environment (separate scope from this project's actual definition)
- An `install.sh` for that prior scope
- An `uninstall.sh` for that prior scope
- `~/.claude/settings.json` + `~/.claude/hooks/*` for that prior scope
- An opencode bridge plugin in `~/.config/opencode/plugin/`
- A memory folder at `~/.claude/projects/-root/memory/` referenced by the prior AI as an authoritative source

Per operator directive on 2026-05-04 ("I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST"), this prior content is not part of the operator's project and is not authoritative. The actual project as defined in this README does not depend on, integrate with, or extend any of that prior content. The prior content is debris that may be cleaned up or left in place per operator direction; it does not factor into the project's definition.

## Build Order: Methodology Before Modules

The operator has stated the build order explicitly:

> "all this and the wiki LLM and methodology goes before the modules since the modules you are not going to do, I am going to do In a session in a the root project when its ready and will not drop/crash in my hands" — operator, 2026-05-04

This translates to a specific ordering of work. The methodology layer + sister-project integration + agent-context files + foundation IaC must land BEFORE the modules. The reasons:

1. **Modules will be built within the methodology framework.** Modules have stage-gate progressions (document → design → scaffold → implement → test) tracked as epics, modules, and tasks in the backlog. Without the methodology in place, module work has no framework to record itself in, no stage gates to enforce quality, no backlog to track progression.

2. **Modules will use the second brain's source-synthesis pages.** The Suricata + PolarProxy module designs reference the source-synthesis pages already authored in the second brain. The connection to the second brain has to be live so the module-design-time agent can run `python3 -m tools.gateway query` and `python3 -m tools.view search` to pull the relevant content.

3. **Modules will be operator-driven, not AI-authored.** The operator handles module integration in a future session. The agent-context files (CLAUDE.md, AGENTS.md, CONTEXT.md, etc.) need to be in place so that future session has clear operating rules and routing, otherwise it crashes the way prior sessions did.

4. **The foundation has to not crash.** The operator's exact phrase: "when its ready and will not drop/crash in my hands." The methodology layer + agent-context + foundation IaC need to be solid enough that a future session in `$HOME` doesn't immediately fall apart — which means the IaC needs to be idempotent, the methodology needs to be adopted not just copied, and the agent-context needs to be authoritative for that future session.

So the work this session has been doing — methodology adoption, sister-project registration, agent-context authoring — is the **load-bearing precondition** for module work. Modules layer on top of a stable foundation. They cannot be built before the foundation is in place.

## Methodology Layer

This project adopts the second brain's stage-gate methodology per the Adoption Guide at `<second-brain>/wiki/spine/references/adoption-guide.md`. The Adoption Guide's six steps:

1. **Copy and adapt `methodology.yaml`** — engine: stages, task types, modes, end conditions
2. **Copy and adapt `agent-directive.md`** (or methodology-profile.yaml in current naming) — work loop, enforcement, gates
3. **Create the backlog structure** — epics, modules, tasks
4. **Create the operator log** — verbatim directives, session logs
5. **Add methodology rules to CLAUDE.md** — agent reads and follows
6. **Adapt quality gates to your tech stack** — gate commands per stage

For this project, Steps 1-4 are complete. Step 5 is what this README's authoring + CLAUDE.md authoring satisfies. Step 6 is downstream of foundation IaC.

### Files in `wiki/config/`

| File | Profile | Why this profile |
|---|---|---|
| [`wiki/config/methodology.yaml`](wiki/config/methodology.yaml) | (engine) | The 9 methodology models, 5 universal stages, ALLOWED/FORBIDDEN per stage, gate command slots, end conditions. Copied verbatim from second brain — adapt artifacts/protocols per project, keep the invariants. |
| [`wiki/config/sdlc-profile.yaml`](wiki/config/sdlc-profile.yaml) | `simplified` | Right-sized for micro scale + solo execution mode. Avoids ceremony that suits team-scale projects. |
| [`wiki/config/domain-profile.yaml`](wiki/config/domain-profile.yaml) | `infrastructure` | Gate-command + path-pattern overrides specific to infrastructure work (vs knowledge work, code work, documentation work). |
| [`wiki/config/methodology-profile.yaml`](wiki/config/methodology-profile.yaml) | `stage-gated` | Hard stage boundaries. ALLOWED/FORBIDDEN outputs per stage are enforced. Suits OS-setup work where leakage between stages (shipping implementation in a Document-stage task) carries security cost. |

### 5 Universal Stages

| Stage | Readiness | ALLOWED outputs | FORBIDDEN outputs | Gate (this project) |
|---|---|---|---|---|
| **document** | 0–25% | wiki-page, raw notes, research notes | code, tests | Page exists with Summary + gaps identified |
| **design** | 25–50% | design-document, ADR, tech-spec, type sketches IN docs | code, tests | Spec reviewed; trade-offs documented |
| **scaffold** | 50–80% | type-definitions, schema, test-stubs, config-files | implementation, real test assertions | Types compile, no business logic; for IaC: install.sh exists and runs `--dry-run` cleanly without performing real changes |
| **implement** | 80–95% | implementation, integration-wiring, config | new tests | Code/IaC executes; for this project's foundation: `install.sh` runs and the box reaches transparent-bridge state on first run |
| **test** | 95–100% | test-implementation, test-results | new features | 0 test failures; for IaC: idempotent re-run is no-op, integrity verifications pass, end-to-end smoke (a packet routed through the bridge, observed by inspection if module is installed) |

**Stage rules:**
- "Continue" = advance within CURRENT stage. NEVER skip ahead.
- One commit per stage. Don't advance without the stage's gate passing.
- ALLOWED/FORBIDDEN are hard constraints, not suggestions.

### Backlog Hierarchy

**Epic → Module → Task.** Readiness flows up. Status flows up. You work on tasks, not epics directly.

- **Epic** = long-running mission (e.g. "SFIF Rollout + Second-Brain Integration")
- **Module** = scoped deliverable within an epic (e.g. "M005 — First specialized feature module")
- **Task** = atomic work unit going through stages (e.g. "T-M005-3 — Capture sample test pcap")

Active epic: [wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md).

## Sister Project of the Research-Wiki Second Brain

This project is registered as a sister of the research-wiki second brain located at `<second-brain>/`. The registration is operator-authorized; the actual integration (MCP entry + forwarders + brain-pointer block) lands when operator runs the connection command.

### Registration

| Field | Value |
|---|---|
| Sister-projects.yaml entry | `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-modules` |
| Identity profile (canonical) | `<second-brain>/wiki/ecosystem/project_profiles/root-modules/identity-profile.md` |
| `auto_connect` | `false` (operator-authorized manual connection only) |
| `type` | `root` |
| `group` | `operating-system-setup` |
| Path | `~/` (repo root is the home dir; on root user `~/` = `$HOME`; on jfortin `~/` = `/home/jfortin`) |
| `wiki_dir` | `wiki` |

### Connection mechanism

```bash
# Preview what would be written, no files modified:
cd <second-brain>/
python3 -m tools.setup --connect-project $HOME --dry-run

# Apply connection (requires operator authorization since auto_connect=false):
python3 -m tools.setup --connect-project $HOME
```

When the connection runs, four artefacts land in `$HOME`:

| Artefact | What it does |
|---|---|
| `$HOME/.mcp.json` `mcpServers.research-wiki` entry | Programmatic access to the second brain via MCP. Available tools include `wiki_gateway_orient`, `wiki_gateway_query`, `wiki_search`, `wiki_read_page`, `wiki_status`, `wiki_methodology_guide`, `wiki_gateway_contribute`, ~28 total. |
| `$HOME/tools/gateway.py` (forwarder) | CLI access. `python3 -m tools.gateway orient`, `query`, `compliance`, `health`, `template`, `flow`, `contribute`. Dispatches with `cwd=<second-brain>/` and the sister's CWD passed as `--wiki-root`. |
| `$HOME/tools/view.py` (forwarder) | CLI access. `python3 -m tools.view spine`, `model <name>`, `lessons`, `standards`, `search <query>`. |
| `## Second Brain Connection` block in `AGENTS.md` (or `CLAUDE.md`) | Documents the connection so a fresh agent in $HOME finds it on first load. Variant per `type`/`group` resolution: this project gets the `ROOT_OS_SETUP` variant (OS-setup-tier framing — methodology + verification source emphasis). |

### Bidirectional flow

| Direction | What flows |
|---|---|
| **Second brain → root-modules** | Methodology engine (5 universal stages, ALLOWED/FORBIDDEN per stage, gate commands), 9 methodology models, 25+ standards, 44+ validated lessons, 19+ patterns, 16+ decisions, 3 governing principles, the 16 named models, source-synthesis pages for Suricata + PolarProxy + Hanke integration, sister-project queries (`wiki_sister_project root-modules`). |
| **root-modules → second brain** | Lessons learned during this project's lifecycle (e.g. "deny-all+whitelist .gitignore in root-of-home pattern works"), patterns observed (e.g. "transparent-bridge IPS topology with PolarProxy-via-dummy-interface"), decisions made (e.g. "AF_PACKET vs NFQUEUE choice for this segment"). Contributed via `python3 -m tools.gateway contribute --type lesson --title "..."`. |

The second brain does not push runtime configuration into root-modules. Root-ghostproxy decides whether to query, when to query, and what to consume. The connection makes querying possible; the project makes the choice.

### `auto_connect: false` rationale

A type=root + group=operating-system-setup project gates the security envelope of the host. Auto-connecting it from `tools.setup` (which is the default behavior for `auto_connect: true` sisters) would bypass the operator's explicit-authorization step. The friction-by-design of `auto_connect: false` is that integration requires a deliberate `--connect-project $HOME` call. After M008 smoke test proves the connection is stable end-to-end, the operator may flip `auto_connect: true` (this is M010's decision) — or keep it false permanently as a security-tier signal.

## Backlog + Active Work

Active epic: [SFIF Rollout + Second-Brain Integration (2026-05)](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md).

The epic decomposes the project's foundation work into 14 modules organized into two streams that can be progressed largely independently (Stream 1 has a single dependency on Stream 2 M001 producing AGENTS.md):

### Stream 2 — Pure SFIF Project Base

| Module | SFIF Stage | Focus |
|---|---|---|
| **[M001 — Author CLAUDE.md + AGENTS.md](wiki/backlog/modules/root-modules-m001-author-claude-md-and-agents-md.md)** | Scaffold | Three-layer agent context. AGENTS.md cross-tool universal; CLAUDE.md Claude-Code-specific routing. Tight + pointer-based by design — does not duplicate auto-loaded content from elsewhere. |
| **[M002 — Methodology layer decision](wiki/backlog/modules/root-modules-m002-methodology-layer-decision.md)** | Scaffold/Design | Decision: local methodology.yaml (current — copied) OR pointer-only to second brain. Decided + documented. |
| **[M003 — Foundation hardening](wiki/backlog/modules/root-modules-m003-foundation-hardening.md)** | Foundation | Idempotent install path, integrity verification, network configuration. The foundation IaC. |
| **[M004 — Infrastructure tooling](wiki/backlog/modules/root-modules-m004-infrastructure-tooling.md)** | Infrastructure | Project-internal verifier tooling (e.g. `tools/verify-policy.py`), validation pipeline (pre-commit or CI). |
| **[M005 — First specialized feature module](wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md)** | Features | Operator picks: Suricata first OR PolarProxy first. Single-module first; second module is its own subsequent epic. |

### Stream 1 — Second-Brain Integration

| Module | Focus |
|---|---|
| **[M006 — Pre-connect verification](wiki/backlog/modules/root-modules-m006-pre-connect-verification.md)** | Verify Stream 2 M001 (AGENTS.md) is complete; verify root-modules is at a clean state; verify operator authorizes; dry-run the connect script. |
| **[M007 — Connect to second brain](wiki/backlog/modules/root-modules-m007-connect-second-brain.md)** | Run `python3 -m tools.setup --connect-project $HOME` from second brain. Inspect each of the 4 written artefacts. Commit $HOME mutations atomically. |
| **[M008 — Smoke test from inside](wiki/backlog/modules/root-modules-m008-smoke-test-from-inside.md)** | Open fresh Claude Code session in $HOME. Verify gateway orient + view spine + research-wiki MCP tool invocation work end-to-end. Time-to-orient ≤ 60 seconds. |
| **[M009 — Worked example](wiki/backlog/modules/root-modules-m009-worked-example-readme-ingest.md)** | Bidirectional flow proof. The second brain's representation of root-modules is queryable + current; root-modules can contribute lessons back. |
| **[M010 — sister-projects.yaml auto_connect decision](wiki/backlog/modules/root-modules-m010-sister-projects-yaml-flip.md)** | Operator-decision after M009 stability proven: keep auto_connect=false (security-tier signal) or flip to true (auto-hookup convenience). |

Module pages live at [wiki/backlog/modules/](wiki/backlog/modules/). Atomic task pages at [wiki/backlog/tasks/](wiki/backlog/tasks/) (initial set being authored). Operator directives + session logs at [wiki/log/](wiki/log/).

### Operator vs AI Work Split

| Stream/Module | Worked by | Why |
|---|---|---|
| Stream 2 M001 (CLAUDE.md + AGENTS.md) | AI authoring with operator approval | Agent-context authoring is the AI's job; the AI is the consumer of these files; producing them and having operator review the result is the right shape. |
| Stream 2 M002 (Methodology layer decision) | Operator decision + AI scaffolding | Decision belongs to operator; mechanical copy-and-adapt is AI work. |
| Stream 2 M003 (Foundation hardening) | AI authoring with operator approval; verification operator-driven | install.sh + network config drafted by AI; operator runs `--dry-run` and verifies the state. |
| Stream 2 M004 (Infrastructure tooling) | AI authoring with operator approval | Verifier scripts authored by AI; integrated into pre-commit / CI per operator direction. |
| Stream 2 M005 (First feature module) | **Operator-driven future-session work** | Operator stated explicitly: "the modules you are not going to do, I am going to do In a session in a the root project when its ready and will not drop/crash in my hands." |
| Stream 1 M006 (Pre-connect verification) | AI executes checks; operator authorizes | Mechanical pre-conditions; operator gates the actual connect. |
| Stream 1 M007 (Connect) | Operator runs the command from second brain | The connect command mutates $HOME; operator-authorized only. |
| Stream 1 M008 (Smoke test from inside) | Operator-driven; AI assists | Operator opens fresh session; AI participates in smoke testing. |
| Stream 1 M009 (Worked example) | AI verifies; operator confirms | Bidirectional flow checks; AI runs them, operator confirms results. |
| Stream 1 M010 (auto_connect flip) | Operator-decision | Pure decision, no implementation lift. |

## SFIF Stages for This Project

The SFIF model (Scaffold → Foundation → Infrastructure → Features) is the second brain's project-lifecycle macro model. Applied to root-modules:

### What SFIF Is Part Of (per operator's check: *"Remember SFIF and what it is part of?"*)

SFIF (Scaffold → Foundation → Infrastructure → Features) is not a standalone framework — it sits within the second brain's broader methodology architecture in four specific ways:

1. **The Quality category of the 16 named models** — SFIF is one of the named models in the Quality category, alongside the Quality & Failure Prevention model. Its canonical home is `wiki/spine/models/quality/model-sfif-architecture.md`.
2. **The project-lifecycle macro model in the methodology engine** — SFIF appears in `wiki/config/methodology.yaml` as the `project-lifecycle` model with `composition: nested`, meaning other methodology models (feature-development, bug-fix, research, etc.) nest inside its stages.
3. **Mapped to the 3 quality tiers** (Skyscraper / Pyramid / Mountain) — Skyscraper = full SFIF progression with all gates; Pyramid = deliberate-compression SFIF (skip stages with documented reasoning); Mountain = accidental chaos (the anti-pattern to avoid).
4. **Recursive across scales** — SFIF applies at project / feature / component / design-system levels. The same Scaffold → Foundation → Infrastructure → Features sequence repeats inside any unit of work that has independent lifecycle.

For root-modules, SFIF is applied at the project-lifecycle level (the project as a whole goes through Scaffold → Foundation → Infrastructure → Features). Future modules will apply SFIF recursively at the module-lifecycle level.

### Scaffold

**What it means.** Directory structure, file stubs, conventions in place. No business logic. No real implementation. The shape of the project is laid out so subsequent stages have somewhere to land.

**Gate.** Types compile, frontmatter validates, no business logic; for this project: backlog scaffolded with epic + modules indexed; methodology.yaml + profile yamls present and parseable; agent-context files exist (this README + CLAUDE.md + AGENTS.md + CONTEXT.md + secondary depth files).

**Status.** In progress — completed by the end of this README's authoring conversation.

### Foundation

**What it means.** The project installs reliably on a fresh host. Idempotent re-runs. Dry-run preview. Explicit integrity verification. Foundation = "this works, end to end, on a clean install."

**Gate.** `./install.sh --dry-run` succeeds cleanly on a clean Linux host AND on an already-installed host (no-op confirmation). The transparent-bridge topology comes up after install. Network sanity checks pass (bridge forwards frames, wifi is outbound-only).

**Status.** Not yet started. install.sh + network config + integrity checks have not been authored. This is the next major work block after the agent-context files settle.

### Infrastructure

**What it means.** The project enforces its own quality gates programmatically — verifier scripts, validation pipelines (CI or pre-commit). SFIF Infrastructure means "the project's safety + quality posture is enforced by tooling, not by prose."

**Gate.** A `tools/verify-policy.py` (or equivalent) returns 0 on a known-good state, fails with explanation on deliberate degradation. Integrated into a pre-commit hook OR CI workflow.

**Status.** Not yet started. Module M004 is the work block.

### Features

**What it means.** Specialized feature modules deployed. For root-modules these are the inspection modules (Suricata, PolarProxy). Features tier is operator-driven future-session work.

**Gate.** At least one feature module installed end-to-end with smoke test passing (canary alert SID 2100498 via curl testmynids.org for Suricata; benign HTTPS session captured + decrypted for PolarProxy).

**Status.** Not yet started. Modules M005 (and the implied M005-bis for the second module) are the work blocks. Operator-driven.

## Spec-Driven Development (Operating Doctrine)

This project is operated under **spec-driven development** with strong methodology and standards. This is the doctrinal frame that the three principles below execute under. Per operator directive 2026-05-05 (verbatim):

> *"we prone spec driven development and a strong methodology and standards. this make a huge difference in the executions and the outputs and the quality and reliability and tracability and operability and observability and project management and progress tracking and LLM Wiki enforment and compatibility exploitation."*

**What SDD means here:**
- The repo carries the **spec**, not the realized state. The brain files, `wiki/config/*.yaml`, the backlog (epic + modules + tasks), `install.sh`, hook scripts, `.claude/rules/*.md` — all are spec artefacts. The repo is replayable: `git clone` + `./install.sh` reconstitutes a working host.
- The realized state (vendor binaries, downloaded sources, hydrated configs with secrets, session state, vendor logs) is **not** in the repo. It is regenerated per host by `install.sh` reading the spec.
- The `.gitignore` deny-all + whitelist enforces this: only spec gets tracked; state gets denied.
- Vendor introduction (e.g., a new IPS rule source or a new TLS-inspection tool) goes through the same flow: a vendor manifest is added to the spec; `install.sh` learns to fetch + verify + configure it; the vendor's binaries/source remain external. The spec records identity + version + integrity hash + install method; not the vendor itself.

**Why SDD makes "a huge difference"** (operator's named impact areas, verbatim):
| Area | How SDD delivers it |
|---|---|
| Executions | The spec is machine-readable; install.sh + tooling realize it deterministically |
| Outputs | What ships is the spec, not artifacts that drift between hosts |
| Quality | Spec is reviewable, version-controlled, gated through stages (document → design → scaffold → implement → test) |
| Reliability | Replays produce equivalent state; drift is detectable via spec-vs-state comparison |
| Traceability | Every realized artifact links back to a spec entry; commit history is the project's spine |
| Operability | A fresh host runs install.sh and matches the spec — no tribal knowledge |
| Observability | Hooks, leak-detector, integrity check, post-install verification — all spec'd, all auditable |
| Project management | Backlog (epic + modules + tasks) IS spec; readiness flows up; status is computed |
| Progress tracking | Tasks have `Done When` checklists; modules accumulate readiness; SFIF stages gate epics |
| LLM Wiki enforcement | Wiki schema (`wiki/config/wiki-schema.yaml`) + methodology engine (`wiki/config/methodology.yaml`) + brain files form the spec the LLM operates under |
| Compatibility exploitation | The spec lets sister projects (OpenArms, OpenFleet, AICP, devops-control-plane) share methodology, models, standards — coherent ecosystem instead of N silos |

The three principles below execute UNDER this SDD doctrine, not parallel to it.

## Three Principles in Action

The second brain's three governing principles (Infrastructure Over Instructions, Structured Context Governs Agent Behavior, Right Process for Right Context) apply to root-modules as follows:

### 1. Infrastructure Over Instructions

**Principle:** If a rule can be checked by a tool, enforce it structurally (hooks, validators, pipeline post), not with prose rules. Measured: prose rules ~25% compliance; structural enforcement ~100%. BUT enforcement must be mindful — every block needs a reason and a bypass mechanism.

**Application here:**
- The Suricata IPS posture (drop / reject / alert per signature) is structural enforcement of network policy. Prose rules in CLAUDE.md or AGENTS.md cannot block malicious packets; Suricata can.
- The PolarProxy CA-trust requirement on LAN endpoints is structural — endpoints with a trusted CA inspect; endpoints without see cert errors and self-block.
- The `tools.setup --dry-run` patch was a structural enforcement: M006 pre-connect-verification can preview the diff before writing, instead of an instruction "remember to dry-run first."
- Future Infrastructure-tier verifier scripts (M004) will check the project's invariants programmatically rather than by checklist.

### 2. Structured Context Governs Agent Behavior More Than Content

**Principle:** Tables, MUST/MUST NOT lists, YAML fields, callout types program agent behavior more reliably than natural language paragraphs. Same content restructured from paragraphs to tables: 25% → 60% compliance improvement.

**Application here:**
- This README is structured-content-heavy: tables for identity, layers, modules, sister-project fields, SFIF stages, work split. Where prose paragraphs would have been used (and lost compliance), tables are used.
- The methodology engine is structured YAML (`methodology.yaml`), not prose ("agents should follow the document → design → scaffold → implement → test sequence"). The engine machine-reads its own contents.
- Module pages have explicit `Done When` checklists, `Dependencies` lists, `Open Questions` callouts — not prose paragraphs about what each module does.

### 3. Right Process for Right Context (Goldilocks)

**Principle:** Process must adapt to identity (type, phase, scale, PM level). A POC doesn't need full enforcement. Production does. Don't hardcode one process level for all contexts. The Goldilocks point shifts as the project matures.

**Application here:**
- root-modules is type=root + group=operating-system-setup + scale=micro + execution_mode=solo. The Goldilocks point is the **simplified** SDLC profile + **stage-gated** methodology profile.
- A team-scale project at the same SFIF tier would use the **default** or **full** SDLC profile with multi-reviewer gates.
- A research-domain project would use the **research** methodology model that caps at 50% readiness in design.
- The point is the framework adapts. Each project's methodology layer is a per-project YAML overlay; the engine remains shared.

## Setup Path

`install.sh` exists (implement-stage, readiness 98%) and is the canonical foundation installer. Two scopes: OS-root install (this dev host's mode) and per-project agent-brain install into a sister project.

### Prerequisites

- **Linux host** — Debian-family fully supported (Debian 11+, Ubuntu 20.04+, derivatives); RHEL-family + Arch OS-family detection in place; cross-distro install hints emitted per family.
- Two ethernet ports for L2 bridge (only when running in `--mode bridge` or `hybrid`)
- One wifi interface for outbound-only management (only when `--with-wifi`)
- Wifi credentials for operator's existing SSID (operator fills `wpa_supplicant-mgmt0.conf` placeholders post-deploy)
- Local console access for recovery (if wifi config goes wrong)
- Python 3.11+ for project tooling (`python3` + `jq` are core deps; `nft` + `ip` + `wpa_supplicant` are conditional per enabled ops — install.sh's `require_dependencies` checks + emits per-OS install hint when missing)
- `git`, optional Claude Code and/or opencode installed (the endpoint-safety + brain target these; other AI tools are facultative)

### Setup steps

```bash
# 1. Get the project repo onto the host (anywhere — install.sh handles path resolution)
git clone <url> /tmp/root-modules
cd /tmp/root-modules

# 2. Wizard mode — state-aware "where you are + what to do next" report
#    Safe to run from any state (curl-bootstrap / post-clone / post-install / drift / maintenance)
./install.sh --wizard                   # detects route + offers prioritized next-best-actions

# 3. Preview the foundation install
./install.sh --dry-run                  # base profile, default mode=auto
./install.sh --dry-run --profile full   # base + facultative modules (ccstatusline)
./install.sh --check                    # drift-check existing install state (read-only)

# 3b. Granular install — group-level selection (composes with --profile)
./install.sh --profile base --no-group wifi --no-group integrity   # base minus 2 groups
./install.sh --profile base --with-group ccstatusline              # base + 1 Features group
# Available groups: security, session-lifecycle, agent-discipline, stamp,
#                   bridge, opencode, wifi, integrity, ccstatusline,
#                   tools-{core,cycle,stamp,objective,all}

# 3. Execute foundation install (idempotent — re-runs are no-ops where state matches)
sudo ./install.sh                       # base profile (hooks + opencode + bridge + wifi + integrity)
sudo ./install.sh --profile full        # base + ccstatusline (npm-based)
sudo ./install.sh --mode endpoint       # endpoint-only (no bridge/wifi ops)
# Sovereign-os node consumption (proxy mode disabled) — canonical guide:
#   docs/sovereign-os-endpoint-usage.md  (`--profile base --mode endpoint`)

# 4. Per-op toggles (override profile defaults)
sudo ./install.sh --no-bridge --no-wifi   # safety policy + opencode bridge plugin only
sudo ./install.sh --with-ccstatusline     # add ccstatusline to base

# 5. Post-install verification (runs op_verify — same as --check)
./install.sh --check
# Reports: settings.json parses, hooks executable, integrity match,
# opencode bridge resolves, br0 UP, wifi config + ruleset + table loaded,
# brain pieces deployed counts. Exit 0 = clean; exit 1 = drift detected.

# 6. (Optional) Connect to second brain (operator-authorized; auto_connect=false):
cd <second-brain>/
python3 -m tools.setup --connect-project $HOME --dry-run    # preview
python3 -m tools.setup --connect-project $HOME              # apply

# 7. Verify second-brain connection from $HOME:
cd $HOME
python3 -m tools.gateway orient
python3 -m tools.view spine
```

### Per-project install — agent brain into a sister project

Per operator directive 2026-05-06 (*"this should also probably be part of the things we can chose to install into project and not only the root"*), `--profile project` deploys the agent brain (settings + hooks + rules + commands + agents + modes + skills + tools) into a sister project. OS-level ops (bridge/wifi/integrity/ccstatusline/opencode) are disabled in project mode.

```bash
# Preview deployment to a sister project
./install.sh --dry-run --profile project --dest /opt/devops-solutions-information-hub
./install.sh --dry-run --profile project --dest /home/jfortin/openarms

# Real deploy
./install.sh --profile project --dest /opt/devops-solutions-information-hub

# Operator-facing slash command (equivalent wrapper; no-install-script invocation)
/install-agent-brain /opt/devops-solutions-information-hub
/install-agent-brain /home/jfortin/openarms --dry-run
```

After deploy, verify in the target project:
```bash
cd /opt/devops-solutions-information-hub
python3 -m tools.stamp show              # confirms tools/ deployed + working
ls .claude/{rules,commands,agents,modes,skills,hooks}/  # confirms brain pieces
```

### Module install (future, operator-driven)

```bash
# Future, after M005 work block — module structure decided at M005 design time
sudo ./install.sh --with-suricata          # facultative IDS/IPS module
sudo ./install.sh --with-polarproxy        # facultative TLS inspection module
sudo ./install.sh --profile full           # all facultative modules
```

## Verification

`install.sh --check` is the canonical verification path. It runs the same `op_verify` chain that real-install runs at the end (read-only mode — exits non-zero on drift).

### Foundation verification

```bash
# Comprehensive drift + integrity check (16+ sub-checks)
./install.sh --check                      # exit 0 = clean; exit 1 = drift
./install.sh --check --profile full       # full-profile expectations

# Per-component spot-checks (manual):

# Bridge forwards frames + members are correct (when --with-bridge):
ip link show br0
ip link show <upstream-eth> <lan-eth>

# Wifi outbound-only enforced at nftables (when --with-wifi):
sudo nft list table inet ghp_mgmt_wifi    # ruleset loaded
systemctl is-enabled wpa_supplicant@mgmt0.service
systemctl is-active wpa_supplicant@mgmt0.service

# Idempotency — re-running real install touches nothing when state matches:
sudo ./install.sh                         # all `install_file` lines say "unchanged"

# Integrity baselines (when --with-integrity):
cat $HOME/.claude/integrity.json | jq '.baselines | length'
```

### Module verification (future)

```bash
# Suricata module canary alert (per src-suricata-install-quickstart):
sudo tail -f /var/log/suricata/fast.log &
curl http://testmynids.org/uid/index.html
# Expected: alert on SID 2100498 ("GPL ATTACK_RESPONSE id check returned root")

# PolarProxy decryption smoke test (per src-polarproxy + Hanke pattern):
# 1. Install PolarProxy CA on a test client
# 2. Generate a benign HTTPS session from the client
# 3. Verify the session appears decrypted in PolarProxy's PCAP output
# 4. Verify Suricata sees the cleartext via the dummy interface
```

## Status

| Metric | Value (current, 2026-05-06 evening) | Target (full install) |
|---|---|---|
| **SFIF Stage** | scaffold + partial-foundation (foundation gate met for `install.sh --dry-run`; T012 advance to implement-stage GREENLIT per D024) | Features (modules deployed) |
| **Methodology layer** | Adopted (4 yaml files in $HOME/wiki/config/) | Adopted + adapted (gate commands customized) |
| **Backlog** | Active epic + 14 modules + 66 atomic tasks + 4 epics + 1 milestone (v0.2 active alongside v0.1) | Same + atomic tasks under each module |
| **Sister-project registration** | Complete in second brain | Same (no drift) |
| **Sister-project connection (--connect-project)** | Not run for real (only dry-run tested) | Run, all 4 artefacts in place, smoke test passing |
| **Agent-context files** | README + 9 top-level (CLAUDE.md, AGENTS.md, BOOTSTRAP.md, CONTEXT.md, ARCHITECTURE.md, TOOLS.md, DESIGN.md, SECURITY.md, SKILLS.md) — in progress under operator-led brain-improvement mandate (2026-05-06) | All authored, methodology-aware, no duplication |
| **Foundation IaC (install.sh)** | **Authored, implement-stage, readiness 98%** — `--dry-run` + `--check` + `--profile {base\|full\|project\|interactive}` + `--mode {bridge\|endpoint\|hybrid\|auto}` + per-op toggles + `--wizard` state-aware route. shellcheck PASS. Idempotent. Real-execute pending operator-driven future-session run. | Real-execute on at-least-one operator host; idempotency invariant verified (T016) |
| **Network bridge config** | **Templates authored** at `templates/systemd-networkd/` (.netdev + .network); FORWARD/OUTPUT nftables rules pending T013 operator-decision | Authored + deployed: bridge with two ethernet members, management wifi outbound-only, FORWARD/OUTPUT nftables locked down |
| **Project-internal verifier tooling** | Partial — `install.sh --check` runs op_verify (16+ checks); standalone `tools/verify-policy.py` not yet authored (M004 work block) | `tools/verify-policy.py` exists, integrated into pre-commit or CI |
| **Suricata module** | Not installed | Installed, integrated, canary alert verified |
| **PolarProxy module** | Not installed | Installed, integrated, decryption smoke-tested |
| **AI-specific Suricata rule sets** | Not authored | Curated, deployed, tested against captured AI traffic |
| **TLS-firewall ruleset for PolarProxy** | Not authored | Authored, tested, banking/healthcare/pinned domains bypassed |
| **Operator's `auto_connect` decision** | Pending (currently `false`) | Operator-decided per M010 |
| **Brain pieces (post-/loop iteration)** | 11 rules + 30 commands + 3 modes + 3 agents + 2 skills + 15 tools + 17 hooks (10 wired) + 138-row SB tracker + 40 decisions + 8 hook regression test files (counts empirically verified 2026-05-06 evening) | Same shape; counts evolve with project |

**Phase:** Scaffold + partial-foundation. **Scale:** Micro. **Execution mode:** Solo. **PM Level:** L1.

## Documentation Map

| File | Purpose |
|---|---|
| **README.md** (this file) | Project overview, vision, identity, layered architecture, modules, current state, build order, methodology, sister-project integration, backlog, SFIF stages, principles, setup path, verification, status, glossary. The front door. |
| **[AGENTS.md](AGENTS.md)** | Universal cross-tool agent context. Tight + pointer-based — references canonical sources rather than re-stating their content. Identity at-a-glance + pointer table to canonical sources + project-specific hard rules + working contract + mission verbatim. |
| **[CLAUDE.md](CLAUDE.md)** | Claude Code-specific operating context. Operator-intent → tool/command routing table for THIS project's actual operations. Methodology pointer per Adoption Guide step 5. Hard rules specific to operating in $HOME. |
| **[CONTEXT.md](CONTEXT.md)** | Current operational state — active SFIF stage, active modules, recent operator directives, next-best moves. Changes turn-to-turn. Distinct from CLAUDE.md (rules) and README.md (description). |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Deep system topology — bridge configuration, interface roles, hook flow, integrity check sentinel, module integration interfaces, failure modes + recovery. Distinct from README's architecture summary. |
| **[TOOLS.md](TOOLS.md)** | Per-script reference — install.sh (when it exists), foundation verification scripts, project-internal verifier (M004 tooling), module install scripts. Concrete invocations + invariants. |
| **[DESIGN.md](DESIGN.md)** | Design pattern rationale — why deny-by-default, why fail-closed integrity, why stealth bridge over routing-firewall, why facultative modules, why second-brain methodology adoption. The "why this shape." |
| **[SECURITY.md](SECURITY.md)** | Threat model, protections layer-by-layer, fail-closed invariants, escalation paths, hooks/enforcement reference, audit logging, known limitations. Load-bearing for type=root projects. |
| **[SKILLS.md](SKILLS.md)** | Skills directory context (where skills live, conventions, when to use each). Future-tense for this project — skills directory may not exist initially. |

Each file serves ONE concern. Together they form the multi-layer agent context architecture: AGENTS.md (universal cross-tool) + CLAUDE.md (Claude Code-specific) + secondary depth files (per-concern).

### Subdirectory READMEs (added 2026-05-06 evening — DRAFT v1, agent-authored, operator-revisable)

Per operator directive 2026-05-06 ("we might even create new files... for the needs and or SRP and cleaneness and polish"), the following subdirs gained DRAFT v1 indexing READMEs to reduce cold-pickup-friction. Each is flagged agent-authored in frontmatter (per SB-095) — operator promotes to stable after review.

| Subdir README | What it indexes |
|---|---|
| **[`scripts/README.md`](scripts/README.md)** | Deployment + maintenance toolkit — install-from-curl, checkout-A/B, merge-from-backup + `lib/` (pre-existing; refreshed 2026-05-06 with install.sh wizard reference + agent-learning notes) |
| **[`tools/README.md`](tools/README.md)** | 15 deterministic Python modules (state, blockers, progress, decisions, cycle, tasks, stamp, mcp_server, _paths, objective, priorities, questions, run-tests, group, +helpers) + composition map |
| **[`.claude/commands/README.md`](.claude/commands/README.md)** | 30 slash commands organized by category (orient/cycle, modes, stamp, objective layer, backlog, knowledge/audit, install) |
| **[`.claude/hooks/README.md`](.claude/hooks/README.md)** | 18 hook scripts (10 wired matchers across 8 events; 8 archive — retained per operator directive); per-event tables + composition (compound + waterfall axes) |
| **[`.claude/modes/README.md`](.claude/modes/README.md)** | 3 modes (PM Scrum Master / DevOps Architect / Dual Expert) with cycle-sequence comparison |
| **[`.claude/rules/README.md`](.claude/rules/README.md)** | 11 on-demand topic rules with strictness-tier + when-loaded matrix |
| **[`.claude/agents/README.md`](.claude/agents/README.md)** | 3 brain-loaded subagents (root-explorer / root-architect / root-pm-scoper) — runtime gap noted (SB-081 session-restart required) |
| **[`.claude/skills/README.md`](.claude/skills/README.md)** | 2 skills (surface-state / surface-blockers) — description-match auto-trigger mechanism |
| **[`templates/README.md`](templates/README.md)** | 5 template categories (ccstatusline-config + widgets, nftables, systemd-networkd, wpa_supplicant) used by install.sh |

## For Agents Working on This Project

| For… | Read |
|---|---|
| Project front door (you are here) | [README.md](README.md) |
| Universal cross-tool agent rules | [AGENTS.md](AGENTS.md) |
| Claude Code-specific operator-intent routing | [CLAUDE.md](CLAUDE.md) |
| Current SFIF stage + active modules + recent operator directives | [CONTEXT.md](CONTEXT.md) |
| Architecture in depth (topology, hook flow, module interfaces) | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Tool reference (install scripts, verifiers, module installs) | [TOOLS.md](TOOLS.md) |
| Design pattern rationale (why this shape) | [DESIGN.md](DESIGN.md) |
| Security policy (threat model, protections, fail-closed) | [SECURITY.md](SECURITY.md) |
| Skills directory context | [SKILLS.md](SKILLS.md) |
| Methodology engine (5 stages, ALLOWED/FORBIDDEN, gate commands) | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| SDLC profile (simplified for micro+solo) | [wiki/config/sdlc-profile.yaml](wiki/config/sdlc-profile.yaml) |
| Domain profile (infrastructure) | [wiki/config/domain-profile.yaml](wiki/config/domain-profile.yaml) |
| Methodology profile (stage-gated) | [wiki/config/methodology-profile.yaml](wiki/config/methodology-profile.yaml) |
| Active epic | [wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md) |
| Module pages | [wiki/backlog/modules/](wiki/backlog/modules/) |
| Atomic tasks | [wiki/backlog/tasks/](wiki/backlog/tasks/) |
| Operator directives + session logs | [wiki/log/](wiki/log/) |
| Identity profile (Goldilocks 9-dimension full) | `<second-brain>/wiki/ecosystem/project_profiles/root-modules/identity-profile.md` |
| Sister-projects.yaml entry (in second brain) | `<second-brain>/wiki/config/sister-projects.yaml` → `projects.root-modules` |
| Suricata source-syntheses (4 pages, in second brain) | `<second-brain>/wiki/sources/src-suricata*.md` |
| PolarProxy source-syntheses (2 pages, in second brain) | `<second-brain>/wiki/sources/src-polarproxy.md`, `src-hanke-honeypot-polarproxy-suricata-integration.md` |
| Adoption Guide (the strictly-defined adoption process) | `<second-brain>/wiki/spine/references/adoption-guide.md` |
| `tools.setup --connect-project` (the connection mechanism) | `<second-brain>/tools/setup.py` |

After connection (M007) lands, also:

| For… | Read / Run |
|---|---|
| Second-brain orientation (canonical first step) | `python3 -m tools.gateway orient` |
| Browse second-brain spine | `python3 -m tools.view spine` |
| Query a methodology model | `python3 -m tools.gateway query --model <name>` |
| Search across the second brain | `python3 -m tools.view search "<query>"` |
| Contribute a lesson back to the second brain | `python3 -m tools.gateway contribute --type lesson --title "..." --content "..."` |

## Operator Directives Captured This Session

The directives below are operator-stated, verbatim, captured during this README's authoring session and the preparation work that preceded it. They define the project's intent + the build order + the stop conditions. Future sessions in $HOME should treat these as authoritative.

| Date | Directive (verbatim) | Implication |
|---|---|---|
| 2026-05-04 | "this is a new machine with a new root project $HOME but first we need to load into context this project knowledge" | The project is new on a new machine; prior $HOME content is debris from a prior session, not authoritative. |
| 2026-05-04 | "we need to prepare to work on the new root project and make sure we can install to it as a sister project and as a project of type root and group operating-system-setup. WHy root ? since it could have been jfortin install too.. since its an operating system IaC project, even in a user such as jfortin it would remain a root-type project" | type=root because OS-level scope, not install-path. group=operating-system-setup. Sister-project of second brain. |
| 2026-05-04 | "the project is barely started... we will need to build everything inside of it so that a future session in its context can work properly. not only the full second-brain integration but just pure sfif project base. Remember SFIF and what it is part of?" | Project is barely started. Build everything inside. SFIF is part of the project-lifecycle macro model in the second brain's methodology. |
| 2026-05-04 | "I am able to start a session in the $HOME project and am able to start working on the two vendors & modules integrations and following the methodology with the wiki LLM and everything" | Mission: future session works on Suricata + PolarProxy modules, following methodology, with the second brain integrated. |
| 2026-05-04 | "you can work in $HOME for now for whatever we need to reach that point or to read the current state" | Authorized to work in $HOME for foundation prep. |
| 2026-05-04 | "its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network... So its not just an IPS its a system AI safety setup project and the IPS tools (suricata and [polarproxy]) as modules" | Project = system AI safety setup. Position = IPS between OPNsense and LAN. Suricata + PolarProxy = modules. |
| 2026-05-04 | "first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed" | Modules are facultative. Layered architecture. Full install adds them all. |
| 2026-05-04 | "do not forget the root task that is to shape and prepare the root-modules project... you mostly prepared and did the knowledge part but there is still much progress to do... including the second-brain integration when we reach this point... all this and the wiki LLM and methodology goes before the modules since the modules you are not going to do, I am going to do In a session in a the root project when its ready and will not drop/crash in my hands" | Order: methodology + integration FIRST, modules SECOND. Modules are operator-driven future-session work. |
| 2026-05-04 | "you make the change to setup.py and keep or any tools that needs it and keep moving toward the target solution / requests" | Authorized to extend setup.py and other second-brain tooling that needs to support the integration. |
| 2026-05-05 | "I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST" | Prior $HOME content (README, install.sh, hooks, integrity.py, opencode bridge, memory folder) is not operator-authored, not authoritative, not part of the project. Forget it exists. |
| 2026-05-05 | "imagine there is no fucking root-GHOSTPROXY project righT NOW.. this whole system is virgIN" | Treat the system as virgin. Build the project from scratch from the operator's verbatim definitions, not from existing $HOME content. |
| 2026-05-05 | "WE NEED TO BUILD IT FROM THE BOTTOM-UP" | Bottom-up: foundation first, then layers. Not top-down comprehensive vision before grounding. |
| 2026-05-05 | "STOP FUCKING WORKING IN REVERSE" | Don't reverse-engineer the project from existing artefacts. Build forward from definition. |
| 2026-05-05 | "THE MAIN FUCKING TASK OF THIS WHOLE CONVERSTAION IS TO CREATE THE FUCKING 3 main MD files and then the 3-7+ secondary MD files" | This conversation's deliverable: 3 main MD files (README, CLAUDE.md, AGENTS.md) + 3-7+ secondary (CONTEXT, ARCHITECTURE, TOOLS, DESIGN, SECURITY, SKILLS, etc.). |
| 2026-05-05 | "we are going to need to create at least two new templates list for a new project and for a new second-brain preparation to integration" | Two template lists in the wiki: sister-project-preparation manifest + second-brain-integration overlay manifest. (Both authored in second brain at `wiki/config/templates/sister-project-preparation/` and `wiki/config/templates/second-brain-integration/`.) |

The full operator directive log lives at `$HOME/wiki/log/` (and additionally at `<second-brain>/raw/notes/` for cross-project reference).

## Glossary

Terms specific to root-modules as used in this README and the project's other documentation.

| Term | Definition |
|---|---|
| **Bridge** | The Linux L2 bridge (typically `br0`) with the two ethernet interfaces as members. The bridge forwards Ethernet frames between its members; the box is L3-invisible to endpoints on the inspected segment. |
| **Edge firewall** | OPNsense or compatible. The L3 routing/firewall device upstream of root-modules. The internet-side of the bridge. |
| **Facultative module** | A module that is optional. The project runs without it. Suricata and PolarProxy are both facultative. |
| **Full install** | An install that deploys the foundation + all available modules. Per operator: "if I do a full install they would all be installed." |
| **Goldilocks** | The 9-dimension identity protocol from the second brain that right-sizes process per project. type, group, domain, phase, scale, execution mode, SDLC profile, PM level, trust tier. |
| **Ghost** (in the project name) | The transparent L2 bridge property. The box has no IP on the inspected segment; endpoints don't see it as a hop. L3-invisible. |
| **IaC** | Infrastructure-as-Code. The project's foundation is declared in code (install scripts, config files, systemd units) and reproducible from a fresh host. |
| **LAN** | The local area network on the first-switch side of root-modules. The endpoints whose traffic the project inspects. |
| **Methodology engine** | `wiki/config/methodology.yaml`. Defines stages, models, ALLOWED/FORBIDDEN per stage, gate commands. Copied from second brain, adaptable per project. |
| **Module** | An optional inspection capability layered onto the foundation. Currently named: Suricata (IDS/IPS), PolarProxy (TLS termination). |
| **Operator** | The human directing the project's work. The "PO" in PO-approval-boundary contexts. The single human authority on this project. |
| **Operator-supervised trust tier** | The agent operates with operator review on all non-trivial changes. Approval gates apply to security-relevant edits, anything touching the bridge data path, anything touching the upstream OPNsense relationship. |
| **Outbound-only management** | The wifi interface is configured so that the host can initiate outbound connections (apt updates, threat-intel feeds, AI APIs) but no service listens for inbound on it. nftables INPUT chain drops everything except established/related on the management wifi interface. |
| **Proxy** (in the project name) | The TLS termination capability provided by the PolarProxy module. Without that module, the box is not a proxy in any sense. |
| **Sister project** | A project registered with the research-wiki second brain via the sister-projects.yaml registry. Sisters consume from + contribute to the second brain. |
| **Stealth posture** | The project runs in stealth mode by default — no L3 visibility on the inspected segment. The "ghost" half of the project name. |
| **Second brain** | The research-wiki at `<second-brain>/`. The shared knowledge system across the 5-project ecosystem. root-modules is a sister of this. |
| **SFIF** | Scaffold → Foundation → Infrastructure → Features. The project-lifecycle macro model defined in the second brain. Each stage builds on the previous. |
| **Stream 1** | The second-brain-integration stream of the active epic. Modules M006–M010. Gated on Stream 2 M001 producing AGENTS.md. |
| **Stream 2** | The pure-SFIF-project-base stream of the active epic. Modules M001–M005. |
| **Transparent inspection** | Inspection that doesn't change the apparent network topology. Endpoints don't see "an extra hop"; they see what looks like a direct connection through the segment. |
| **Type=root** | The project's scope claim — what it configures is the operating system itself, regardless of which user runs the install. Distinct from "runs as root" (an install-time property). |
| **Variant=ROOT_OS_SETUP** | The brain-pointer block variant rendered by `tools.setup --connect-project` for this project (per its type=root + group=operating-system-setup classification). Emphasizes OS-level IaC framing over generic adoption-tier framing. |

## Limitations (Aspirational + Current)

The limitations below are inherited from the modules' upstream tools (Suricata + PolarProxy) and from the project's intended posture. They will be relevant once the modules are installed; they are not current-state limitations because the modules don't exist yet.

### From PolarProxy (upstream)

1. **Free-tier ceiling fails OPEN, not closed.** PolarProxy free tier caps at 10 GB / 10 000 sessions / 10 000 rule-matches per day. Past the cap, PolarProxy keeps forwarding TLS but stops decrypting. Inspection silently degrades. Operational mitigation: monitor the rate of TLS sessions seen vs decrypted; alert on divergence after the cap.

2. **No support for opportunistic STARTTLS / explicit TLS.** SMTP STARTTLS, FTPS AUTH TLS, etc. are not decryptable by PolarProxy. Those flows pass through encrypted regardless of the inspection posture.

3. **No ESNI / ECH support.** Sessions using Encrypted SNI / Encrypted Client Hello are not decryptable. Adoption rate of ESNI/ECH on the LAN's outbound destinations affects how much traffic remains opaque.

4. **CA must be installed on every client whose traffic is decrypted.** PolarProxy generates a unique CA per instance (or accepts a pre-loaded CA). Endpoints without that CA in their trust store see cert errors and self-block. Cert-pinned apps (banking, mobile pinning) reject the proxy's CA regardless.

5. **Not FIPS-compliant.** PolarProxy uses cryptographic algorithms that are not FIPS 140-compliant. On FIPS-enabled hosts PolarProxy refuses to start.

### From Suricata (upstream)

1. **In IPS mode, a Suricata crash takes the inspected segment offline UNLESS bypass is configured.** The bridge layer (br0 + nftables) MUST have a failopen mechanism — either NFQUEUE `bypass` option (network keeps working when Suricata is down, inspection silently disabled) or kernel-level bridge passthrough. This is a load-bearing M005 design decision.

2. **Custom rules conflict with reserved upstream SID ranges.** Suricata reserves SIDs 2200000–2299999 per protocol/component. Local custom rules for root-modules must use 1000000–1999999 (per ET/Snort convention) to avoid update collisions.

3. **Hardware offloads (GRO/LRO/TSO) interfere with inline inspection.** Must be disabled on the bridge interfaces to prevent dropped packets from oversized datagrams.

### From the project's intended posture

1. **The bridge as inline data path means a hardware/software failure of the box stops traffic** unless the bridge layer has explicit failopen. Operator's threat model decides: high-trust environment → fail-closed (acceptable downtime); inspection-not-firewall environment → fail-open (network keeps working when inspection is offline).

2. **The wifi as outbound-only management means in-band recovery is limited.** If the wifi misconfigures or the host is unreachable from operator's network, recovery requires local console access. SSH is not bound to the wifi interface; that is by design.

3. **CA distribution is a separate operational track.** The PolarProxy module's CA must be deployed to LAN endpoints by some mechanism (manual install, AD GPO, MDM, Linux package). root-modules doesn't include that mechanism — it provides the proxy + CA, deployment is operator's lift.

## Publishing

The project is structured to be installable from a clean checkout on any compatible Linux host. The repo's `.gitignore` (when authored as part of foundation work) will be a deny-all + whitelist allowing only the project's own files (CLAUDE.md, AGENTS.md, etc., the install scripts, the wiki/ structure, etc.) — credentials, sessions, transcripts, logs, history, ssh, env, and machine-specific state stay local.

When the foundation is published:

```bash
# Verify only whitelisted files are tracked:
git status              # only project files appear
git ls-files            # final sanity check
```

## License

License is to-be-decided. The project's modules have their own licenses (Suricata = GPL-2.0; PolarProxy = CC BY-ND 4.0 with paid-tier license server for high-volume use). The project's own IaC + tooling license will be set when the foundation work lands.

## Relationship to the 5-Project Ecosystem

root-modules is a sister of four other projects in the operator's ecosystem, all connected through the research-wiki second brain. Each project has its own brain (its own CLAUDE.md / AGENTS.md / skills / hooks); the second brain is the shared knowledge resource they all consume from + contribute to.

```
                      ┌───────────────────────────────────────────────────┐
                      │  Research Wiki (the second brain)                 │
                      │  <second-brain>/            │
                      │                                                   │
                      │  - Methodology engine (9 models, 5 stages)        │
                      │  - 25 standards (per-type + per-model)            │
                      │  - 44+ validated lessons                          │
                      │  - 19+ validated patterns                         │
                      │  - 16+ decisions                                  │
                      │  - 3 governing principles                         │
                      │  - 16 named models                                │
                      │  - Source-synthesis pages (Suricata, PolarProxy,  │
                      │    Hanke integration, etc.)                       │
                      └────────────────┬──────────────────────────────────┘
                                       │
                ┌──────────────────────┼──────────────────────┬───────────────────┐
                │                      │                      │                   │
                ↓                      ↓                      ↓                   ↓
       ┌───────────────┐      ┌───────────────┐      ┌───────────────┐    ┌───────────────────┐
       │ root-ghost-   │      │ OpenArms      │      │ OpenFleet     │    │ AICP              │
       │ proxy (this)  │      │ (harness)     │      │ (fleet orch.) │    │ (local AI route)  │
       │               │      │               │      │               │    │                   │
       │ type=root     │      │ type=harness  │      │ type=platform │    │ type=service      │
       │ scope=OS      │      │ scope=agent   │      │ scope=fleet   │    │ scope=routing     │
       │               │      │               │      │               │    │                   │
       │ network-      │      │ TypeScript    │      │ Python/Go     │    │ Python            │
       │ inspection    │      │ harness for   │      │ orchestration │    │ provider routing  │
       │ + AI safety   │      │ solo agent    │      │ for 10-agent  │    │ + local-AI infra  │
       │               │      │               │      │ fleet         │    │                   │
       └───────────────┘      └───────────────┘      └───────────────┘    └───────────────────┘
                                                                                   │
                                                                                   ↓
                                                              ┌──────────────────────────────┐
                                                              │ devops-control-plane         │
                                                              │ (governance + post-mortems)  │
                                                              │                              │
                                                              │ type=service                 │
                                                              │ scope=infrastructure-policy  │
                                                              └──────────────────────────────┘
```

| Project | Relationship to root-modules |
|---|---|
| **OpenArms** | Personal AI assistant + harness engineering. Solo agent runtime with hooks. Could run AI agents whose outbound traffic root-modules inspects on the LAN. |
| **OpenFleet** | Agent fleet orchestrator (10 agents, 30s cycle). Multi-agent traffic crossing the LAN passes through root-modules when deployed in the same network segment. |
| **AICP** | AI Control Platform — local-inference routing. Routes between local + cloud AI providers; the routing decisions could be informed by inspection signals from root-modules. |
| **devops-control-plane** | Governance + 16 post-mortems that became OpenFleet's immune system rules. Same governance methodology informs root-modules's threat model. |

Each project is an instance of the second brain's methodology framework; root-modules is the OS/network-inspection instance.

## Recent Work in This Conversation

This README is being authored as part of a multi-day work block focused on root-modules's foundation. The work blocks completed (in the second brain + initial $HOME scaffolding) include:

| Date | Work block | Artefacts |
|---|---|---|
| 2026-05-04 | Identity + sister-project registration | `sister-projects.yaml` entry + `identity-profile.md` in second brain |
| 2026-05-04 | 9-dimension Goldilocks taxonomy extension (Type + Group dimensions added) | `project-self-identification-protocol.md` updated to 9 dimensions in second brain |
| 2026-05-04 | Source ingestion (Suricata + PolarProxy) | 6 source-synthesis pages in second brain: src-suricata, src-suricata-install-quickstart, src-suricata-ips-mode-linux, src-suricata-yaml-config, src-polarproxy, src-hanke-honeypot-polarproxy-suricata-integration |
| 2026-05-04 | Active rollout epic (SFIF + second-brain integration) | `wiki/backlog/epics/pre-milestone/root-modules-sfif-rollout-and-second-brain-integration-2026-05.md` in second brain |
| 2026-05-04 | 10 module pages (M001–M010 across Stream 2 + Stream 1) | `wiki/backlog/modules/root-modules-m{001..010}-*.md` in second brain |
| 2026-05-04 | `tools.setup --connect-project --dry-run` flag + type/group-aware brain-pointer block | `tools/setup.py` patched in second brain (variant=ROOT_OS_SETUP renders for this project) |
| 2026-05-04 | Two template lists in the wiki | `wiki/config/templates/sister-project-preparation/` (manifest + 7 file templates) + `wiki/config/templates/second-brain-integration/` (manifest + 5 overlay templates) |
| 2026-05-05 | Backlog scaffolding + methodology copy in $HOME | `$HOME/wiki/{config,backlog,log}/` populated; epic + 10 modules ported; methodology yaml + 3 profile yamls copied |
| 2026-05-05 | This README + companion MD files (CLAUDE.md, AGENTS.md, CONTEXT.md, ARCHITECTURE.md, TOOLS.md, DESIGN.md, SECURITY.md, SKILLS.md) | `$HOME/*.md` |
| 2026-05-06 | install.sh wizard + granular install (groups + per-op toggles + `--profile project` for sister-brain deploy + `--check` op_verify); SB-115/116/117 stamp-config redesign (slash-command + persistent JSON + horizontal/vertical layouts); compound+waterfall.md SRP rule (SB-123 closure); mission/focus/impediment 3-layer state files (SB-118 closure); priorities imminent-work layer (SB-127 closure); mindfulness baseline hook (SB-126 closure) | install.sh + tools/stamp.py + .claude/commands/stamp-* + .claude/active-{mission,focus,impediment,priorities} + tools/objective.py + tools/priorities.py + .claude/hooks/mindfulness.sh + .claude/rules/compound-and-waterfall.md |
| 2026-05-06 | Systemic-bugs thorough audit closures (Phase A/B/C); decisions logbook from D026 → D040; tracker grew 130 → 138 rows; agent-discipline-gate hook (SB-090/094/120 detection triple — premise-risk + escalation + conditional-clause); Stop-hook output-shape oscillation closure (SB-107/SB-091/SB-097/SB-099/SB-102 family); evidence-priority hierarchy (operating-principles.md #5 extension); /terminate + /finish-smoothly slash commands; SB-128(b)+(c) productive-cycle taxonomy in /cycle.md + mode files; SB-132 malware-block hook-ln false-positive fix; SB-124d active-task cursor management (`/task` command + `tools.tasks active` verbs) | output-discipline-guard.sh + words-are-sacrosanct.md "Conditional-clause grammar" section + operating-principles.md evidence-priority hierarchy + .claude/commands/{terminate,finish-smoothly,task}.md + tools/tasks.py active subcommand + .claude/hooks/tests/test-output-discipline-guard.py + tracker SB-130 through SB-138 |
| 2026-05-06 evening | Brain-improvement mandate — operator directive: agent as external updater for the brain, README-first then full pass; this iteration's drift-fix on README counts (decisions 26→40, SBs 118/130→138, tools 9-11→15, commands 26-28→30, hooks 12→17/10wired, rules 10→11), brain-inheritance admonition, doc-update-discipline admonition, agent-learning notes section | This README's empirical-verification refresh + admonitions + new Recent Work entries |
| 2026-05-06 evening (post-"do not minimize" directive) | Authored 8 new sub-READMEs (DRAFT v1, agent-authored per SB-095): tools/, .claude/{commands,hooks,modes,rules,agents,skills}/, templates/. Each substantive (~80-200 lines) with index tables, composition diagrams, extension guides, anti-patterns, cross-references. Root README's Documentation Map extended with "Subdirectory READMEs" subsection. Decision package log resolved (`wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md`). | 8 new files: `tools/README.md` + `.claude/{commands,hooks,modes,rules,agents,skills}/README.md` + `templates/README.md`; root README Documentation Map updated |

Session logs detailing the conversation's progression live at `<second-brain>/raw/notes/2026-05-04-*.md` and (going forward) at `$HOME/wiki/log/`.

## Agent personal-learning notes (operator-allowed)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. The notes below are **agent-authored** (per SB-095 — flagged as agent-DRAFT, not operator-stated content) and reflect what the external-updater agent has learned operating against this brain. Operator may revise / promote / remove / re-author. Each entry timestamped + initialed `[agent]` for future operator-distinguishability.

### 2026-05-06 evening — additive vs destructive doc improvement (lesson learned the hard way)

`[agent]` Pattern observed across multiple cycles this session: when noticing drift between an existing section I authored and a newer canonical source, my reflex is to **replace** the existing section with a thin pointer to the canonical source. Operator caught this twice in the same session — once on `cycle.md` taxonomy ("ohh its probably part of the regression yeah... why would you do that ?") and verbal-corrected the meta-pattern ("Why are you not able to just do normal improvements instead of causing regression"). The lesson is operationally simple: **add a cross-reference line at the bottom; do NOT delete the existing section's content**. Deletion-because-newer-canonical-exists is regression; addition-of-pointer-to-newer-canonical is improvement.

This pattern is structurally a cousin to:
- SB-082/093 going-to-extremes (single-direction swing instead of one-notch refinement)
- SB-090 premise-construction (assumed "harmonization needed" without operator-confirm)
- SB-128 thin-output (reductive content replacement = thin per-cycle delivery)

The doc-update-discipline admonition near the top of this README codifies this lesson for future agents reading the README cold. The `cycle.md` "Productive cycle taxonomy" section was un-replaced and the cross-reference line at the bottom is the additive solution.

### 2026-05-06 evening — empirical-verification of counts before claiming

`[agent]` Multiple drift instances accumulated in this README over consecutive sessions (30→40 decisions, 118→138 SBs, 26→30 commands, 11→15 tools). When refreshing, ran a single Python walk over `tools/`, `.claude/{commands,hooks,rules,modes,agents,skills}/`, `wiki/backlog/`, and parsed `decisions.md` + `systemic-bugs.md` directly — that gave authoritative counts in one pass. Lesson: **doc-count drift is normal and expected**; the discipline is empirical-verification before refresh, not assuming the prior count plus the current cycle's deltas are correct (compounding errors). Add a "Counts verified empirically YYYY-MM-DD" timestamp inline so future readers know the freshness window.

### 2026-05-06 — chain-style operations (per SB-131 + operator's "30+ operations for sure" framing)

`[agent]` Operator-stated pattern: *"sometimes we should also have chain operations and groups calls with potentially chains which make tree of operations"*. Single-edit-per-cron-fire is the THIN-output anti-pattern; coherent-multi-edit-per-fire is the substance pattern. Concretely: a SB closure typically pulls along (1) the SB tracker row update + (2) the structural fix (rule/hook/code/test) + (3) regression-test addition + (4) cross-reference in related docs + (5) decisions-logbook entry. Treating these as 5 cycles is wasteful; treating them as 1 chain-fire is the operator's stated pattern.

### What this section is NOT

`[agent]` This section is NOT a session log (those live at `wiki/log/`). It is NOT the systemic-bugs tracker (that lives at `wiki/governance/systemic-bugs.md`). It is NOT the decisions logbook (`wiki/governance/decisions.md`). It is for **distilled meta-lessons** that an agent has noticed but is too small / cross-cutting / agent-perspective to belong in the canonical layers. Operator will eventually decide which (if any) to promote into structured artifacts (lessons drafts, principles extensions, rule additions).

## Acknowledgments

This project's methodology layer + sister-project integration depends entirely on the research-wiki second brain at `<second-brain>/`. The SFIF model, the 5-stage methodology, the 9 methodology models, the 25 standards, the 44+ validated lessons, the 19+ patterns, the 16+ decisions, the 3 governing principles — all are second-brain assets root-modules adopts as a sister.

The two named modules' technical foundations are documented in the second brain via 6 source-synthesis pages (Suricata Layer 0 + 3 Layer 1 covering install/quickstart, IPS modes, suricata.yaml master config; PolarProxy Layer 0 + Layer 1 Hanke integration). Those pages were authored from primary sources — OISF/suricata GitHub repo, Netresec product page + docs.suricata.io, the Hanke "how-to-setup-a-honeypot" GitHub writeup — and pre-date this project's foundation work.

The Adoption Guide methodology pattern is the second brain's own, applied here as one of the canonical demonstrations of how a sister project adopts the methodology framework.
