---
title: "T063 — M011 profile mechanism design (config-file-per-profile + switch UX)"
type: task
status: in-progress
priority: P1
parent_module: "root-modules-m011-ccstatusline-statusline-widget"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 80
sfif_stage: Features
created: 2026-05-05
updated: 2026-05-05
sources:
  - id: ccstatusline-readme
    type: external
    url: https://github.com/sirmalloc/ccstatusline/blob/main/docs/USAGE.md
tags: [task, p1, t063, m011, ccstatusline, profile-mechanism, design]
---

# T063 — Profile mechanism for M011

## Description

Operator wants multiple loadable profiles (project-aware mode vs standard mode). ccstatusline supports `--config <path>` flag (v2.1.8+) for custom config file location. This enables one config file per profile.

## Mechanism (researched cycle 20)

ccstatusline default behavior:
- Reads config from default location (TUI-configured)
- `--config <path>` overrides location
- Each config = one statusline definition

Profile mechanism options:

| Option | How it works | Pros | Cons |
|---|---|---|---|
| **A: Multiple config files + env var** | `~/.config/ccstatusline/profile-project.json` + `~/.config/ccstatusline/profile-standard.json`; `CC_STATUSLINE_CONFIG` env var picks one; ccstatusline launched with `--config $CC_STATUSLINE_CONFIG` | Simple; profile-switch via env | Requires shell wrapper or Claude Code config edit per profile change |
| **B: Slash command in Claude Code** | `/statusline-profile project` writes the env var or symlinks the active config | Most discoverable | Requires Claude Code custom command |
| **C: Persistent config-file directive** | One config file with conditional widget rendering based on directory or env signal | Single-file simplicity | Requires custom widget logic; limits profile scope |

## Done When

- [ ] Operator picks profile-switch mechanism (A / B / C / hybrid)
- [ ] Profile config file paths + naming convention defined
- [ ] Switch command (slash / shell wrapper) authored if A or B picked

## Dependencies

- T062 (widget set scope) — informs what each profile contains

## Relationships

- PART OF: [[root-modules-m011-ccstatusline-statusline-widget|M011]]
- BLOCKED BY: T062
- BLOCKS: T064 (vendor integration), T065 (operator decisions)
