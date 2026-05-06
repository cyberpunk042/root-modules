#!/usr/bin/env python3
# mode-enforcement.sh — UserPromptSubmit hook injecting active-mode persona +
# discipline + live-state context.
#
# Operator directives:
#   2026-05-06 — *"I feel like the mode is not respected much.. maybe it
#     should inject directives and such and context and whatnot. I am in
#     dual-expert mode and I dont feel it"*
#   2026-05-06 — *"Lets not minize the situation either.. you cannot just
#     put any random information and call it a day.... we need a real hook
#     with real engineering..."*
#
# Engineering scope (closes SB-056 family at runtime layer):
#
#   1. DYNAMIC PARSING — not hardcoded strings. Reads the active mode's brain
#      piece file at /root/.claude/modes/<mode>.md, extracts the Persona,
#      Persona-voice (discipline table), and /cycle-sequence sections via
#      markdown header parsing. Stale mode files / missing sections are
#      detected + logged.
#
#   2. LIVE-STATE CROSS-REFERENCE — pulls current systemic-bugs counts (open +
#      recurring), 3 most-recent operator log slugs, active task cursor from
#      progress.md callout. Reminder composes these so the agent sees the
#      immediate context, not a generic mode reminder.
#
#   3. PERSONA-VOICE TABLE EXTRACTION — parses the Quality / What it sounds
#      like / Anti-pattern markdown table from the mode file and surfaces the
#      first 3-4 disciplines verbatim from the operator-authored mode brain
#      piece. Extends to mode-enforcement of operator's actual standards.
#
#   4. LENGTH-BOUNDED OUTPUT — cap additionalContext at 1200 chars to fit
#      Claude Code context budget without crowding out other UserPromptSubmit
#      hooks (context-warning, output-discipline-guard).
#
#   5. ERROR-PATH ENGINEERING — explicit branches for: BOOTSTRAP missing,
#      not-project-context (cross-fire prevention), active-mode file missing,
#      empty mode, unknown mode, mode file missing, mode file unparseable,
#      no sections matched. Each error path traces to /tmp/hook-fire-trace.log.
#
#   6. DIAGNOSTIC — captures: mode resolved, sections extracted, char count of
#      reminder composed, parse-error info if any. Log line per fire shows
#      what was actually surfaced, enabling post-hoc verification per SB-091
#      (real-session diag log, not synthetic test).
#
#   7. COMPOSABILITY — runs alongside context-warning + output-discipline-guard
#      on UserPromptSubmit. Each emits its own additionalContext; they don't
#      conflict (different content, different fields, same channel).

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

PROJECT_ROOT = Path.home()
ACTIVE_MODE_FILE = PROJECT_ROOT / ".claude" / "active-mode"
ACTIVE_MISSION_FILE = PROJECT_ROOT / ".claude" / "active-mission"
ACTIVE_FOCUS_FILE = PROJECT_ROOT / ".claude" / "active-focus"
ACTIVE_IMPEDIMENT_FILE = PROJECT_ROOT / ".claude" / "active-impediment"
ACTIVE_PRIORITIES_FILE = PROJECT_ROOT / ".claude" / "active-priorities"
MODES_DIR = PROJECT_ROOT / ".claude" / "modes"
SYSTEMIC_BUGS_PATH = PROJECT_ROOT / "wiki" / "governance" / "systemic-bugs.md"
LOG_DIR = PROJECT_ROOT / "wiki" / "log"
PROGRESS_PATH = PROJECT_ROOT / "wiki" / "governance" / "progress.md"

# NO hard cap on reminder length. Operator directive 2026-05-06: capping
# mode-enforcement output is the agent self-managing operator-context-budget
# without authorization (same family as SB-119 — % self-interpretation). The
# reminder surfaces persona + cycle steps + mission/focus/impediment + live
# state — all operator-explicit-set or operator-authored content. Truncating
# is dismissive; let it land at full fidelity.


def is_project_context() -> bool:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    home = str(PROJECT_ROOT)
    if project_dir:
        return project_dir == home or project_dir.startswith(home + "/")
    cwd = os.getcwd()
    return cwd == home or cwd.startswith(home + "/")


def _trace(tag: str, extra: str = "") -> None:
    try:
        with open("/tmp/hook-fire-trace.log", "a") as f:
            f.write(
                f"[{datetime.now().isoformat()}] hook=mode-enforcement.sh "
                f"path={tag} cwd={os.getcwd()} "
                f"claude_proj={os.environ.get('CLAUDE_PROJECT_DIR', '<unset>')} "
                f"{extra}\n"
            )
    except Exception:
        pass


