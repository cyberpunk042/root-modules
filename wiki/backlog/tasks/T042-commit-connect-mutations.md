---
title: "T042 — Commit $HOME mutations atomically with descriptive message"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m007-connect-second-brain"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 0
sfif_stage: Stream-1-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m007-connect-second-brain.md
tags: [task, p0, t042, stream-1, connect, git-commit, m007]
---

# T042 — Atomic commit of $HOME mutations

## Description

After artefact inspection (T041) confirms correctness, commit the 4 changes as a single atomic git commit so the connection diff is reviewable as a unit.

## Done When

- [ ] `cd $HOME && git status` shows the 4 expected new/modified files (.mcp.json, tools/gateway.py, tools/view.py, AGENTS.md) and possibly tools/__init__.py if newly created.
- [ ] `git add <expected files>` (specific add, not `git add -A`).
- [ ] `git commit -m 'M007: connect $HOME to second brain via tools.setup --connect-project (variant=ROOT_OS_SETUP)'` (or operator-preferred message).
- [ ] Commit SHA captured to `$HOME/wiki/log/<date>-m007-connect-output.md`.
- [ ] `git log --oneline` confirms the commit landed.

## Dependencies

- T041 (artefact inspection passed)
- T032 (pre-connect git state was clean — so this commit is single-purpose)

## Relationships

- PART OF: [[root-modules-m007-connect-second-brain|M007]]
- BLOCKED BY: T041
- BLOCKS: T043 (rollback policy depends on this commit being the rollback target)
