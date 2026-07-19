---
title: "T018 — Operator approves verifier scope (which checks, which strictness)"
type: task
status: not-started
reclassified_2026-05-05: "from pending-operator-decision — actually prerequisite-blocked by M003 completion; M004 verifier scope decision happens AFTER M003 Foundation gate passes, not blocking-now"
priority: P0
parent_module: "root-modules-m004-infrastructure-tooling"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 25
sfif_stage: Infrastructure
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m004-infrastructure-tooling.md
tags: [task, p0, t018, infrastructure, verifier-scope, operator-decision-pending, m004]
---

# T018 — Operator approves verifier scope

## Description

Operator approves which invariants the project-internal verifier (`tools/verify-policy.py` or equivalent) checks and how strictly. The verifier is M004's central deliverable — it converts hand-checked safety invariants into structurally-enforced ones (per the second brain's Principle 1: Infrastructure Over Instructions).

## Decisions to confirm

| Decision | Default proposal | Operator-decision |
|---|---|---|
| Verifier language | Python (aligns with prior `integrity.py` if extended) | (pending) |
| Integrity check delegate | Call existing tamper-detection sentinel | (pending) |
| Deny-set count threshold | ≥ N (operator-set; original prior debris had ~150) | (pending) |
| Hook executable + permissions check | All required hooks present + executable + correct mode | (pending) |
| Hook size deviation check | Within ±X% of baseline (prevent stub replacements) | (pending) |
| .gitignore deny-all + whitelist verification | Run `git ls-files` + match against whitelist set | (pending) |
| Backup-file leftover check | No `*.ghostproxy.bak.*` orphaned (out-of-sync state would leave them) | (pending) |
| Strictness | Block on any failure / warn but pass / per-check tunable | (pending) |
| Output format | Plain English + JSON (`--json`) | (pending) |

## Done When

- [ ] Operator approves the verifier's scope (which checks).
- [ ] Operator approves strictness (block vs warn per check).
- [ ] Decision documented; T019 (authoring) unblocked.

## Dependencies

- T012 (install.sh) — verifier checks install.sh's deployed state
- T014 (endpoint AI safety policy) — verifier checks the policy's invariants

## Relationships

- PART OF: [[root-modules-m004-infrastructure-tooling|M004]]
- BLOCKS: T019 (verifier authoring)
- RELATES TO: M003 task T017 (Foundation gate uses verifier as part of its check)
