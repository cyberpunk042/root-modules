---
title: "T027 — Author module design doc at $HOME/docs/<module>-module-design.md"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m005-first-specialized-feature-module"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 0
sfif_stage: Features
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md
tags: [task, p0, t027, features, design-doc, m005]
---

# T027 — Author module design doc

## Description

Author the design doc for the first feature module per operator's choice (T024). Per methodology stage `design` ALLOWED outputs: design-document, ADR, tech-spec, type sketches IN docs.

## Sections (per chosen module)

### If Suricata-first

| Section | Content |
|---|---|
| Deployment mode | NFQUEUE+iptables / NFQUEUE+nftables / AF_PACKET copy-mode / DPDK / Netmap (per `src-suricata-ips-mode-linux.md`) |
| Capture method | Aligns with deployment mode |
| Failopen behavior | NFQUEUE+bypass (fail-OPEN) vs AF_PACKET copy-mode (fail-CLOSED at L2) — operator's threat-model decision |
| Ruleset | ET Open (free) / ET Pro (paid) / Talos / custom AI-safety subset |
| Output sink | eve.json local + (optional) downstream Filebeat → SIEM |
| Integration interface for PolarProxy | Slot for dummy interface as af-packet capture source (when PolarProxy lands) |
| systemd unit | suricata.service (autostart, recovery) |
| Failure mode + recovery | Per `src-suricata-ips-mode-linux.md` |

### If PolarProxy-first

| Section | Content |
|---|---|
| Mode | Transparent Forward Proxy (default for root-modules bridge topology) |
| CA management | Per-instance dynamic CA OR operator-supplied .p12; CA distribution mechanism (manual install / AD GPO / MDM) |
| Bypass list | Banking, healthcare, cert-pinned domains (chrome-bypass list as starting point) |
| Output | `--pcapoverip 4430` for live consumption + rotated `-o` directory for forensics |
| Integration interface for Suricata | Dummy interface + tcpreplay bridge (Hanke pattern from `src-hanke-honeypot-polarproxy-suricata-integration.md`) |
| License tier | Free (10 GB / 10 K sessions / 10 K rule-matches per day) vs paid; alert on decryption-rate divergence past cap |
| systemd unit chain | dummy-iface@.service + polarproxy.service + polarproxy-tcpreplay.service |

## Done When

- [ ] Design doc at `$HOME/docs/<module>-module-design.md` covering all sections above.
- [ ] Trade-offs documented for each architectural decision.
- [ ] Integration interface for the OTHER module documented (the second module is its own subsequent epic; the first module's design must leave a clean integration slot).
- [ ] Test pcap from T026 referenced as the gate input.
- [ ] Operator-pending decisions explicitly listed.

## Stage-gate (Design)

Per methodology: design stage ALLOWS design-document, ADR, tech-spec, type sketches IN docs; FORBIDS code, tests. The design doc is itself the design-stage output.

## Dependencies

- T024 (module choice)
- T025 (source-syntheses) ✓
- T026 (test pcap)

## Relationships

- PART OF: [[root-modules-m005-first-specialized-feature-module|M005]]
- BLOCKED BY: T024, T026
- BLOCKS: T028 (install integration), T029 (smoke test), T030 (operator validation)
