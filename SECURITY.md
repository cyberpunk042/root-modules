# SECURITY.md — root-modules

> Security policy for root-modules. Threat model, layer-by-layer protections, fail-closed invariants, escalation, audit, and known limitations. Load-bearing for type=root + group=operating-system-setup projects — the project IS a security envelope, so SECURITY.md is not auxiliary documentation but a load-bearing artefact of the project itself.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct)**: when refreshing SECURITY.md, **adding ≠ discarding**. Layer new content; refresh inline values where empirically drifted; do NOT replace existing sections wholesale. Going-to-extremes (SB-082/093 family) recurs when an agent rewrites instead of revises — particularly dangerous on a security-policy doc where defense-in-depth layers can be silently lost. Sacrosanct: operator-verbatim quotes (network posture line 87+ "wifi client mode... DNS over TLS... no leak... no SSH server" · acknowledgments framing line 227+ "secure an OS and configure claude code and opencode at the root with all the safety needed") preserved EXACTLY. Threat Model + Fail-Closed Invariants + Layer-by-Layer Protections structure preserved (only ADD new threats / invariants / layers in dedicated sub-sections).

## Summary

This file documents root-modules's security policy — the project IS a security envelope, so this doc is load-bearing not auxiliary. Stance: **deny-by-default at every layer** (endpoint AI agent policy + bridge inspection + integrity layer); **fail-closed where stakes are high** (tamper detection refuses every tool call until restored) + **fail-open where stakes are low** (Suricata IPS bypass option keeps network up during inspection-down windows; PolarProxy free-tier silently degrades decryption past cap). 3 protection layers: Layer 1 endpoint AI agent safety (foundation — always required) · Layer 2 Suricata IDS/IPS (facultative module) · Layer 3 PolarProxy TLS termination (facultative module). Threat model defends against 3 in-scope adversaries (external network attacker · adversarial content via tool outputs · compromised AI agent on host) with 4 out-of-scope categories explicitly listed (insider with operator credentials · AI provider account compromise · physical access · supply chain). 7 fail-closed invariants enforced via tamper-detection sentinel. Audit logging across 7 channels. Hardening intensifies per SFIF stage. Known limitations distinguish inherited (PolarProxy + Suricata upstream constraints) from by-design (project-posture choices). **Hard Rules 11-15** (CLAUDE.md / AGENTS.md hot-path layer) operationalize security discipline: additive ≠ discarding (defense-in-depth preservation) · brain-inheritance pattern ($HOME source-of-truth for safety policy; /opt cannot weaken) · chain operations (SB closures pull along regression tests) · productive-cycle taxonomy (read-only-audit action type IS security audit) · empirical-count-verification (deny-set threshold verified, not estimated).

## Project Security Stance (one paragraph)

root-modules is a system AI safety setup project. Its security stance is **deny-by-default** at every layer: the endpoint AI agent policy denies tool calls unless they pass deny-set + behavior checks; the bridge denies fall-through traffic if the inspection layer says drop; the integrity layer denies every tool call if safety controls are tampered with. The project assumes adversarial input — both at the network layer (untrusted inbound/outbound traffic) and at the agent layer (adversarial content embedded in tool outputs that can hijack agent reasoning via prompt injection). The protections are designed to fail closed where the cost of a false positive is small (deny a tool call; alert the operator) and fail open only where the cost of a false negative is small AND the cost of a false positive is large (network inspection in degraded mode keeps traffic flowing; alerting the operator that inspection has degraded is the mitigation).

## Threat Model

### Adversaries

| Adversary | Capabilities | What we defend against |
|---|---|---|
| **External attacker (network)** | Can send packets crossing the bridge from the upstream side; can attempt to compromise endpoints on the LAN; can scan for open services on the host's management interface | Inbound exploits aimed at LAN endpoints; lateral movement; persistence on the bridge host itself; scanning of the management network |
| **Adversarial content via tool outputs** | Web pages, file contents, search results, MCP server responses fetched by an agent can contain instructions that subvert the agent's reasoning | Prompt-injection-driven agent actions: deny credential reads, deny suspicious filesystem writes, deny exfil-shaped network calls regardless of how the agent was prompted to perform them |
| **Compromised AI agent on the host** | An agent whose reasoning is subverted (prompt injection, malicious instruction) attempts to read credentials, write persistence, exfiltrate data, install malware, tamper with the safety controls themselves | Tool-call-time policy enforcement that blocks dangerous actions even when the agent itself is no longer trusted; tamper-detection that refuses every subsequent tool call if controls are disabled |
| **Insider with operator credentials** | An operator-equivalent actor who can edit configuration, push to the repo, run installs | Out of scope — operator is trusted by design. The project's audit logs preserve a record so operator actions are traceable, but they are not blocked. |
| **AI provider account compromise** | An attacker who gains the operator's API key for a cloud LLM provider can issue API calls posing as the operator | Out of scope at the network layer (these are the operator's own outbound calls); credential-scoped — the operator's responsibility to rotate keys + monitor billing |
| **Untrusted physical access to the host** | An attacker with physical access can take the host offline, read disks, manipulate firmware | Out of scope — physical security is a different control layer (host placement + physical access control) |
| **Adversarial Suricata rule flooding** | A traffic generator that triggers signature matches at high rate to overwhelm logging or saturate the IPS path | Out of scope by default; mitigation is rate-limiting + alert thresholds in the Suricata module's tuning, not in the core foundation |

