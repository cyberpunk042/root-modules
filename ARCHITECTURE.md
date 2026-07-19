# ARCHITECTURE.md — root-modules system architecture

> Deep system topology + component inventory + data flow + hook architecture + module integration interfaces + failure modes. Distinct from [README.md](README.md)'s architecture summary (high-level project description); ARCHITECTURE.md is the technical depth file. Distinct from [DESIGN.md](DESIGN.md) (pattern rationale); ARCHITECTURE.md is the *what + how*, DESIGN.md is the *why*.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct)**: when refreshing ARCHITECTURE.md, **adding ≠ discarding**. Layer new content; refresh inline values where empirically drifted; do NOT replace existing sections wholesale. Going-to-extremes (SB-082/093 family) recurs when an agent rewrites instead of revises. Sacrosanct: operator-verbatim quotes in ADR table preserved EXACTLY · ASCII diagrams (network position, data flows, hook firing order) preserved EXACTLY · Glossary entries preserved (only ADD new terms) · Failure Modes table preserved (operationally critical; updates need empirical verification per Hard Rule 15).

## Summary

This file documents the technical depth of root-modules's two architectural halves — a **transparent L2 inspection bridge** (between OPNsense edge and LAN switch; module slots for Suricata IDS/IPS + PolarProxy TLS termination) AND an **OS-level AI agent safety envelope** (shared safety policy at OS root level; all installed AI tools obey via canonical envelope contract). Topology + Interface Roles + Component Inventory + 4 Data Flow subsections + 2-Layer Hook Architecture (machine-level fires before project-level) + Module Integration Interfaces (Suricata NFQUEUE/AF_PACKET paths · PolarProxy transparent forward + dummy-interface Suricata pairing) + Failure Modes + Recovery + Performance Characteristics (aspirational) + Scalability boundaries + External integration points + Architectural Decisions (ADRs with operator-verbatim) + Glossary. **Empirical state verified 2026-05-06 evening**: 30 slash commands · 10 wired hook matchers across 8 events (17 .sh + 1 .py on disk; archived hooks retained per operator directive) · 15 Python tools + MCP server (10 root_* tools) · 11 rules · 138-row systemic-bugs tracker · 40 decisions D001-D040 · milestone v0.2 + 4 epics + 14 modules + 66 atomic tasks (4-level hierarchy). Brain-improvement mandate Phase 2 in flight (per [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)).

## System Overview

root-modules turns a Linux host into two things at once:

1. **A transparent L2 inspection bridge** — physically positioned between an OPNsense edge firewall and the LAN switch, forwarding Ethernet frames in both directions without announcing itself at L3.
2. **An OS-level AI agent safety envelope** — a shared safety policy at the OS root level that all installed AI tools (Claude Code, opencode, future tools) obey through their respective extension mechanisms.

These two roles run on the same host but are architecturally orthogonal — one operates on network packets crossing the bridge, the other operates on tool calls inside AI agent runtimes. Their failure modes are independent (a Suricata crash does not affect the safety envelope; a tampered settings.json does not affect bridge forwarding).

The host is single-purpose: every system service on it serves one of these two roles or supports the methodology + sister-project integration scaffolding.

## Topology

### Network position