def parse_mode_sections(mode_path: Path) -> dict:
    """Parse a mode brain-piece file into named sections.

    Sections are split by `## ` (H2) and `### ` (H3) headers. Returns dict
    keyed by lowercase section name → body text. Empty dict if unparseable.
    """
    if not mode_path.exists():
        return {}
    try:
        text = mode_path.read_text()
    except Exception:
        return {}

    sections: dict = {}
    current_name: Optional[str] = None
    current_lines: list = []
    for line in text.splitlines():
        m = re.match(r"^##+ +(.+?)\s*$", line)
        if m:
            if current_name:
                sections[current_name.lower()] = "\n".join(current_lines).strip()
            current_name = m.group(1).strip()
            current_lines = []
        elif current_name is not None:
            current_lines.append(line)
    if current_name:
        sections[current_name.lower()] = "\n".join(current_lines).strip()

    return sections


def find_persona_section(sections: dict) -> str:
    """Return the Persona section body (first paragraph) or empty string."""
    for key in ("persona",):
        if key in sections:
            body = sections[key]
            # Take first non-empty paragraph
            for para in body.split("\n\n"):
                if para.strip():
                    return para.strip()
    return ""


def find_persona_voice_table(sections: dict) -> list:
    """Extract Quality / How-it-sounds rows from the Persona voice section.

    Returns list of (quality, sounds_like) tuples. Empty list if section
    absent or table malformed.
    """
    voice_key = next(
        (k for k in sections if "persona voice" in k or "voice" in k),
        None,
    )
    if not voice_key:
        return []
    body = sections[voice_key]
    rows: list = []
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        # Skip header / separator rows
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 3:
            continue
        if cells[0] in ("Quality", "---"):
            continue
        if cells[0].startswith("---"):
            continue
        quality, sounds, anti = cells[0], cells[1], cells[2]
        if quality and sounds:
            rows.append((quality, sounds))
    return rows


def find_cycle_sequence_steps(sections: dict, max_steps: int = 4) -> list:
    """Extract numbered list items from the /cycle sequence section."""
    cycle_key = next(
        (k for k in sections if "/cycle" in k or "cycle sequence" in k),
        None,
    )
    if not cycle_key:
        return []
    body = sections[cycle_key]
    steps: list = []
    for line in body.splitlines():
        m = re.match(r"^\s*\d+\.\s+(.+?)\s*$", line)
        if m:
            steps.append(m.group(1).strip())
            if len(steps) >= max_steps:
                break
    return steps


def get_live_state_context() -> dict:
    """Pull live state for cross-reference: open SBs, recent log slugs, task cursor.

    Hooks may be invoked from arbitrary cwd by Claude Code; explicitly add
    PROJECT_ROOT to sys.path so `tools.cycle` import resolves regardless of
    invocation context. Failures still trapped (no silent stale state) and
    traced with reason for post-hoc diagnosis.
    """
    state: dict = {"open_sbs": [], "recurring_sbs": [], "recent_logs": [], "task_cursor": "",
                   "mission": "", "focus": "", "impediment": "", "priorities": [],
                   "_sb_load_error": ""}

    # Mission / focus / impediment state files (SB-118 build, operator directive 2026-05-06)
    for layer, path in (
        ("mission", ACTIVE_MISSION_FILE),
        ("focus", ACTIVE_FOCUS_FILE),
        ("impediment", ACTIVE_IMPEDIMENT_FILE),
    ):
        try:
            if path.exists():
                state[layer] = path.read_text().strip()
        except Exception:
            pass

    # Priorities (SB-127 build, operator directive 2026-05-06): top-priorities imminent-work list
    try:
        if ACTIVE_PRIORITIES_FILE.exists():
            state["priorities"] = [
                ln.strip() for ln in ACTIVE_PRIORITIES_FILE.read_text().splitlines() if ln.strip()
            ]
    except Exception:
        pass

    # Systemic bugs — explicit sys.path injection for cwd-independent import
    if str(PROJECT_ROOT) not in sys.path:
        sys.path.insert(0, str(PROJECT_ROOT))
    try:
        from tools.cycle import parse_systemic_bugs_status  # type: ignore
        sbs = parse_systemic_bugs_status()
        state["open_sbs"] = sbs.get("open_ids", [])[:6]
        state["recurring_sbs"] = sbs.get("recurring_ids", [])[:6]
    except Exception as exc:
        state["_sb_load_error"] = repr(exc)[:80]

    # Recent logs (3 newest by mtime)
    try:
        if LOG_DIR.exists():
            files = sorted(
                [p for p in LOG_DIR.glob("*.md") if p.is_file()],
                key=lambda p: p.stat().st_mtime, reverse=True,
            )[:3]
            for p in files:
                slug = p.stem.lstrip("0123456789-")
                # Strip time-prefixed numerics if present (e.g., 003620-pre-compact)
                slug = re.sub(r"^\d+-", "", slug)
                state["recent_logs"].append(slug[:50])
    except Exception:
        pass

    # Task cursor from progress.md callout (best-effort regex)
    try:
        if PROGRESS_PATH.exists():
            text = PROGRESS_PATH.read_text()
            m = re.search(r"Active task cursor:\s*([^\n]+)", text)
            if m:
                state["task_cursor"] = m.group(1).strip()[:80]
    except Exception:
        pass

    return state


