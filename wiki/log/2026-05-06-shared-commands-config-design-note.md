---
title: "2026-05-06 — Shared-commands config — global-by-default + per-project flexibility (design note)"
type: log
domain: cross-domain
status: design-note
confidence: medium
maturity: seed
created: 2026-05-06
updated: 2026-05-06
sources:
  - id: operator-directive-2026-05-06-missing-shared-commands-config
    type: directive
tags: [log, design, slash-commands, sharing, config, global, per-project, flexibility, sacrosanct]
---

# Shared-commands config — design note

## Operator directive (verbatim, sacrosanct)

> "This is what I meant about a missing piece. a missing config to share them globally and let them remain flexible."

(Surfaced after observing /terminate + /finish-smoothly visible live in `/root` TTY but not in `/opt` TTY.)

## The missing piece

Claude Code's existing slash-command discovery:
- `$HOME/.claude/commands/*.md` — **user-level**, inherited by all sessions of that user
- `$PROJECT/.claude/commands/*.md` — **project-level**, overrides user-level on name conflict

For root-user (this dev host), `$HOME = /root` AND `$PROJECT = /root` for root-ghostproxy → SAME path (Path-A collision per SB-087). User-level commands are also project-level commands here.

For `/opt/devops-solutions-information-hub` session:
- `$HOME = /root` → user-level still resolves to `/root/.claude/commands/`
- `$PROJECT = /opt/devops-solutions-information-hub` → project-level at `/opt/.../.claude/commands/`

User-level inheritance SHOULD make /root commands visible in /opt session. **Empirically inconsistent**: live-added commands appear in /root TTY immediately but /opt TTY doesn't always pick them up the same way (cache/discovery-timing asymmetry between sessions).

This is the "missing piece" — there's no first-class config that says *"share these commands globally + let projects remain flexible to override or opt-out"*. The behavior is inferred from path-precedence rules, not declared.

## What "share globally + remain flexible" needs

| Capability | Today | Want |
|---|---|---|
| **Global definition** | Implicit via `$HOME/.claude/commands/` | Same — but explicit in config (manifest) |
| **Per-project visibility** | Implicit user-level inheritance (timing-inconsistent) | Reliable — declared as "include shared commands: yes" |
| **Per-project override** | Project-level command shadows user-level on name conflict (works) | Same |
| **Per-project opt-out** | None | Project can declare "don't include shared command X" or "exclude all shared" |
| **Per-project additions** | Project-level `.claude/commands/` (works) | Same |
| **Discovery: live across sessions** | Inconsistent (/root sees live; /opt may not) | Reliable — explicit re-scan trigger or settings flag |

## Approach options (4 considered)

### Approach A — Manifest file at user-level
**Mechanism**: `$HOME/.claude/shared-commands.json` lists commands marked "shareable":
```json
{
  "shared_commands": ["orient", "handoff", "terminate", "finish-smoothly", "stamp-on", ...],
  "version": 1
}
```
Each project's `.claude/settings.local.json` opts in via `"include_shared_commands": true|"all"|<list>` or opts out.

Trade-offs: explicit + auditable; adds a new mechanism Claude Code doesn't natively understand → would need a wrapper or re-scan helper that materializes commands per project per the manifest.

### Approach B — Symlink projects' `.claude/commands/` to a shared dir
**Mechanism**: `/opt/.../.claude/commands/` becomes a symlink (or contains symlinks) to `/root/.claude/commands/` files. Project-specific overrides live as real files alongside.

Trade-offs: works with Claude Code's existing discovery (symlinks are transparent); per-project override is messy (need symlink management); not "config-driven" — file-system convention only.

### Approach C — install.sh + /install-agent-brain handles propagation
**Mechanism**: When operator runs `/install-agent-brain <target>`, the target's `.claude/commands/` gets a copy of all `$HOME/.claude/commands/`. New commands authored later → operator re-runs install (or a `/sync-commands <target>` command).

