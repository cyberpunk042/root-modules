---
title: "T043 — Rollback policy: revert + re-run if M007 reveals issues"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m007-connect-second-brain"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Stream-1-Connect
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m007-connect-second-brain.md
tags: [task, p0, t043, stream-1, connect, rollback, m007]
---

# T043 — Rollback policy

## Description

If T041 inspection or M008 smoke test reveals problems, the connect-script's mutations are rolled back via the snapshot taken in T036, then the issue is fixed and the connect re-run.

## Done When

- [ ] Rollback procedure documented:
  - **Git path:** `cd $HOME && git revert <T042-commit-SHA>` reverts the 4 artefacts as a single revert commit.
  - **Tar path:** restore from the tar artefact taken in T036.
- [ ] `python3 -m tools.setup --disconnect` (run from $HOME) is the alternative rollback for the .mcp.json portion specifically (removes `mcpServers.research-wiki` entry).
- [ ] Rollback policy documented in `$HOME/wiki/log/<date>-m007-rollback-policy.md` so future failed M007 runs have a clear path.
- [ ] If a rollback IS needed: execute it; re-investigate the issue; fix in setup.py or in the project's state; re-run M007.

## Dependencies

- T036 (pre-connect snapshot taken)
- T042 (connect commit SHA known)

## Relationships

- PART OF: [[root-modules-m007-connect-second-brain|M007]]
- BLOCKED BY: T036, T042 (rollback only meaningful after artefacts committed)
- ENABLES: M007 module exit (passes when no rollback needed; fails-fast when one is)
