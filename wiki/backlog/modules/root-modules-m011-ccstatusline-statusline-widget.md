---
title: "root-modules M011 — ccstatusline custom widget for Claude Code interface"
aliases:
  - "M011 — ccstatusline statusline widget"
type: module
domain: backlog
status: draft
priority: P1
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 75
progress: 0
sfif_stage: Features
sfif_ordering: "Stream 2, after M004 (Infrastructure tooling), BEFORE M005 (Suricata/PolarProxy first feature)"
stages_completed: []
artifacts: []
confidence: medium
created: 2026-05-05
updated: 2026-05-05
sources:
  - id: operator-directive-2026-05-05-rules-and-ccstatusline
    type: directive
    file: /opt/devops-solutions-information-hub/raw/notes/2026-05-05-rules-files-and-ccstatusline-module-directive.md
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
tags: [module, p1, root-modules, sfif-features, m011, ccstatusline, claude-code, statusline, custom-widget, profile-loadable, ordering-before-m005]
---

# M011 — ccstatusline custom widget for Claude Code interface

## Summary

Author a `ccstatusline` custom widget (Claude Code statusline customization) so the operator's Claude Code interface displays project-aware + session-aware information at a glance. The widget supports loadable profiles — different profiles can show different status fields. At minimum: selected-task, progress, stage. Plus the obvious normal stuff: context, context usage, billing usage, 5h windows, 7d windows, tokens. This is a smaller, simpler module than the Suricata/PolarProxy feature module (M005) and is ordered BEFORE it in the SFIF Features stream.

## Operator directive (verbatim, 2026-05-05)

> "we are also going to have a simpler module for ccstatusline custom widget so my claude code interface is better and we can even load different profile such as one that allow to see the selected-task, progress, stage and etc... + the obvious normal stuff  I need such as context and context usage and billing usage, 5h windows, 7d + tokens and etc... I am not saying do it now. I am saying this is one of the modules and it will be before suricata and polarproxy."

## Scope

Two profiles minimum (operator-extensible):

**Profile A — Project-aware (project-work mode)**
- Selected task ID (e.g., T015)
- Module ID + name
- SFIF stage (e.g., `Foundation`)
- Readiness % for the active task
- Methodology stage (document/design/scaffold/implement/test)

**Profile B — Standard (session-aware mode)**
- Context tokens used / available
- Billing usage (current 5h window)
- Billing usage (rolling 7d)
- Total tokens consumed in session
- Model in use

Operator can define additional profiles or extend either. "and etc..." in the directive is intentional — operator will add fields as the widget surfaces them.

## Done When

