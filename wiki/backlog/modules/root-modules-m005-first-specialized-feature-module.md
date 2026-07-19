---
title: "root-modules M005 — First Specialized Feature Module (Suricata or PolarProxy)"
aliases:
  - "M005 — Suricata-or-PolarProxy first"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Features
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
  - id: src-suricata
    type: wiki
    file: wiki/sources/src-suricata.md
    description: "Suricata Layer 0 — IDS/IPS/NSM engine README, QA process, SID conventions"
  - id: src-suricata-install-quickstart
    type: wiki
    file: wiki/sources/src-suricata-install-quickstart.md
    description: "Suricata Layer 1 — install paths (PPA / Debian / source build), quickstart suricata.yaml + canary alert SID 2100498"
  - id: src-suricata-ips-mode-linux
    type: wiki
    file: wiki/sources/src-suricata-ips-mode-linux.md
    description: "Suricata Layer 1 — 5 IPS modes (NFQUEUE iptables/nftables, AF_PACKET, DPDK, Netmap), failopen via nftables `bypass`, br0-vs-AF_PACKET-IPS architectural decision"
  - id: src-suricata-yaml-config
    type: wiki
    file: wiki/sources/src-suricata-yaml-config.md
    description: "Suricata Layer 1 — suricata.yaml master config navigation (22 sub-sections + 8 sub-chapters), action-order semantics, EVE JSON, threading, hardening"
  - id: src-polarproxy
    type: wiki
    file: wiki/sources/src-polarproxy.md
    description: "PolarProxy Layer 0 — TLS inspection proxy, 8 modes, license tiers, routing patterns"
  - id: src-hanke-honeypot-polarproxy-suricata-integration
    type: wiki
    file: wiki/sources/src-hanke-honeypot-polarproxy-suricata-integration.md
    description: "Layer 1 — canonical Suricata + PolarProxy integration via dummy interface + tcpreplay; 4-service systemd dependency chain"
tags: [module, p0, root-modules, sfif-features, suricata, polarproxy, operator-decision-pending, m005]
---

# M005 — First Specialized Feature Module (Suricata or PolarProxy)

## Summary

Build the first SFIF-Features-tier module of root-modules: either the Suricata IDS/IPS module OR the PolarProxy TLS inspection module. Both are operator-named as the "two vendors & modules" the project will integrate. M005 covers ONE of them end-to-end (design → integration into install.sh → tests); the second module is its own subsequent epic. Operator picks which first based on architectural sequencing and risk preference. Both source-synthesis pages already exist in the second brain (`wiki/sources/src-suricata.md` and `src-polarproxy.md`), capturing modes, deployment patterns, license, FAQ, and operational scaffold notes — these are the Layer-1-ish starting points for design.

## Done When

- [ ] Operator chooses suricata or polarproxy as the first module
- [ ] Design doc lands at `$HOME/docs/<chosen-module>-module-design.md` covering: deployment mode, capture method (Suricata) or routing pattern (PolarProxy), failopen behaviour, output destination, integration with the second module (architectural pairing PolarProxy → PCAP → Suricata)
- [ ] Integration into `$HOME/install.sh`: package install + systemd service unit + bridge-layer nftables rules where applicable + log directory + permission setup
- [ ] Smoke tests: service starts cleanly; expected output (alerts for Suricata, PCAP for PolarProxy) is produced under controlled traffic
- [ ] No regression of Foundation gate (M003) or Infrastructure gate (M004) after the feature module lands
- [ ] Operator validates end-to-end behaviour against a sample threat (Suricata) or sample TLS session (PolarProxy)

## Dependencies

- M001, M002, M003, M004 — full SFIF stack must be at Infrastructure tier before Features module work begins (per SFIF discipline)
- **Source corpus (6 syntheses, all in second brain as of 2026-05-04):**
  - `wiki/sources/src-suricata.md` — Layer 0 (README + repo metadata)
  - `wiki/sources/src-suricata-install-quickstart.md` — Layer 1 install paths + canary test
  - `wiki/sources/src-suricata-ips-mode-linux.md` — Layer 1 the 5 IPS modes + br0 architectural decision
  - `wiki/sources/src-suricata-yaml-config.md` — Layer 1 suricata.yaml navigation + key sections
  - `wiki/sources/src-polarproxy.md` — Layer 0 (PolarProxy product page)
  - `wiki/sources/src-hanke-honeypot-polarproxy-suricata-integration.md` — Layer 1 dummy-interface + tcpreplay integration pattern
