# root-modules — Summary

> One page, plain language: what you get by default, what you can add on top, and the pros and cons of each choice. Detail lives in [README.md](README.md), [ARCHITECTURE.md](ARCHITECTURE.md), [SECURITY.md](SECURITY.md); this page is the overview.

**root-modules is, first and by default, a root or home folder upgrader and evolver. Secondly, you can install supplementary modules — like the ghostproxy combo** (transparent inspection bridge + Suricata IDS/IPS + PolarProxy TLS inspection).

Everything is Infrastructure-as-Code: the repo carries the *spec*, and `git clone` + `./install.sh` turns a fresh Linux host (target: Debian 13) into the configured state. Re-running the install is a no-op when nothing drifted.

---

## What you get by default (the foundation)

Running `./install.sh` (profile `base`) upgrades the root/home folder with four things:

| Layer | What it is |
|---|---|
| **Endpoint AI agent safety** | One safety policy at the OS-root level that every AI tool on the host obeys — Claude Code hooks (secret-read blocking, dangerous-command blocking, output leak detection, cross-project write boundary) plus an opencode bridge so both runtimes consult the same policy. An integrity sentinel (SHA256 baselines) detects tampering with the policy itself. |
| **Agent brain** | The working environment for AI sessions: slash commands, deterministic Python tools, on-demand rules, operator-pickable modes, sub-agents, an MCP server, and session-lifecycle hooks (orient on start, handoff before compaction, status stamp at end of turn). |
| **Methodology + backlog** | The stage-gate methodology engine (document → design → scaffold → implement → test), the Milestone → Epic → Module → Task backlog, and governance docs (decisions, blockers, progress, systemic-bugs tracker). |
| **Network readiness** | When the install mode includes it: the transparent bridge network config (systemd-networkd `gpbr0`), outbound-only management wifi (wpa_supplicant + nftables), and post-install verification (`install.sh --check`, 16+ drift checks). |

### Pros and cons of the default

| Pros | Cons |
|---|---|
| **One policy, every AI tool, every session.** Hooks fire machine-level, so any project you open on the host inherits the same safety envelope — no per-tool duplicate configs. | **Deny-by-default friction.** Legitimate actions sometimes hit a block and need the documented bypass (each block prints its reason + remediation, but it is still a step). |
| **Idempotent + portable.** Same install on this machine or the next one; re-run to converge; `--dry-run` previews and `--check` audits without changing anything. | **Fail-closed tamper detection cuts both ways.** If the policy files are damaged (even by accident), tool calls refuse until restored — safe, but it can stop you mid-work. |
| **Reversible and inspectable.** `uninstall.sh` with a safety contract; conflicting files are backed up (`.pre-ghostproxy.bak`), never destroyed. | **A brain has upkeep.** Hooks, commands, rules, and counts drift as the project evolves and need maintenance passes (the methodology exists precisely to manage this). |
| **Works standalone, offline, on any folder.** No bridge hardware, no modules, no second-brain connection required — endpoint mode is a complete install (this is how sovereign-os consumes it). | **Per-prompt hook output adds noise/latency.** The compound banner and stamps inform, but they occupy context and screen space (tunable via `/stamp-*` and mode commands). |
| **Everything is spec.** Nothing hand-configured on the host that a fresh clone + install can't reproduce. | **Claude Code + opencode are the covered runtimes today.** Other AI tools need a thin adapter each before the shared policy binds them. |

### Install choices (all defaults, no modules involved)

| Choice | Options | Meaning |
|---|---|---|
| `--profile` | `base` (default) · `full` · `project` · `interactive` | *What scope*: foundation only / foundation + all facultative modules / agent-brain-only into a sister project (`--dest <path>`) / prompted. |
| `--mode` | `auto` (default) · `endpoint` · `bridge` · `hybrid` | *What role*: endpoint = AI safety only, no network ops; bridge = inspection appliance; hybrid = both; auto-detect. |
| Per-op toggles | `--with-*` / `--no-*`, `--with-group` / `--no-group`, `--wizard` | Granular opt-in/out of any single operation or group. |

---

## The modules you can add

Modules are **facultative** — per the operator's standing rule: *"first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed."* The foundation never requires them.

### The ghostproxy combo (network inspection)

The named combo: a **ghost** (invisible inline bridge) that becomes a **proxy** (TLS interceptor) when its inspection modules are installed. It watches the AI-related traffic that endpoint policy can't see — what agents actually send and receive over the network.

