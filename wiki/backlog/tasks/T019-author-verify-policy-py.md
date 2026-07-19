---
title: "T019 — Author $HOME/tools/verify-policy.py (project-internal verifier)"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m004-infrastructure-tooling"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: scaffold
readiness: 0
sfif_stage: Infrastructure
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m004-infrastructure-tooling.md
  - id: tools-md
    type: wiki
    file: TOOLS.md
    description: "Planned verify-policy.py invocations + invariants"
tags: [task, p0, t019, infrastructure, verifier, authoring, m004]
---

# T019 — Author $HOME/tools/verify-policy.py

## Description

Author the project-internal verifier per T018-approved scope. Single Python module (`tools.verify_policy`) callable as `python3 -m tools.verify_policy`. Returns 0 on all-pass; non-zero with specific failure list otherwise.

## Done When

- [ ] `$HOME/tools/verify_policy.py` (or `verify-policy.py`) exists, executable.
- [ ] `$HOME/tools/__init__.py` exists (Python package marker).
- [ ] `python3 -m tools.verify_policy` runs without errors and returns expected exit codes.
- [ ] Sub-checks per T018 scope: integrity check + deny-set count + hook permissions + hook executable + .gitignore audit + (operator-approved subset).
- [ ] Output: human-readable per check (✓/✗/skip with reason) + summary; `--json` for machine consumption.
- [ ] `--quick` flag: integrity check only (subset; faster).
- [ ] `--help`: lists all checks + flags.
- [ ] Idempotent + side-effect-free — running it does not mutate state.
- [ ] Smoke-tested per T021.

## Stage-gate (Implement)

Per methodology stage `implement`: code compiles + lint passes + ≥1 existing file imports new code. For Python: `python3 -c "from tools import verify_policy"` succeeds; CLAUDE.md routing table references it.

## Dependencies

- T018 (scope decision) ✓ when made
- T012 (install.sh) — verifier checks install.sh's deployed state
- T014 (endpoint AI safety) — verifier checks the policy's invariants

## Relationships

- PART OF: [[root-modules-m004-infrastructure-tooling|M004]]
- BLOCKED BY: T018, T012, T014
- BLOCKS: T020 (CI/pre-commit wiring), T021 (smoke test), T022 (CLAUDE.md routing entry), T023 (foundation re-gate)
