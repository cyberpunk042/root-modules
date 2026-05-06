#!/usr/bin/env python3
# context-warning.sh — UserPromptSubmit + PostCompact hook. Surfaces % context
# remaining at strategic thresholds so the operator's strategic-compaction
# decision (per $HOME/wiki/log/2026-05-06-strategic-context-window-management-synthesis.md
# 4 modes: auto / strategic-early / edging / scope-shift-clear) is informed by
# real perception. Pure observability — does NOT prescribe action.
#
# Operator directives (sacrosanct):
#   2026-05-06 — "there should be a hook that start warning at the prompt
#     inputs so that at <5% we say something and then at 3 and 2 pourcent
#     and then after the compact like normal too"
#   2026-05-06 — "we do not invent random things"
#   2026-05-06 — "its not mindless waht we do at 5 -3 and 2 and 0%... its
#     strategic... its logical... its sounds"
#   2026-05-06 — "you can stay at 0% so long when done properly for example"
#   2026-05-06 — "asmuch as you might want to compact sooner in some cases"
#   2026-05-06 — "WE DONT DO HACK AND QUICKIX.... WTF IS THIS... YOU USE THE
#     ENVIRONMENT VARIABLES TO ACTUALLY HAVE THE RIGHT VALUE"
#
# Window resolution (root-cause fix per SB-107):
#   PRIMARY: stdin payload's `context_window.context_window_size` field —
#     same source ccstatusline reads (verified in
#     /usr/local/lib/node_modules/ccstatusline/dist/ccstatusline.js:55180).
#     This IS the authoritative value Claude Code provides; not an env var
#     mapping nor a model-id heuristic.
#   FALLBACK: model-id prefix mapping if `context_window` field absent
#     (older Claude Code versions or schema variation).
#   LAST RESORT: 200_000 (smallest known window — Haiku 4.5 / Sonnet 3.5).
#
# Used-tokens resolution:
#   PRIMARY: stdin's `context_window.current_usage.{input_tokens +
#     cache_creation_input_tokens + cache_read_input_tokens}` (same as
#     ccstatusline's calculation, line 55196).
#   FALLBACK: read most-recent assistant message's `usage` block from
#     session jsonl (same as before, used when stdin lacks context_window).
#
# Self-gates via BOOTSTRAP.md presence + cwd / CLAUDE_PROJECT_DIR check.
# Silent (no output) when above all thresholds — quiet by default.
# Threshold name IS the threshold value — no invented severity labels.

from __future__ import annotations

import glob
import json
import os
import sys
from pathlib import Path

PROJECT_ROOT = Path.home()

# Fallback model→window map (used only when stdin payload lacks the
# `context_window.context_window_size` field).
MODEL_CONTEXT_WINDOWS = {
    "claude-opus-4-7": 1_000_000,
    "claude-opus-4-6": 1_000_000,
    "claude-sonnet-4-6": 1_000_000,
    "claude-haiku-4-5": 200_000,
    "claude-3-5-sonnet": 200_000,
    "claude-3-opus": 200_000,
}
DEFAULT_WINDOW = 200_000

# Threshold values per operator directive 2026-05-06: <5%, <3%, <2%.
# Threshold name IS the threshold value — no invented severity labels.
THRESHOLDS = [5.0, 3.0, 2.0]


def _trace(tag: str, extra: str = "") -> None:
    try:
        from datetime import datetime as _dt
        with open("/tmp/hook-fire-trace.log", "a") as f:
            f.write(
                f"[{_dt.now().isoformat()}] hook=context-warning.sh "
                f"path={tag} cwd={os.getcwd()} "
                f"claude_proj={os.environ.get('CLAUDE_PROJECT_DIR', '<unset>')} {extra}\n"
            )
    except Exception:
        pass


def _find_session_jsonl(session_id: str) -> str | None:
    if not session_id:
        return None
    pattern = f"{PROJECT_ROOT}/.claude/projects/*/{session_id}.jsonl"
    matches = glob.glob(pattern)
    return matches[0] if matches else None


def _used_from_stdin(payload: dict) -> int:
    """Used tokens from payload.context_window.current_usage. Returns 0 if absent."""
    cw = payload.get("context_window") if isinstance(payload, dict) else None
    if not isinstance(cw, dict):
        return 0
    cu = cw.get("current_usage")
    if isinstance(cu, (int, float)):
        return max(0, int(cu))
    if isinstance(cu, dict):
        # Same calculation ccstatusline performs at line 55196:
        # input + output + cache_creation + cache_read
        keys = ("input_tokens", "output_tokens",
                "cache_creation_input_tokens", "cache_read_input_tokens")
        total = 0
        for k in keys:
            v = cu.get(k)
            if isinstance(v, (int, float)) and v >= 0:
                total += int(v)
        return total
    return 0


