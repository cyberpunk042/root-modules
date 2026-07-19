---
title: "T065 — M011 surface decisions for operator (after T062-T064 preliminary research complete)"
type: task
status: in-progress
priority: P1
parent_module: "root-modules-m011-ccstatusline-statusline-widget"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 60
sfif_stage: Features
created: 2026-05-05
updated: 2026-05-05
tags: [task, p1, t065, m011, ccstatusline, operator-decisions, document-stage]
---

# T065 — Surface decisions for operator (M011 prelim closeout)

## Description

After T062 (widget scope), T063 (profile mechanism), T064 (vendor research) — surface the genuinely-uncertain operator decisions in DECISION PACKAGE format (per SB-071) so M011 can transition from preliminary to active.

## Decisions to surface (anticipated, per cycle-20 research)

1. **Widget set finalization** — confirm built-ins listed in T062; confirm custom widgets needed (selected-task / progress / stage); approve any additions/removals.
2. **Profile mechanism** — A (env var + multiple configs) / B (slash command) / C (persistent conditional)? Recommend A.
3. **Integration approach** — A (system npm) / B (vendored) / C (vendor manifest + install.sh)? Recommend C (composes with M012).
4. **Profile names** — operator's preferred names (e.g., `project` / `standard` vs `pm` / `engineer` vs other)?
5. **Start with which profile** — author project-aware first or standard first?
6. **Custom Text shell commands** — confirm proposed shell-outs (T064 lists drafts).

## Done When

- [ ] All 6 anticipated decisions surfaced as DECISION PACKAGES (CONTEXT/GUIDANCE/RECOMMEND/ALTERNATIVES/TO-ANSWER per SB-071)
- [ ] Operator answers / approves
- [ ] M011 module status moves from `draft` to `not-started` (atomic implementation tasks T-M011-impl-* authored after this gate)

## Dependencies

- T062 + T063 + T064 (research complete)

## Relationships

- PART OF: [[root-modules-m011-ccstatusline-statusline-widget|M011]]
- BLOCKED BY: T062, T063, T064
- BLOCKS: M011 transition from draft to active feature work
