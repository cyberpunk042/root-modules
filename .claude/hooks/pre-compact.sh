#!/usr/bin/env python3
# PreCompact hook — capture handoff state BEFORE compaction summarizes context away.
#
# Why: Compaction destroys nuance. Operator-verbatim quotes, recent decisions,
# in-flight task state, sub-agent findings, current cycle's SB pick — all
# get lossy-compressed by the summarizer. PreCompact fires BEFORE that, so
# we can capture deterministic state to a handoff doc the post-compact
# orient chain can read back.
#
# Operator directive 2026-05-05 (SB-078): "we should have added a hook that
# should have realize as we get closer to the context limit that we need to
# prepare for compact and do a strong handoff document and register our
# knowledge and learnings before we are forced to compact or such... should
# be ready by that point and keep the handoff up to date as we continue or
# trigger ourself the compact if logical"
#
# Note: agent CANNOT detect approaching-context proactively (no
# context-percentage exposed at runtime per claude-code-guide research
# 2026-05-05). PreCompact fires only WHEN compaction is triggered (auto by
# system at limit, or manual via /compact). The proactive "keep handoff up
# to date" lives in /cycle step 9 + a future skill (F012). This hook owns
# the at-compact-time deterministic snapshot.
#
# Strategy:
#   1. Read in-flight state (active mode, active task, latest cycle, last 5 logs)
#   2. Snapshot to <project>/wiki/log/<date>-pre-compact-handoff.md
#   3. Inject additionalContext directing post-compact /orient to read it
#
# Self-gates via BOOTSTRAP.md presence.

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


# ---------- Portable path resolution ----------
HOME = Path.home()
PROJECT_ROOT = HOME  # type=root project: $HOME == project root
WIKI_LOG = PROJECT_ROOT / "wiki" / "log"


def _resolve_python() -> str:
    """Resolve a Python interpreter that has the project's tools.* importable.

    Tries (in order):
      1. RGP_PROJECT_PYTHON env var (operator override)
      2. <second-brain>/.venv/bin/python (where tools.* deps live)
      3. system python3 (last resort)
    """
    env = os.environ.get("RGP_PROJECT_PYTHON", "").strip()
    if env and os.path.exists(env):
        return env
    sb = os.environ.get("RGP_SECOND_BRAIN_ROOT", "").strip()
    if sb:
        candidate = Path(sb).expanduser() / ".venv" / "bin" / "python"
        if candidate.exists():
            return str(candidate)
    home_sb = HOME / "devops-solutions-information-hub" / ".venv" / "bin" / "python"
    if home_sb.exists():
        return str(home_sb)
    opt_sb = Path("/opt/devops-solutions-information-hub/.venv/bin/python")
    if opt_sb.exists():
        return str(opt_sb)
    return "python3"


PYTHON = _resolve_python()


def safe_run(cmd: list[str], default: str = "") -> str:
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=5).decode().strip()
    except Exception:
        return default


def safe_read(path: str, default: str = "") -> str:
    try:
        return Path(path).read_text().strip()
    except Exception:
        return default


