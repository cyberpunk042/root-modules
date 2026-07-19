---
title: "T051 — Reframe M009: bidirectional flow already partially proven by registry+identity+epic+sources+forwarders"
type: task
status: not-started
reclassified_2026-05-05: "from pending-operator-decision — BLOCKED BY T050 (M008 module exit); reframe decision happens AFTER M008 smoke-test confirms connection works"
priority: P1
parent_module: "root-modules-m009-worked-example-readme-ingest"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 50
sfif_stage: Stream-1-Worked-Example
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m009-worked-example-readme-ingest.md
tags: [task, p1, t051, stream-1, worked-example, reframe, m009]
---

# T051 — Reframe M009 (operator-decision)

## Description

Per operator's directive 2026-05-05 to NOT ingest $HOME files (they're operator's authored OUTPUT, not WIKI INPUT), the original M009 framing of "ingest $HOME/README.md as a source-synthesis page" is wrong. The bidirectional flow is already partially proven by:

- The second brain has root-modules as a queryable entity (sister-projects.yaml entry, identity-profile.md, SFIF rollout epic, 10 module pages, 6 source-syntheses for Suricata + PolarProxy, two template lists).
- After M007 connection: research-wiki MCP entry + gateway/view forwarders enable the consumption-direction flow.
- The contribute-direction flow uses `python3 -m tools.gateway contribute` from $HOME (after M008 connection live).

The original "ingest README as worked example" was an AI-author misunderstanding; the operator rejected it.

## Done When

- [ ] Operator decides M009's reframed scope:
  - **Option A:** M009 is now "verify second brain has root-modules as a queryable entity" (already proven; mark complete).
  - **Option B:** M009 is "demonstrate operator's first contribute-back flow" (operator authors a real lesson learned + runs `gateway contribute --type lesson --title "..."`).
  - **Option C:** M009 is "demonstrate the second brain consuming a different $HOME artefact" (e.g. ingest $HOME/wiki/log/<latest>.md as a session-log source if appropriate; operator decides which artefact is appropriate).
- [ ] Decision documented in $HOME/wiki/log/.
- [ ] M009 module page updated to reflect the chosen reframe.

## Dependencies

- M008 (smoke test confirms connection works, prerequisite for any M009 reframe option)

## Relationships

- PART OF: [[root-modules-m009-worked-example-readme-ingest|M009]]
- BLOCKED BY: T050 (M008 module exit)
- BLOCKS: T052 through T056 (subsequent work scoped per reframe choice)
