---
title: "T022 — Document verify-policy invocation in CLAUDE.md operator-intent routing table"
type: task
status: not-started
priority: P1
parent_module: "root-modules-m004-infrastructure-tooling"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 0
sfif_stage: Infrastructure
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m004-infrastructure-tooling.md
tags: [task, p1, t022, infrastructure, claude-md, documentation, m004]
---

# T022 — Document verify-policy in CLAUDE.md routing

## Description

Add verify-policy invocations to $HOME/CLAUDE.md's operator-intent routing table — Foundation operations sub-table — so future sessions can route operator's audit/verify intents to the verifier directly.

## Done When

- [ ] CLAUDE.md routing table updated with new entries for verify-policy:
  - `"verify policy"` / `"is the safety envelope intact"` → `python3 -m tools.verify_policy`
  - `"quick integrity check"` → `python3 -m tools.verify_policy --quick`
  - `"verify policy (machine-readable)"` → `python3 -m tools.verify_policy --json`
- [ ] TOOLS.md per-tool reference updated — verify-policy section reflects authored reality (status: complete; invocation: documented; expected output: documented).
- [ ] Cross-reference from CONTEXT.md "Recent work completed" table.

## Dependencies

- T019 (verifier exists to be referenced)
- T020 (validation pipeline existence)
- T021 (smoke-tested behavior)

## Relationships

- PART OF: [[root-modules-m004-infrastructure-tooling|M004]]
- BLOCKED BY: T019, T020, T021
- ENABLES: future-session operator-intent recognition for verify operations