def main() -> None:
    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        sys.exit(0)

    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    # Cross-firing prevention via stdin (fail-OPEN per SB-087b: env+cwd
    # unreliable; suppress only on positive evidence of mismatch).
    project_root_str = str(PROJECT_ROOT).rstrip("/")
    workspace = payload.get("workspace", {}) or {}
    candidates = [
        workspace.get("project_dir"),
        workspace.get("current_dir"),
        payload.get("cwd"),
    ]
    for c in candidates:
        if c:
            c_norm = str(c).rstrip("/")
            if c_norm and not (c_norm == project_root_str or c_norm.startswith(project_root_str + "/")):
                sys.exit(0)
            break

    matcher = payload.get("matcher") or payload.get("trigger") or "auto"
    timestamp = datetime.now().strftime("%Y-%m-%d-%H%M%S")
    handoff_path = str(WIKI_LOG / f"{timestamp}-pre-compact-handoff.md")

    active_mode = safe_read(str(PROJECT_ROOT / ".claude" / "active-mode"), "(none)")
    active_task = safe_read(str(PROJECT_ROOT / ".claude" / "active-task"), "(none)")
    # Objective layer (SB-118) + priorities (SB-127)
    active_mission = safe_read(str(PROJECT_ROOT / ".claude" / "active-mission"), "(unset)")
    active_focus = safe_read(str(PROJECT_ROOT / ".claude" / "active-focus"), "(unset)")
    active_impediment = safe_read(str(PROJECT_ROOT / ".claude" / "active-impediment"), "(none — focus unblocked)")
    active_priorities = safe_read(str(PROJECT_ROOT / ".claude" / "active-priorities"), "(none set)")

    cycle_json = safe_run(
        [PYTHON, "-m", "tools.cycle", "--json"],
        "{}"
    )
    blockers_json = safe_run(
        [PYTHON, "-m", "tools.blockers", "--json"],
        "{}"
    )

    recent_logs = safe_run(
        ["bash", "-c", f"ls -t {WIKI_LOG}/*.md 2>/dev/null | head -5"],
        ""
    )

    git_status = safe_run(["git", "-C", str(PROJECT_ROOT), "status", "--short"], "")

    handoff = f"""# Pre-Compact Handoff — {timestamp}

> Auto-generated by `<project>/.claude/hooks/pre-compact.sh`. Compaction trigger: `{matcher}`.
> This file is the deterministic snapshot of state at the moment compaction was triggered.
> Post-compact /orient should read this to recover everything the summarizer would otherwise lose.

## Active mode

{active_mode}

## Active task

{active_task}

## Objective (mission · focus · impediment) — SB-118

- **Mission**:    {active_mission}
- **Focus**:      {active_focus}
- **Impediment**: {active_impediment}

## Priorities (imminent-work — SB-127)

```
{active_priorities}
```

## Cycle state (tools.cycle --json)

```json
{cycle_json}
```

## Blockers state (tools.blockers --json)

```json
{blockers_json}
```

## Recent logs (last 5 by mtime)

```
{recent_logs}
```

## Git state (uncommitted view)

```
{git_status}
```

## Recovery instructions for post-compact agent

1. Run `/orient` to reload the brain (BOOTSTRAP, CONTEXT, rules).
2. Read this handoff file to recover in-flight state.
3. Read the last 1-2 entries from "Recent logs" above — those carry verbatim operator directives that the summarizer would have erased.
4. Read the last cycle's SB pick from `wiki/governance/systemic-bugs.md` (the most-recently-edited row by file mtime).
5. Re-read CLAUDE.md / AGENTS.md — auto-loaded but worth re-confirming after compaction.
6. ASK the operator: "Pre-compact we were at <task> in <mode>; cycle was driving <SB-pick>. Continue or shift?" — don't assume continuation.

## Notes

- The handoff is deterministic state-capture only. Conversation nuance (operator's tone, mid-flight tradeoffs you and operator already weighed) WILL be lost by the summarizer; this handoff cannot recover that. Operator awareness is the only authoritative source for those.
- If this handoff repeats every few hours, that's a signal to ask operator if a /compact-free workflow is wanted (ScheduleWakeup with longer cadence, or session restart).
"""

    try:
        Path(handoff_path).write_text(handoff)
    except Exception:
        pass

    additional_context = f"""═══════════════════════════════════════════════════════════════════════════
ROOT-GHOSTPROXY — PRE-COMPACT HANDOFF WRITTEN
═══════════════════════════════════════════════════════════════════════════

Compaction is about to run (trigger: {matcher}). State has been captured to:

  {handoff_path}

After compaction, the PostCompact hook will direct you to /orient. AFTER /orient
completes, READ THIS HANDOFF FILE to recover the in-flight state the
summarizer will have erased (operator-verbatim from last logs, cycle's SB
pick, decision packages in flight, sub-agent findings).

DO NOT block this compaction (returning decision=block here is reserved for
genuine "operator just registered new directives that would be lost"
situations). Default: let it proceed; the handoff is sufficient.

═══════════════════════════════════════════════════════════════════════════"""

    # Schema: PreCompact does NOT accept hookSpecificOutput.additionalContext.
    # Use top-level systemMessage (the only operator-visible channel for
    # PreCompact per Claude Code hook schema).
    output = {"systemMessage": additional_context}
    print(json.dumps(output))
    sys.exit(0)


if __name__ == "__main__":
    main()
