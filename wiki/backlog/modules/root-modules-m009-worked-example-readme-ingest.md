---
title: "root-modules M009 — Worked Example: Ingest README into Second Brain"
aliases:
  - "M009 — Bidirectional flow proof"
type: module
domain: backlog
status: draft
priority: P1
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 10
progress: 0
sfif_stage: Stream-1-Worked-Example
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
tags: [module, p1, root-modules, second-brain-integration, stream-1, worked-example, bidirectional-flow, m009]
---

# M009 — Worked Example: Ingest $HOME/README.md into Second Brain

## Summary

Prove the bidirectional knowledge flow works end-to-end by ingesting $HOME/README.md into the second brain as a source-synthesis page. M009 demonstrates that root-modules is a first-class source in the corpus — the second brain consumes from $HOME, not just pushes config to it. This is the parallel of M007 (push from second brain) but in the opposite direction: pull from $HOME into corpus. After M009, future questions about root-modules can be answered by querying the second brain's corpus directly (`wiki_search root-modules`) rather than re-reading $HOME files each time.

## Done When

- [ ] $HOME/README.md is fetched into second brain's raw/ via `wiki_fetch file://$HOME/README.md` OR `pipeline fetch` with file:// URL OR explicit copy
- [ ] A source-synthesis page exists at second brain's `wiki/sources/src-root-modules-readme.md` (or similar) with: full frontmatter, summary ≥30 words, key insights, relationships to identity-profile + epic
- [ ] Page passes `pipeline post` validation (0 errors)
- [ ] `pipeline crossref` finds connections between the new readme page and existing root-modules entries (epic, identity-profile, src-suricata, src-polarproxy)
- [ ] Operator confirms the page accurately represents $HOME/README.md's current content

## Dependencies

- M008 (Smoke test) — connection is verified working
- $HOME/README.md exists in a stable, reviewed state (current README is from prior session — operator may want to update it via M001/M003 first; M009 then ingests the updated version)
- Pipeline + crossref tools available on second brain side (already verified this session)

## Open Questions

> [!question] Should $HOME/README.md be ingested via wiki_fetch (web-style) or via direct file copy + scaffold?
> Both work. wiki_fetch with `file://` URL is closer to the standard ingestion playbook (raw/ → synthesis page → post → crossref). Direct copy skips the "pipeline as the canonical ingestion path" principle — only do that if file:// fetching is not supported.

> [!question] Should the source-synthesis page domain be infrastructure (matching Suricata + PolarProxy) or ecosystem-projects (matching the wiki/sources/ecosystem-projects/ folder)?
> root-modules README is an ecosystem-project source — `wiki/sources/ecosystem-projects/src-root-modules-readme.md` is the right path. domain field: ecosystem-projects.

> [!question] How often should $HOME/README.md be re-ingested as it evolves?
> The README will change over the project's lifetime. Manual re-ingestion when the operator decides the README has shifted enough is the simplest policy. Automated re-ingestion (a watcher) is over-engineering at this stage.

> [!question] Does this need to wait for M001 (CLAUDE.md + AGENTS.md exist + are stable)?
> M001 is in Stream 2; M009 is in Stream 1. Logical dependency: ingesting the README is more valuable AFTER M001/M003 because the README will be updated then. But not strictly blocked — the current README can be ingested as a baseline.

## Tasks

| Task | Description | Status |
|---|---|---|
| T-M009-1 | Decide ingestion path (wiki_fetch with file:// vs direct copy) | ⊙ pending |
| T-M009-2 | Fetch $HOME/README.md into second brain's raw/ (file path: raw/articles/root-modules-readme.md or similar) | ⊙ pending |
| T-M009-3 | Author source-synthesis page at wiki/sources/ecosystem-projects/src-root-modules-readme.md per source-synthesis schema | ⊙ pending |
| T-M009-4 | Run `pipeline post` — must return 0 errors | ⊙ pending |
| T-M009-5 | Run `pipeline crossref` — verify connections to existing root-modules pages found | ⊙ pending |
| T-M009-6 | Operator reviews the synthesis for accuracy | ⊙ pending |

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BLOCKED BY: [[root-modules-m008-smoke-test-from-inside|M008 — Smoke test (connection must be working)]]
- RELATES TO: [[root-modules-m001-author-claude-md-and-agents-md|M001 — README is ideally updated before M009 ingests it]]
- ENABLES: [[root-modules-m010-sister-projects-yaml-flip|M010 — sister-projects.yaml auto-connect decision]]

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M008 — Smoke test (connection must be working)]]
[[M001 — README is ideally updated before M009 ingests it]]
[[M010 — sister-projects.yaml auto-connect decision]]
