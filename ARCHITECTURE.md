# ARCHITECTURE.md — root-ghostproxy system architecture

> Deep system topology + component inventory + data flow + hook architecture + module integration interfaces + failure modes. Distinct from [README.md](README.md)'s architecture summary (high-level project description); ARCHITECTURE.md is the technical depth file. Distinct from [DESIGN.md](DESIGN.md) (pattern rationale); ARCHITECTURE.md is the *what + how*, DESIGN.md is the *why*.

## System Overview

root-ghostproxy turns a Linux host into two things at once:

1. **A transparent L2 inspection bridge** — physically positioned between an OPNsense edge firewall and the LAN switch, forwarding Ethernet frames in both directions without announcing itself at L3.
2. **An OS-level AI agent safety envelope** — a shared safety policy at the OS root level that all installed AI tools (Claude Code, opencode, future tools) obey through their respective extension mechanisms.

These two roles run on the same host but are architecturally orthogonal — one operates on network packets crossing the bridge, the other operates on tool calls inside AI agent runtimes. Their failure modes are independent (a Suricata crash does not affect the safety envelope; a tampered settings.json does not affect bridge forwarding).

The host is single-purpose: every system service on it serves one of these two roles or supports the methodology + sister-project integration scaffolding.

## Topology

### Network position

```
   ┌──────────┐    ┌────────────┐         ┌────────────────────────────────────┐         ┌────────────────┐
   │ Internet │ ─→ │ OPNsense   │ ──────→ │  root-ghostproxy host              │ ──────→ │  first switch  │ ─→ LAN endpoints
   │          │    │ edge FW    │         │                                    │         │                │   (workstations,
   │          │    │            │         │  ┌──────────┐    ┌──────────┐     │         │                │    AI agents,
   └──────────┘    └────────────┘         │  │ upstream │    │   LAN    │     │         └────────────────┘    services)
                                          │  │ ethernet │    │ ethernet │     │
                                          │  └──────────┘    └──────────┘     │
                                          │       │              │            │
                                          │       └──── br0 ─────┘            │
                                          │       (Linux bridge,              │
                                          │        L3-invisible)              │
                                          │              │                    │
                                          │              ↕                    │
                                          │   ┌─────────────────────┐         │
                                          │   │  inspection modules │         │
                                          │   │  (Suricata,         │         │
                                          │   │   PolarProxy)       │         │
                                          │   │  facultative        │         │
                                          │   └─────────────────────┘         │
                                          │              │                    │
                                          │              ↓                    │
                                          │   ┌─────────────────────┐         │
                                          │   │ management wifi     │ ──────→ operator network
                                          │   │ (outbound-only)     │         (apt, threat-intel,
                                          │   └─────────────────────┘          AI APIs, web)
                                          │                                    │
                                          │   ┌─────────────────────┐         │
                                          │   │ AI agent runtimes   │         │
                                          │   │  - Claude Code      │         │
                                          │   │  - opencode (via    │         │
                                          │   │    bridge plugin)   │         │
                                          │   │  - others (future)  │         │
                                          │   └─────────────────────┘         │
                                          │              │                    │
                                          │              ↓                    │
                                          │   ┌─────────────────────┐         │
                                          │   │ OS-root safety      │         │
                                          │   │ envelope            │         │
                                          │   │  - tamper sentinel  │         │
                                          │   │  - pre-tool hooks   │         │
                                          │   │  - post-tool hooks  │         │
                                          │   │  - session hooks    │         │
                                          │   └─────────────────────┘         │
                                          └────────────────────────────────────┘
```

### Interface Roles

| Interface | Role | L3 visible? | Firewall posture |
|---|---|---|---|
| Upstream-facing ethernet | One side of the bridge — typically the OPNsense-facing side | No (bridge member, no IP) | Forward bridge traffic; nftables FORWARD chain decides per IPS-mode policy |
| LAN-facing ethernet | Other side of the bridge — typically the first-switch-facing side | No (bridge member, no IP) | Same as upstream side (bridge symmetry) |
| Management wifi | Outbound-only management — wifi client to operator's existing secure SSID | Yes (host's own management IP from the wifi network's DHCP) | INPUT chain drops everything except established/related; OUTPUT chain accepts; no inbound services bind |

The bridge interface (typically `br0`) holds the two ethernet members. The bridge is the inline data path; modules see traffic crossing it.