- [ ] Operator confirms the two-profile scope (or names alternative profiles).
- [ ] Selected statusline implementation approach (ccstatusline tool itself OR Claude Code's native statusline mechanism if applicable).
- [ ] Configuration file format defined (TOML / JSON / YAML — operator decides).
- [ ] Profile A authored with the 5 project-aware fields.
- [ ] Profile B authored with the 5 standard fields.
- [ ] Profile-loading mechanism wired (e.g., env var, slash command, config-file directive).
- [ ] Documentation page at `$HOME/docs/` or `$HOME/wiki/` covering: install, configure, switch profiles, extend.
- [ ] Smoke-test: open a Claude Code session, confirm the active profile renders correctly + reflects session reality.
- [ ] Integration check: ensure widget reads from project state (e.g., active task from $HOME/wiki/backlog or session-claimed task) — not hardcoded values.

## Dependencies

- Parent epic must be in document/scaffold stage (it is).
- Claude Code statusline mechanism research — what API surface does Claude Code expose for custom statuslines? Spike needed before scaffold.
- Project-state reader: how does the widget read selected-task / stage / readiness? File-watch on $HOME/wiki/backlog/tasks/T###*.md frontmatter? A small JSON state file that the agent updates? Operator decides.

## Open questions

> [!question] Which statusline mechanism — `ccstatusline` tool, Claude Code native statusline, or a third option?
> Operator named "ccstatusline custom widget." Likely refers to a specific tool. Spike: confirm the named tool exists + its config surface. If it doesn't exist or doesn't fit, propose alternative.

> [!question] Where does the widget read project state from?
> Options: (a) parse the active task's frontmatter directly, (b) maintain a small JSON state file (`$HOME/.claude/statusline-state.json`) updated by an agent hook on task-claim, (c) use Claude Code's session-state if accessible. Operator decides.

> [!question] Profile-switch mechanism — env var, slash command, config-file?
> Convenient: env var (e.g., `CC_STATUSLINE_PROFILE=project`). Discoverable: slash command (`/statusline-profile project`). Persistent: config-file. Operator decides — likely env var for simplicity.

## Ordering note

This module is **ordered before M005** (First specialized feature module — Suricata/PolarProxy) per operator directive 2026-05-05. The SFIF stream becomes:

| Order | Module | SFIF stage |
|---|---|---|
| 1 | M001 | Scaffold |
| 2 | M002 | Scaffold-Design |
| 3 | M003 | Foundation |
| 4 | M004 | Infrastructure |
| **5** | **M011 (this module)** | **Features** |
| 6 | M005 (Suricata/PolarProxy first) | Features |

Module IDs are slugs, not strict order. Numbering preserved (no renumbering churn) — operator decides if/when to renumber.

## Tasks

Preliminary tasks authored cycle 20 (per F-eval-6 closeout, with researched ccstatusline content from sirmalloc/ccstatusline v2.2.12):

- [T062 — Scope ccstatusline widget set (built-in standard + custom project-aware)](../tasks/T062-m011-scope-widget-set.md)
- [T063 — Profile mechanism design (config-file-per-profile + switch UX)](../tasks/T063-m011-profile-mechanism.md)
- [T064 — Vendor research + integration approach](../tasks/T064-m011-vendor-integration-approach.md)
- [T065 — Surface decisions for operator (M011 prelim closeout)](../tasks/T065-m011-surface-decisions-for-operator.md)

## Implementation deliverables (cycles 29-35, M011 active-impl)

Per operator clarification 2026-05-05 cycle 33 ("I didn't put a brake on ccstatusline"), M011 advanced from preliminary into active-impl:

| Deliverable | Path | Cycle | Purpose |
|---|---|---|---|
| Custom widget shell scripts | `$HOME/templates/ccstatusline-widgets/{selected-task,progress,stage}.sh` | 29 | Custom Text widget data sources for project-aware fields |
| Profile JSON templates | `$HOME/templates/ccstatusline-config/profile-{project,standard}.json` | 30 | Two named profiles (project-aware vs session-aware), JSON-valid |
| Profile switcher | `$HOME/templates/ccstatusline-config/switch-profile.sh` | 33 | Operator-facing CLI: status/list/path/set; state at `~/.config/ccstatusline/active-profile` |
| Claude Code statusLine wrapper | `$HOME/templates/ccstatusline-config/claude-code-statusline-wrapper.sh` | 33 | Reads active-profile + invokes ccstatusline with right --config; graceful fallback |
| install.sh op 6 (op_install_ccstatusline) | `$HOME/install.sh` | 34 | npm install + deploy templates + profile + wrapper |
| settings.json statusLine.command wiring (idempotent jq patch) | install.sh op 6 | 35 | Adds `statusLine: {type: command, command: <wrapper-path>}` to deployed settings.json |

Module readiness 30 → 75 across cycles 29-35.

Remaining for M011 closure (operator-driven future-session):
- Run actual install on a host with npm + ccstatusline; verify the rendered statusline
- Customize profile JSONs per operator preference (current: ~best-guess at v2.2.12 widget catalog)
- Possibly: extend with operator-named profiles beyond the 2 default (project, standard)

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- ORDERED BEFORE: [[root-modules-m005-first-specialized-feature-module|M005 — Suricata/PolarProxy first feature]]
- RELATES TO: [[root-modules-m003-foundation-hardening|M003 — Foundation hardening]] (statusline reads project state, which the foundation must keep stable)

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M005 — First specialized feature module]]
