---
title: "T024 — Operator picks first feature module (Suricata-first vs PolarProxy-first)"
type: task
status: not-started
reclassified_2026-05-05: "from pending-operator-decision — BLOCKED BY T017+T023 (M003+M004 prerequisites); operator decides AFTER those, not now"
priority: P0
parent_module: "root-modules-m005-first-specialized-feature-module"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 25
sfif_stage: Features
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md
  - id: src-suricata-ips-mode
    type: file
    file: /opt/devops-solutions-information-hub/wiki/sources/src-suricata-ips-mode-linux.md
    description: "Suricata IPS modes + failopen architectural decision (NFQUEUE+bypass vs AF_PACKET copy-mode)"
  - id: src-polarproxy
    type: file
    file: /opt/devops-solutions-information-hub/wiki/sources/src-polarproxy.md
    description: "PolarProxy product page synthesis — modes, license tiers, CA distribution"
tags: [task, p0, t024, features, module-choice, operator-decision-pending, m005]
---

# T024 — Operator picks first feature module

## Description

Both Suricata + PolarProxy are facultative modules per operator's verbatim. Operator picks which to integrate first.

## Trade-off

| Aspect | Suricata first | PolarProxy first |
|---|---|---|
| Maturity | More mature OSS (OISF), Debian package available | Vendor binary, dynamic per-instance CA |
| Test surface | Passive IDS mode is non-disruptive; IPS mode requires bridge failopen design | Inline TLS termination; cert-distribution is the operational hard part |
| Useful without the other | Yes (TLS metadata only — SNI, JA3) | Limited (PCAPs go nowhere without an IDS reading them) |
| First-principle | Passive-before-active default | De-risk cert-distribution if operator's threat model puts that uncertainty first |

## Done When

- [ ] Operator picks Suricata-first OR PolarProxy-first.
- [ ] Rationale documented in $HOME/wiki/log/<date>-m005-first-module-decision.md.
- [ ] Subsequent M005 tasks are scoped to the chosen module.

## Dependencies

- M003 + M004 complete (Foundation + Infrastructure both green) ✓ when complete
- Source-syntheses available in second brain ✓
- Operator decision

## Relationships

- PART OF: [[root-modules-m005-first-specialized-feature-module|M005]]
- BLOCKED BY: T017 (M003 Foundation gate), T023 (M004 no-regression check)
- BLOCKS: T025 through T030 (subsequent module work scoped per choice)