def _from_transcript(transcript_path: str) -> tuple[int, str]:
    """Read most-recent assistant message's usage + model from transcript.
    Uses the `transcript_path` Claude Code provides directly in stdin payload —
    NOT a glob over session_id, NOT path heuristics. This IS the official
    structured field per Claude Code hook contract.

    Returns (used_tokens, model_id). Either may be 0/'' on failure.
    """
    used = 0
    model_id = ""
    try:
        with open(transcript_path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - 100_000))
            tail = f.read().decode("utf-8", errors="replace")
        for line in reversed(tail.split("\n")):
            if not line.strip():
                continue
            try:
                d = json.loads(line)
            except Exception:
                continue
            msg = d.get("message")
            if not isinstance(msg, dict):
                continue
            # Capture model from records with a REAL claude-* model. Skip
            # system-injected pseudo-models like "<synthetic>" (Claude Code
            # uses those for compaction summaries / sidechain messages). Without
            # this filter the most-recent <synthetic> record poisons window
            # resolution → falls back to DEFAULT_WINDOW=200_000 spuriously.
            if not model_id:
                m = msg.get("model")
                if isinstance(m, str) and m.startswith("claude-"):
                    model_id = m
            usage = msg.get("usage")
            if not used and isinstance(usage, dict) and "cache_read_input_tokens" in usage:
                used = (
                    usage.get("cache_read_input_tokens", 0)
                    + usage.get("cache_creation_input_tokens", 0)
                    + usage.get("input_tokens", 0)
                )
            if used and model_id:
                break
    except Exception:
        pass
    return used, model_id


def _window_from_stdin(payload: dict) -> int:
    """Window size from payload.context_window.context_window_size. Returns 0 if absent."""
    cw = payload.get("context_window") if isinstance(payload, dict) else None
    if not isinstance(cw, dict):
        return 0
    sz = cw.get("context_window_size")
    if isinstance(sz, (int, float)) and sz > 0:
        return int(sz)
    return 0


def _window_from_model_id(model_id: str) -> int:
    if not model_id:
        return DEFAULT_WINDOW
    for prefix, window in MODEL_CONTEXT_WINDOWS.items():
        if model_id.startswith(prefix):
            return window
    return DEFAULT_WINDOW


def main() -> None:
    _trace("entered")

    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        sys.exit(0)
    # NO project-context self-gate: context-window is a per-SESSION concern,
    # not per-project. Operator directive 2026-05-06: hook must fire from /opt
    # second-brain sessions too, not only $HOME project sessions.

    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    # WINDOW + USED resolution (root-cause fix per SB-107):
    #
    # UserPromptSubmit stdin payload schema (empirically observed 2026-05-06,
    # diagnostic at trace 09:11:31):
    #   top-level keys: cwd, hook_event_name, permission_mode, prompt,
    #                   session_id, transcript_path
    # No `context_window` field (that's statusLine event only — ccstatusline
    # reads it because statusLine receives a different payload schema).
    # No `model` field at top level either.
    #
    # The authoritative source for THIS hook event: `transcript_path` —
    # Claude Code provides this field directly in stdin pointing at the
    # session log. Most-recent assistant message has `message.model` +
    # `message.usage.{input_tokens, cache_read_input_tokens,
    # cache_creation_input_tokens}`. Read those for window + used.
    #
    # PRIMARY (UserPromptSubmit): transcript_path → message.model + usage
    # FALLBACK 1: stdin context_window field (statusLine-style; for forward
    #             compat if Claude Code adds it to UserPromptSubmit later)
    # FALLBACK 2: stdin model_id (if Claude Code adds it later)
    window = 0
    used = 0
    window_source = ""
    used_source = ""

    transcript_path = payload.get("transcript_path", "") or ""
    if transcript_path:
        t_used, t_model = _from_transcript(transcript_path)
        if t_used > 0:
            used = t_used
            used_source = "transcript"
        if t_model:
            window = _window_from_model_id(t_model)
            window_source = f"transcript:{t_model}"

    # Forward-compat fallbacks (Claude Code may add these to UserPromptSubmit):
    if window <= 0:
        w = _window_from_stdin(payload)
        if w > 0:
            window = w
            window_source = "stdin.context_window"
        else:
            model_id = (payload.get("model") or {}).get("id") or ""
            window = _window_from_model_id(model_id)
            window_source = f"fallback:model_id={model_id or '<empty>'}"

    if used <= 0:
        u = _used_from_stdin(payload)
        if u > 0:
            used = u
            used_source = "stdin.context_window"

    if used <= 0 or window <= 0:
        _trace("exit-no-usage-data", f"used={used} window={window}")
        sys.exit(0)

    pct_remaining = 100.0 * (window - used) / window
    _trace("computed",
           f"used={used} window={window} pct_remaining={pct_remaining:.2f} "
           f"window_src={window_source} used_src={used_source}")

    # Pick the lowest threshold the current % remaining crosses.
    triggered_threshold = None
    for threshold_pct in THRESHOLDS:
        if pct_remaining < threshold_pct:
            triggered_threshold = threshold_pct

    if triggered_threshold is None:
        sys.exit(0)

    # Color graduates with proximity to limit (visual only, no severity claim).
    R = "\033[31m"; Y = "\033[33m"; D = "\033[2m"; BO = "\033[1m"; X = "\033[0m"
    color = R if triggered_threshold <= 2.0 else Y

    # Per SB-078 verbatim (operator 2026-05-05 cycle 41): the realization-
    # mechanism this hook IS — surfaces context % so the operator's strategic
    # decision (synthesis 4 modes) is informed. Reference SB-078's literal
    # framing for context, no prescription.
    msg = (
        f"```ansi\n"
        f"{color}{BO}⚠ CONTEXT-WINDOW · <{triggered_threshold:g}% threshold crossed{X}    "
        f"{BO}{pct_remaining:.1f}% remaining{X}    "
        f"{D}({used:,} / {window:,} tokens){X}\n"
        f"{D}SB-078 framing: prepare for compact · strong handoff document · register knowledge/learnings{X}\n"
        f"```"
    )

    print(json.dumps({"systemMessage": msg}))
    _trace("fired", f"threshold={triggered_threshold} pct={pct_remaining:.2f}")
    sys.exit(0)


if __name__ == "__main__":
    main()
