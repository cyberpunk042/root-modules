---
title: "T052 — Execute the chosen bidirectional flow demo (per T051 reframe)"
type: task
status: not-started
priority: P1
parent_module: "root-modules-m009-worked-example-readme-ingest"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 0
sfif_stage: Stream-1-Worked-Example
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m009-worked-example-readme-ingest.md
tags: [task, p1, t052, stream-1, worked-example, demo, m009]
---

# T052 — Execute bidirectional flow demo

## Description

Per T051 chosen reframe, execute the demo:
- **Option A:** Run queries to verify second brain has root-modules as a queryable entity (`wiki_search root-modules`, `wiki_sister_project root-modules`, `gateway timeline --scope root-modules`).
- **Option B:** Operator authors a lesson; runs `gateway contribute --type lesson --title "..." --content "..."`; lesson lands in second brain's lessons inbox; verify it appears.
- **Option C:** Operator picks a $HOME artefact (NOT $HOME/README.md per operator's rejection); ingests it via the second brain's pipeline (`wiki_fetch file://$HOME/<path>`).

## Done When

- [ ] Demo runs end-to-end without errors.
- [ ] Output captured to `$HOME/wiki/log/<date>-m009-bidirectional-flow-demo.md`.
- [ ] If Option B: lesson appears in `/opt/devops-solutions-information-hub/wiki/lessons/00_inbox/`.
- [ ] If Option C: the chosen artefact appears in second brain's raw/ + has a synthesis page.

## Dependencies

- T051 (reframe decision)
- M008 connection live

## Relationships

- PART OF: [[root-modules-m009-worked-example-readme-ingest|M009]]
- BLOCKED BY: T051
- BLOCKS: T053 through T056
