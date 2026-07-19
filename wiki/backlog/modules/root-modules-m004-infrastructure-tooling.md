---
title: "root-modules M004 — Infrastructure Tooling"
aliases:
  - "M004 — root-modules Infrastructure"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Infrastructure
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
tags: [module, p0, root-modules, sfif-infrastructure, tooling, validation, ci, pre-commit, m004]
---

# M004 — Infrastructure Tooling for root-modules

## Summary

Bring root-modules from Foundation tier to Infrastructure tier by adding project-internal tooling: at minimum a verifier script that wraps integrity_check + deny-list count + hook permissions, and a validation pipeline (CI workflow OR local pre-commit hook) that runs the verifier on every change. SFIF Infrastructure means: the project enforces its own quality gates programmatically, not via prose. For a micro-scale OS-setup project, "infrastructure tooling" can be lean: one Python file under tools/ + one shell-level pre-commit hook is sufficient at this stage; full CI on a multi-host fleet is Phase-2.

## Done When

- [ ] `tools/verify-policy.py` exists at $HOME/tools/, callable as `python3 -m tools.verify_policy` (or as `./tools/verify-policy.py`), running:
  - `integrity.integrity_check()` (existing, unchanged)
  - Deny-list pattern count check (count must be ≥ N, where N is the operator-confirmed minimum currently 151 per memory)
  - Hook executables present + executable bit set
  - All hooks wired in ~/.claude/settings.json
- [ ] `tools/verify-policy.py` returns 0 when all checks pass; non-zero with explanation when any check fails
- [ ] Validation pipeline: either a `.pre-commit-config.yaml` running the verifier on relevant file changes, OR a CI workflow (GitHub Actions if repo distribution lands in M-future)
- [ ] Operator approves the verifier scope — operator is the source of truth for "151+ deny patterns required"; verifier must not invent new gates without operator authorization
- [ ] Foundation gate (M003) still passes after Infrastructure tooling is added — no regressions

## Dependencies

- M003 (Foundation hardening) — Infrastructure builds on Foundation; integrity_check + dry-run + check already verified
- M001 (CLAUDE.md + AGENTS.md) — verifier invocation goes in routing table
- Operator decision: pre-commit hook vs CI workflow vs both? Repo-distribution decision (open in epic) affects CI option

## Open Questions

> [!question] Should the verifier be Python or shell?
> Python aligns with existing $HOME/integrity.py. Shell aligns with $HOME/install.sh and is more legible for ops. Likely Python given the integrity.py call is the load-bearing piece — calling Python from shell is fine, the inverse is awkward.

> [!question] What level of strictness for the deny-list count?
> Memory says 151+ deny patterns required as fail-closed. Verifier should pin to that count (or higher); below it, fail. Operator may want stricter (e.g. exact match on a known-good list) — that's a Phase-2 enhancement.

> [!question] Pre-commit hook vs CI workflow?
> Pre-commit is local-only, doesn't catch unstaged drift on the host. CI catches more, but requires GitHub remote (epic open question — repo distribution still unresolved). Pragmatic answer: pre-commit first, CI when remote stabilizes.

> [!question] Should the verifier run on each ./install.sh invocation as a self-check?
> Possibly, but creates dependency loops (install.sh → verifier → integrity.py → install.sh state). Cleaner: install.sh stays bootstrap-only, verifier runs separately as `tools/verify-policy.py` post-install.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M004-1 | Operator approves verifier scope (which checks, which strictness) | ⊙ pending |
| T-M004-2 | Author $HOME/tools/verify-policy.py with the approved checks | ⊙ pending |
| T-M004-3 | Wire pre-commit hook OR CI workflow (decided by operator + repo-distribution status) | ⊙ pending |
| T-M004-4 | Smoke-test the verifier: known-good state passes; deliberate degradation fails with explanation | ⊙ pending |
| T-M004-5 | Document verifier invocation in CLAUDE.md routing table | ⊙ pending |
| T-M004-6 | Re-run M003 Foundation gate to confirm no regression | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BUILDS ON: [[model-sfif-architecture|Model — SFIF and Architecture]]
- BLOCKED BY: [[root-modules-m003-foundation-hardening|M003 — Foundation hardening]]
- ENABLES: [[root-modules-m005-first-specialized-feature-module|M005 — First specialized feature module (Suricata or PolarProxy)]]
- DEMONSTRATES: [[infrastructure-over-instructions-for-process-enforcement|Principle 1]] (validation pipeline > prose-only "remember to check this")

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[model-sfif-architecture|Model — SFIF and Architecture]]
[[M003 — Foundation hardening]]
[[M005 — First specialized feature module (Suricata or PolarProxy)]]
[[infrastructure-over-instructions-for-process-enforcement|Principle 1]]