Trade-offs: copy-not-link → drift over time (target's copy is frozen); need re-sync flow. Simplest mechanism but least "global" (each target has its own copy).

### Approach D — settings.json `commandsDir` array (if Claude Code supports)
**Mechanism**: Claude Code's `settings.json` adds:
```json
{
  "commandsDirs": [".claude/commands", "$HOME/.claude/commands", "/etc/claude-code/shared-commands"]
}
```
Discovery walks all listed dirs in order; later entries override earlier on name conflict.

Trade-offs: would be the cleanest — declarative + flexible. Requires Claude Code feature support (research needed: claude-code-guide). If supported, this is the win.

## Resolution (2026-05-06)

Operator correction: *"lol we are talking about user level lol what do you think $Home is ?"*

The "missing piece" was **already solved** by Claude Code's existing user-level inheritance:

- `$HOME/.claude/commands/*.md` IS the user-level (= global for that user)
- For root user: `$HOME = /root` → `/root/.claude/commands/` IS globally inherited by every session run by root user
- `<project>/.claude/commands/` overrides user-level on name conflict (Claude Code's default; gives per-project flexibility)
- Per-project opt-out: project simply doesn't add a same-named file (then user-level wins) — no extra mechanism needed

The asymmetry observed earlier (/root TTY saw live-added commands, /opt TTY didn't right away) was **discovery TIMING** (cache window per session), not a missing config mechanism. Both sessions read user-level; cache freshness varies.

**No new tooling needed.** The v0 path (author commands at `$HOME/.claude/commands/`) already gives the "share globally + remain flexible" capability operator wanted. v1 sync-helper proposal is unnecessary; struck.

## What this means in practice

- `/terminate` + `/finish-smoothly` authored at `/root/.claude/commands/` = user-level = available to all sessions of root user (with discovery-cache-window caveat).
- For sister-project sessions wanting an OVERRIDE: drop a same-named file in their `.claude/commands/`.
- For sister-project sessions wanting OPT-OUT: don't override; if Claude Code's deeper opt-out mechanism becomes needed, see hook-optout design note for parallel approaches.

## Research result archive (still useful for future questions)

Per claude-code-guide research 2026-05-06: Claude Code's official documentation:
- No `commandsDirs` array, `commandsPath`, or equivalent multi-directory configuration in settings.json
- Discovery is FIXED to two locations: `~/.claude/commands/` (user-level) + `./.claude/commands/` (project-level)
- Live discovery during active session: undocumented (operator-observed live-pickup is unofficial)
- Symlinks: not addressed in docs (untested + unsupported)

Sources: code.claude.com/docs/en/{settings,claude-directory,commands,skills}

Approaches A/B/D NOT pursued. Approach C (`/install-agent-brain` propagation) remains useful for non-Path-A sister projects where `$HOME` differs from /root.

## Operator-decision points

| # | Question | Options |
|---|---|---|
| Q1 | Research Claude Code for `commandsDirs` settings.json support? | (a) Yes — first checking via claude-code-guide  (b) Skip — assume it doesn't exist |
| Q2 | If Approach A picked: manifest format — flat list, or per-command policies (shared/exclusive/override-allowed)? | (a) Flat (b) Per-command |
| Q3 | Sync mechanism — operator-invoked (/sync-shared-commands) OR auto on install.sh re-run? | (a) Manual command (b) Auto in install (c) Both |
| Q4 | Live-update propagation — out-of-scope for v1? | (a) v1 is sync-on-demand only; v2 adds watch (b) v1 includes watch |
| Q5 | Override convention — project-level `.claude/commands/` always wins on name conflict (current Claude Code default)? | (a) Yes (default behavior) (b) Configurable per command via manifest |

## Status

Design note only. NOT implemented. Per operator framing — surfaced as "missing piece" without scoping yet. Awaits operator pick on Approach + answers to Q1–Q5.

## Cross-references

- `/install-agent-brain` slash command (the additive deploy path; partial Approach C today)
- `wiki/log/2026-05-06-project-level-hook-optout-design-note.md` (sister design note for hooks opt-out — same shared-vs-flexible tension)
- Operating principle #2 (always flexible) — this design captures the flexibility-by-config the principle implies
- Claude Code platform: research needed for `commandsDirs` settings.json support
