# $HOME/.claude/rules/hook-architecture.md — Hook design + 2-layer architecture for root-ghostproxy

> Loaded on demand when hooks are designed, debugged, or invoked. CLAUDE.md + AGENTS.md have summaries; this file has the project-specific detail.
>
> **Strictness tier** (per `operating-principles.md`): **Strict** — the 2-layer architecture invariant + the 3-component hook design pattern (insertion point + reason + remediation) MUST hold. Bypass mechanism per hook is **Enforced** (deny + reason + remediation). Status notes (current vs draft) are **Advisory** until T006 reconciles.

## Two-layer hook architecture (this project)

Per AGENTS.md: machine-level hooks fire BEFORE project-level hooks.

| Layer | Path | Owner | Purpose |
|---|---|---|---|
| **Machine-level** | `$HOME/.claude/hooks/` | root user (this project's deliverable) | OS-level safety envelope: deny secrets, deny dangerous bash, leak-detection on output, session-start banner, session-end summary. Fires first regardless of which project the user is operating in. |
| **Project-level** | `/$HOME/.claude/hooks/` | per-project | Workflow-specific enforcement (ingestion gates, output discipline, etc.). Fires after machine-level. |

Currently this project has machine-level hooks only. Project-level hooks (e.g., for /root-as-a-project workflows) are scaffolded but unwired.

## Wired hooks (machine-level — currently 7 fires across 5 events)

Settings: `$HOME/.claude/settings.json`. All scripts at `$HOME/.claude/hooks/` and named `*.sh` but **are Python** (`#!/usr/bin/env python3` shebang) — extension is misleading but functional.

| Event | Matcher | Hook | Reason |
|---|---|---|---|
| PreToolUse | `Read\|Bash\|Edit\|Write\|NotebookEdit\|Glob\|Grep\|WebFetch\|WebSearch\|Agent\|TaskCreate\|TaskUpdate\|mcp__.*` | `policy-block.sh` (Python) | Deny reads of secret patterns (.env, *.pem, id_rsa, credentials, etc.). |
| PreToolUse | `Bash\|Edit\|Write\|NotebookEdit` | `malware-block.sh` (Python) | Block dangerous bash patterns (rm -rf /, fork bombs, etc.). |
| PreToolUse | `Write\|Edit\|NotebookEdit` | `opt-write-block.sh` (Python) | Block knowledge-content writes to /opt second-brain (cross-project boundary); allow operational-config writes via documented bypass per SB-098. |
| PostToolUse | `Read\|Bash\|WebFetch\|Grep` | `leak-detector.sh` (Python) | Scan tool output for leaked secret patterns; log to `$HOME/.claude/hooks/leaks.log`. |
| SessionStart | (any) | `session-start.sh` (Python) | Print one-line confirmation that policy hooks are active. |
| SessionStart | (any) | `session-orient.sh` (Python) | Project-priming via `additionalContext` JSON; directs agent to invoke `/orient` for the deterministic 21-step intel-gathering chain. Self-gates via BOOTSTRAP.md + `CLAUDE_PROJECT_DIR` cross-fire prevention (SB-088). |
| UserPromptSubmit | (any) | `context-warning.sh` (Python) | Surface % context remaining at strategic thresholds (5/3/2/0%) so operator strategic-compaction decision is informed. Pure observability. |
| UserPromptSubmit | (any) | `output-discipline-guard.sh` (Python, agent-discipline-gate) | Per SB-090 + SB-094 + SB-108: high-confidence-only premise-construction-risk + operator-escalation detection. Single-line concise banner via `additionalContext` when triggered; silent on routine prompts. Closes detection layer for SB-090 / SB-094 / SB-105 / SB-107 / SB-111 family. |
| UserPromptSubmit | (any) | `mode-enforcement.sh` (Python) | Per SB-056: dynamic mode-file parsing (Persona, Persona-voice-table, /cycle-sequence) + live-state cross-reference (open + recurring SBs from tracker, recent log slugs, task cursor) + objective layer (mission, focus, impediment from `$HOME/.claude/active-{mission,focus,impediment}` per SB-118). Injects per-prompt persona/discipline/state reminder via `additionalContext` when an active-mode is set. **No length cap** (SB-122 closure 2026-05-06: capping operator-explicit content was self-imposed agent-courtesy + dismissed operator directives). sys.path-injected for cwd-independent imports; 8 error-path branches each diagnostically traced. Silent when no active-mode. |
| UserPromptSubmit | (any) | `mindfulness.sh` (Python) | Per SB-126 (operator directive 2026-05-06): mindfulness baseline reminder fires per-prompt when active-mode set. 4-clause compact reminder via `additionalContext`: (1) one-notch-not-extreme (SB-082/093 pendulum); (2) confirm-don't-construct (SB-090 premise); (3) artifacts-flagged-as-agent-draft (SB-095 hallucinated-artifacts); (4) forward-not-freeze (SB-099 abdication). Compounds with mode-enforcement + output-discipline-guard + context-warning (each emits separate additionalContext). Steady baseline (not under-pressure-trigger like output-discipline-guard) — addresses pre-trigger prevention per operator's compound directive. Silent when no active-mode. |
| PreCompact | (any) | `pre-compact.sh` (Python) | Per SB-078: write deterministic state snapshot to `wiki/log/<ts>-pre-compact-handoff.md` before compaction destroys nuance; `additionalContext` directs post-compact agent to read it. |
| PostCompact | (any) | `post-compact.sh` (Python) | Warn about behavioral-state degradation post-compaction; chain to `/orient` + reads most-recent pre-compact-handoff doc for state recovery. |
| Stop | (any) | `end-of-cycle-stamp.sh` (Python) | Per SB-114/SB-115: emit end-of-turn status stamp via `systemMessage` (the only valid display channel for Stop hook per Claude Code schema). Reads `$HOME/.claude/stamp-config.json` for layout (horizontal/vertical) and enabled (on/off/auto) — slash-command-driven config via `tools/stamp.py`. DRAFT per SB-116 UX redesign Epic. |
| SessionEnd | (any) | `session-summary.sh` (Python) | Print session-end summary. |

## Hook design pattern (every hook MUST follow)

Three load-bearing components:

1. **Logical insertion point** — fire at the right Claude Code lifecycle event with the right matcher. Wrong insertion = misses the rule or false-positives unrelated calls.
2. **Logical reason** — explain WHY it acted. A hook that blocks with no reason is a black box. Print: `BLOCKED: <action>. REASON: <rule>. <citation>`.
3. **Remediation offer** — offer the correct alternative. Print: `INSTEAD: <correct command>. BYPASS: <how to legitimately escalate>`.

## Bypass / escalation

Hooks must offer a documented bypass for legitimate cases. Blind enforcement creates its own failures. Patterns:
- Env-var bypass: `REASON=<reason>` env var on the bash call documents why a normally-blocked action is justified.
- Operator override: hook defers to operator approval if operator-PR-approved.
- Logged exception: hook allows but logs to `$HOME/.claude/hooks/<event>.log` for audit.

## Status (this project)

The 14 wired machine-level hook fires (8 distinct events: PreToolUse + PostToolUse + SessionStart + UserPromptSubmit + PreCompact + PostCompact + Stop + SessionEnd) are functional but **not yet operator-confirmed canonical** for all of them. T006 (prior-debris reconciliation) decides which artefacts at $HOME are operator-authoritative vs prior-session debris. Until T006, the hooks fire actively but their canonical status is provisional. False-positive refinement queued at M003 task **T-M003-7**. New 2026-05-06 additions (pending operator-empirical): `output-discipline-guard.sh` UserPromptSubmit (SB-108), `end-of-cycle-stamp.sh` Stop (SB-114/115 — DRAFT per SB-116), `mode-enforcement.sh` UserPromptSubmit (SB-056 — closes mode-not-felt at runtime layer with dynamic mode-file parsing + live-state cross-reference).

## Cross-references

- Universal hook architecture (canonical, second brain): `<second-brain>/.claude/rules/hook-architecture.md`
- AGENTS.md two-layer hook architecture section.
- ARCHITECTURE.md hook firing order section.