def compose_reminder(mode: str, sections: dict, state: dict) -> tuple[str, list]:
    """Compose the mode-enforcement reminder text.

    Returns (reminder_text, diagnostic_keys_extracted).
    """
    keys: list = []

    parts: list = [f"MODE-ENFORCEMENT: {mode} active."]

    persona = find_persona_section(sections)
    if persona:
        # First sentence (up to first period or 200 chars)
        first_sentence = re.split(r"(?<=[.!?])\s+", persona)[0]
        parts.append(f"PERSONA: {first_sentence[:240]}")
        keys.append("persona")

    voice_rows = find_persona_voice_table(sections)
    if voice_rows:
        embody_items = [f"{q}: {s}" for q, s in voice_rows[:4]]
        parts.append("EMBODY: " + " · ".join(embody_items))
        keys.append("persona-voice-table")

    cycle_steps = find_cycle_sequence_steps(sections, max_steps=3)
    if cycle_steps:
        parts.append("CYCLE STEPS: " + " · ".join(s[:80] for s in cycle_steps))
        keys.append("cycle-sequence")

    # Top-priorities (SB-127) — imminent-work hot-queue, surfaces ABOVE PM-decision-tier
    # per operator directive: "imminent work, even before the PM work"
    priorities = state.get("priorities") or []
    if priorities:
        prio_lines = [f"P{i}: {p}" for i, p in enumerate(priorities[:5], start=1)]
        parts.append("PRIORITIES: " + " · ".join(prio_lines))
        keys.append("priorities")
    else:
        parts.append("PRIORITIES: (none set)")
        keys.append("priorities")

    # Mission / Focus / Impediment (SB-118) — operator-explicit-set
    # Always render all 3 even when empty (operator-visibility: empty = "(unset)")
    objective_parts: list = [
        f"MISSION: {state.get('mission') or '(unset)'}",
        f"FOCUS: {state.get('focus') or '(unset)'}",
        f"IMPEDIMENT: {state.get('impediment') or '(none — focus unblocked)'}",
    ]
    parts.append(" · ".join(objective_parts))
    keys.append("objective")

    # Live state cross-reference
    live_parts: list = []
    if state["open_sbs"]:
        live_parts.append(
            f"open SBs: {', '.join(state['open_sbs'][:4])}"
            + (" ..." if len(state["open_sbs"]) > 4 else "")
        )
    if state["recurring_sbs"]:
        live_parts.append(
            f"recurring SBs: {', '.join(state['recurring_sbs'][:4])}"
            + (" ..." if len(state["recurring_sbs"]) > 4 else "")
        )
    if state["recent_logs"]:
        live_parts.append(f"recent logs: {' · '.join(state['recent_logs'])}")
    if state["task_cursor"]:
        live_parts.append(f"task cursor: {state['task_cursor']}")
    if live_parts:
        parts.append("LIVE STATE: " + " | ".join(live_parts))
        keys.append("live-state")

    text = "  ".join(parts)
    return text, keys


def main() -> None:
    _trace("entered")

    if not (PROJECT_ROOT / "BOOTSTRAP.md").exists():
        _trace("exit-bootstrap-missing")
        sys.exit(0)
    if not is_project_context():
        _trace("exit-not-project-context")
        sys.exit(0)

    # Drain stdin (payload not needed)
    try:
        sys.stdin.read()
    except Exception:
        pass

    if not ACTIVE_MODE_FILE.exists():
        _trace("exit-no-active-mode-file")
        sys.exit(0)

    try:
        mode = ACTIVE_MODE_FILE.read_text().strip()
    except Exception:
        _trace("exit-active-mode-read-error")
        sys.exit(0)

    if not mode:
        _trace("exit-empty-mode")
        sys.exit(0)

    mode_path = MODES_DIR / f"{mode}.md"
    if not mode_path.exists():
        _trace(f"exit-mode-file-missing:{mode}")
        sys.exit(0)

    sections = parse_mode_sections(mode_path)
    if not sections:
        _trace(f"exit-mode-unparseable:{mode}")
        sys.exit(0)

    state = get_live_state_context()
    reminder, keys_extracted = compose_reminder(mode, sections, state)

    if not keys_extracted:
        _trace(f"exit-no-sections-matched:{mode}")
        sys.exit(0)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": reminder,
        }
    }
    print(json.dumps(output))
    _trace(
        f"fired-mode:{mode}",
        f"reminder_len={len(reminder)} keys={','.join(keys_extracted)}",
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
