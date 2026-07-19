---
title: "T062 — M011 scope ccstatusline widget set (built-in standard + custom project-aware)"
type: task
status: done
priority: P1
parent_module: "root-modules-m011-ccstatusline-statusline-widget"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 100
sfif_stage: Features
created: 2026-05-05
updated: 2026-05-05
sources:
  - id: ccstatusline-github
    type: external
    url: https://github.com/sirmalloc/ccstatusline
  - id: ccstatusline-npm
    type: external
    url: https://www.npmjs.com/package/ccstatusline
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m011-ccstatusline-statusline-widget.md
tags: [task, p1, t062, m011, ccstatusline, widget-scope, document-stage]
---

# T062 — Scope the ccstatusline widget set

## Description

Per operator directive: M011 needs widgets for two profiles: project-aware (selected-task, progress, stage) + standard (context, context-usage, billing 5h, 7d, tokens). Scope which widgets are built-in to `sirmalloc/ccstatusline` v2.2.12 vs need custom authoring.

## Built-in widgets (researched cycle 20 from README.md)

**Standard profile fields → ALL built-in:**

| Operator-named field | Built-in widget | Note |
|---|---|---|
| context tokens used | `Context %` / `Context Bar` | with `Used/Remaining` toggle |
| billing 5h | `Session Usage` (5h block) | with cursor for elapsed-time position |
| billing 7d | `Weekly Usage` | weekly rolling |
| tokens | `Token Speed` (Input/Output/Total) | configurable 0-120s rolling window |
| model | `Model` | strips `(1M context)` suffix |
| context size | `Context Window` | full window size (separate from used) |
| compactions | `Compaction Counter` | session-scoped compaction counts |
| memory | `Memory Usage` | `Mem: used/total` |

**Adjacent built-ins potentially useful:**

- Block Reset Timer / Weekly Reset Timer (5h/7d boundaries)
- Thinking Effort (current `/effort` level — `xhigh`/`high`/`mid`/`low`)
- Vim Mode
- CWD (with `~` home abbreviation; `fish` style path)
- Session Name (Claude Code `/rename`)
- Skills widget (Claude Code skills)
- Many Git widgets (branch, PR/MR, status, ahead/behind, conflicts, SHA, worktree, insertions/deletions, GitHub/GitLab links)
- Powerline themes + separators

**Project-aware fields → NOT built-in; require custom authoring:**

| Operator-named field | Built-in? | Custom strategy |
|---|---|---|
| selected-task (T###) | NO | Custom Text widget reading from a state file (e.g., `~/.claude/active-task` or `$HOME/.claude/active-task`) |
| progress (readiness %) | NO | Custom Text reading from a state file OR computed from `tools.progress` output |
| stage (SFIF stage) | NO | Custom Text from state file OR `tools.state` output |

`Custom Text` widget exists (v2.0.12+ with emoji support). Approach: shell-out script that reads $HOME state + outputs the desired string.

## Done When

- [ ] List of built-in widgets to use, finalized
- [ ] List of custom widgets to author + their data sources, finalized
- [ ] Operator confirms widget set OR specifies additions/removals

## Dependencies

- M011 module page (this module's parent)
- ccstatusline researched (DONE this cycle)

## Relationships

- PART OF: [[root-modules-m011-ccstatusline-statusline-widget|M011]]
- BLOCKS: T063 (profile mechanism), T064 (vendor integration), T065 (operator decisions)
