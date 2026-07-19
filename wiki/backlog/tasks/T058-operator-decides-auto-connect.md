---
title: "T058 — Operator decides auto_connect: false (status quo) vs true (auto-hookup)"
type: task
status: not-started
reclassified_2026-05-05: "from pending-operator-decision — auto_connect=false stays per operator-stated intentional friction (Hard Rule #4 design); revisit decision deferred to AFTER M009 stability proven; not blocking-now"
priority: P2
parent_module: "root-modules-m010-sister-projects-yaml-flip"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 25
sfif_stage: Stream-1-Operator-Decision
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m010-sister-projects-yaml-flip.md
tags: [task, p2, t058, stream-1, m010, operator-decision-pending]
---

# T058 — Operator decides auto_connect

## Description

After cooling-off period (T057), operator decides whether to flip `auto_connect` for root-modules in `/opt/devops-solutions-information-hub/wiki/config/sister-projects.yaml` from `false` to `true`.

## Trade-off

| Keep `false` (status quo) | Flip to `true` |
|---|---|
| Friction-by-design: type=root projects gate security envelope; explicit-authorization gate via --connect-project preserved | Convenience: subsequent `tools.setup` runs auto-hookup root-modules when path resolves |
| Multi-host scenario: each host requires explicit operator command | Multi-host scenario: operator runs setup once per host; auto-connect handles each |
| Aligns with security-tier signal for type=root projects | Aligns with operational convenience for stable, well-tested integrations |

## Done When

- [ ] Operator decides; verbatim rationale captured.
- [ ] Decision documented in M010 module page + $HOME/wiki/log/.

## Dependencies

- T057 (cooling-off period)

## Relationships

- PART OF: [[root-modules-m010-sister-projects-yaml-flip|M010]]
- BLOCKED BY: T057
- BLOCKS: T059 (apply) or T060 (document why-no)