### Assets to Protect

In priority order:

1. **Credentials in `$HOME`** — `.env*`, `*.pem`, `*.key`, `id_rsa*`, `.aws/credentials`, `kubeconfig`, `.netrc`, `.git-credentials`, `**/secret*` and similar credential-shaped paths. The endpoint policy's deny-set targets these.
2. **AI provider tokens and API keys** — Anthropic, OpenAI, Google, GitHub, GitLab, Slack, AWS, Stripe, SendGrid, npm, Telegram, JWT. The endpoint policy's leak-detection inspects tool outputs for these patterns and refuses to surface them in agent context.
3. **Private keys and DB connection strings** — same leak-detection layer applies.
4. **Authorization headers in tool outputs** — same.
5. **LAN endpoint traffic content** — when the network inspection modules are deployed, the bridge sees and (optionally) controls the content of traffic crossing it. The TLS-firewall ruleset in PolarProxy decides which destinations get decrypted vs bypassed (e.g. banking, healthcare, cert-pinned apps bypass).
6. **Operator's session transcripts, history files, ssh keys** — the deny-set covers these path patterns.
7. **The safety policy itself** — `~/.claude/` and equivalent policy directories must remain owned by the operator and integrity-verified. Tampering refuses every tool call until restored.

### Out of Scope

