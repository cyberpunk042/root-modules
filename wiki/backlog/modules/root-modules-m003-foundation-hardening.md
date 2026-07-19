---
title: "root-modules M003 — Foundation Hardening"
aliases:
  - "M003 — root-modules Foundation"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Foundation
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
  - id: model-sfif-architecture
    type: wiki
    file: wiki/spine/models/quality/model-sfif-architecture.md
    description: "Foundation tier definition and gates"
  - id: root-modules-readme
    type: file
    file: $HOME/README.md
    description: "Existing README — install steps, v1 limitations"
  - id: root-modules-install-script
    type: file
    file: $HOME/install.sh
    description: "Existing bootstrap script — classified as not-IaC per prior session"
tags: [module, p0, root-modules, sfif-foundation, install, idempotency, integrity-check, m003]
---

# M003 — Foundation Hardening for root-modules

## Summary

Move root-modules from current scaffold-plus-partial-foundation state to a clean SFIF Foundation tier. Foundation = the project installs reliably from a clean host into a working state, with idempotent re-runs, dry-run preview, and explicit integrity verification. Concrete gates: `./install.sh --dry-run` must succeed cleanly, `./install.sh --check` must succeed cleanly, `integrity_check()` must continue to return None (OK), README must document install steps + verification commands explicitly. install.sh's prior-session classification as not-IaC is preserved (it's a bootstrap, not a desired-state declarator) — this module hardens what's there, not converts to IaC.

## Done When

- [ ] `./install.sh --dry-run` runs to completion with exit code 0 on a clean Debian 13 host AND on the current $HOME host (no-op confirmation)
- [ ] `./install.sh --check` runs to completion with exit code 0 — verifies installed state matches expected
- [ ] `integrity.py integrity_check()` returns None (OK) before and after a re-run of install.sh — fail-closed properties preserved
- [ ] $HOME/README.md updated to document: install + dry-run + check + integrity-check commands; v1 limitations section reflects current state (not stale)
- [ ] Idempotency invariants documented explicitly: which files install.sh creates / overwrites / leaves-alone, and how a second run behaves
- [ ] No regressions in existing memory-layer rules / hooks behaviour after the hardening

## Dependencies

- M001 (CLAUDE.md + AGENTS.md) — Foundation hardening references go in those files
- M002 (Methodology decision) — gate commands resolved via methodology engine (local or pointer)
- Existing $HOME/install.sh and $HOME/integrity.py from prior session — must not be regressed
- Operator-side host access for clean-host install verification (the current $HOME is the only known host)

## Open Questions

> [!question] How to verify clean-host install when there's only one host?
> Options: (a) snapshot the current $HOME state, run a clean-Debian-13 VM, install, compare; (b) wait until a second host appears; (c) trust the dry-run + check output. (a) is most rigorous; (b) is impractical short-term; (c) is acceptable for Foundation tier given micro-scale + solo mode.

> [!question] Is the not-IaC classification of install.sh a Foundation gate or a permanent stance?
> Classification was made in a prior session per operator direction. If install.sh stays not-IaC, then "IaC-ness" is a Phase-2 module. If it migrates to IaC (Ansible, Salt, NixOS, chezmoi-style desired-state) at some later point, that's an explicit module reset, not a creep.

> [!question] What does "integrity_check returns None" mean operationally for the Foundation gate?
> integrity.py is fail-closed for ~/.claude/settings.json (151+ deny patterns required, hooks wired, executables present). Returning None = OK. The Foundation gate must verify None both before AND after install, ensuring install doesn't degrade integrity.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M003-1 | Run `./install.sh --dry-run` on current host, capture full output, log any anomalies | ⊙ pending |
| T-M003-2 | Run `./install.sh --check` on current host, capture full output, log any anomalies | ⊙ pending |
| T-M003-3 | Run `integrity_check()` before and after install.sh re-run; verify both return None | ⊙ pending |
| T-M003-4 | Document idempotency invariants in $HOME/docs/foundation-invariants.md (or inline in README) | ⇗ [[T016-document-idempotency-invariants\|T016]] status:review (landed inline at TOOLS.md `#### Idempotency invariants` per F46 design decision) |
| T-M003-5 | Update $HOME/README.md install + verify section with the verified commands | ⊙ pending |
| T-M003-6 | Decide: clean-host VM verification (option a) or trust dry-run + check (option c)? | ⊙ pending |
| T-M003-7 | Refine hook pattern matching to eliminate false positives (per `wiki/log/2026-05-05-hook-pattern-false-positives-for-m003-refinement.md`) — policy-block + malware-block both fire on legitimate commands containing credential-name substrings as data or `install.sh` co-occurring with `.claude/hooks/` path references | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BUILDS ON: [[model-sfif-architecture|Model — SFIF and Architecture]]
- BLOCKED BY: [[root-modules-m001-author-claude-md-and-agents-md|M001]], [[root-modules-m002-methodology-layer-decision|M002]]
- ENABLES: [[root-modules-m004-infrastructure-tooling|M004 — Infrastructure tooling (depends on Foundation gate)]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[model-sfif-architecture|Model — SFIF and Architecture]]
[[M001]]
[[M002]]
[[M004 — Infrastructure tooling (depends on Foundation gate)]]