Specific device names (e.g. `enp2s0`, `enp4s0`, `wlp3s0`, or `eth0`/`eth1`/`wlan0`) depend on the host's hardware and udev naming and are resolved at install time, not at the architecture level.

## Component Inventory

| Component | Layer | Purpose | Status |
|---|---|---|---|
| **Linux bridge** | Foundation | Forwards Ethernet frames between the two ethernet members. The inline data path. | Pending Foundation IaC (M003) |
| **Bridge nftables rules** | Foundation | nftables INPUT/FORWARD/OUTPUT chains; controls what traffic crosses the bridge + what reaches the host | Pending Foundation IaC (M003) |
| **Management wifi service** | Foundation | wpa_supplicant or equivalent; wifi client config; outbound-only nftables rules | Pending Foundation IaC (M003) |
| **OS-root safety envelope** | Foundation | The shared AI agent policy: tamper sentinel + pre-tool hooks + post-tool hooks + session-lifecycle hooks. The endpoint half of the AI safety setup. | Pending Foundation IaC (M003) — operator-authored, not extending prior $HOME/.claude debris |
| **opencode bridge plugin** | Foundation | Maps opencode's tool names + plugin SDK envelope onto the canonical Claude Code envelope; spawns the same hook scripts so opencode obeys the same policy. | Pending Foundation IaC (M003) |
| **Methodology engine** | Foundation | `wiki/config/methodology.yaml` + `sdlc-profile.yaml` + `domain-profile.yaml` + `methodology-profile.yaml`. Drives stage-gated work loop. | Complete (copied from second brain to `$HOME/wiki/config/`) |
| **Backlog scaffold** | Foundation | `wiki/backlog/{epics,modules,tasks}/` with active rollout epic + 14 modules + 66 atomic tasks | Complete (in `$HOME/wiki/backlog/`) |
| **Sister-project integration** | Foundation | Registration in second brain + `--connect-project` mechanism produces 4 artefacts in $HOME: `.mcp.json` `research-wiki` entry, `tools/gateway.py` forwarder, `tools/view.py` forwarder, `## Second Brain Connection` block in AGENTS.md (variant=ROOT_OS_SETUP) | Registration complete; --connect-project not yet run for real |
| **Project-internal verifier** | Infrastructure | `tools/verify-policy.py` (or equivalent) — verifies safety envelope invariants programmatically | Pending Infrastructure tooling (M004) |
| **Suricata module** | Features (facultative) | Inline IDS/IPS on bridge data path; eve.json structured output | Not installed |
| **PolarProxy module** | Features (facultative) | TLS termination + cleartext PCAP-over-IP for downstream consumption (Suricata via dummy interface + tcpreplay) | Not installed |
| **Backlog tasks (atomic)** | Continuous | `wiki/backlog/tasks/T<NNN>-*.md` — atomic work units going through stages | Initial scaffolding only |
| **Operator log + session log** | Continuous | `wiki/log/YYYY-MM-DD-*.md` — operator directives verbatim + AI session logs + completion notes | Not yet populated |

## Data Flow

### Network data flow (bridge in passive forward, no modules)

```
upstream ethernet → br0 (Linux bridge, kernel-level forwarding) → LAN ethernet
        ↑                                                                 ↓
        └─────────────── bidirectional, no inspection ───────────────────┘
```