- Physical security of the host
- Console access (it is the recovery path; an attacker with console can override anything)
- Operator's manual edits to configuration (operator is trusted; their edits are subject to integrity verification afterward but are not blocked)
- Cryptographic strength of TLS itself (the project relies on the host's TLS implementation; replacing OpenSSL or hardening cipher suites is a host-config concern, not a project concern)
- Side-channel attacks (timing, power, thermal) on co-located AI accelerators
- Supply chain integrity of upstream packages (Suricata, PolarProxy, Debian packages — the project relies on package signature verification done by the host's package manager)

## Layer-by-Layer Protections

The project defends in depth across three layers. Layer 1 is the foundation and is always required. Layers 2 and 3 are facultative modules — operator decides at install time whether to deploy them.

### Layer 1 — Endpoint AI Agent Safety (foundation)

**What it provides.** A shared policy source at the OS-root level that all installed AI tools (Claude Code, opencode, future tools) obey through their respective extension mechanisms. Protections include:

- **Deny-set on credential-shaped paths.** Tool calls that touch credential-shaped paths are blocked before the AI tool's runtime hands the call to the OS — regardless of which AI tool issued the call.
- **Behavior-pattern check on tool inputs.** Tool inputs are inspected for shell-exfil idioms, malicious payload patterns, and known dangerous-shape inputs. Matches are blocked or asked-for-confirmation depending on severity.
- **Output scanning for sensitive values.** Tool outputs are inspected for credential-shaped values matching patterns for major AI/cloud/SaaS providers. Detected leaks are logged and the operator is alerted; the leak-shaped value is optionally redacted before being surfaced to the agent.
- **Cross-AI-tool consistency via shared policy.** Multi-AI-tool environments share one policy source so deny rules + behavior checks are not duplicated across tool runtimes — defined once at the OS-root level, enforced uniformly. Adding a new AI tool means adding a thin extension that mirrors hooks under the new tool's plugin/extension SDK; the policy itself is not duplicated.
- **Fail-closed tamper detection.** A pre-tool-call sentinel verifies the safety policy is intact: policy source present, hooks not disabled, deny-set above a known-safe threshold, all required enforcement scripts present + executable + non-suspicious size. If any check fails, every subsequent tool call refuses until restored. The sentinel itself is integrity-protected. Implementation: `.claude/hooks/integrity.py` imported by policy-block.sh + malware-block.sh (per `.claude/hooks/README.md` canonical inventory).
- **Agent-discipline runtime layer** (per SB-108 + 2026-05-06 closures). UserPromptSubmit hook `output-discipline-guard.sh` detects 3 high-confidence agent-behavioral safety patterns at runtime: PREMISE-RISK (SB-090 — premise-construction-without-confirmation; agent infers operator-stated when operator only observed), ESCALATION (SB-094 — operator-frustration markers compound the risk), and CONDITIONAL-CLAUSE (SB-120 — future-conditional grammar that agent may treat as current grant). Single-line concise banner via additionalContext when triggered; silent on routine prompts. **Mindfulness baseline** (`mindfulness.sh` UserPromptSubmit hook per SB-126) injects 7-clause baseline reminder per-prompt when active-mode set: one-notch (anti-pendulum SB-082/093) · confirm-don't-construct (SB-090) · artifacts-flagged-as-agent-draft (SB-095) · forward-not-freeze (SB-099) · P1-first (SB-128) · substance-per-cycle (SB-128) · not-blocked-when-unblocked + chain-operations (SB-131). These are agent-behavioral safety controls (cycle-quality + drift-prevention discipline); distinct from credential/exfil safety controls but operating in the same lifecycle layer (4-hook UserPromptSubmit compound stack per SB-126).

**What it does NOT provide at this layer:**
- Network-layer defense — that's Layers 2 and 3
- Agent reasoning correction — the model can still be fooled by prompt injection; what this layer prevents is the ACTIONS that flow from being fooled
- Per-AI-tool runtime sandboxing — the AI tools run as themselves; the policy operates AROUND them, not under them

### Layer 2 — Network IDS/IPS (Suricata module — facultative)

**Status.** Module not yet installed. Foundation runs without it. Documented here for the layered-defense story.

**What it provides when installed.** Inline signature-based detection on the bridge data path. Suricata sees every packet crossing the bridge, matches against rule sets (ET Open, custom AI-safety rules, operator-curated additions), and either alerts (IDS mode) or drops (IPS mode) flows that match malicious or AI-policy-violating patterns. Output is structured eve.json for downstream consumption.

**Failopen behavior.** Per the source-synthesis at `wiki/sources/src-suricata-ips-mode-linux.md`, Suricata's IPS mode has a load-bearing failopen decision:
- **Phase-1 path (recommended for inspection-not-firewall posture):** keep the kernel bridge, use NFQUEUE on the FORWARD chain with the `bypass` option. When Suricata is down, traffic flows uninspected — network keeps working, inspection silently degrades.
- **Phase-2 path (tighter integration, fail-CLOSED at L2):** retire the kernel bridge, use AF_PACKET IPS mode with copy-mode pairing of the two ethernet interfaces. When Suricata is down, the copy stops and packets pile up at the NIC.

The failopen choice is operator's threat-model decision and is part of M005 module-design work.

### Layer 3 — Network TLS Inspection (PolarProxy module — facultative)

**Status.** Module not yet installed. Foundation runs without it.

**What it provides when installed.** Transparent TLS termination on the bridge data path. PolarProxy intercepts TLS streams, decrypts using a per-instance dynamically generated CA, re-encrypts toward the destination, and emits cleartext as PCAP-over-IP for downstream consumers (typically Suricata). Pairs with Suricata via the Hanke-pattern dummy interface + tcpreplay setup (per `wiki/sources/src-hanke-honeypot-polarproxy-suricata-integration.md`).

**Failopen behavior of the free tier.** Per `wiki/sources/src-polarproxy.md`: PolarProxy's free tier caps at 10 GB / 10 000 sessions / 10 000 rule-matches per day. Past the cap, PolarProxy keeps forwarding TLS but stops decrypting. **Inspection silently degrades; network keeps working.** This is fail-OPEN at the inspection layer. Mitigation: monitor the rate of TLS sessions seen vs decrypted; alert on divergence after the cap; consider paid tier when traffic volume sustains above the cap.

**CA distribution requirement.** PolarProxy decryption requires that LAN endpoints trust the proxy's CA. Endpoints without the CA in their trust store see cert errors and self-block. Cert-pinned apps (banking, mobile pinning) reject the proxy's CA regardless of trust-store presence; these destinations must be added to the bypass list (`--bypass <regex-file>` or the TLS-firewall ruleset).

## Network Posture (host-level constraints)

Per operator directive 2026-05-05: *"with the wifi client mode enabled with will not be in dhcp and we will make sure that we are in DNS over TLS and that we are not opening any leak, this is not for not reason I said no to ssh server setup"*.

The $HOME host operates under these network constraints:

| Constraint | What it means | Why |
|---|---|---|
| **WiFi client mode** | The host has a wifi interface in client mode (not AP mode) for management connectivity | Reduces RF surface; host doesn't broadcast its presence; uses an existing trusted network for out-of-band management |
| **NOT in DHCP** | Static IP assignment; addresses configured deterministically | DHCP broadcast solicitation leaks MAC + hostname + DHCP options; static config eliminates the leak vector |
| **DNS over TLS (DoT)** | All DNS resolution over TLS to a trusted resolver | Eliminates plaintext DNS leaks (which expose visited domains to anyone on-path); aligns with the no-leak principle |
| **No leaks** | Broader principle: no unintended outbound flows from the host | Aligns with the leak-detector hook (PostToolUse on Read/Bash/WebFetch/Grep scans tool output for credential patterns); network-stack-level extension of the same principle |
| **No SSH server** | SSH **server** explicitly NOT installed (operator's verbatim decision); SSH client may exist for outbound use | Operator: *"this is not for not reason I said no to ssh server setup"*. SSH server = remote attack surface + auth log + key management surface; conflicts with the no-leak principle. Out-of-band management via wifi client interface or console-only is sufficient |

These constraints inform M003 (Foundation hardening) install.sh authoring: install.sh should configure the wifi client interface with static IP, set DNS over TLS as the system resolver (e.g., systemd-resolved with DoT, or stubby), and explicitly NOT install or enable openssh-server.

## Fail-Closed Invariants

| Invariant | What it means | Enforcement |
|---|---|---|
| **Tamper detection precedes every tool call** | An integrity sentinel runs before every tool call decision. If safety controls are tampered, the call refuses. | Pre-tool-call hook in the AI tool's policy mechanism. |
| **Policy source must be present and not disabled** | If the safety-policy file is missing, or hooks are disabled (`disableAllHooks=true`-equivalent), the integrity check fails. | Tamper detection. |
| **Deny-set must meet a known-safe threshold** | If the deny-set has been eroded below an operator-set threshold (e.g. `< N` patterns), the integrity check fails. The threshold is operator-decided based on how comprehensive the original deny-set was. | Tamper detection. |
| **Required enforcement scripts must be present + executable** | If any required hook script is missing, non-executable, or suspiciously small (size deviation from baseline), the integrity check fails. | Tamper detection. |
| **Stage gates are hard during methodology-driven work** | When operator or agent works on the project under the stage-gate methodology, ALLOWED/FORBIDDEN per stage is enforced — implementation cannot ship in a Document-stage task, code cannot ship in a Design-stage task. | Methodology engine + agent's adherence + (when authored) project-internal verifier (M004). |
| **Tracked git files must match the deny-all + whitelist invariant** | The repo's `.gitignore` is deny-all + whitelist. Only project files are visible to git. Credentials, sessions, transcripts, logs, ssh, env stay local. Verifier checks `git ls-files` against the expected whitelist. | Foundation gate (M003) + Infrastructure tooling (M004). |

## Escalation Paths

| Event | Detection | Response |
|---|---|---|
| Tool call denied by deny-set | Endpoint policy logs the denial with reason | Logged for operator review; agent receives clear failure indicating the policy decision. No silent allow-throughs. |
| Tool call asks-for-confirmation on legitimate-but-risky operation | Behavior pattern matched (apt/pip/sudo/crontab/authorized_keys/etc.) | Operator confirms or denies in real-time. Pattern + decision logged for retrospective. |
| Leak detected in tool output | Output-scanning hook matched a credential-shaped value pattern | Leak logged with provider tag and redacted excerpt; operator alerted via system message; the leak-shaped value optionally redacted before being surfaced to the agent context. |
| Tamper detected | Integrity sentinel returned non-OK | Every subsequent tool call refuses. Operator must restore policy and re-verify integrity before tool calls resume. The sentinel's failure mode is fail-CLOSED. |
| Suricata IPS alert at high severity | Suricata rule with priority=1 (or operator-curated equivalent) matched a flow | When the Suricata module is installed: eve.json event emitted + (optional) downstream sink (Filebeat → Loki / Logstash → Slack / etc. — see Hanke-pattern integration). The default is alert-only; operator decides what becomes a drop. |
| PolarProxy free-tier cap reached | Rate of TLS sessions seen vs decrypted diverges after the daily cap | When the PolarProxy module is installed: monitor the divergence; alert operator; decision: provision a paid license tier or accept inspection degradation. |
| Bridge link flap or unrecoverable foundation error | systemd unit reports failure / kernel logs report bridge issue | Configurable per operator's threat model: fail-OPEN (network keeps working, inspection silently disabled) or fail-CLOSED (network stops; operator notified). The default is operator-decision at Foundation tier. |

## Audit Logging

| Channel | What's logged | Retention |
|---|---|---|
| **Tool-call decisions** | Per-call timestamp + tool + input pattern + decision (allow/deny/ask) + reason | Operator-decided rotation policy at Infrastructure tier (M004) |
| **Leak detections** | Timestamp + provider tag + redacted excerpt + tool + agent session ID | Same rotation policy |
| **Suricata events** (when module installed) | eve.json structured events: alert, anomaly, http, dns, tls, flow, fileinfo, stats. Daily rotation. | logrotate config in M005 install |
| **PolarProxy decryption metadata** (when module installed) | TLS handshake metadata + flow timing + bypass-decision audit. PCAP files of the cleartext (fed to Suricata). | Operator-decided rotation policy |
| **Operator directives + session logs** | `$HOME/wiki/log/YYYY-MM-DD-<slug>.md` — operator's verbatim directives, AI session logs, completion notes | Permanent (git-tracked when whitelisted) |
| **Backlog + work-state evolution** | `$HOME/wiki/backlog/` epic + module + task pages with frontmatter state-machine fields (status, current_stage, readiness, progress, stages_completed) | Permanent (git-tracked) |
| **Memory-layer auto-journals** | NOT used by this project. The `~/.claude/projects/-root/memory/` directory at $HOME from prior session is debris and not part of the project's authoritative state. | (n/a) |

## Hardening Posture by SFIF Stage

The project's security posture intensifies as it climbs SFIF stages:

| SFIF Stage | Security characteristic |
|---|---|
| **Scaffold** | Identity declared; methodology adopted; backlog scaffolded; agent-context files authored. No live security enforcement yet — this is the planning layer. |
| **Foundation** | Endpoint AI agent safety operational. Idempotent install. Integrity check operational. Deny-set in place. Bridge topology configured (passive forwarding). Policy source-of-truth present. Tamper-detection operational. Audit logging enabled. **This is when the project becomes a security envelope.** |
| **Infrastructure** | Project-internal verifier tooling enforces invariants programmatically (deny-set threshold, hook permissions, executable presence, integrity check). Validation pipeline (pre-commit OR CI) runs the verifier on every change. Operator-authorable threshold values in config. |
| **Features** | First inspection module deployed (Suricata or PolarProxy). Network-layer defense becomes operational alongside endpoint-layer. Failopen behavior of the chosen module is the operator's decision per threat model. |

## Operational Hygiene

| Practice | Why |
|---|---|
| Run `./install.sh --dry-run` before any install on a host | Preview what will change. The install backs up existing files but a dry-run is the safety net before any backup ever happens. |
| Verify integrity check passes before AND after any change to the safety policy | The integrity check is what stops a half-installed or tampered state from going live. |
| Audit `git status` and `git ls-files` before publishing | Ensure no unintended file is in the tracked set. The deny-all + whitelist `.gitignore` should leave only project files visible. |
| Run hook + tools regression tests after editing any hook or tool | **Canonical: `python3 -m tools.run-tests`** — unified runner across **13 test files** (8 hook tests at `.claude/hooks/tests/test-*.py` + 5 tools tests at `tools/tests/test-*.py`). Per Hard Rule 14 (productive-cycle taxonomy — verified-edit action type) requires real regression-suite output, not synthetic test (per SB-091 anti-pattern). Aggregate as of 2026-05-06 evening: **215/234 passing** (3 partial-fail surfaced for operator-decision: test-mode-enforcement.py 0/0 collection regression — pytest discovery issue NOT logic regression; test-end-of-cycle-stamp-diff-suppression.py 21/22 — SB-138 territory; test-questions.py 33/51 — SB-134 DRAFT scaffolds). All 7 hook regex regression suites individually green (policy-block 10/10 · malware-block 8/8 · opt-write-block 5/5 · output-discipline-guard 19/19 · context-warning 8/8 · mindfulness 22/22). |
| Rotate AI provider keys regularly | Key compromise is out of scope at the network layer; rotation is operator's responsibility. |
| Review leak-detector logs weekly | Patterns of leak attempts are themselves a signal. |
| Re-verify deny-set count after any settings.json edit | The threshold is what tamper-detection enforces. Editing without re-verifying risks fail-closing every subsequent tool call. |
| Keep `~/.claude/settings.json` in version control (tracked side) | Auditability of the policy source's evolution. |
| Review the operator-pending decisions table in CONTEXT.md regularly | The `auto_connect` flip (M010), failopen mechanism choice for Suricata, license tier for PolarProxy, etc. accumulate. |
| Before initial publish: run `bash /tmp/publish-root-ghostproxy.sh` (dry-run) + Python audit script | Verify which files would actually stage; defense-in-depth against credential paths slipping in via deep-dir whitelist gaps (e.g. SB-085 caught `/scripts/lib/` exclusion that would have shipped broken merge-from-backup.sh). |

## Reporting a Vulnerability

Vulnerability reporting channel is **to be determined** at Foundation tier — likely an email channel (`security@<operator-domain>`) or a GitHub Security Advisory channel once the project is published with a remote. Until then, the operator's direct channel is the reporting path.

**Coordinated disclosure.** When the project is published with a remote, plan to follow standard coordinated-disclosure practice: private report → fix authored → patched release → public advisory after a reasonable embargo (typically 90 days from report).

**Severity tiers.** Adopted from the upstream Suricata SECURITY.md pattern (`wiki/sources/src-suricata.md`):
- **CRITICAL** — disrupts availability or enables traffic-based RCE/crash/evasion. Fix in private; release across all supported branches; immediate.
- **HIGH** — lower-risk than critical, perhaps disabled-by-default features or less likely exploitation. Fix in private up to ~1 month.
- **MODERATE** — Tier-2 / Community features not enabled by default. Roll up into the next release.
- **LOW** — CLI utilities, unlikely configurations. Fix in development versions; backport at discretion.

The same severity classification applies whether the vulnerability is in the foundation IaC, the Suricata module integration, or the PolarProxy module integration.

## Known Limitations

These limitations are inherited (from upstream tooling) or by-design (from the project's posture). They are not bugs; they are documented constraints.

### Inherited from PolarProxy upstream

1. **Free tier fails OPEN past the daily cap** — 10 GB / 10 000 sessions / 10 000 rule-matches per day. Past the cap, decryption stops; forwarding continues. Mitigation: monitor decryption-rate divergence + alert; provision paid tier when sustained above cap.
2. **No support for opportunistic STARTTLS / explicit TLS** — SMTP STARTTLS, FTPS AUTH TLS, etc. are not decryptable. Those flows pass through encrypted regardless of the inspection posture.
3. **No ESNI / ECH support** — Sessions using Encrypted SNI / Encrypted Client Hello are not decryptable. Adoption rate of ESNI/ECH on the LAN's outbound destinations affects how much traffic remains opaque.
4. **CA distribution required for every endpoint** — Endpoints without the proxy's CA in their trust store see cert errors. Pinned apps (banking, mobile pinning) reject the proxy's CA regardless. Cert-pinning bypass for some Android apps is possible via Frida-based scripts but out of project scope.
5. **Not FIPS-compliant** — PolarProxy uses non-FIPS-compliant cryptography. On FIPS-enabled hosts it refuses to start.

### Inherited from Suricata upstream

1. **In IPS mode a Suricata crash takes the inspected segment offline UNLESS bypass is configured** — The bridge layer MUST have a failopen mechanism (NFQUEUE `bypass` option, kernel-level bridge passthrough, or systemd-watchdog). Operator decides at M005 module-design.
2. **Custom rule SIDs must avoid reserved upstream ranges** — Suricata reserves SIDs 2200000–2299999 per protocol/component. Local rules must use 1000000–1999999 (per ET/Snort convention) to avoid update collisions.
3. **Hardware offloads (GRO/LRO/TSO) interfere with inline inspection** — Must be disabled on the bridge interfaces to prevent dropped packets from oversized datagrams.

### By-design (project posture)

1. **The bridge as inline data path means a hardware/software failure of the host stops traffic** unless the bridge layer has explicit failopen. Operator's threat model decides: high-trust environment → fail-closed (acceptable downtime); inspection-not-firewall environment → fail-open (network keeps working when inspection is offline).
2. **The wifi as outbound-only management means in-band recovery is limited.** If the wifi misconfigures or the host is unreachable from operator's network, recovery requires local console access. SSH is not bound to the wifi interface; that is by design.
3. **CA distribution is a separate operational track.** PolarProxy's CA must be deployed to LAN endpoints by some mechanism (manual install, AD GPO, MDM, Linux package). root-modules provides the proxy + CA; deployment is operator's lift.
4. **Two-layer hook architecture means root-modules's machine-level policy fires across all sister-project Claude Code sessions on the host.** A LAN endpoint with root-modules installed has its endpoint AI safety policy enforced uniformly across every AI-agent session, regardless of which project that session is operating in. Operator working in another sister project on the same host inherits root-modules's policy. This is by-design (it's the point of the machine-level layer); the side-effect is that other-project work is constrained by root-modules's deny-set.
5. **Multi-host portability is intent, not yet realized.** Operator's framing is that root-modules will be deployable to a new host when needed (`"this machine or another [new] one"`). The current state is single-host. Cross-host deployment may surface host-specific config items (interface device names, CA trust paths, package manager differences) that are currently abstracted but not validated across hosts.
6. **3 partial-fail tests surfaced for operator-decision** (per Hooks pass 2026-05-06 evening): test-mode-enforcement.py 0/0 collection regression (pytest discovery issue — likely import-path / fixture / pytest config change since 38/38 passing per D033; NOT mode-enforcement.sh logic regression); test-end-of-cycle-stamp-diff-suppression.py 21/22 (1 fail — SB-138 stamp diff-suppression D038 territory); test-questions.py 33/51 (18 fail — SB-134 DRAFT scaffolds + many test paths likely incomplete). Per Hooks-pass option A discipline: surfaced for operator-decision, NOT unilateral fix. Open question for operator: investigate test-discovery regression as priority (it's the most concerning — was 38/38 before).
7. **Archive hook scripts retained on disk per operator directive 2026-05-06**: 4 archived hooks (`deny-secret-files.sh`, `premise-guard.sh`, `stamp-control.sh`, `integrity.py-not-yet-wired-as-CLI`) retained per operator verbatim *"label them as archive if they are not usefull anymore. dont necessarily delete them"*. Cached session config invoking premise-guard.sh stub is harmless (drain stdin + exit 0 = official no-op); deny-secret-files.sh is subsumed by policy-block.sh (broader matcher); stamp-control.sh is superseded by SB-115 redesign (slash-command + persistent JSON config). 17 .sh + 1 .py on disk; 10 wired matchers across 8 events. Per-hook canonical inventory at [.claude/hooks/README.md](.claude/hooks/README.md).
8. **Agent-DRAFT artifacts flagged at every reference per SB-095** (Hard Rule 4 + hallucinated-artifacts anti-pattern). 9 sub-READMEs authored 2026-05-06 evening per brain-improvement mandate are DRAFT v1 — `status: draft` + `confidence: medium` + `maturity: seed` in frontmatter. Operator promotes after fresh-pickup-agent navigability review. Rule extension: any agent-authored file MUST flag DRAFT in frontmatter or body header at every reference; never treat as operator-known unless explicitly acknowledged.

## Hard Rules 11-15 — security-relevant operationalization at hot-path layer

The 5 universal Hard Rules added 2026-05-06 to CLAUDE.md + AGENTS.md operationalize security discipline at every-prompt-context-budget layer. Each is security-relevant:

| Hard Rule | Security implication |
|---|---|
| **Rule 11 — Adding ≠ discarding** | **Defense-in-depth preservation**. SECURITY.md and the safety-policy artifacts (`.claude/settings.json`, hook scripts, deny-set, integrity sentinel) must NEVER be wholesale-replaced. Going-to-extremes pendulum (SB-082/093 family) on a security-policy doc could silently lose layer protections. The discipline is additive — refresh inline values where empirically drifted; do NOT replace defense-in-depth layers. Operator directive 2026-05-06: *"Why are you not able to just do normal improvements instead of causing regression"*. |
| **Rule 12 — Brain-inheritance pattern** | **$HOME source-of-truth for safety policy; /opt second-brain cannot weaken**. Per SB-115 + Two-layer hook architecture: machine-level (root-modules at $HOME) fires BEFORE project-level. /opt is INHERITS / adapts operational tooling FROM $HOME, not the reverse. Safety-policy ownership is unambiguous. Sister project sessions on the same host inherit root-modules's safety-floor uniformly per Two-layer architecture. |
| **Rule 13 — Chain operations per fire** | **Security pattern: SB closure pulls along all defense layers**. When a security regression is caught (e.g., SB-083 cmd-sub regex false-positive, SB-084 script-capture false-positive, SB-106 log-tamper false-positive, SB-132 hook-ln false-positive), the closure chain is: tracker row update + structural fix (regex anchored) + regression-test addition + cross-references in related docs + decisions-logbook entry. Per-cycle multi-edit chain ensures the protection layer is restored holistically, not piecemeal. SB-128 thin-output anti-pattern (single-edit-per-fire) is structurally inappropriate for security work. |
| **Rule 14 — Productive cycle taxonomy** | **`read-only-audit` action type IS the security-audit emission**. M-E001-1 vocabulary type 9 — every cycle-fire that runs `/audit` (10-step integrity check) emits this canonical type. Cross-tool universal — every AI tool's cycle skill emits the same audit-vocabulary regardless of which tool fires. Mandatory cycle-report last-line `Productive output: read-only-audit — <one-line specific>` ensures security audits are visibly named in the cycle report (no silent skipping). |
| **Rule 15 — Empirical-count-verification before drift-claim** | **Deny-set threshold + hook count + test-pass count verified, not estimated**. Tamper detection's "deny-set above known-safe threshold" check is a count-based assertion — must be verified empirically (not estimated). Same applies to "all required enforcement scripts present" check. Programmatic walk + parse before any drift-claim. Compounding errors on security-relevant counts is the failure mode this rule prevents. |

These hot-path rules complement the design-time principles in DESIGN.md (4 cross-cutting Design Principles) — design at slow-thoughtful tier; runtime enforcement at fast-reflex tier.

## Agent personal-learning notes (operator-allowed, per directive 2026-05-06)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. Entries are **agent-authored** (per SB-095 — agent-DRAFT, not operator-stated). Operator may revise / promote / remove. Each timestamped + initialed `[agent]`. SECURITY.md-specific framing — security-policy-doc lessons.

### 2026-05-06 evening — SECURITY.md is load-bearing, not auxiliary

`[agent]` SECURITY.md is the project's security policy artifact — load-bearing for type=root + group=operating-system-setup projects. Any edit must preserve defense-in-depth layers. The going-to-extremes pendulum (SB-082/093) is particularly dangerous on this doc — wholesale-replace of a layer's protection description could silently lose context that future agents rely on. Discipline: ADD new threats / invariants / layers in dedicated sub-sections; never restructure the Threat Model + Layer-by-Layer + Fail-Closed Invariants tables.

### 2026-05-06 evening — Empirical-count-verification applies to security-relevant counts

`[agent]` Per Hard Rule 15: deny-set threshold + hook count + test-pass count must be verified empirically. SECURITY.md previously claimed "test-policy-block.py + test-malware-block.py PASS 4/4 before claiming a hook fix done" — this was accurate at authoring time but drifted by 2026-05-06 evening (13 test files / 215/234 aggregate, with 3 partial-fail surfaced). Discipline: when SECURITY.md cites counts, run `python3 -m tools.run-tests` first; inline empirically-verified-YYYY-MM-DD timestamp. Counts in SECURITY.md are security-relevant signals — drift here means stale verification claims.

### 2026-05-06 evening — Threat model categories rarely change; protections evolve

`[agent]` Threat Model (Adversaries + Assets to Protect + Out of Scope) is naturally stable — these are project-level taxonomy decisions. What changes more often is the protections at each Layer (e.g., agent-discipline-gate runtime layer added 2026-05-06 per SB-108/090/094/120 closures; mindfulness baseline added per SB-126). Discipline: ADD new protections to Layer 1/2/3 sub-sections; don't add new Threat Model categories unless operator explicitly directs.

### 2026-05-06 evening — Hard Rules 11-15 are runtime operationalization of design-time principles

`[agent]` DESIGN.md captures the 4 cross-cutting Design Principles (deny-by-default · fail-closed/open · markdown-as-IaC · no-policy-duplication) at design-time tier. CLAUDE.md / AGENTS.md Hard Rules 11-15 codify operationalizations at runtime tier. The new "Hard Rules 11-15 — security-relevant operationalization" section in this SECURITY.md bridges the two layers — design-time + runtime are complementary; both needed for defense-in-depth. Discipline: when authoring new Hard Rules at hot-path layer, cross-reference the design-time principle they operationalize.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). Not DESIGN.md (design-time principles). Not ARCHITECTURE.md (technical depth). For SECURITY.md-specific security-policy-doc lessons that benefit fresh-pickup agents but are too small to warrant their own structured artifact. Operator promotes when pattern matures.

## Cross-References

### Top-level brain files (10)

| For… | Read |
|---|---|
| Project front door | [README.md](README.md) |
| Cold-pickup orientation | [BOOTSTRAP.md](BOOTSTRAP.md) |
| Architecture topology + component responsibilities | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Design pattern rationale (why deny-by-default, why fail-closed, why two layers — design-time tier) | [DESIGN.md](DESIGN.md) |
| Tool reference (install + verifier + tools.run-tests) | [TOOLS.md](TOOLS.md) |
| Universal cross-tool agent rules + 15 universal Hard Rules (incl. 11-15 security operationalization) | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing + 15 Hard Rules | [CLAUDE.md](CLAUDE.md) |
| Current operational state (Active Objective Layer + SFIF + pending decisions) | [CONTEXT.md](CONTEXT.md) |
| Skills directory context (incl. hook-vs-command-vs-skill decision for safety enforcement) | [SKILLS.md](SKILLS.md) |

### Subdirectory READMEs (9 — DRAFT v1, agent-authored 2026-05-06 evening)

| For… | Read |
|---|---|
| **Per-hook canonical inventory + WIRED-vs-ARCHIVE labels** (canonical extension of Layer 1 endpoint AI agent safety section) | [.claude/hooks/README.md](.claude/hooks/README.md) |
| 30 slash commands by category (incl. /audit security-audit slash command) | [.claude/commands/README.md](.claude/commands/README.md) |
| 15 Python tools (incl. tools.run-tests unified regression runner per Hard Rule 14) | [tools/README.md](tools/README.md) |
| 11 rules + strictness-tier matrix (security-relevant: hook-architecture · operating-principles · words-are-sacrosanct) | [.claude/rules/README.md](.claude/rules/README.md) |
| 3 modes + cycle-sequence comparison | [.claude/modes/README.md](.claude/modes/README.md) |
| 3 brain-loaded sub-agents | [.claude/agents/README.md](.claude/agents/README.md) |
| 2 skills + mechanism-choice context | [.claude/skills/README.md](.claude/skills/README.md) |
| 5 install template categories (incl. nftables outbound-only ruleset + wpa_supplicant config) | [templates/README.md](templates/README.md) |
| Deployment + maintenance toolkit (incl. merge-from-backup.sh governance with security-scan.sh) | [scripts/README.md](scripts/README.md) |

### Universal cross-cutting rules (security-relevant)

| For… | Read |
|---|---|
| **Hook architecture rule** (2-layer + 3-component design pattern + bypass mechanism per hook) | [.claude/rules/hook-architecture.md](.claude/rules/hook-architecture.md) |
| **Operating principles** (deny-by-default + fail-closed/open + 4 core + 11 extension principles + Hard Rules 11-15 mapping) | [.claude/rules/operating-principles.md](.claude/rules/operating-principles.md) |
| **Operator-words sacrosanct** + premise-confirmation gate + conditional-clause grammar (agent-behavioral safety discipline) | [.claude/rules/words-are-sacrosanct.md](.claude/rules/words-are-sacrosanct.md) |
| Self-reference (what $HOME IS + bidirectional inheritance with /opt for safety-policy ownership) | [.claude/rules/self-reference.md](.claude/rules/self-reference.md) |
| Trigger-model unified 8-mechanism signal→action→recovery (security-relevant: every mechanism emits actions per M-E001-1 vocabulary including read-only-audit type) | [.claude/rules/trigger-model.md](.claude/rules/trigger-model.md) |

### Brain-improvement mandate (this work block — 2026-05-06)

| For… | Read |
|---|---|
| Sacrosanct verbatim directive governing the brain-quality passes | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| **M-E001-1 productive-cycle action vocabulary DRAFT v2** (Hard Rule 14 — `read-only-audit` action type IS security-audit emission) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |

### Backlog + governance + log (security-relevant)

| For… | Read |
|---|---|
| Methodology engine | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| Active SFIF rollout epic | [wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md) |
| **138-row systemic-bugs tracker** — security-regression record (SB-083/084/106/132 hook-regex false-positives chain · SB-088 cross-fire prevention · SB-098 opt-write-block bypass mechanism · SB-105/107 stamp/widget security implications · SB-115 brain-inheritance ownership · SB-126 mindfulness baseline · SB-133 envelope schema fix) | [wiki/governance/systemic-bugs.md](wiki/governance/systemic-bugs.md) |
| **40-entry decisions logbook (D001-D040)** — security-decision provenance | [wiki/governance/decisions.md](wiki/governance/decisions.md) |

### Second brain (canonical sources)

| For… | Read |
|---|---|
| Suricata source-syntheses (Layer 0 README + Layer 1 install/quickstart, IPS modes for Linux, suricata.yaml master config) | `<second-brain>/wiki/sources/src-suricata*.md` |
| PolarProxy source-syntheses (Layer 0 product page + Layer 1 Hanke integration via dummy interface + tcpreplay) | `<second-brain>/wiki/sources/src-polarproxy.md`, `src-hanke-honeypot-polarproxy-suricata-integration.md` |
| Identity profile (canonical Goldilocks 9-dim) | `<second-brain>/wiki/ecosystem/project_profiles/root-modules/identity-profile.md` |
| Adoption Guide canonical | `<second-brain>/wiki/spine/references/adoption-guide.md` |

## Acknowledgments

This SECURITY.md is informed by:
- The upstream Suricata SECURITY.md (severity-tier framing, coordinated-disclosure pattern)
- The upstream PolarProxy product page (license-tier failure semantics, CA-distribution constraints)
- The Hanke honeypot writeup (the Suricata + PolarProxy integration pattern + audit-log routing)
- The second brain's Principle 1 (Infrastructure Over Instructions) — the deny-set + integrity check + tamper detection are structural enforcement, not prose-rule reliance
- The second brain's Principle 4 (Declarations Aspirational Until Verified) — every protection in this document needs a verification gate (verifier script, test, or operator-confirmed observation) before it is real, not aspirational
- Operator's verbatim project framing: *"secure an OS and configure claude code and opencode at the root with all the safety needed"* + *"its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network"*