- Follow-up ingestions deferred (not blockers for M005 design but useful for deeper config): Suricata EVE JSON output schema (chapter 12.1.9.5 + chapter 15), Suricata Performance chapter (11) for tuning, Suricata eBPF/XDP chapter for high-throughput AF_PACKET multi-thread. PolarProxy Docker / Podman deployment blog posts for containerized path. Snort.conf migration if existing Snort rules are in scope.
- Hardware: existing $HOME host (Debian 13, 2× ethernet bridged via br0, 1× wifi as outbound-only). Bridge topology decisions (br0 with enp2s0 + enp4s0) already in place — see src-suricata-ips-mode-linux for the br0-vs-AF_PACKET-IPS architectural decision M005 must explicitly resolve.

## Open Questions

> [!question] Which module first — Suricata or PolarProxy?
> | Aspect | Suricata first | PolarProxy first |
> |---|---|---|
> | Maturity | More mature OSS (OISF), Debian package available | Vendor binary, dynamic per-instance CA, simpler deploy |
> | Test surface | Passive IDS mode is non-disruptive; IPS mode requires bridge failopen design | Inline TLS termination; cert distribution is the operational hard part |
> | Useful without the other | Yes (TLS metadata only — SNI, JA3) | Limited (PCAPs go nowhere without an IDS reading them) |
> | Recommendation | Default first per "passive before active" principle | Pick if cert-distribution path is the higher-uncertainty risk to de-risk first |
>
> Operator decides.

> [!question] How do the two modules integrate when the second arrives?
> Per the source syntheses: PolarProxy → PCAP/PCAP-over-IP → Suricata is the canonical pairing. Whichever module ships first must leave the integration interface explicit (Suricata first: leave a "TLS-decryption input" capture source slot; PolarProxy first: leave a `--pcapoverip` listener slot ready for downstream consumers).

> [!question] Do we need a working test pcap before the design doc lands?
> Probably yes — design without a known-good test pcap is unverifiable. Capturing a sample threat (Suricata) or a benign HTTPS session (PolarProxy) is a M005 prerequisite task.

> [!question] Failopen mechanism for the bridge when Suricata is in IPS mode and crashes?
> Source synthesis flagged this as load-bearing: "in IPS mode a crash may knock a network offline." Options: kernel-level bridge passthrough on Suricata exit, systemd watchdog flips bridge to direct-forward, explicit nftables fallback rules. Architectural decision for M005 if Suricata-first.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M005-1 | Operator picks first module (Suricata or PolarProxy) and rationale | ⊙ pending |
| T-M005-2 | Run follow-up ingestions identified by source-synthesis open questions (docs.suricata.io key pages OR Netresec blog posts + Hanke writeup) | ⊙ pending |
| T-M005-3 | Capture sample test pcap (threat sample for Suricata, benign HTTPS for PolarProxy) | ⊙ pending |
| T-M005-4 | Author design doc at $HOME/docs/<module>-module-design.md | ⊙ pending |
| T-M005-5 | Integrate into install.sh + systemd unit + nftables rules where applicable | ⊙ pending |
| T-M005-6 | Smoke-test on the host; verify Foundation + Infrastructure gates still pass | ⊙ pending |
| T-M005-7 | Operator validates end-to-end | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BUILDS ON: [[src-suricata|Suricata Layer 0]]
- BUILDS ON: [[src-suricata-install-quickstart|Suricata install + quickstart]]
- BUILDS ON: [[src-suricata-ips-mode-linux|Suricata IPS Mode for Linux]]
- BUILDS ON: [[src-suricata-yaml-config|Suricata.yaml master config]]
- BUILDS ON: [[src-polarproxy|PolarProxy Layer 0]]
- BUILDS ON: [[src-hanke-honeypot-polarproxy-suricata-integration|Hanke integration pattern]]
- BLOCKED BY: [[root-modules-m004-infrastructure-tooling|M004 — Infrastructure tooling]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[Suricata Layer 0]]
[[Suricata install + quickstart]]
[[Suricata IPS Mode for Linux]]
[[Suricata.yaml master config]]
[[PolarProxy Layer 0]]
[[Hanke integration pattern]]
[[M004 — Infrastructure tooling]]
