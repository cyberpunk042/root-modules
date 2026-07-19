---
title: "T037 — Assemble M006 pre-connect audit log (collected evidence + operator authorization)"
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
  - id: pre-connect-checklist-template
    type: file
    file: /opt/devops-solutions-information-hub/wiki/config/templates/second-brain-integration/pre-connect-checklist.md.template
tags: [task, p0, t037, stream-1, pre-connect, audit-log, m006]
---

# T037 — Assemble M006 audit log

## Description

Bundle all pre-connect evidence + operator authorization into a single audit log per the pre-connect-checklist template (`/opt/devops-solutions-information-hub/wiki/config/templates/second-brain-integration/pre-connect-checklist.md.template`).

## Done When

- [ ] Audit log at `$HOME/wiki/log/<date>-m006-pre-connect-audit.md`.
- [ ] Contains pre-conditions verification table with all 6 checks (AGENTS.md exists, git status clean, sister entry correct, .mcp.json captured, $HOME/tools/ captured, snapshot taken) — sourced from T031, T032, T033, T034, T036.
- [ ] Contains the dry-run output from T035.
- [ ] Contains the variant determination: ROOT_OS_SETUP per type=root + group=operating-system-setup.
- [ ] Contains operator authorization (verbatim, with timestamp).
- [ ] Decision block: proceed with M007 connect (yes/no/blocked).

## Done When (M006 module exit)

Operator's "yes, proceed" in the audit log marks M006 complete and unblocks M007.

## Dependencies

- T031, T032, T033, T034, T035, T036 — all pre-connect evidence checks

## Relationships

- PART OF: [[root-modules-m006-pre-connect-verification|M006]]
- BLOCKED BY: T031, T032, T033, T034, T035, T036
- BLOCKS: T038 (M007 connect)