```
   ┌──────────┐    ┌────────────┐         ┌────────────────────────────────────┐         ┌────────────────┐
   │ Internet │ ─→ │ OPNsense   │ ──────→ │  root-modules host              │ ──────→ │  first switch  │ ─→ LAN endpoints
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

| Component | Layer | Purpose | Status (2026-05-06 evening) |
|---|---|---|---|
| **Linux bridge** | Foundation | Forwards Ethernet frames between the two ethernet members. The inline data path. | install.sh implement-stage 98% (D024 GREENLIT); systemd-networkd templates authored at `templates/systemd-networkd/`; real-execute = operator-driven future-session run |
| **Bridge nftables rules** | Foundation | nftables INPUT/FORWARD/OUTPUT chains; controls what traffic crosses the bridge + what reaches the host | T013 FORWARD/OUTPUT operator-decision pending (default-accept vs default-drop threat-model question); INPUT chain (mgmt wifi outbound-only) authored |
| **Management wifi service** | Foundation | wpa_supplicant or equivalent; wifi client config; outbound-only nftables rules | Authored at `templates/wpa_supplicant/`; wpa_supplicant@mgmt0.service systemd unit enabled at install; outbound-only ruleset at `templates/nftables/` |
| **OS-root safety envelope** | Foundation | The shared AI agent policy: tamper sentinel + pre-tool hooks + post-tool hooks + session-lifecycle hooks. The endpoint half of the AI safety setup. | **10 wired hook matchers across 8 events** (17 .sh + 1 .py on disk; archived hooks retained per operator directive 2026-05-06); per-hook inventory at [`.claude/hooks/README.md`](.claude/hooks/README.md) |
| **Active Objective Layer** (state files SB-118 + SB-127 + SB-124d) | Foundation | Multi-cycle objective tracking — `$HOME/.claude/active-{mission,focus,impediment,priorities,task}` state files. Read by mode-enforcement.sh banner + cycle.py stamp + mcp_server.py (root_objective MCP tool) + /handoff handoff doc + pre-compact.sh handoff snapshot. Operator-set via `/mission`, `/focus`, `/impediment`, `/priorities`, `/task` slash commands. | Implemented + operator-empirical verified |
| **opencode bridge plugin** | Foundation | Maps opencode's tool names + plugin SDK envelope onto the canonical Claude Code envelope; spawns the same hook scripts so opencode obeys the same policy. | Implemented at `$HOME/.config/opencode/plugin/claude-bridge.ts` (untested with live opencode) |
| **Methodology engine** | Foundation | `wiki/config/methodology.yaml` + `sdlc-profile.yaml` + `domain-profile.yaml` + `methodology-profile.yaml`. Drives stage-gated work loop. | Complete (copied from second brain to `$HOME/wiki/config/`) |
| **Backlog scaffold** | Foundation | `wiki/backlog/{milestones,epics,modules,tasks}/` with **milestone v0.2 + 4 active epics + 14 modules + 66 atomic tasks** (4-level hierarchy introduced 2026-05-06: Milestone → Epic → Module → Task) | Complete (in `$HOME/wiki/backlog/`) |
| **Governance layer** | Foundation | `wiki/governance/` SRP-separated docs: blockers.md (operator-decision-pending) + decisions.md (40 entries D001-D040 logbook) + progress.md (live-state callout) + systemic-bugs.md (138-row tracker; max ID SB-138; 1 historical duplicate) | Complete — populated daily |
| **Sister-project integration** | Foundation | Registration in second brain + `--connect-project` mechanism produces 4 artefacts in $HOME: `.mcp.json` `research-wiki` entry, `tools/gateway.py` forwarder, `tools/view.py` forwarder, `## Second Brain Connection` block in AGENTS.md (variant=ROOT_OS_SETUP) | Registration complete; --connect-project not yet run for real (M007 territory) |
| **Subdirectory READMEs** (9 — DRAFT v1) | Foundation (documentation) | Per-mechanism canonical indexes — `.claude/{commands,hooks,modes,rules,agents,skills}/README.md` + `tools/README.md` + `templates/README.md` + `scripts/README.md`. All wiki-schema 9-field compliant + Summary + Relationships sections. | Authored 2026-05-06 evening per brain-improvement mandate Phase 1 |
| **Project-internal verifier** | Infrastructure | `tools/verify-policy.py` (or equivalent) — verifies safety envelope invariants programmatically | Pending Infrastructure tooling (M004); `install.sh --check` runs op_verify (16+ checks) as interim |
| **Suricata module** | Features (facultative) | Inline IDS/IPS on bridge data path; eve.json structured output | Not installed (M005 operator-driven future-session) |
| **PolarProxy module** | Features (facultative) | TLS termination + cleartext PCAP-over-IP for downstream consumption (Suricata via dummy interface + tcpreplay) | Not installed (M005 operator-driven future-session) |
| **ccstatusline integration** | Features | Custom Claude Code statusline with 13 widgets + 5 profiles + wrapper. Operator-mandated 3-profile column tier. | Implemented + OPERATOR VISUALLY VERIFIED cycle 43 |
| **Backlog tasks (atomic)** | Continuous | `wiki/backlog/tasks/T<NNN>-*.md` — atomic work units going through stages | 66 tasks T001-T066 across M001-M014 + new E001/E002/E003 epics |
| **Operator log + session log** | Continuous | `wiki/log/YYYY-MM-DD-*.md` — operator directives verbatim + AI session logs + completion notes + decision packages + design notes | Extensively populated (many 2026-05-04/05/06 sessions; brain-improvement mandate log + M-E001-1 vocabulary log + decision-package logs) |

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
| Machine-level | `~/.claude/settings.json` + `~/.claude/hooks/*` | Fires on every tool call from every Claude-Code-protocol tool on the host, in every project | **root-modules** |
| Project-level | `$HOME/.claude/settings.json` + `$HOME/.claude/hooks/*` | Fires on tool calls in sessions opened in `<project>` only | The project itself (each sister project may have its own) |

