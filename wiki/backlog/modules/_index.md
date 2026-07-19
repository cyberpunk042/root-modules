---
title: "root-modules modules"
type: index
status: active
created: 2026-05-04
updated: 2026-05-05
---

# Modules — SFIF Rollout Epic

## Stream 2 — Pure SFIF project base

| Order | Module | SFIF Stage | Status |
|---|---|---|---|
| 1 | [M001 — CLAUDE.md + AGENTS.md](root-modules-m001-author-claude-md-and-agents-md.md) | Scaffold | draft |
| 2 | [M002 — Methodology layer](root-modules-m002-methodology-layer-decision.md) | Scaffold-Design | draft |
| 3 | [M003 — Foundation hardening](root-modules-m003-foundation-hardening.md) | Foundation | draft |
| 4 | [M004 — Infrastructure tooling](root-modules-m004-infrastructure-tooling.md) | Infrastructure | draft |
| 4b | [M012 — Vendor mapping + fresh-machine install + auto-detect](root-modules-m012-vendor-mapping-install-and-auto-detect.md) | Infrastructure | draft |
| 5 | [M011 — ccstatusline custom widget](root-modules-m011-ccstatusline-statusline-widget.md) | Features | draft |
| 6 | [M005 — First specialized feature module](root-modules-m005-first-specialized-feature-module.md) | Features | draft |
| 6b | [M014 — luckyPipewrench/pipelock integration](root-modules-m014-luckypipewrench-pipelock-preliminary-scaffolding.md) | Features | draft (preliminary done; parallel to M005, facultative) |

> Order column reflects SFIF execution order. M011 inserted 2026-05-05 per operator directive — *"this is one of the modules and it will be before suricata and polarproxy"*. M012 inserted 2026-05-05 same iteration per operator directive on .gitignore audit + vendor-mapping + fresh-machine install + auto-detect — co-located with M004 (Infrastructure). Module IDs preserved (no renumbering).

## Stream 1 — Second-brain integration

| Module | Status |
|---|---|
| [M006 — Pre-connect verification](root-modules-m006-pre-connect-verification.md) | draft |
| [M007 — Connect to second brain](root-modules-m007-connect-second-brain.md) | draft |
| [M008 — Smoke test from inside](root-modules-m008-smoke-test-from-inside.md) | draft |
| [M009 — Worked example](root-modules-m009-worked-example-readme-ingest.md) | draft |
| [M010 — sister-projects.yaml flip](root-modules-m010-sister-projects-yaml-flip.md) | draft |

## Pending-clarification

| Module | Status | Awaits |
|---|---|---|
| [M013 — Agent modes architecture](root-modules-m013-agent-modes-and-mode-aware-loops.md) | draft | (mostly Phase 1 implemented — atomic tasks deferred per operator) |

Methodology engine: [`../../config/methodology.yaml`](../../config/methodology.yaml).
