---
title: "T064 — M011 vendor research + integration approach (sirmalloc/ccstatusline npm install + Claude Code wiring)"
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
  - id: ccstatusline-github
    type: external
    url: https://github.com/sirmalloc/ccstatusline
  - id: ccstatusline-npm
    type: external
    url: https://www.npmjs.com/package/ccstatusline
tags: [task, p1, t064, m011, ccstatusline, vendor-research, integration, design]
---

# T064 — Vendor research + integration approach for M011

## Vendor (researched cycle 20)

| Field | Value |
|---|---|
| Project | `sirmalloc/ccstatusline` |
| License | MIT |
| Latest | v2.2.12 |
| Last push | 2026-05-04 |
| Stars | 8741 |
| Language | TypeScript |
| Runtime | Node.js |
| Distribution | npm: `ccstatusline` |
| Repo | https://github.com/sirmalloc/ccstatusline |

## Claude Code integration (per ccstatusline README)

Claude Code consumes a statusline via the `statusLine` setting in `~/.claude/settings.json`. ccstatusline configures itself to be invoked there. From v2.1.97 of Claude Code, ccstatusline can also set `statusLine.refreshInterval` from its TUI.

ccstatusline's own data sources:
- Claude Code's status JSON (token counts, model, context, session info)
- `~/.claude.json` (account email)
- Streaming JSONL (token counts, deduplication for accuracy)
- Shell commands (git widgets shell out to `git`, `gh`, `glab`)
- Environment variables (e.g., `HTTPS_PROXY`)

## Integration approach options

| Option | How | Notes |
|---|---|---|
| **A: System-install via npm** | `npm install -g ccstatusline` + configure via TUI + commit `~/.claude/settings.json` integration | Standard; well-supported |
| **B: Vendored npm in $HOME** | `npm install` locally to `$HOME/vendor/ccstatusline` + invoke via `node` path | Per-project isolation but adds maintenance |
| **C: Vendor manifest + install.sh integration** | M012 (vendor mapping) tracks ccstatusline as a vendor; install.sh runs the npm install during foundation setup | Methodology-aligned with M012 vendor pattern |

Recommend **C** (composes with M012 — vendor manifest + install.sh integration). Aligns with root-modules's IaC discipline.

## Custom widget data sources (ties to T062)

Custom Text widget invokes a shell command. For project-aware fields:

| Field | Shell command (preliminary) |
|---|---|
| selected-task | `cat $HOME/.claude/active-task 2>/dev/null \|\| echo "(none)"` |
| progress | `python3 -m tools.progress --callout 2>/dev/null \| grep readiness \| awk '{print $3}'` |
| stage | `python3 -m tools.state --field current-sfif-stage 2>/dev/null` |

(Exact paths/commands finalized after T062.)

## Done When

- [ ] Vendor identity confirmed (sirmalloc/ccstatusline) — DONE
- [ ] Integration approach picked (A/B/C)
- [ ] If C: M012 vendor manifest entry drafted for ccstatusline
- [ ] Claude Code settings.json integration snippet drafted

## Dependencies

- T062 (widget set) — informs what custom widgets need data
- T063 (profile mechanism) — informs install steps (single config vs multi)
- M012 (vendor mapping) — if integration approach C picked

## Relationships

- PART OF: [[root-modules-m011-ccstatusline-statusline-widget|M011]]
- BLOCKED BY: T062, T063
- BLOCKS: T065 (operator decisions)
- RELATES TO: [[root-modules-m012-vendor-mapping-install-and-auto-detect|M012]]
