---
title: "T028 — Integrate first feature module into install.sh + systemd unit + nftables rules"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m005-first-specialized-feature-module"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 0
sfif_stage: Features
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md
tags: [task, p0, t028, features, integration, install-sh, systemd, m005]
---

# T028 — Integrate first feature module into install.sh

## Description

Per the design doc (T027), implement the module integration. Either:
- Extend `$HOME/install.sh` with module install logic + flag (e.g. `./install.sh --with-suricata` / `--with-polarproxy`), OR
- Author a separate `install-module.sh <name>` script (per TOOLS.md planned interface).

Operator-decision (in T024 design): which integration shape.

## Done When

- [ ] Module install script (or extended install.sh) authored.
- [ ] Module package install: `apt install suricata` (Suricata-first) OR PolarProxy binary download + install (PolarProxy-first).
- [ ] Module config: `/etc/suricata/suricata.yaml` (Suricata-first) OR `/etc/polarproxy/...` (PolarProxy-first) authored per design doc.
- [ ] systemd unit(s) authored + installed. (Suricata-first: suricata.service. PolarProxy-first: dummy-iface@.service + polarproxy.service + polarproxy-tcpreplay.service.)
- [ ] nftables rules where applicable (Suricata-first NFQUEUE redirect; PolarProxy-first 443→10443 redirect).
- [ ] Integration with the OTHER module's slot: explicit (dummy interface as af-packet capture source for Suricata when PolarProxy is also installed).
- [ ] Module install is idempotent (re-run = no-op).
- [ ] Module install does not regress Foundation gate (T017 still passes after).
- [ ] Module uninstall is supported (`./install-module.sh suricata --uninstall`).

## Stage-gate (Implement)

Per methodology stage `implement`: implementation, integration-wiring, config allowed; FORBIDS new test files. Module install code authored + integrated.

## Dependencies

- T027 (design doc)
- T012 (install.sh) ✓ when complete (or extended here)
- T017 (Foundation gate green) ✓ when complete

## Relationships

- PART OF: [[root-modules-m005-first-specialized-feature-module|M005]]
- BLOCKED BY: T027, T012, T017
- BLOCKS: T029 (smoke test), T030 (operator validation)
