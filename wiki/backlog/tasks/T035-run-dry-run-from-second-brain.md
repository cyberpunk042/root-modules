---
title: "T035 — Run `python3 -m tools.setup --connect-project $HOME --dry-run` from second brain (preview)"
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
tags: [task, p0, t035, stream-1, pre-connect, dry-run, m006]
---

# T035 — Dry-run --connect-project from second brain

## Description

The patched `tools.setup --connect-project --dry-run` (added during preparation session 2026-05-04) previews what the connect script would write WITHOUT writing. Run it before the real connection.

## Done When

- [ ] From the second brain: `cd /opt/devops-solutions-information-hub && python3 -m tools.setup --connect-project $HOME --dry-run`.
- [ ] Output captured to `$HOME/wiki/log/<date>-pre-connect-dry-run.md`.
- [ ] Output confirms: target=$HOME, brain=/opt/devops-solutions-information-hub, sister entry resolved as `root-modules` with type=root + group=operating-system-setup, brain-pointer block variant=ROOT_OS_SETUP.
- [ ] No files modified by the dry-run (verify no diff in $HOME after).
- [ ] If the dry-run reveals collisions or unexpected behavior: pause + investigate before proceeding to T038 real connect.

## Dependencies

- T031 (AGENTS.md exists, otherwise the brain-pointer would skip)
- T033 (pre-connect state snapshotted for diff comparison)
- `tools/setup.py` patched with --dry-run ✓ (done 2026-05-04)

## Relationships

- PART OF: [[root-modules-m006-pre-connect-verification|M006]]
- BLOCKED BY: T031, T033
- BLOCKS: T036 (variant determination), T037 (audit log)
