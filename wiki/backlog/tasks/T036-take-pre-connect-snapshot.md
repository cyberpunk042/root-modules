---
title: "T036 — Take pre-connect snapshot (git commit OR tar) for atomic rollback"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m006-pre-connect-verification"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Pre-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m006-pre-connect-verification.md
tags: [task, p0, t036, stream-1, pre-connect, snapshot, rollback, m006]
---

# T036 — Take pre-connect snapshot

## Description

For atomic rollback if M007 reveals issues: take a snapshot of $HOME before running --connect-project for real. Operator picks granularity:
- **Git commit** (preferred when $HOME is git-tracked + clean state): `git commit -m 'pre-M007-connect snapshot'` then post-connect changes can be reverted as a single revert.
- **Tar artefact** (fallback): `tar -czf /tmp/root-pre-connect-<UTC-timestamp>.tar.gz -C / root` (or operator-specified subset).

## Done When

- [ ] Operator picks snapshot mechanism (git OR tar OR both).
- [ ] Snapshot taken; artefact path / commit SHA recorded.
- [ ] Rollback procedure documented (specific commands to revert if M007 reveals issues).
- [ ] Snapshot referenced in $HOME/wiki/log/<date>-m006-pre-connect-checklist.md.

## Dependencies

- T032 (clean git state) — required if git-snapshot path chosen

## Relationships

- PART OF: [[root-modules-m006-pre-connect-verification|M006]]
- BLOCKED BY: T032
- BLOCKS: T037 (audit log), T038 (M007 connect — rollback target known)
