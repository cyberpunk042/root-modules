---
title: "T006 — Decide reconciliation for prior $HOME debris files"
type: task
status: done
priority: P1
parent_module: "root-modules-m001-author-claude-md-and-agents-md"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 100
sfif_stage: Scaffold
created: 2026-05-04
updated: 2026-05-05
decision_date: 2026-05-05
decision: "LEAVE-IN-PLACE — prior debris is non-authoritative per operator (per CLAUDE.md Hard Rule #8 + AGENTS.md Hard Rule #5); M003 proceeds as-if virgin; cleanup orthogonal/deferred"
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m001-author-claude-md-and-agents-md.md
  - id: operator-directive-forget-everything
    type: directive
    description: "Operator 2026-05-05: 'I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST'"
tags: [task, p1, t006, scaffold, prior-debris, operator-decision-pending, m001]
---

# T006 — Decide reconciliation for prior $HOME debris files

## Description

The $HOME directory contains AI-debris from a prior session that the operator has explicitly stated is not authoritative:

| Prior-debris path | What it was |
|---|---|
| `$HOME/install.sh` (the one from prior session) | Idempotent installer for the prior scope (Claude+opencode hardening) |
| `$HOME/uninstall.sh` (prior) | Inverse of prior install.sh |
| `~/.claude/settings.json` (prior) | Deny patterns + hooks config |
| `~/.claude/hooks/policy-block.sh, malware-block.sh, leak-detector.sh, session-start.sh, session-summary.sh, integrity.py` (prior) | Prior session's hook scripts |
| `~/.config/opencode/opencode.json + plugin/claude-bridge.ts + plugin/package.json` (prior) | Prior opencode bridge plugin |
| `~/.claude/projects/-root/memory/` (prior) | Auto-memory from prior session — operator explicitly rejected: *"I DO NOT WANT TO USE THE FUCKING MEMORY FOLDER... I NEVER FUCKING TALKED ABOUT IT"* |

The decision: do these get **deleted** (clean slate for re-author), **left in place** (pending re-author at M003 time), or **partially preserved** (e.g. keep the integrity.py concept as a starting point but re-author from scratch)?

## Done When

- [x] Operator decides reconciliation policy: **LEAVE-IN-PLACE** (effective decision per multi-session operator-verbatim — see Decision section).
- [x] Decision documented in $HOME/wiki/log/ — multiple operator-verbatim logs this session.
- [N/A] Delete path not chosen.
- [x] Leave-in-place: M003 work block proceeds as-if virgin (per operator); foundation gate at M003 will verify project's own implementation (not prior debris) passes. Confirmed by T011's greenfield decision.
- [N/A] Partial preserve not chosen.

## Decision (2026-05-05)

**Leave-in-place** — prior $HOME debris (install.sh, uninstall.sh, ~/.claude/settings.json, hooks, integrity.py, opencode bridge plugin, ~/.claude/projects/-root/memory/) remains physically present BUT is treated as non-authoritative for project intent. Cleanup is orthogonal to foundation work.

**Operator verbatim directives that decided this:**

> *"I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST"*

> *"imagine there is no fucking root-GHOSTPROXY project right NOW.. this whole system is virgin"*

> *"I DO NOT WANT TO USE THE FUCKING MEMORY FOLDER... I NEVER FUCKING TALKED ABOUT IT"* (auto-memory specifically — rejected outright)

These are now formalized in CLAUDE.md Hard Rule #8 + AGENTS.md Hard Rule #5 + Hard Rule #6 (auto-memory).

**Downstream impact:**
- M003 (Foundation hardening) proceeds with greenfield authoring per T011.
- Auto-memory folder: ignored (Hard Rule #6).
- Cleanup of prior files: deferred until foundation work explicitly needs the paths; can be handled per-task as part of M003 rather than as a separate decision.
- M001 (this task's parent) unblocked from this gate.

## Dependencies

- Operator decision (this task is gated on operator authority).

## Notes

- The auto-memory folder is **decided** (delete or ignore — operator-rejected outright).
- The other prior-debris files are **operator-discretion**.
- Until decided, the project's M003 work block proceeds as-if the prior debris does not exist (per the "imagine virgin" framing). The prior files' presence does not block M003; their cleanup or re-author is orthogonal.

## Relationships

- PART OF: [[root-modules-m001-author-claude-md-and-agents-md|M001]]
- RELATES TO: [[root-modules-m003-foundation-hardening|M003]] — M003 authors the project's own implementation; reconciliation policy informs whether to extend or replace prior files