Frames cross at L2 with no L3 visibility on the inspected segment. nftables FORWARD chain default-accept (or default-drop with explicit allow rules per operator's threat model — operator decision at Foundation stage).

### Network data flow (with Suricata module, IPS mode)

Two architectural paths per `wiki/sources/src-suricata-ips-mode-linux.md`:

**Path 1 — NFQUEUE on the FORWARD chain (Phase-1 default):**
```
upstream → br0 → NFQUEUE → Suricata inspects → verdict (accept/drop) → out via LAN ethernet
                  └─ bypass option: when Suricata is down, treat as ACCEPT (fail-OPEN)
```

**Path 2 — AF_PACKET copy-mode IPS (Phase-2):**
```
upstream → Suricata copies to LAN side via AF_PACKET (kernel bridge retired)
              └─ when Suricata is down, the copy stops and packets pile at NIC (fail-CLOSED at L2)
```

The choice of path is operator's failopen-vs-failclosed decision at M005 design time.

### Network data flow (with PolarProxy module, transparent forward proxy mode)

Per `wiki/sources/src-hanke-honeypot-polarproxy-suricata-integration.md`:

```
upstream HTTPS:443 → nftables NAT redirect 443 → 10443 → PolarProxy
                                                              ↓
                                                     decrypts + re-encrypts
                                                              ↓
                                                     re-emit on LAN side at 443
                                                              ↓
                                                     emit cleartext PCAP-over-IP on tcp/4430
                                                              ↓
                                                  nc localhost 4430 | tcpreplay -i polarproxytls -t -
                                                              ↓
                                                  Linux dummy interface (polarproxytls)
                                                              ↓
                                                  Suricata reads as af-packet capture source
```

The dummy interface is created at boot (`ip link add polarproxytls type dummy`); the tcpreplay bridge runs as a systemd service depending on PolarProxy.service being up.

### Tool-call data flow (endpoint AI agent safety)

```
operator prompt → AI agent reasoning → tool call decision (e.g. Bash, Read, Write, WebFetch)
                                              ↓
                                  AI tool runtime emits canonical envelope:
                                    { session_id, tool_name, tool_input, hook_event_name: "PreToolUse" }
                                              ↓
                            ┌─────────────── Hook firing order ───────────────┐
                            │ 1. Tamper-detection sentinel                   │
                            │    - safety policy present?                    │
                            │    - hooks not disabled?                       │
                            │    - deny-set above threshold?                 │
                            │    - all required scripts present + executable?│
                            │    - on FAIL: refuse this + every subsequent   │
                            │      tool call until restored (fail-CLOSED)    │
                            └─────────────────────────────────────────────────┘
                                              ↓ (sentinel passes)
                            ┌─────────────── Pre-tool-call hooks ────────────┐
                            │ - credential-file blocker (deny-set match)     │
                            │ - behavior-pattern blocker (shell-exfil idioms,│
                            │   malicious-shape inputs)                       │
                            │ - operator-curated additions                    │
                            │   each returns: allow / deny / ask              │
                            └─────────────────────────────────────────────────┘
                                              ↓ (decision = allow OR ask-confirmed)
                                  Tool executes → tool output
                                              ↓
                            ┌─────────────── Post-tool-call hooks ────────────┐
                            │ - leak-detector (credential-shaped value scan)  │
                            │   logs detections, alerts operator,              │
                            │   optionally redacts before surfacing to agent   │
                            └─────────────────────────────────────────────────┘
                                              ↓
                                  output surfaced to AI agent reasoning
```

For Claude Code, this flow runs natively via Claude Code's PreToolUse + PostToolUse hooks.

For opencode, the bridge plugin (`~/.config/opencode/plugin/claude-bridge.ts`) maps opencode's native tool names (`bash` → `Bash`, `read` → `Read`, etc.) onto the canonical envelope and invokes the same hook scripts. **Same scripts. Same envelope. Different runtime.**

## Hook Architecture (Two-Layer)

Hooks live at two layers; both fire on every tool call:

| Layer | Path | Scope | Owner |
|---|---|---|---|
| Machine-level | `~/.claude/settings.json` + `~/.claude/hooks/*` | Fires on every tool call from every Claude-Code-protocol tool on the host, in every project | **root-ghostproxy** |
| Project-level | `$HOME/.claude/settings.json` + `$HOME/.claude/hooks/*` | Fires on tool calls in sessions opened in `<project>` only | The project itself (each sister project may have its own) |

Order: **machine-level fires before project-level**. The machine-level layer cannot be overridden by a project-level layer's allow rules. Project-level can ADD restrictions but not subtract from the machine-level set.

Hook event types:

| Event | When it fires | Typical purpose |
|---|---|---|
| `PreToolUse` | Before a tool call executes | Tamper sentinel + policy decision |
| `PostToolUse` | After tool output is captured | Leak detection + output redaction |
| `SessionStart` | At session start | Banner + integrity self-check + project-priming (`session-orient.sh` directs agent to invoke `/orient`) |
| `UserPromptSubmit` | When operator submits a prompt | `context-warning.sh` (% context remaining at thresholds 5/3/2/0); `output-discipline-guard.sh` (agent-discipline-gate per SB-108: high-confidence premise-risk + escalation detection, single-line banner via additionalContext when triggered) |
| `PreCompact` | Before context compaction | `pre-compact.sh` writes deterministic state snapshot to `wiki/log/<ts>-pre-compact-handoff.md` (active mode + active task + cycle JSON + blockers JSON + recent logs + git state) so post-compact recovery has lossless reference |
| `PostCompact` | After context compaction | `post-compact.sh` directs agent to invoke `/orient`; finds + references the most-recent pre-compact-handoff doc in additionalContext (closes the SB-078/SB-079 loop) |
| `Stop` | At end of agent's turn | `end-of-cycle-stamp.sh` per SB-114/SB-115: emit end-of-turn status stamp via top-level `systemMessage` (the only valid display channel for Stop hook per Claude Code schema). Reads `$HOME/.claude/stamp-config.json` for layout (horizontal/vertical) + enabled (on/off/auto). Slash-command-driven config via `/stamp-*` commands + `tools/stamp.py`. DRAFT per SB-116 UX redesign Epic. |
| `SessionEnd` / `SessionSummary` | At session end | Per-session deny/leak count + audit log entry |

### Project surfaces composing with hooks

The hook layer is one of 8 mechanisms in the project's unified trigger model (per `.claude/rules/trigger-model.md`):

| Mechanism | Path | Determinism | Role |
|---|---|---|---|
| Hooks | `.claude/hooks/*.sh` | Logical | Lifecycle enforcement + project-priming |
| Slash commands | `.claude/commands/*.md` (25 — incl. /orient, /cycle, /handoff, /audit, /log, /blockers, /progress, /decisions, /sync-progress, /help-root, /mode-{pm,architect,dual,clear,status}, /stamp-{horizontal,vertical,on,off,auto,status} (SB-115), /install-agent-brain, /mission, /focus, /impediment (SB-118)) | 100% on invoke | Operator-typed deterministic workflows |
| Skills | `.claude/skills/<name>/` (2 local + user-level) | Description-match | Auto-trigger on operator prose |
| Modes | `.claude/modes/*.md` (3) | State-driven | Persona shift across turns; modulates `/cycle` |
| Sub-agents | `.claude/agents/*.md` (3 brain-loaded) | Cold-context | Delegated research with explicit "load brain first" prompts |
| Tools | `tools/*.py` (10 modules — state, blockers, progress, decisions, cycle, tasks, stamp, objective, mcp_server, _paths) + harness-deferred | Programmatic | State queries + computations + render config |
| MCP tools | `mcp_server.py` (6 read-only tools) | Programmatic | Cross-process structured returns |
| Scheduled tasks | `CronCreate` / `ScheduleWakeup` | Cron OR self-paced | Wraps any of the above for repeated firing |

Hook regression tests live at `.claude/hooks/tests/` — cycle 53 added `test-policy-block.py` (verifies SB-083 fix) and `test-malware-block.py` (verifies SB-084 fix). Run: `python3 .claude/hooks/tests/test-*.py` for pre-flight verification before hook edits.

## Module Integration Interfaces

Modules layer on top of the foundation through specific architectural slots:

### Suricata integration

Suricata reads packets from the bridge data path. Two integration shapes:

- **NFQUEUE consumer:** Suricata runs with `-q 0` (or multi-queue `-q 3 -q 4 -q 5` with `fanout` option). nftables forwards FORWARD-chain packets to NFQUEUE. Suricata returns verdicts (accept/drop). Bypass option in nftables makes the queue fail-OPEN if Suricata is down.
- **AF_PACKET copy-mode:** Suricata's af-packet config lists the two ethernet interfaces with `copy-mode: ips` and reciprocal `copy-iface` settings. Kernel bridge retired (mutually exclusive with this mode). Suricata is the bridge.

When PolarProxy is also installed, Suricata adds a third capture source (the dummy interface fed by tcpreplay) to its af-packet config.

Output: eve.json (structured JSON Lines). Default location `/var/log/suricata/eve.json`. Logrotate config at install time.

### PolarProxy integration

PolarProxy as transparent forward proxy:

- nftables NAT rule on the LAN side: redirect tcp/443 → 10443 (or operator-chosen port).
- PolarProxy listens on 10443 with the dynamic CA, decrypts, re-encrypts toward the destination.
- Output: rotated PCAP files (`-o /var/log/polarproxy/`) AND/OR PCAP-over-IP listener (`--pcapoverip 4430`) for live consumption.

Pairing with Suricata via dummy interface:
- Boot-time `ip link add polarproxytls type dummy` (systemd-networkd `[NetDev]` config OR oneshot service).
- `tcpreplay -i polarproxytls -t -` reads from PolarProxy's PCAP-over-IP socket and replays into the dummy interface.
- Suricata's af-packet config includes the dummy interface.

CA distribution: dynamic CA generated on first PolarProxy run; exposed via `--certhttp <port>` for client retrieval. Operator deploys to LAN endpoints by some mechanism (manual install, AD GPO, MDM, package).

### Future module slot

Architecture supports additional modules at Layer 4 (e.g. eBPF-based traffic classification, AI-specific signature feeds, per-flow audit logging, active response). Each future module would have its own module page in `wiki/backlog/modules/`, its own design doc, its own facultative install option. The slot is a Layer-4 in the layered architecture diagram.

## Failure Modes + Recovery

| Failure | Detection | Recovery | Failopen / Failclosed |
|---|---|---|---|
| **Linux bridge link flap** | `ip link` shows DOWN on a member | Bridge auto-recovers when member returns; systemd unit may restart bridge | Operator-decision: keep forwarding via the surviving member (degraded), or stop forwarding (clean); default keep-forwarding |
| **Linux bridge config corrupt** | nftables / `brctl show` shows misconfig | Operator console + reload from IaC config | Bridge stops forwarding |
| **Suricata IPS mode crash (NFQUEUE path)** | systemd reports unit failure | systemd restarts; bypass option in nftables means traffic flows uninspected during the crash | Fail-OPEN (with bypass option enabled) |
| **Suricata IPS mode crash (AF_PACKET path)** | systemd reports unit failure | systemd restarts; copy-mode kernel infra means packets pile at NIC during the crash | Fail-CLOSED at L2 |
| **PolarProxy free-tier cap reached** | Rate of TLS sessions seen vs decrypted diverges after the daily cap | Provision paid license tier; alert operator | Fail-OPEN (forwarding continues, decryption stops) |
| **PolarProxy crash** | systemd reports unit failure | systemd restarts; in transparent forward mode, NAT rule still redirects 443→10443 → connection refused on 10443 → application sees connection failure | Fail-CLOSED at the proxy hop (operator may want a bypass-when-down NAT rule for fail-OPEN — operator decision) |
| **Tamper sentinel detects tampering** | Sentinel returns non-OK | Operator restores safety policy from IaC; integrity check passes; tool calls resume | Fail-CLOSED (every tool call refuses) |
| **AI agent runtime crash** | Tool call returns error | AI tool runtime auto-recovers per its own logic; safety envelope unchanged | (n/a — orthogonal to safety envelope) |
| **Management wifi disconnect** | Wifi link DOWN | wpa_supplicant retries; if persistent, operator console fallback | Bridge unaffected (orthogonal) |
| **Host kernel panic / hardware failure** | Host offline | Operator physically restarts host | Bridge stops forwarding (Fail-CLOSED at the host level) |
| **Inspection log volume exceeds disk** | logrotate reports failure / disk full | Operator-set retention policy; logrotate trims oldest | Inspection continues but historical record truncates |

## Performance Characteristics

(To be characterized at Foundation stage; aspirational at present.)

- **Bridge throughput:** depends on kernel bridge implementation + interface speed; typical Gigabit link sustained without inspection
- **Suricata IPS throughput (NFQUEUE):** typically lower than Layer-2 modes; ~100-500 Mbps on commodity hardware single-thread
- **Suricata IPS throughput (AF_PACKET multi-thread + eBPF LB):** Gigabit+ on commodity hardware with proper threading + load balancing
- **PolarProxy throughput:** TLS termination is CPU-bound; ~100-200 Mbps for cleartext throughput on commodity hardware single-thread
- **Combined PolarProxy + Suricata + dummy-interface bottleneck:** tcpreplay is single-thread; under heavy decrypted-traffic load, the bridge becomes the bottleneck

These are starting-point estimates from the source-syntheses; actual values are M005 module-design verification work.

## Scalability + Scale-out Boundaries

The current architecture is **single-host single-segment**. Scale boundaries:

- **Multi-segment** (multiple LAN switches) — would require either multi-host deployment (one root-ghostproxy per segment) or multi-bridge config (multiple `br0`-equivalent bridges per host, each pair of ethernet ports a separate bridge). Each bridge is independent.
- **Multi-host** (operator's portability intent: *"this machine or another [new] one"*) — multiple root-ghostproxy hosts deployed independently. No shared state between hosts; each is a self-contained appliance.
- **High-availability** (active-passive failover between two root-ghostproxy hosts) — out of scope; would require a shared-state mechanism + bridge-level failover (VRRP, etc.) not in current architecture.

## Integration Points (with other systems)

| External system | Integration shape |
|---|---|
| **OPNsense edge firewall** (upstream) | root-ghostproxy is downstream from OPNsense; OPNsense remains the L3 routing/firewall device. OPNsense does NOT need to know root-ghostproxy exists (the bridge is L3-invisible). |
| **LAN switch** (downstream) | root-ghostproxy is upstream from the first switch; the switch sees a direct connection to the OPNsense-side. No switch reconfiguration needed. |
| **LAN endpoints** | Endpoints see what looks like a direct connection through the segment. No endpoint reconfiguration needed UNLESS PolarProxy is installed (then endpoints need the proxy's CA in their trust store). |
| **Operator network** (via management wifi) | Outbound-only. Host fetches apt updates, threat-intel feeds, AI APIs, etc. No inbound services on the wifi interface. |
| **Research-wiki second brain** (`<second-brain>/`) | Sister-project relationship. Registered in `sister-projects.yaml`. Connection installs MCP entry + forwarders + brain-pointer block. Bidirectional flow (consume methodology + standards + lessons; contribute lessons learned). |
| **AI provider APIs** (Anthropic, OpenAI, etc.) | Outbound from AI agents on the host; pass through the management wifi (host's own outbound) OR through the bridge (if the agent is running on a LAN endpoint). When PolarProxy is installed, these flows are decryption-eligible per the bypass-list policy. |
| **External SIEM / log aggregation** (Filebeat → Elasticsearch / Loki / etc.) | Optional. When the inspection modules are installed, eve.json + leak-log + audit-log can be shipped to a downstream SIEM. Integration shape is operator-decided (Filebeat is a typical choice per the Hanke pattern). |

## Architectural Decisions (recent ADRs)

| Date | Decision | Rationale |
|---|---|---|
| 2026-05-04 | type=`root` is scope, not install path | Operator: *"WHy root ? since it could have been jfortin install too.. since its an operating system IaC project, even in a user such as jfortin it would remain a root-type project."* |
| 2026-05-04 | group=`operating-system-setup` introduced as a new dimension | New dimension distinct from Type (scope) and Domain (technology). Group is intent / purpose-class axis. |
| 2026-05-04 | Modules (Suricata, PolarProxy) are facultative | Operator: *"first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed."* |
| 2026-05-04 | Methodology layer copied from second brain (not pointer) | `$HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml` — local copies. Adapt artifacts/protocols/gates per project; keep stage-name + ordering invariants. Per Adoption Guide step 1. |
| 2026-05-04 | SDLC profile = `simplified` | Goldilocks: micro scale + solo execution + scaffold/foundation phase. Avoids ceremony that suits team-scale projects. |
| 2026-05-04 | Methodology profile = `stage-gated` | OS-setup work has security cost on stage-leakage; hard ALLOWED/FORBIDDEN per stage suits the threat model. |
| 2026-05-05 | Prior $HOME files (README, install.sh, hooks, integrity.py, opencode bridge plugin, memory folder) are AI-debris from prior session, not authoritative | Operator: *"I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST."* Project's authoritative implementation will be re-authored by methodology-driven flow. |
| 2026-05-05 | Two-layer hook architecture is invariant | Machine-level (root-ghostproxy) fires before project-level (sister projects). Machine-level deny is final. Project-level can add restrictions but not subtract. |
| 2026-05-05 | `auto_connect: false` permanent default for type=root | Type=root projects gate the security envelope; explicit-authorization gate via `--connect-project` is the friction-by-design. M010 may revisit per operator. |

ADR detail (when authored at design stage) lives at `$HOME/wiki/decisions/` (planned location; not yet populated).

## Glossary (architectural terms)

| Term | Definition |
|---|---|
| **Bridge (br0)** | The Linux L2 bridge with the two ethernet interfaces as members. Forwards Ethernet frames between members. The inline data path. |
| **Bridge member** | An ethernet interface joined to the Linux bridge via `brctl addif` (or equivalent). Bridge members do not have IPs of their own when in the bridge. |
| **Canonical envelope** | The Claude Code-style JSON envelope every AI tool's hook input + output uses on this host: `{session_id, tool_name, tool_input, hook_event_name}` for input; `{permissionDecision, permissionDecisionReason, systemMessage}` for output. |
| **Dummy interface** | A virtual Linux network interface created with `ip link add <name> type dummy`. Used for the PolarProxy → Suricata integration to feed cleartext PCAP back into Suricata's af-packet capture. |
| **Failopen** | A failure mode where the system continues to forward traffic when an inspection layer is down — inspection silently degrades, network keeps working. Operator's threat-model decision. |
| **Failclosed** | A failure mode where the system stops forwarding when an inspection layer is down — network downtime, no traffic without inspection. Operator's threat-model decision. |
| **Hook script** | An executable script (typically `.sh` or `.py`) called by an AI tool runtime at a specific lifecycle event (PreToolUse, PostToolUse, SessionStart, etc.). Receives the canonical envelope on stdin; returns a JSON decision on stdout. |
| **Machine-level layer** | The OS-root level safety policy at `~/.claude/settings.json` + `~/.claude/hooks/*`. Owned by root-ghostproxy. Fires on every tool call from every Claude-Code-protocol tool on the host. |
| **Module slot** | An architectural position where a facultative inspection module can be installed. Suricata fills the IDS/IPS slot; PolarProxy fills the TLS-termination slot; future modules can fill new slots. |
| **NFQUEUE** | Linux netfilter mechanism that hands off packets from kernel space to userspace for verdicts. Suricata uses NFQUEUE for one of its IPS modes. |
| **PCAP-over-IP** | A protocol where PCAP data is streamed over a TCP connection. PolarProxy emits PCAP-over-IP for live downstream consumption (typically by Suricata via tcpreplay → dummy interface). |
| **Project-level layer** | A project-specific `.claude/` config that adds further restrictions on top of the machine-level layer. Sister projects may have one; root-ghostproxy itself may also have one. |
| **Project-level vs machine-level (precedence)** | Machine-level fires BEFORE project-level. Machine deny is final. Project-level can ADD restrictions but cannot subtract from machine. |
| **Stealth bridge** | A transparent L2 bridge configured so the host has no IP on the inspected segment — endpoints don't see "an extra hop"; they see what looks like a direct connection. The "ghost" half of root-ghostproxy. |
| **Tamper sentinel** | The integrity-check pre-tool-call hook that verifies the safety envelope is intact before honoring any tool call. Fail-CLOSED — refuses every subsequent call when tampering is detected. |
| **Transparent forward proxy** | The PolarProxy operating mode for root-ghostproxy: connects to external TLS servers on behalf of LAN clients, decrypting + re-encrypting in flight. The "proxy" half of root-ghostproxy (when PolarProxy is installed). |
| **Two-layer hook architecture** | The OS-root + project-level hook arrangement. Machine-level fires first (root-ghostproxy's domain); project-level fires second (each project's own). |

## Cross-References

| For… | Read |
|---|---|
| Project front door + vision + identity + modules + status | [README.md](README.md) |
| Why this shape (design pattern rationale) | [DESIGN.md](DESIGN.md) |
| Tool reference (when scripts exist) | [TOOLS.md](TOOLS.md) |
| Threat model + protections + escalation + audit | [SECURITY.md](SECURITY.md) |
| Cross-tool agent contract | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing | [CLAUDE.md](CLAUDE.md) |
| Current operational state | [CONTEXT.md](CONTEXT.md) |
| Skills directory context (skill-vs-command-vs-hook decision matrix) | [SKILLS.md](SKILLS.md) |
| Methodology engine | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| SFIF model (canonical) | `<second-brain>/wiki/spine/models/quality/model-sfif-architecture.md` |
| Suricata source-syntheses (in second brain) | `<second-brain>/wiki/sources/src-suricata*.md` |
| PolarProxy source-syntheses (in second brain) | `<second-brain>/wiki/sources/src-polarproxy.md`, `src-hanke-honeypot-polarproxy-suricata-integration.md` |