**1. Transparent L2 bridge** — ships in the foundation today via `--mode bridge|hybrid`

The box sits inline between the edge firewall (OPNsense) and the first LAN switch, forwarding frames with no IP on the inspected segment. Endpoints can't see it; management happens over a separate outbound-only wifi link.

| Pros | Cons |
|---|---|
| Invisible at L3 — no DHCP/gateway/route changes anywhere on the LAN | Inline single point of failure — if the box dies, the LAN path dies with it (console recovery) |
| Ground truth on all traffic crossing the segment | Needs dedicated hardware: 2 ethernet NICs + a wifi interface |
| Useful alone (segment tap / stealth baseline) even with zero inspection modules | Adds a hop of latency/throughput ceiling; offloads (GRO/LRO/TSO) must be disabled for inspection |

**2. Suricata (IDS/IPS)** — planned module, not yet integrated (module M005)

Signature-based detection on the bridge path: alert (IDS) or drop (IPS) flows matching malicious or AI-policy-violating patterns; structured event logs (eve.json).

| Pros | Cons |
|---|---|
| Detects known-bad and AI-shaped traffic patterns (prompt-injection shapes, exfil patterns) in real time | Blind inside TLS without the decryption module — most AI traffic is TLS-wrapped |
| Rich observability: alerts, stats, JSON events for downstream tooling | Rule tuning is ongoing work; false positives on a home/office LAN are real |
| IPS mode can actively drop bad flows, not just report | The IPS wiring choice is a real trade-off: NFQUEUE fails *open* (Suricata down → traffic flows uninspected) vs AF_PACKET fails *closed* (Suricata down → LAN path stops) |

**3. PolarProxy (TLS inspection)** — planned module, not yet integrated

Transparent TLS termination: decrypt, hand cleartext to Suricata (via a dummy interface), re-encrypt toward the destination. This is what turns metadata-level visibility into content-level visibility.

| Pros | Cons |
|---|---|
| Content-level inspection of LLM/API traffic — catches what both endpoint policy and TLS-blind IDS miss | Every inspected endpoint must trust the proxy's CA — distribution burden, and cert-pinned apps break or bypass |
| Canonical, documented pairing with Suricata | Free tier caps at 10 GB / 10 000 sessions per day and then **fails open** (keeps forwarding, stops decrypting) — needs monitoring |
| Selective ruleset: decrypt inspectable destinations, bypass banking/health/pinned domains | Real privacy and trust implications — you are intercepting your own LAN's encrypted traffic; scope deliberately |

**Combo verdict**: endpoint policy sees what agents *can do* on the host; the ghostproxy combo sees what they *actually do* on the wire. Each alone has a blind spot — together they are the full "system AI safety setup." The cost is hardware, inline risk, CA distribution, and tuning time — which is exactly why it's a facultative combo and not the default.

### ccstatusline (Features module) — implemented, installed by `--profile full`

Rich statusline for Claude Code sessions: custom widgets + profiles showing mode, mission/focus/impediment, priorities, task cursor, SFIF stage, blockers.

| Pros | Cons |
|---|---|
| At-a-glance session state; profile switching via `/statusline-*` | Needs npm/node; visual density is taste-dependent (hence profiles) |

### Future module slots (extensible, not committed)

eBPF traffic classification, AI-specific signature feeds, per-flow audit logging, active-response capability — each would arrive as its own facultative module with its own install option.

---

## Choosing in one glance

| You want... | Install |
|---|---|
| AI agent safety + agent brain on a dev machine or home folder (the default; how sovereign-os uses it) | `./install.sh --profile base --mode endpoint` |
| The full inspection appliance between firewall and switch | `./install.sh --profile full --mode bridge` (+ Suricata/PolarProxy modules when they land) |
| Both roles on one box | `--mode hybrid` |
| Just the agent brain inside another project | `./install.sh --profile project --dest <path>` or `/install-agent-brain <path>` |
| To see what would happen first | add `--dry-run`; audit later with `--check`; guided route via `--wizard` |

---

*Rename note (2026-07-19): the project was formerly named root-ghostproxy; "ghostproxy" now names the module combo above, not the project. Directive log: [wiki/log/2026-07-19-rename-root-modules-directive.md](wiki/log/2026-07-19-rename-root-modules-directive.md). This page: agent-authored per operator directive at [wiki/log/2026-07-19-summary-page-directive.md](wiki/log/2026-07-19-summary-page-directive.md).*
