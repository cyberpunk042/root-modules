---
title: "2026-05-06 — Project-level opt-out of globally-installed hooks (design note, future-decision)"
type: log
domain: cross-domain
status: design-note
confidence: medium
maturity: seed
created: 2026-05-06
updated: 2026-05-06
sources:
  - id: operator-directive-2026-05-06-project-hook-optout
    type: directive
tags: [log, design, hooks, opt-out, kill-switch, project-level, future-decision, sacrosanct, verbatim]
---

# Project-level hook opt-out — design note

## Operator directive (verbatim, sacrosanct)

> "also I am thinking about this and I dont remember if I thought about this. it should be possible for project to opt out of the hooks when they are installed globally right ? not that I have such a need for now but It might happens instantly and I want to 'turn everything off in one shot'.. not to deroute you."

## Use case

Hooks installed at `$HOME/.claude/` (user-level) fire automatically across ALL projects (since Claude Code merges user-level settings.json into every session). A specific sister project (e.g., `/opt/devops-solutions-information-hub`) may need to **opt out completely** — turn ALL hooks off in one shot for that project's sessions, while leaving other projects' inheritance unchanged.

This is the inverse of `/install-agent-brain <path>` (which deploys MORE into a target). Opt-out = make the target IGNORE what's globally inherited.

## Approaches (4 considered)

| # | Approach | Mechanism | "One shot off" | Granularity | Complexity |
|---|---|---|---|---|---|
| **A** | Sentinel file at project | `<project>/.claude/disable-global-hooks` (or `no-global-hooks`) — each hook self-gates by checking this file | `touch <project>/.claude/disable-global-hooks` | All-or-nothing per project | Low — one helper fn checked at top of each hook |
| **B** | Project settings.local.json override | Use Claude Code's `disableAllHooks: true` in project's settings.local.json | Edit one settings file per project | All-or-nothing per project | Lowest — uses existing Claude Code mechanism |
| **C** | Per-hook list file | `<project>/.claude/disabled-hooks` containing comma- or newline-separated hook names | Edit list per hook | Granular (per-hook) | Medium — each hook reads + parses list |
| **D** | Env var | `CLAUDEC_GLOBAL_HOOKS_DISABLED=1` checked by all hooks | export env var per shell | Session-scoped (not project-scoped) | Low but session-scoped not project-scoped |

## Recommendation (operator review when scoped)

**Approach B is preferred** — uses Claude Code's existing platform mechanism (no custom check needed in each hook). Concretely: add `"disableAllHooks": true` to `<project>/.claude/settings.local.json` (per-project, gitignored — operator-machine-specific by design).

But Approach A is the cleanest if operator wants a SENTINEL FILE (more explicit + visible than a JSON setting). Trade-off: sentinel = visible single file, easy to flip; settings.local.json = uses existing Claude Code semantics, no new mechanism.

Hybrid: deploy a slash command `/hooks-off` that toggles BOTH (creates sentinel + edits settings.local.json) so operator can do "one shot" from any project session.

## Implementation cost (when operator scopes)

- **Approach A**: ~5 lines per hook (sentinel-check helper) + ONE shared helper at `.claude/hooks/_lib.py` — about 30min total.
- **Approach B**: zero code change in our hooks (Claude Code already implements `disableAllHooks`); operator just edits target's settings.local.json. About 5 minutes operator-facing.
- **Both**: optional `/hooks-off <target-path>` slash command (writes both for belt-and-braces).

## Status

Design note only — NOT scoped or implemented. Per operator: *"not that I have such a need for now"*. Logged as future-decision so the requirement isn't lost.

## Cross-references

- `/install-agent-brain` slash command (the additive complement to this opt-out)
- Wizard design doc: `wiki/log/2026-05-06-install-wizard-granular-state-aware-design.md`
- Relevant rule: `.claude/rules/hook-architecture.md` (when hooks fire + how to gate)
- Operating principle #2 (always flexible) — opt-out IS the flexibility this principle implies
