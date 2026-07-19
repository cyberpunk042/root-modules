---
title: "T030 — Operator validates first feature module end-to-end"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m005-first-specialized-feature-module"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Features
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md
tags: [task, p0, t030, features, operator-validation, m005]
---

# T030 — Operator validates module end-to-end

## Description

Operator runs the module against a real-world sample matching their threat model (not just the canary) and confirms behavior is as expected. Per the working contract: the operator gates module-tier completion.

## Done When

- [ ] Operator runs Suricata-first: real-world threat sample from operator's chosen test set; alert fires; eve.json captured; rule was either ET Open or operator-curated.
- [ ] OR operator runs PolarProxy-first: real-world TLS session from operator's chosen endpoint; decryption verified; bypass list confirmed working for cert-pinned destinations; CA distribution to LAN endpoints completes.
- [ ] Operator reviews the module's eve.json / PCAP / log output and confirms the data is what they expected.
- [ ] Operator confirms the failopen behavior matches their threat model (Suricata: down = traffic continues per bypass; PolarProxy: free-tier cap = decryption stops, traffic continues).
- [ ] Operator approves M005 module complete OR identifies remediation tasks.

## Stage-gate (M005 Test stage exit)

Operator approval marks M005 complete. Module readiness reaches 100. The first feature module is operationally deployed.

## Dependencies

- T029 (smoke test passes the canary)

## Relationships

- PART OF: [[root-modules-m005-first-specialized-feature-module|M005]]
- BLOCKED BY: T029
- ENABLES: future second-feature-module epic (whichever wasn't picked first)
