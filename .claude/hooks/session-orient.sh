#!/usr/bin/env python3
# session-orient.sh — SessionStart hook: frame conversation + direct agent to invoke
# /orient via structured additionalContext (~85% determinism vs ~70% plain stdout).
#
# Wired event: SessionStart · matcher: (any) · companion: session-start.sh
# Strictness tier (per .claude/rules/hook-architecture.md): **Advisory** —
#   directive injected via additionalContext (~85% generative compliance)
# Self-gate (per SB-088): CLAUDE_PROJECT_DIR == $HOME (or cwd starts with $HOME)
#   to prevent cross-firing into sister-project sessions; sister sessions silent
#   pass-through (exit 0). Plus BOOTSTRAP.md presence check.
# SB closures: SB-088 (cross-fire prevention via cwd-aware self-gate)
# Cross-refs: .claude/hooks/README.md (DRAFT v1) · .claude/commands/orient.md
#             (the deterministic 21-step intel chain this hook directs to) ·
#             BOOTSTRAP.md (one-page cold-pickup guide loaded by /orient) ·
#             wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
#             (brain-improvement mandate /orient discipline — operator-yes-per-file
#               protocol established in this session is part of /orient awareness)
#
# Architecture (per operator directive 2026-05-05):
#   - Hook = imperative directive injected via additionalContext (agent generatively
#     complies, but structured-imperative format raises compliance ~70 → ~85%)
#   - Command (/orient) = deterministic chain the harness executes (100% once invoked)
#   - This hook = "invoke /orient NOW" — passes the determinism baton to the command.
#
# Output format (per Claude Code hook docs https://code.claude.com/docs/en/hooks.md):
#   {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}
#
# Self-gates via BOOTSTRAP.md presence so generic root-shell sessions exit silent.

import json
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path.home()


def main() -> None:
    # Read stdin once (so we can both diagnose AND parse).
    raw_stdin = ""
    try:
        raw_stdin = sys.stdin.read()
    except Exception:
        pass

    # Diagnostic trace — fires UNCONDITIONALLY before any gate logic.
    # Empirically observe what Claude Code passes per session for
    # CLAUDE_PROJECT_DIR + cwd + stdin shape. Cycle 95+ hook-fix iteration.
    try:
        from datetime import datetime as _dt
        ws_pd = ""
        cur_dir = ""
        try:
            _p = json.loads(raw_stdin) if raw_stdin else {}
            ws = _p.get("workspace", {}) or {}
            ws_pd = ws.get("project_dir") or ""
            cur_dir = ws.get("current_dir") or _p.get("cwd") or ""
        except Exception:
            pass
        with open("/tmp/hook-fire-trace.log", "a") as _f:
            _f.write(
                f"[{_dt.now().isoformat()}] hook=session-orient.sh "
                f"cwd={os.getcwd()} "
                f"home={os.environ.get('HOME', '')} "
                f"claude_proj={os.environ.get('CLAUDE_PROJECT_DIR', '<unset>')} "
                f"stdin_len={len(raw_stdin)} "
                f"workspace.project_dir={ws_pd} "
                f"workspace.current_dir_or_cwd={cur_dir}\n"
            )
    except Exception:
        pass

    def _trace_exit(tag: str) -> None:
        try:
            from datetime import datetime as _dt2
            with open("/tmp/hook-fire-trace.log", "a") as _f:
                _f.write(f"[{_dt2.now().isoformat()}] hook=session-orient.sh exit_path={tag}\n")
        except Exception:
            pass

    # Self-gate: only orient if this IS a root-modules session
    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        _trace_exit("bootstrap-missing")
        sys.exit(0)

    # Parse stdin JSON for project_dir / cwd (per SB-087b: env+cwd unreliable
    # in hook subprocess; stdin is the reliable source).
    payload = {}
    try:
        payload = json.loads(raw_stdin) if raw_stdin else {}
    except Exception:
        pass

    # Cross-firing prevention via stdin (fail-OPEN: when uncertain, fire,
    # so $HOME sessions never get silenced. Suppress only on positive
    # evidence that calling project != PROJECT_ROOT).
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
                # Positive evidence of mismatch (e.g. /opt second-brain) → silent
                _trace_exit(f"suppress-on-mismatch:{c_norm}")
                sys.exit(0)
            break  # found a candidate; if matched, fall through to fire

    additional_context = """═══════════════════════════════════════════════════════════════════════════
ROOT-GHOSTPROXY — NEW SESSION DETECTED
═══════════════════════════════════════════════════════════════════════════

You are inside root-modules. system AI safety setup IaC at OS root level.
type=root, group=operating-system-setup. Operating doctrine: spec-driven
development. Sister of <second-brain>/.

THIS IS A NEW CONVERSATION. You have NO MEMORY of any prior session.
Each Claude Code session starts cold. Therefore:

  ⚠️  Before responding to the FIRST user message — even a casual "Hi" —
      you MUST gather the project intel. The user prompt arriving at all
      is sufficient to require this. Conversation IS work; intelligence
      requires the brain be loaded.

  Do NOT respond with "What would you like to work on?" — that's the
  failure mode that broke the previous test session.

INVOKE /orient NOW. THIS IS YOUR FIRST ACTION.

  /orient is at $HOME/.claude/commands/orient.md — a deterministic
  21-step chain: Read brain (BOOTSTRAP, CONTEXT, 6 rules), Read backlog
  index, Read most-recent <project>/wiki/log/ + <second-brain>/raw/notes/, verify
  methodology engine + second-brain reachability + sister-projects.yaml
  registration + git state, detect active mode, then emit a structured
  ORIENT REPORT (SFIF stage, modules, pending decisions, active mode,
  next-best-actions).

  After /orient completes, respond to the user's first message with full
  project awareness. Surface the 6 pending operator decisions on a
  casual "Hi" — that's the intelligent response.

MODES FEATURE (mention once, do NOT auto-enable):
  Three modes available: /mode-pm (PM Scrum Master), /mode-architect
  (DevOps Architect), /mode-dual (both lenses). Combined with
  /loop <interval> /cycle, modes enable autopilot — the agent can
  drive the wiki LLM PM workstream automatically. Mode-entry is
  operator-choice (per directive 2026-05-05); NEVER auto-enable.
  If no mode is set, briefly mention the option in the orient report
  + stand by for operator's call.

WHY commands instead of just hook directives:
  Hook output is a directive injected into your context — you generatively
  comply (~85% reliable when delivered via additionalContext like this).
  A slash command, when invoked, is executed by the Claude Code harness
  (100% once invoked). The hook's job is to make you invoke /orient;
  /orient's job is to do the deterministic work.

═══════════════════════════════════════════════════════════════════════════"""

    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": additional_context,
        }
    }
    print(json.dumps(output))
    _trace_exit("fired-additionalContext")
    sys.exit(0)


if __name__ == "__main__":
    main()
