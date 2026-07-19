---
title: "root-modules M008 — Smoke Test from Inside"
aliases:
  - "M008 — Verify second-brain connection works from $HOME"
type: module
domain: backlog
status: draft
priority: P0
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Stream-1-Verify
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
tags: [module, p0, root-modules, second-brain-integration, stream-1, smoke-test, m008]
---

# M008 — Smoke Test the Second-Brain Connection from Inside $HOME

## Summary

Open a fresh Claude Code session in $HOME and verify the second-brain connection works end-to-end: `gateway orient` should resolve and print orientation against the connected second brain; `view spine` should print the second brain's spine pages; the `research-wiki` MCP tools should be available to the agent. M008 is the verification gate of Stream 1 — without a passing M008, the connection is aspirational (P4 violation). The fresh-session-orients-within-60-seconds gate from the parent epic's "cross-cutting verification" section is the load-bearing test.

## Done When

- [ ] Fresh Claude Code session opened with `claude` in $HOME — operator-driven
- [ ] Within 60 seconds: agent reads $HOME/CLAUDE.md, runs `python3 -m tools.gateway orient`, and reports valid orientation including the second brain's identity
- [ ] `python3 -m tools.view spine` from inside $HOME prints the second brain's spine pages without error
- [ ] At least one MCP tool from the connected research-wiki is invocable from inside the session (e.g. `wiki_status` returns valid output)
- [ ] No silent failures: if second brain is unreachable, error is explicit and remediation is clear (per M007 forwarder error-handling decision)
- [ ] Operator confirms the smoke test passes — no manual context loading needed beyond CLAUDE.md + gateway orient

## Dependencies

- M007 (Connect) — explicit
- $HOME/CLAUDE.md must reference the gateway forwarder + the second-brain connection (per M001 routing table)
- A reachable /opt/devops-solutions-information-hub at session time

## Open Questions

> [!question] What's the expected output format of `gateway orient` for a type=root + group=operating-system-setup project?
> The orient command is context-aware. Verify it produces appropriate orientation for this project's identity tier — likely simpler than for the second brain itself. If the orient output doesn't fit the simplified-profile micro-scale project, that's a gateway enhancement back in the second brain.

> [!question] What if the operator opens a session before $HOME/CLAUDE.md exists (e.g. mid-rollout)?
> The fresh-session-orients gate assumes M001 + M007 are complete. If a session is opened mid-rollout, the agent should fall back to README + gateway orient explicitly. Document this fallback in $HOME/CLAUDE.md once it exists.

> [!question] Does the smoke test need to be automatable (a script that can be re-run on every connect-script change)?
> Probably not at scaffold stage; manual smoke test by operator is sufficient. Phase-2 enhancement: automate via a `tools/smoke-second-brain-connection.py` test.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M008-1 | Operator opens fresh `claude` session in $HOME | ⊙ pending |
| T-M008-2 | Time-to-orient measurement: agent should be operating within 60 seconds | ⊙ pending |
| T-M008-3 | Run `python3 -m tools.gateway orient` from inside session, capture output | ⊙ pending |
| T-M008-4 | Run `python3 -m tools.view spine`, capture output | ⊙ pending |
| T-M008-5 | Invoke at least one research-wiki MCP tool, capture response | ⊙ pending |
| T-M008-6 | Test failure mode: temporarily make /opt/devops-solutions-information-hub unreachable, verify clear error message; restore | ⊙ pending |
| T-M008-7 | Document M008 results back in this module page (mark Done When checkboxes) | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BLOCKED BY: [[root-modules-m007-connect-second-brain|M007 — Connect]]
- ENABLES: [[root-modules-m009-worked-example-readme-ingest|M009 — Worked example]]
- DEMONSTRATES: [[declarations-are-aspirational-until-infrastructure-verifies-them|Principle 4]] (connection isn't real until the smoke test passes)

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M007 — Connect]]
[[M009 — Worked example]]
[[declarations-are-aspirational-until-infrastructure-verifies-them|Principle 4]]