Order: **machine-level fires before project-level**. The machine-level layer cannot be overridden by a project-level layer's allow rules. Project-level can ADD restrictions but not subtract from the machine-level set.

Hook event types:

| Event | When it fires | Typical purpose |
|---|---|---|
| `PreToolUse` | Before a tool call executes | Tamper sentinel + policy decision |
| `PostToolUse` | After tool output is captured | Leak detection + output redaction |
| `SessionStart` | At session start | Banner + integrity self-check + project-priming (`session-orient.sh` directs agent to invoke `/orient`) |
| `UserPromptSubmit` | When operator submits a prompt | **4-hook compound stack per SB-126** (each emits separate `additionalContext` field — compound, not competing): (1) `context-warning.sh` (% context remaining at thresholds 5/3/2/0% **AND absolute-token thresholds <50k/<25k/<10k per SB-119**; SB-107 transcript_path resolution); (2) `output-discipline-guard.sh` agent-discipline-gate per SB-108 with **3 detectors**: premise-risk (SB-090) + escalation (SB-094) + **conditional-clause grammar (SB-120)** — single-line banner when triggered; (3) `mode-enforcement.sh` per SB-056/117/118/127/129 (dynamic mode-file parsing + voice-table cite-bracket extraction + SB-117 frequency-control via /tmp cache + SB-118 objective layer + SB-127 priorities tier); (4) `mindfulness.sh` per SB-126/128/131 (7-clause baseline reminder per-prompt when active-mode set — one-notch / confirm-don't-construct / artifacts-flagged-as-agent-draft / forward-not-freeze / P1-first / substance-per-cycle / not-blocked-when-unblocked) |
| `PreCompact` | Before context compaction | `pre-compact.sh` writes deterministic state snapshot to `wiki/log/<ts>-pre-compact-handoff.md` (active mode + active task + active mission/focus/impediment/priorities + cycle JSON + blockers JSON + recent logs + git state) so post-compact recovery has lossless reference. **Emits TOP-LEVEL `systemMessage` per SB-133 envelope schema fix** (NOT `hookSpecificOutput` envelope which only validates for PreToolUse/UserPromptSubmit/PostToolUse/PostToolBatch — was silently failing every compaction since SB-078 introduction). |
| `PostCompact` | After context compaction | `post-compact.sh` directs agent to invoke `/orient`; finds + references the most-recent pre-compact-handoff doc in additionalContext (closes the SB-078/SB-079 loop). **Same SB-133 envelope fix** — top-level `systemMessage`. |
| `Stop` | At end of agent's turn | `end-of-cycle-stamp.sh` per SB-114/SB-115: emit end-of-turn status stamp via top-level `systemMessage` (the only valid display channel for Stop hook per Claude Code schema). Reads `$HOME/.claude/stamp-config.json` for layout (horizontal/vertical) + enabled (on/off/auto). Slash-command-driven config via `/stamp-*` commands + `tools/stamp.py`. DRAFT per **SB-116 UX redesign Epic placeholder**; SB-138 stamp diff-suppression D038 directive partial-test-fail surfaced. |
| `SessionEnd` / `SessionSummary` | At session end | Per-session deny/leak count + audit log entry |

### Project surfaces composing with hooks

The hook layer is one of 8 mechanisms in the project's unified trigger model (per `.claude/rules/trigger-model.md`):

| Mechanism | Path | Determinism | Role |
|---|---|---|---|
| Hooks | `.claude/hooks/*.sh` (10 wired matchers across 8 events; 17 .sh + 1 .py on disk; archived hooks retained per operator directive) | Logical (block + reason + remediation per design pattern) | Lifecycle enforcement + project-priming + UserPromptSubmit 4-hook compound stack per SB-126. Per-hook canonical inventory + WIRED-vs-ARCHIVE labels at [`.claude/hooks/README.md`](.claude/hooks/README.md). |
| Slash commands | `.claude/commands/*.md` (**30** — adds /priorities SB-127, /terminate, /finish-smoothly, /task SB-124d, /questions SB-134 since count last refreshed) | 100% on invoke | Operator-typed deterministic workflows. Per-category index at [`.claude/commands/README.md`](.claude/commands/README.md). |
| Skills | `.claude/skills/<name>/SKILL.md` (2 local + user-level) | ~70-95% description-match | Auto-trigger on operator prose. Per-skill canonical index at [`.claude/skills/README.md`](.claude/skills/README.md). |
| Modes | `.claude/modes/*.md` (3) | State-driven (durable per `.claude/active-mode`) | Persona shift across turns; modulates `/cycle`. Per-mode index + cycle-sequence comparison at [`.claude/modes/README.md`](.claude/modes/README.md). |
| Sub-agents | `.claude/agents/*.md` (3 **brain-loaded** sub-agents per SB-081 closure — distinct from generic cold-context Agent-tool dispatch; mandatory brain-load prompts naming CLAUDE.md/AGENTS.md/relevant rules) | Brain-loaded on spawn (project-specific) | Delegated research with explicit "load brain first" prompts. Runtime gap: session-restart required for Claude Code to discover. Per-agent index at [`.claude/agents/README.md`](.claude/agents/README.md). |
| Tools | `tools/*.py` (**15 .py modules** — state, blockers, progress, decisions, cycle, tasks (incl. active-task cursor SB-124d + create verbs), stamp, objective (SB-118), priorities (SB-127), questions (SB-134), group (Q1 Layer A — chain/group/tree primitive), run-tests (unified regression runner), mcp_server, _paths, __init__) + harness-deferred | Programmatic (100% non-LLM) | State queries + computations + render config. Per-tool index + composition map at [`tools/README.md`](tools/README.md). |
| MCP tools | `tools/mcp_server.py` (**10 root_* tools** — root_state, root_blockers, root_progress, root_decisions_{list,get,verify,next_id}, root_objective SB-118+SB-127, root_questions SB-134, root_orient) | Programmatic | Cross-process structured returns. |
| Scheduled tasks | `CronCreate` / `ScheduleWakeup` | Cron OR self-paced | Wraps any of the above for repeated firing. Auto-cancellation gating per [`.claude/rules/loop-cron-lifecycle.md`](.claude/rules/loop-cron-lifecycle.md) (autonomous-management permission with refined triggers). |

**M-E001-1 productive-cycle action vocabulary** (per Hard Rule 14 in CLAUDE.md/AGENTS.md + `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`): each cycle-fire emits one of 9 canonical action types (sb-closure / verified-edit / drift-fix-with-empirical / explicit-standby-with-named-reason / new-artifact / doc-refresh / blocker-surface / operator-directive-register / read-only-audit). All 8 mechanisms above converge on this same ACTION layer. Mandatory cycle-report last-line: `Productive output: <type> — <one-line specific>`.

Hook regression tests live at `.claude/hooks/tests/` (8 test files) + `tools/tests/` (5 test files) = **13 test files / 215/234 aggregate** (empirically verified 2026-05-06 evening via `python3 -m tools.run-tests`). 3 partial-fail surfaced for operator-decision: test-mode-enforcement 0/0 collection regression, test-end-of-cycle-stamp-diff-suppression 21/22 (1 fail), test-questions 33/51 (18 fail). Run: `python3 -m tools.run-tests` for pre-flight verification before hook edits per Hard Rule 14 (verified-edit action type).

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

- **Multi-segment** (multiple LAN switches) — would require either multi-host deployment (one root-modules per segment) or multi-bridge config (multiple `br0`-equivalent bridges per host, each pair of ethernet ports a separate bridge). Each bridge is independent.
- **Multi-host** (operator's portability intent: *"this machine or another [new] one"*) — multiple root-modules hosts deployed independently. No shared state between hosts; each is a self-contained appliance.
- **High-availability** (active-passive failover between two root-modules hosts) — out of scope; would require a shared-state mechanism + bridge-level failover (VRRP, etc.) not in current architecture.

## Integration Points (with other systems)

| External system | Integration shape |
|---|---|
| **OPNsense edge firewall** (upstream) | root-modules is downstream from OPNsense; OPNsense remains the L3 routing/firewall device. OPNsense does NOT need to know root-modules exists (the bridge is L3-invisible). |
| **LAN switch** (downstream) | root-modules is upstream from the first switch; the switch sees a direct connection to the OPNsense-side. No switch reconfiguration needed. |
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
| 2026-05-05 | Two-layer hook architecture is invariant | Machine-level (root-modules) fires before project-level (sister projects). Machine-level deny is final. Project-level can add restrictions but not subtract. |
| 2026-05-05 | `auto_connect: false` permanent default for type=root | Type=root projects gate the security envelope; explicit-authorization gate via `--connect-project` is the friction-by-design. M010 may revisit per operator. |
| 2026-05-06 | **SB-115 brain-inheritance pattern** (codified as Hard Rule 12) | $HOME source-of-truth for **operational tooling** (hooks, slash commands, tools/*.py, settings.json wiring conventions, ANSI-fence rendering patterns, statusline widgets, mode-enforcement banner shape). /opt second-brain INHERITS / adapts these patterns. **Knowledge** flows OTHER direction (root-modules → second brain via `gateway contribute`). Operator verbatim 2026-05-06: *"WTF WHY WOULD YOU SAY second-brain is different ?? you are the root retart... second-brain take everything from you...."* |
| 2026-05-06 | **SB-118 objective layer state files** (mission/focus/impediment) | Multi-cycle objective tracking ABOVE active-task cursor — `$HOME/.claude/active-{mission,focus,impediment}` state files + `tools/objective.py` set/clear/show + `/mission` `/focus` `/impediment` slash commands + mode-enforcement.sh banner surfacing + cycle.py stamp render + mcp_server root_objective MCP tool. Operator directive 2026-05-06: *"this make me think if we dont also need a current mission and a current focus... we can even add impediment.. this is another sub-level from a focus that is blocked for example"*. |
| 2026-05-06 | **SB-127 priorities tier** (imminent-work hot-queue ABOVE PM blockers) | `$HOME/.claude/active-priorities` state file + `tools/priorities.py` (verbs: add/show/clear/remove/promote/demote/set/insert/update — insert+update added per SB-130) + `/priorities` slash command + mode-enforcement banner section + both stamp layouts. Operator directive 2026-05-06: *"my new STP file which would contain a list with task-and/or-focus combo with priotities that should be identified as the imminent work, even before the PM work"*. |
| 2026-05-06 | **SB-123 compound + waterfall** unified rule | `.claude/rules/compound-and-waterfall.md` formalizes two orthogonal design axes — **compound** (additive layers at-a-moment: mode + priorities + mission + focus + impediment + live state visible simultaneously) + **waterfall** (state flows event-to-event: SessionStart → UserPromptSubmit hooks → Stop → PreCompact → PostCompact → /orient). Operator directive 2026-05-06: *"This also make me think of the compound and waterfall strategy... it should be compounding"*. |
| 2026-05-06 | **SB-126 mindfulness baseline hook** | `.claude/hooks/mindfulness.sh` UserPromptSubmit hook injecting 7-clause baseline reminder per-prompt when active-mode set: one-notch-not-extreme (SB-082/093) · confirm-don't-construct (SB-090) · artifacts-flagged-as-agent-draft (SB-095) · forward-not-freeze (SB-099) · P1-first (SB-128) · substance-per-cycle (SB-128 + Hard Rule 14) · not-blocked-when-unblocked + chain-operations (SB-131). Forms 4-hook UserPromptSubmit compound stack with context-warning + output-discipline-guard + mode-enforcement. |
| 2026-05-06 | **SB-128 productive-cycle taxonomy + Hard Rule 14** | M-E001-1 vocabulary DRAFT v2 — 9 canonical action types every cycle-fire emits. Mandatory cycle-report last-line `Productive output: <type> — <one-line specific>`. THIN standby without named subject is the SB-128 bug. Cross-tool universal — every AI tool's cycle skill emits the same vocabulary. |
| 2026-05-06 | **SB-131 chain-operations** (codified as Hard Rule 13) | Coherent multi-edit per cron-fire is substance pattern; single-edit-per-fire is THIN-output anti-pattern (SB-128 family). Operator directive 2026-05-06: *"sometimes we should also have chain operations and groups calls with potentially chains which make tree of operations.. like updating multiple thing like project file and cursor / ecosystem files and such and whatnot"*. `tools/group.py` Q1 Layer A primitive (chain/group/tree composition). |
| 2026-05-06 | **SB-133 PreCompact + PostCompact envelope schema fix** | Hooks emit TOP-LEVEL `systemMessage` per Claude Code schema (NOT `hookSpecificOutput` envelope which only validates for PreToolUse/UserPromptSubmit/PostToolUse/PostToolBatch). Was silently failing every compaction since SB-078 introduction — defeated entire SB-078/SB-079 reliability chain. Empirical schema-failure observed in /compact stdout proved regression real. |
| 2026-05-06 | **Hard Rules 11-15 codified at hot-path layer** (CLAUDE.md / AGENTS.md) | Five new universal Hard Rules: 11 additive ≠ discarding (SB-082/093 going-to-extremes recurrence) · 12 brain-inheritance pattern (SB-115) · 13 chain-operations per fire (SB-131) · 14 productive-cycle taxonomy (M-E001-1 vocabulary; SB-128 closure) · 15 empirical-count-verification before drift-claim (SB-129 quality-recompile + ad-hoc count drift across multiple brain files). Each cites operator-verbatim or session-incident in Why column. Every-prompt-context-budget operationalization of operating-principles.md extension principles. |
| 2026-05-06 | **Brain-improvement mandate first-pass + 9 sub-READMEs DRAFT v1** | Operator directive 2026-05-06: *"you are going to be the one from the external that update the brain of the root project"* + *"do not minimize"* + *"30+ operations for sure"*. Phase 1 (README pass) complete: README.md refreshed + scripts/README.md refreshed + 8 NEW sub-READMEs authored at `tools/README.md` + `.claude/{commands,hooks,modes,rules,agents,skills}/README.md` + `templates/README.md`. All wiki-schema 9-field compliant + Summary + Relationships sections. Phase 2 (top-level docs + categories) operator-gated per individual yes-per-file: CLAUDE.md / AGENTS.md / CONTEXT.md / TOOLS.md / SKILLS.md / Rules / Hooks / BOOTSTRAP.md done; ARCHITECTURE.md / DESIGN.md / SECURITY.md / commands / modes / agents / skills / tools-docstrings pending. |
| 2026-05-06 | **install.sh implement-stage GREENLIT (D024)** | T012 install.sh advances scaffold → implement (98% readiness); T013 systemd-networkd as network tool; T014 accept current `$HOME/.claude/*` state as canonical. Real-execute on host = operator-driven future-session run. install.sh gains `--wizard` state-aware route + granular `--with-group`/`--no-group` per-category install + `--profile project --dest <path>` for sister-project agent-brain deploy + `/install-agent-brain <path>` slash command wrapper. shellcheck PASS; 16-step `op_verify` `--check` mode. |

ADR detail lives at [`wiki/governance/decisions.md`](wiki/governance/decisions.md) — full audit trail with **40 entries D001-D040**, rationale + reversibility + downstream effects per entry. Refresh via `python3 -m tools.decisions append --title --rationale --reversibility`.

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
| **Machine-level layer** | The OS-root level safety policy at `~/.claude/settings.json` + `~/.claude/hooks/*`. Owned by root-modules. Fires on every tool call from every Claude-Code-protocol tool on the host. |
| **Module slot** | An architectural position where a facultative inspection module can be installed. Suricata fills the IDS/IPS slot; PolarProxy fills the TLS-termination slot; future modules can fill new slots. |
| **NFQUEUE** | Linux netfilter mechanism that hands off packets from kernel space to userspace for verdicts. Suricata uses NFQUEUE for one of its IPS modes. |
| **PCAP-over-IP** | A protocol where PCAP data is streamed over a TCP connection. PolarProxy emits PCAP-over-IP for live downstream consumption (typically by Suricata via tcpreplay → dummy interface). |
| **Project-level layer** | A project-specific `.claude/` config that adds further restrictions on top of the machine-level layer. Sister projects may have one; root-modules itself may also have one. |
| **Project-level vs machine-level (precedence)** | Machine-level fires BEFORE project-level. Machine deny is final. Project-level can ADD restrictions but cannot subtract from machine. |
| **Stealth bridge** | A transparent L2 bridge configured so the host has no IP on the inspected segment — endpoints don't see "an extra hop"; they see what looks like a direct connection. The "ghost" half of root-modules. |
| **Tamper sentinel** | The integrity-check pre-tool-call hook that verifies the safety envelope is intact before honoring any tool call. Fail-CLOSED — refuses every subsequent call when tampering is detected. |
| **Transparent forward proxy** | The PolarProxy operating mode for root-modules: connects to external TLS servers on behalf of LAN clients, decrypting + re-encrypting in flight. The "proxy" half of root-modules (when PolarProxy is installed). |
| **Two-layer hook architecture** | The OS-root + project-level hook arrangement. Machine-level fires first (root-modules's domain); project-level fires second (each project's own). |

## Agent personal-learning notes (operator-allowed, per directive 2026-05-06)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. Entries are **agent-authored** (per SB-095 — agent-DRAFT, not operator-stated). Operator may revise / promote / remove. Each timestamped + initialed `[agent]`. ARCHITECTURE.md-specific framing — system-architecture-doc lessons.

### 2026-05-06 evening — ARCHITECTURE.md is the technical depth file (NOT the project description)

`[agent]` ARCHITECTURE.md and README.md sometimes drift into duplication when an agent extends both with the same content. Discipline: README.md = project description + identity + vision + modules + status (what the project IS); ARCHITECTURE.md = topology + components + data flow + hook architecture + module integration interfaces + failure modes (what the project DOES technically). Don't duplicate. When an architecture detail belongs in both, put it in ARCHITECTURE.md and cross-reference from README.md.

### 2026-05-06 evening — ASCII diagrams are sacrosanct (preserve box-drawing exactly)

`[agent]` The 4 ASCII diagrams in ARCHITECTURE.md (network position, network passive flow, Suricata IPS paths, PolarProxy integration, tool-call flow + hook firing order) are sacrosanct in their exact rendering. Box-drawing characters + line breaks + indentation form the visual structure. ANY edit risks misalignment. Discipline: when the underlying topology changes, RE-RENDER the entire diagram in a scratch buffer + verify alignment + paste — don't piecemeal-edit lines within the diagram.

### 2026-05-06 evening — ADR table is append-only with operator quotes preserved

`[agent]` The ADR table (lines 313+) accumulates architectural decisions over project lifetime. Operator-verbatim quotes in ADRs (lines 317/319/323 + new 2026-05-06 ADRs) are sacrosanct. Discipline: APPEND new ADRs at the END of the table; never reorder; never modify existing rows; preserve operator quotes EXACTLY. The decisions logbook at `wiki/governance/decisions.md` (40 entries D001-D040) is the operational source-of-truth; the ADR table here is the architectural curation (a subset focused on architectural decisions, not all decisions).

### 2026-05-06 evening — Component Inventory Status column drifts fast

`[agent]` The Status column in Component Inventory transitions frequently (Pending → Implemented → Operator-empirical-verified → DRAFT → Archive). Per Hard Rule 15 (empirical-count-verification before drift-claim), refresh status values inline with empirical-verification-YYYY-MM-DD timestamp where useful. Don't compound prior status values with current cycle's deltas. Run a programmatic walk + parse before refreshing.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). Not DESIGN.md (pattern rationale — the WHY). For ARCHITECTURE.md-specific system-architecture-doc lessons that benefit fresh-pickup agents but are too small to warrant their own rule file. Operator promotes to structured artifact when pattern matures.

## Cross-References

### Top-level brain files (10)

| For… | Read |
|---|---|
| Project front door + vision + identity + modules + status | [README.md](README.md) |
| Cold-pickup orientation | [BOOTSTRAP.md](BOOTSTRAP.md) |
| Why this shape (design pattern rationale) | [DESIGN.md](DESIGN.md) |
| Tool reference (when scripts exist) | [TOOLS.md](TOOLS.md) |
| Threat model + protections + escalation + audit | [SECURITY.md](SECURITY.md) |
| Cross-tool agent contract + 15 universal Hard Rules | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing + 15 Hard Rules | [CLAUDE.md](CLAUDE.md) |
| Current operational state (Active Objective Layer + SFIF + pending decisions) | [CONTEXT.md](CONTEXT.md) |
| Skills directory context (skill-vs-command-vs-hook decision matrix) | [SKILLS.md](SKILLS.md) |

### Subdirectory READMEs (9 — DRAFT v1, agent-authored 2026-05-06 evening)

| For… | Read |
|---|---|
| **Per-hook canonical inventory** + WIRED-vs-ARCHIVE labels (canonical extension of Hook Architecture section above) | [.claude/hooks/README.md](.claude/hooks/README.md) |
| 30 slash commands by category (canonical extension of Project surfaces table) | [.claude/commands/README.md](.claude/commands/README.md) |
| **Per-tool composition map** + state-file architecture diagram | [tools/README.md](tools/README.md) |
| 3 modes + cycle-sequence comparison | [.claude/modes/README.md](.claude/modes/README.md) |
| 11 rules + strictness-tier matrix | [.claude/rules/README.md](.claude/rules/README.md) |
| 3 brain-loaded sub-agents + SB-081 runtime gap | [.claude/agents/README.md](.claude/agents/README.md) |
| 2 skills + mechanism-choice context | [.claude/skills/README.md](.claude/skills/README.md) |
| 5 install template categories | [templates/README.md](templates/README.md) |
| Deployment + maintenance toolkit | [scripts/README.md](scripts/README.md) |

### Backlog + governance + log

| For… | Read |
|---|---|
| Methodology engine | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| 4-level backlog hierarchy (Milestone → Epic → Module → Task) | [wiki/backlog/](wiki/backlog/) |
| **40-entry decisions logbook (D001-D040)** — full audit trail | [wiki/governance/decisions.md](wiki/governance/decisions.md) |
| **138-row systemic-bugs tracker** | [wiki/governance/systemic-bugs.md](wiki/governance/systemic-bugs.md) |
| Operator-decision-pending blockers register | [wiki/governance/blockers.md](wiki/governance/blockers.md) |
| Live-state callout | [wiki/governance/progress.md](wiki/governance/progress.md) |

### Universal cross-cutting rules (architecture-relevant)

| For… | Read |
|---|---|
| **Unified 8-mechanism signal→action→recovery model** + M-E001-1 action layer | [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) |
| **Compound + waterfall axes** (additive layering at-a-moment + sequential cascade event-to-event — directly relevant for hook architecture) | [.claude/rules/compound-and-waterfall.md](.claude/rules/compound-and-waterfall.md) |
| Context-engineering (auto/pre/on-demand/facultative injection modes) | [.claude/rules/context-engineering.md](.claude/rules/context-engineering.md) |
| Hook architecture rule (2-layer + 3-component design pattern + bypass mechanism per hook) | [.claude/rules/hook-architecture.md](.claude/rules/hook-architecture.md) |
| Loop-cron-lifecycle (when scheduled tasks self-cancel/update) | [.claude/rules/loop-cron-lifecycle.md](.claude/rules/loop-cron-lifecycle.md) |
| Operating principles (4 core + 11 extension + Hard Rules 11-15 mapping) | [.claude/rules/operating-principles.md](.claude/rules/operating-principles.md) |
| **CLAUDE.md / AGENTS.md Hard Rules 11-15** — additive≠discarding · brain-inheritance · chain-operations · productive-cycle taxonomy · empirical-count-verification | [CLAUDE.md](CLAUDE.md) Rules 11-15 + [AGENTS.md](AGENTS.md) Rules 11-15 |

### Brain-improvement mandate (this work block — 2026-05-06)

| For… | Read |
|---|---|
| Sacrosanct verbatim directive governing the brain-quality passes | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| **M-E001-1 productive-cycle action vocabulary DRAFT v2** (9 types — every mechanism above emits one) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |
| Decision package log (RESOLVED — sub-READMEs scope) | [wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md](wiki/log/2026-05-06-194730-decision-package-new-subdir-readmes.md) |

### Second brain (canonical sources)

| For… | Read |
|---|---|
| Methodology engine canonical | `<second-brain>/wiki/config/methodology.yaml` |
| SFIF model canonical | `<second-brain>/wiki/spine/models/quality/model-sfif-architecture.md` |
| Suricata source-syntheses (4 pages) | `<second-brain>/wiki/sources/src-suricata*.md` |
| PolarProxy source-syntheses (2 pages) | `<second-brain>/wiki/sources/src-polarproxy.md` + `src-hanke-honeypot-polarproxy-suricata-integration.md` |
| Identity profile canonical | `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` |
| Adoption Guide canonical | `<second-brain>/wiki/spine/references/adoption-guide.md` |
| Wiki-schema (9 required fields + per-type required sections) | `<second-brain>/wiki/config/wiki-schema.yaml` |
