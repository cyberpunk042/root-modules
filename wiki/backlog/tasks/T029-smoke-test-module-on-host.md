---
title: "T029 — Smoke-test first feature module on host (canary alert / decryption verification)"
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
tags: [task, p0, t029, features, smoke-test, m005]
---

# T029 — Smoke-test module on host

## Description

After module is installed (T028), verify it works end-to-end against the test pcap from T026.

## Done When (Suricata-first path)

- [ ] `systemctl status suricata` reports active.
- [ ] `sudo suricata --build-info` shows the chosen capture method (NFQ / af-packet / DPDK / netmap).
- [ ] Canary alert: `sudo tail -f /var/log/suricata/fast.log &` → `curl http://testmynids.org/uid/index.html` → expected `[1:2100498:7] GPL ATTACK_RESPONSE id check returned root` alert fires.
- [ ] eve.json shows `event_type=alert` for the canary.
- [ ] Failopen test (NFQUEUE+bypass path): stop Suricata → traffic continues uninspected; restart → inspection resumes.
- [ ] Foundation gate (T017) still passes after Suricata install (no regression).

## Done When (PolarProxy-first path)

- [ ] `systemctl status polarproxy` + `polarproxy-tcpreplay` + `dummy-iface@polarproxytls` all report active.
- [ ] `ip link show polarproxytls` shows the dummy interface UP.
- [ ] `opencode debug config` shows polarproxy plugin (or equivalent verification) — n/a if module is independent.
- [ ] CA distribution: install proxy's CA on a test endpoint; verify cert chain accepted on a test HTTPS session.
- [ ] Decryption verification: capture a benign HTTPS session from CA-trusting endpoint; confirm cleartext appears in the PCAP-over-IP stream / output PCAP.
- [ ] Free-tier cap awareness: traffic generation under cap → all decrypted; over cap → divergence between sessions-seen and sessions-decrypted.
- [ ] Foundation gate (T017) still passes after PolarProxy install (no regression).

## Stage-gate (Test)

Per methodology: test stage allows test-implementation + test-results. Smoke test against the canary pcap is the gate-passing artefact.

## Dependencies

- T028 (module installed)
- T026 (test pcap) — the smoke test consumes the pcap

## Relationships

- PART OF: [[root-modules-m005-first-specialized-feature-module|M005]]
- BLOCKED BY: T028
- BLOCKS: T030 (operator end-to-end validation)
