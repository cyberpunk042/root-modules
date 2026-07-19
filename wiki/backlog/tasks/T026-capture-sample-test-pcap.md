---
title: "T026 — Capture sample test pcap (canary threat for Suricata, benign HTTPS for PolarProxy)"
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
tags: [task, p0, t026, features, test-pcap, design-input, m005]
---

# T026 — Capture sample test pcap

## Description

Module design needs a known-good test artefact. For Suricata-first: a pcap containing the canary threat (SID 2100498 trigger via `curl http://testmynids.org/uid/index.html`). For PolarProxy-first: a pcap of a benign HTTPS session crossing the bridge to confirm decryption works end-to-end.

## Done When

- [ ] Suricata-first path: capture a pcap of `curl http://testmynids.org/uid/index.html` traffic. Stored at `$HOME/wiki/log/test-pcaps/canary-suricata.pcap`.
- [ ] PolarProxy-first path: capture a pcap of a benign HTTPS session from a CA-trusting test endpoint. Stored at `$HOME/wiki/log/test-pcaps/benign-polarproxy.pcap`.
- [ ] PCAP metadata documented in $HOME/wiki/log/<date>-test-pcap-capture.md (timestamp, source IPs, expected behavior under each module).
- [ ] PCAPs ARE NOT committed to git (per `.gitignore` deny-all + whitelist; PCAPs may contain real-IP data).

## Dependencies

- T024 (operator picks first module) — gates which pcap to capture
- T025 (source-syntheses) ✓ for design context

## Relationships

- PART OF: [[root-modules-m005-first-specialized-feature-module|M005]]
- BLOCKED BY: T024
- BLOCKS: T027 (design doc references the test pcap), T029 (smoke test uses it)
