"""tools.cycle — read active mode + dispatch the per-mode cycle reads/checks.

Per operator directive 2026-05-05 ("F015"): a tool wrapping the cycle dispatch
so sub-agents + MCP consumers can invoke a cycle programmatically without going
through the slash command.

This tool DOESN'T execute the agent-side prose (the cycle's "report + stand by"
narrative is for the agent's response). It DOES return the structured data
each cycle step would produce: state + blockers + progress + per-mode
emphasis.

Usage:
    python3 -m tools.cycle              # human-readable cycle summary for active mode
    python3 -m tools.cycle --json       # JSON output (for MCP / scripting)
    python3 -m tools.cycle --mode pm    # force a specific mode (override active)

Composes-with:
- Slash commands: /cycle (this tool's primary consumer; routes per active-mode), /orient
- Hooks: end-of-cycle-stamp.sh + mode-enforcement.sh both consume cycle-status JSON for
  display blocks (--diff-fence / --ansi-fence / --ansi-horizontal modes)
- Mode files: dispatches to pm-scrum-master / devops-architect / dual-expert per
  $HOME/.claude/active-mode (per CYCLE_DEFINITIONS dict)
- MCP: cycle JSON consumed by sub-agents + sister-project agents via /opt gateway integration

Sister tools imported: tools.state.read_state(), tools.blockers.detect_drift(),
tools.progress.compute_progress() — composes the read-side surface for cycle status.

Idempotency invariant: read-only orchestration; no state mutation; re-run on same
filesystem state = same JSON output.

Action vocabulary (Hard Rule 14): the slash command `/cycle` (which this tool backs)
emits one of 9 canonical action types per fire — mandatory cycle-report last-line
`Productive output: <type> — <one-line specific>`. Per-mode action subset:
  PM-mode: blocker-surface · sb-closure · drift-fix-with-empirical · explicit-standby
  Architect-mode: verified-edit · sb-closure · drift-fix-with-empirical · new-artifact
                  · doc-refresh · explicit-standby
  Dual-mode: ANY of the 9 (broadest scope)
See wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md.

Lifecycle signals: per .claude/rules/loop-cron-lifecycle.md L1-L7 scenarios; this tool
auto-flags applicable signals in JSON output for self-evaluation per cycle.

Test file: implicit (cycle dispatch exercised via /cycle integration runs).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from tools.state import read_state
from tools.blockers import detect_drift
from tools.progress import compute_progress
from tools._paths import PROJECT_ROOT

ACTIVE_MODE_PATH = PROJECT_ROOT / ".claude" / "active-mode"

CYCLE_DEFINITIONS = {
    "pm-scrum-master": {
        "name": "PM Scrum Master",
        "lens": ["pm"],
        "steps": [
            "orient",
            "surface-decisions",
            "backlog-status",
            "risk-blocker-scan",
        ],
        "report_emphasis": "PM-side: pending decisions, blocker drift, readiness flow",
    },
    "devops-architect": {
        "name": "DevOps Software Engineer & Architect",
        "lens": ["architect"],
        "steps": [
            "orient",
            "progress-snapshot",
            "architecture-review",
            "implementation-progress",
            "stage-gate-check",
        ],
        "report_emphasis": "Engineering-side: open design questions, in-progress task next-actions, gate-blockers",
    },
    "dual-expert": {
        "name": "Dual Expert",
        "lens": ["pm", "architect"],
        "steps": [
            "orient",
            "pm-lens-surface-decisions",
            "architect-lens-architecture-review",
            "cross-cutting",
        ],
        "report_emphasis": "Both lenses: PM + Architect concerns; lens-switching per task",
    },
}


def read_active_mode() -> str | None:
    if not ACTIVE_MODE_PATH.exists():
        return None
    name = ACTIVE_MODE_PATH.read_text().strip()
    return name if name else None


def get_cycle_for_mode(mode: str | None) -> dict:
    if mode is None or mode not in CYCLE_DEFINITIONS:
        return {
            "mode": "(none)",
            "valid": False,
            "message": "No mode active. /cycle requires a mode. Use /mode-pm, /mode-architect, or /mode-dual.",
        }
    return {
        "mode": mode,
        "valid": True,
        **CYCLE_DEFINITIONS[mode],
    }


def evaluate_cycle() -> dict:
    """Compose state + blockers + progress + cycle definition for active mode."""
    mode = read_active_mode()
    cycle_def = get_cycle_for_mode(mode)

    state = read_state()
    blockers = detect_drift()
    progress = compute_progress()

    # Lifecycle scenarios (per loop-cron-lifecycle.md) — flag any that apply
    lifecycle_signals = []
    pending_count = blockers["task_status_counts"].get("pending-operator-decision", 0)
    not_started_count = blockers["task_status_counts"].get("not-started", 0)
    done_count = blockers["task_status_counts"].get("done", 0)

    if pending_count > 0 and not_started_count > 0 and done_count > 0:
        # not strictly "completely blocked" — there's done work and not-started possibilities
        lifecycle_signals.append({
            "scenario": "L1-near",
            "note": f"{pending_count} active blockers; {not_started_count} not-started tasks (most gated); evaluate per mode whether progress is possible",
        })

    if state["git-state"] == "uncommitted" and state["git-uncommitted"] > 50:
        lifecycle_signals.append({
            "scenario": "L4-near",
            "note": f"{state['git-uncommitted']} uncommitted files — consider committing the spec before next phase",
        })

    # Compound layers (SB-118 + SB-127): operator-explicit objective + priorities state
    objective = {"mission": "", "focus": "", "impediment": ""}
    for layer in ("mission", "focus", "impediment"):
        p = PROJECT_ROOT / ".claude" / f"active-{layer}"
        if p.exists():
            try:
                objective[layer] = p.read_text().strip()
            except Exception:
                pass
    priorities: list = []
    pp = PROJECT_ROOT / ".claude" / "active-priorities"
    if pp.exists():
        try:
            priorities = [ln.strip() for ln in pp.read_text().splitlines() if ln.strip()]
        except Exception:
            pass

    # Questions retention layer (operator directive 2026-05-06)
    questions: list = []
    qp = PROJECT_ROOT / ".claude" / "active-questions"
    if qp.exists():
        try:
            questions = [ln.strip() for ln in qp.read_text().splitlines() if ln.strip()]
        except Exception:
            pass

    return {
        "active_mode": mode,
        "cycle": cycle_def,
        "state": state,
        "blockers_summary": {
            "in_sync": blockers["drift"]["in_sync"],
            "task_counts": blockers["task_status_counts"],
            "pending_decision_tasks": blockers["live_pending_decision_tasks"],
        },
        "progress_summary": {
            "epic_readiness": progress["epic"].get("readiness", "?"),
            "module_count": progress["modules"]["total"],
            "task_total": progress["tasks"]["total"],
            "task_counts": progress["tasks"]["by_status"],
            "recent_logs_count": len(progress.get("recent_logs", [])),
        },
        "objective": objective,
        "priorities": priorities,
        "questions": questions,
        "lifecycle_signals": lifecycle_signals,
    }


from tools._paths import SYSTEMIC_BUGS_DOC as SYSTEMIC_BUGS_PATH


def get_sb_short_desc(sb_id: str, max_len: int = 60) -> str:
    """Return short description for an SB row from the tracker.

    Reads the bold `**short**` portion of the bug-description column. Returns
    empty string if not found. Used by horizontal stamp Cursor line for context.
    """
    if not SYSTEMIC_BUGS_PATH.exists():
        return ""
    import re
    content = SYSTEMIC_BUGS_PATH.read_text()
    pattern = rf"^\| {re.escape(sb_id)} \| \*\*(.+?)\*\*"
    m = re.search(pattern, content, re.MULTILINE)
    if not m:
        # Fallback: bug-description is plain text (no bold) — take first phrase
        plain = re.search(rf"^\| {re.escape(sb_id)} \| ([^|]+?) \|", content, re.MULTILINE)
        if plain:
            text = plain.group(1).strip()
            # Stop at em-dash, period, or first parenthesis to get the head
            for sep in [" — ", " - ", ". ", " ("]:
                if sep in text:
                    text = text.split(sep, 1)[0]
                    break
            return text[:max_len]
        return ""
    desc = m.group(1).strip()
    return desc[:max_len]


def parse_systemic_bugs_status() -> dict:
    """Parse status counts from systemic-bugs.md tracker.

    Status field may contain parenthetical annotations like
    "structurally-fixed (DRAFT)" or "structurally-fixed (covered by SB-090)";
    we extract the canonical first word for counting.
    """
    if not SYSTEMIC_BUGS_PATH.exists():
        return {"open": 0, "structurally-fixed": 0, "verified": 0, "recurring": 0, "total": 0}
    content = SYSTEMIC_BUGS_PATH.read_text()
    import re
    # Match: | SB-XXX | <bug-desc> | <status with possible parens> | <fix-evidence> | <verified> |
    rows = re.findall(r"^\| (SB-[\w-]+) \| .+? \| ([^|]+?) \| .+? \| .+? \|\s*$", content, re.MULTILINE)
    counts: dict = {}
    open_ids: list = []
    recurring_ids: list = []
    for sb_id, status_raw in rows:
        # Canonical status = first whitespace-separated word, lowercased
        status = status_raw.strip().split()[0].lower() if status_raw.strip() else "unknown"
        counts[status] = counts.get(status, 0) + 1
        if status == "open":
            open_ids.append(sb_id)
        elif status == "recurring":
            recurring_ids.append(sb_id)
    counts["total"] = len(rows)
    counts["open_ids"] = open_ids
    counts["recurring_ids"] = recurring_ids
    return counts


# ANSI codes for terminal colors (when --color is on)
class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    RED = "\033[31m"
    CYAN = "\033[36m"
    MAGENTA = "\033[35m"


def emit_status_block_ansi_horizontal(result: dict, fence: bool = True) -> None:
    """Horizontal stamp — single-line-per-section with consistent padded labels.
    Per SB-114 sub-req (a) + SB-116 UX iteration: aligned `@@ Label @@` headers,
    spelled-out count words instead of cryptic single-letter codes, multi-space
    breathing room between fields, honest verified-vs-claimed separation.
    Iteration #1 of horizontal-layout UX work (SB-116 Epic placeholder).
    """
    from datetime import datetime as _dt_h
    cycle = result["cycle"]
    blockers = result["blockers_summary"]
    progress = result["progress_summary"]
    sbs = parse_systemic_bugs_status()

    pending_tasks = blockers.get("pending_decision_tasks", [])
    open_sbs = sbs.get("open_ids", [])
    recurring_sbs = sbs.get("recurring_ids", [])

    R, G, Y, B, M, K, BO, D, X = (
        "\033[31m", "\033[32m", "\033[33m", "\033[34m",
        "\033[35m", "\033[36m", "\033[1m", "\033[2m", "\033[0m",
    )
    ts = _dt_h.now().strftime("%H:%M:%S")

    LABEL_WIDTH = 10  # widest = "Impediment" / "Priorities"
    # Semantic glyph per section for visual scanning at line-start
    GLYPHS = {
        "Status":     "●",   # filled circle = current state
        "Journey":    "↺",   # history loop
        "Plan":       "◆",   # diamond = priority
        "Priorities": "⚡",   # lightning = imminent work (before PM)
        "Tracker":    "⊘",   # circle-slash = tier-explicit (real blockers · Epic-pending · behavioral)
        "Progress":   "▰",   # filled block = progress
        "Cursor":     "▶",   # play/now-pointer
        "Mission":    "✦",   # 4-point star = north star
        "Focus":      "◉",   # bullseye = current sub-objective
        "Impediment": "⚠",   # warning sign = block on focus
    }
    def lbl(name: str) -> str:
        glyph = GLYPHS.get(name, "·")
        return f"{M}{BO}{glyph} {name:<{LABEL_WIDTH}}{X}"

    # Density variant per SB-124c (operator directive 2026-05-06: minified | standard | extended)
    density = "standard"
    try:
        import json as _json
        cfg_path = Path.home() / ".claude" / "stamp-config.json"
        if cfg_path.exists():
            density = _json.loads(cfg_path.read_text()).get("density", "standard")
    except Exception:
        pass

    if fence:
        print("```ansi")

    # Status — timestamp · mode · loop state · task (S:stage)
    loop_state = "alive" if cycle.get("valid") else "no-mode"
    loop_color = G if cycle.get("valid") else R
    # Extract current task ID + stage from progress.md callout (operator directive 2026-05-06:
    # "on the status line there could the the current task too and it stage even with S: for example")
    task_part = ""
    try:
        from pathlib import Path as _P
        import re as _re
        prog_path = _P.home() / "wiki" / "governance" / "progress.md"
        if prog_path.exists():
            text = prog_path.read_text()
            m = _re.search(r"Active task cursor:\s*(T\d+)[^\n]*", text)
            if m:
                task_id = m.group(1)
                # Look up stage from task frontmatter
                task_files = list((_P.home() / "wiki" / "backlog" / "tasks").glob(f"{task_id}-*.md"))
                stage = "?"
                if task_files:
                    fm = task_files[0].read_text()
                    s_match = _re.search(r"^current_stage:\s*(\S+)", fm, _re.M)
                    if s_match:
                        stage = s_match.group(1)
                task_part = f"  ·  {Y}{task_id}{X} {D}(S:{stage}){X}"
    except Exception:
        pass
    print(f"{lbl('Status')}  {D}{ts}{X}  ·  {cycle.get('mode', 'none')}  ·  {loop_color}loop {loop_state}{X}{task_part}")

    # Journey — deduped recent log slugs (top 5)
    journey_slugs = []
    try:
        from tools.progress import collect_recent_logs
        seen: dict[str, int] = {}
        ordered: list[str] = []
        for fname in collect_recent_logs(10):
            raw_short = fname.replace(".md", "").lstrip("0123456789-")
            if len(raw_short) <= 35:
                short = raw_short
            else:
                # Truncate at last word-boundary within 35 chars (no trailing hyphen)
                short = raw_short[:35].rstrip("-")
                # If we cut mid-word, drop the partial word
                if "-" in short:
                    short = short.rsplit("-", 1)[0] + "…"
                else:
                    short = short + "…"
            if short not in seen:
                seen[short] = 1
                ordered.append(short)
            else:
                seen[short] += 1
        for short in ordered[:3]:  # 3 entries — less density per line
            count = seen[short]
            suffix = f" ×{count}" if count > 1 else ""
            journey_slugs.append(f"{short}{suffix}")
    except Exception:
        journey_slugs = ["(unavailable)"]
    if density != "minified":
        print(f"{lbl('Journey')}  {D}" + "  ·  ".join(journey_slugs) + f"{X}")

    # Plan — systemic-bugs progress + module quick-status
    sb_total = max(1, sbs.get("total", 1))
    sb_open = sbs.get("open", 0)
    sb_rec = sbs.get("recurring", 0)
    sb_verified = sbs.get("verified", 0)
    sb_fixed = sb_verified + sbs.get("structurally-fixed", 0)
    sb_pct = round(100 * sb_fixed / sb_total)
    filled = round(sb_pct / 10)  # round, not floor — 79% → 8 blocks
    bar = "█" * filled + "░" * (10 - filled)
    plan_modules = f"{D}ccstatusline (M011 prelim)  ·  pipelock (M014 prelim done){X}"
    # `║` between logical groups (sb-progress | modules) — distinguishes from ` · ` within-group separator
    if density != "minified":
        print(f"{lbl('Plan')}  {Y}systemic-bugs  {bar}  {sb_pct}%{X}  {D}({sb_open} open · {sb_rec} recurring){X}  {D}║{X}  {plan_modules}")

    # Priorities — imminent-work hot-queue (SB-127), surfaces ABOVE PM-decision-tier
    # per operator directive 2026-05-06: "imminent work, even before the PM work"
    try:
        prio_path = Path(__file__).resolve().parent.parent / ".claude" / "active-priorities"
        if not prio_path.exists():
            prio_path = Path.home() / ".claude" / "active-priorities"
        prios: list = []
        if prio_path.exists():
            prios = [ln.strip() for ln in prio_path.read_text().splitlines() if ln.strip()]
        if prios:
            for i, p in enumerate(prios[:5], start=1):
                rank_color = R if i == 1 else (Y if i == 2 else D)
                print(f"{lbl('Priorities') if i == 1 else ' ' * (LABEL_WIDTH + 5)}  {rank_color}P{i}{X}  {p[:140]}")
        else:
            print(f"{lbl('Priorities')}  {D}(none set — operator-edit via /priorities add <text>){X}")
    except Exception:
        pass

    # Questions — agent-pending input-needed queue (operator directive 2026-05-06).
    # Always-render row even when empty so operator can SEE there are no questions
    # (avoiding SB-082 conditional-drop-when-empty pendulum pattern).
    try:
        q_path = Path(__file__).resolve().parent.parent / ".claude" / "active-questions"
        if not q_path.exists():
            q_path = Path.home() / ".claude" / "active-questions"
        qs: list = []
        if q_path.exists():
            qs = [ln.strip() for ln in q_path.read_text().splitlines() if ln.strip()]
        # Detail-presence marker per question (presweep enrichment per operator 2026-05-06)
        detail_dir = Path.home() / ".claude" / "active-questions-detail"
        if qs:
            for i, q in enumerate(qs[:5], start=1):
                marker = f"  {D}[+detail]{X}" if (detail_dir / f"Q{i}.md").exists() else ""
                print(f"{lbl('Questions') if i == 1 else ' ' * (LABEL_WIDTH + 5)}  {Y}Q{i}{X}  {q[:140]}{marker}")
        else:
            print(f"{lbl('Questions')}  {G}(none pending){X}")
    except Exception:
        pass

    # Tracker — tier-explicit per SB-125: distinguish real blockers (pending decisions)
    # from Epic-pending open SBs from behavioral recurring patterns. Conflating these
    # was the SB-125 bug; tier labels enforce honest classification.
    def _fmt_count(label: str, ids: list, color: str, none_color: str = G) -> str:
        n = len(ids)
        if n == 0:
            return f"{none_color}0 {label}{X}"
        if n <= 4:
            head = " ".join(ids)
            return f"{color}{n} {label}{X}{D}: {head}{X}"
        head = " ".join(ids[:3])
        return f"{color}{n} {label}{X}{D}: {head} +{n-3} more{X}"
    blockers_part = _fmt_count("real blockers", pending_tasks, R)
    open_part = _fmt_count("Epic-pending SBs", open_sbs, Y, none_color=G)
    rec_part = _fmt_count("behavioral recurring", recurring_sbs, Y, none_color=G)
    # `║` separates real blockers (gating work) from open+recurring (observations)
    print(f"{lbl('Tracker')}  {blockers_part}  {D}║{X}  {open_part}  ·  {rec_part}")

    # Progress — counts with verified separated (the "real" done) from
    # structurally-fixed (rule-layer claim, behavioral pending)
    p = progress
    tasks_done = p["task_counts"].get("done", 0)
    tasks_ns = p["task_counts"].get("not-started", 0)
    sb_struct = sbs.get("structurally-fixed", 0)
    # `║` separates project-deliverable metrics (stage/modules/tasks) from systemic-bugs-tracker metrics
    print(f"{lbl('Progress')}  {G}epic {p['epic_readiness']}%{X}  ·  {p['module_count']} modules  ·  {p['task_total']} tasks {D}({tasks_done} done · {tasks_ns} todo){X}  {D}║{X}  {sbs.get('total', 0)} SB {D}({X}{G}{sb_verified}✓ verified{X}{D} · {sb_struct} fixed · {sb_rec} recurring · {sb_open} open){X}")

    # Cursor — current pick + short description + reference paths
    next_pick = open_sbs[0] if open_sbs else (recurring_sbs[0] if recurring_sbs else "")
    if next_pick:
        desc = get_sb_short_desc(next_pick)
        desc_part = f" {D}—{X} {desc}" if desc else ""
        print(f"{lbl('Cursor')}  {Y}{next_pick}{X}{desc_part}  {D}· wiki/log + governance/{{progress,blockers,systemic-bugs}}.md{X}")
    else:
        print(f"{lbl('Cursor')}  {D}(no open or recurring SBs){X}")

    # Mission / Focus / Impediment — operator-explicit objective layer (SB-118 + SB-124a)
    # Always render rows even when empty — operator-visibility preserved.
    try:
        from tools.objective import read_layer
        mission = read_layer("mission") or "(unset)"
        focus = read_layer("focus") or "(unset)"
        impediment = read_layer("impediment") or "(none — focus unblocked)"
        print(f"{lbl('Mission')}  {B}{mission}{X}")
        print(f"{lbl('Focus')}  {M}{focus}{X}")
        print(f"{lbl('Impediment')}  {Y}{impediment}{X}")
    except Exception:
        pass

    if fence:
        print("```")


def emit_status_block_ansi(result: dict, fence: bool = True) -> None:
    """ANSI-coded status block. Full palette: red, green, orange/yellow, blue,
    magenta, cyan, bold, dim. When fence=True wraps in ```ansi (markdown chat).
    When fence=False emits raw ANSI to stdout (Bash tool output → Claude Code's
    terminal renderer applies colors).
    """
    from datetime import datetime as _dt_ansi
    cycle = result["cycle"]
    blockers = result["blockers_summary"]
    progress = result["progress_summary"]
    sbs = parse_systemic_bugs_status()

    pending_tasks = blockers.get("pending_decision_tasks", [])
    open_sbs = sbs.get("open_ids", [])
    recurring_sbs = sbs.get("recurring_ids", [])

    R, G, Y, B, M, K, BO, D, X = (
        "\033[31m", "\033[32m", "\033[33m", "\033[34m",
        "\033[35m", "\033[36m", "\033[1m", "\033[2m", "\033[0m",
    )
    bar = "═" * 63
    ts = _dt_ansi.now().strftime("%H:%M:%S")
    if fence:
        print("```ansi")
    print(f"{D}{bar}{X}")
    print(f"{BO}{K}ROOT-GHOSTPROXY · STATUS · {ts} · mode={cycle.get('mode', 'none')}{X}")
    print(f"{D}{bar}{X}")
    print()
    loop_state = "alive" if cycle.get("valid") else "no-mode"
    loop_color = G if cycle.get("valid") else R
    # Task + stage compounded onto first line (parallel to horizontal stamp Status row)
    task_extra = ""
    try:
        from pathlib import Path as _P
        import re as _re
        prog_path = _P.home() / "wiki" / "governance" / "progress.md"
        if prog_path.exists():
            m = _re.search(r"Active task cursor:\s*(T\d+)[^\n]*", prog_path.read_text())
            if m:
                tid = m.group(1)
                tfiles = list((_P.home() / "wiki" / "backlog" / "tasks").glob(f"{tid}-*.md"))
                stage = "?"
                if tfiles:
                    sm = _re.search(r"^current_stage:\s*(\S+)", tfiles[0].read_text(), _re.M)
                    if sm:
                        stage = sm.group(1)
                task_extra = f"    {Y}TASK   {tid}{X} {D}(S:{stage}){X}"
    except Exception:
        pass
    print(f"{loop_color}LOOP   {loop_state}{X}    {BO}MODE   {cycle.get('name', '(none)')}{X}{task_extra}")
    print()
    # Density variant per SB-124c (operator directive 2026-05-06: minified | standard | extended)
    density = "standard"
    try:
        import json as _json2
        cfg_path = Path.home() / ".claude" / "stamp-config.json"
        if cfg_path.exists():
            density = _json2.loads(cfg_path.read_text()).get("density", "standard")
    except Exception:
        pass
    if density != "minified":
        print(f"{M}{BO}@@ JOURNEY (recent wiki/log/) @@{X}")
        try:
            from tools.progress import collect_recent_logs
            seen: dict[str, int] = {}
            ordered: list[str] = []
            for fname in collect_recent_logs(10):
                short = fname.replace(".md", "").lstrip("0123456789-")[:60]
                if short not in seen:
                    seen[short] = 1
                    ordered.append(short)
                else:
                    seen[short] += 1
            for short in ordered[:5]:
                count = seen[short]
                suffix = f"  ×{count}" if count > 1 else ""
                print(f"{D}· {short}{suffix}{X}")
        except Exception:
            print(f"{D}· (recent-logs read unavailable){X}")
        print()
        print(f"{M}{BO}@@ PLAN (operator's logical order) @@{X}")
    sb_pct = round(100 * (sbs.get("verified", 0) + sbs.get("structurally-fixed", 0)) / max(1, sbs.get("total", 1)))
    sb_bar = ("█" * (sb_pct // 7)).ljust(14, "░")
    if density != "minified":
        print(f"{Y}1. systemic bugs       {sb_bar}  ~{sb_pct}% · {sbs.get('open', 0)} open · {sbs.get('recurring', 0)} recurring{X}")
        print(f"{D}2. ccstatusline (M011) ░░░░░░░░░░░░░░  prelim · impl=operator-driven future-session{X}")
        print(f"{D}3. pipelock   (M014)   ░░░░░░░░░░░░░░  prelim done · impl=operator-driven future-session{X}")
        print()
    # Priorities — imminent-work hot-queue (SB-127), surfaces ABOVE PM-decision-tier
    try:
        prio_path = Path.home() / ".claude" / "active-priorities"
        prios: list = []
        if prio_path.exists():
            prios = [ln.strip() for ln in prio_path.read_text().splitlines() if ln.strip()]
        print(f"{M}{BO}@@ ⚡ PRIORITIES (imminent work · before PM tier) @@{X}")
        if prios:
            for i, p in enumerate(prios[:5], start=1):
                rank_color = R if i == 1 else (Y if i == 2 else G if i == 3 else D)
                print(f"{rank_color}{BO}P{i}{X}  {p[:160]}")
        else:
            print(f"{D}(none set — operator-edit via /priorities add <text>){X}")
        print()
    except Exception:
        pass

    # Questions section (operator directive 2026-05-06): agent-pending input-needed
    try:
        q_path = Path(__file__).resolve().parent.parent / ".claude" / "active-questions"
        if not q_path.exists():
            q_path = Path.home() / ".claude" / "active-questions"
        qs_v: list = []
        if q_path.exists():
            qs_v = [ln.strip() for ln in q_path.read_text().splitlines() if ln.strip()]
        print(f"{M}{BO}@@ ? QUESTIONS (agent → operator · pending input) @@{X}")
        detail_dir_v = Path.home() / ".claude" / "active-questions-detail"
        if qs_v:
            for i, q in enumerate(qs_v[:5], start=1):
                marker = f"  {D}[+detail]{X}" if (detail_dir_v / f"Q{i}.md").exists() else ""
                print(f"{Y}{BO}Q{i}{X}  {q[:160]}{marker}")
        else:
            print(f"{G}(none pending){X}")
        print()
    except Exception:
        pass
    # Tier-explicit per SB-125: real blockers (gating work) vs Epic-pending SBs (observations) vs behavioral recurring
    print(f"{M}{BO}@@ ⊘ TRACKER · tier-explicit @@{X}")
    if pending_tasks:
        print(f"{R}{len(pending_tasks)} real blockers (pending-decision)   wiki/backlog/tasks/{{{','.join(pending_tasks)}}}.md{X}")
    else:
        print(f"{G}0 real blockers{X}  {D}(project unblocked){X}")
    if open_sbs:
        print(f"{Y}{len(open_sbs)} Epic-pending SBs  ({','.join(open_sbs)}){X}  {D}— operator-scope-pending, not gating{X}")
    else:
        print(f"{G}0 Epic-pending SBs{X}")
    if recurring_sbs:
        print(f"{Y}{len(recurring_sbs)} behavioral recurring SBs  {','.join(recurring_sbs)}{X}  {D}— operator-catch-only patterns{X}")
    else:
        print(f"{G}0 behavioral recurring{X}")
    print()
    p = progress
    print(f"{G}{BO}✓ PROGRESS{X} · epic {p['epic_readiness']}% · modules {p['module_count']} · tasks {p['task_total']} ({p['task_counts'].get('done', 0)} done · {p['task_counts'].get('not-started', 0)} not-started · {p['task_counts'].get('pending-operator-decision', 0)} pending)")
    print(f"{G}            SBs {sbs.get('total', 0)} ({sbs.get('verified', 0)} verified · {sbs.get('structurally-fixed', 0)} fixed-pending · {sbs.get('open', 0)} open · {sbs.get('recurring', 0)} recurring){X}")
    print()
    print(f"{M}{BO}@@ → CURSOR · NEXT @@{X}")
    if open_sbs:
        print(f"{Y}primary systemic pick:  {open_sbs[0]}{X}")
    elif recurring_sbs:
        print(f"{Y}recurring catch:        {recurring_sbs[0]}{X}")
    else:
        print(f"{Y}(no open/recurring SBs — feature work resumes){X}")
    print(f"{B}parallel branches:      see wiki/log/ + governance/{{progress,blockers,systemic-bugs}}.md{X}")
    print()
    # Mission / Focus / Impediment — operator-explicit objective layer (SB-118 + SB-124a)
    # Always render section even when fields empty — operator-visibility preserved.
    try:
        from tools.objective import read_layer
        mission = read_layer("mission") or "(unset)"
        focus = read_layer("focus") or "(unset)"
        impediment = read_layer("impediment") or "(none — focus unblocked)"
        print(f"{M}{BO}@@ ✦ OBJECTIVE (mission · focus · impediment) @@{X}")
        print(f"{B}{BO}✦ MISSION   {X}{B}{mission}{X}")
        print(f"{M}{BO}◉ FOCUS     {X}{M}{focus}{X}")
        print(f"{Y}{BO}⚠ IMPEDIMENT{X}{Y} {impediment}{X}")
    except Exception:
        pass
    print(f"{D}{bar}{X}")
    if fence:
        print("```")


def emit_status_block(result: dict, use_color: bool = False, diff_fence: bool = False) -> None:
    """Emit the end-of-cycle status block per SB-061 + SB-060 + SB-063 + SB-064.

    Multi-consumer:
    - JSON via --json (programmatic / tools)
    - Plain via default (terminal-readable)
    - ANSI via --color (terminal direct, ANSI-rendering shell)
    - Diff-fence via --diff-fence (markdown chat / Claude Code response — verified
      to render red/green via ```diff syntax highlighting per operator 2026-05-05)
    """
    def color(text: str, code: str) -> str:
        return f"{code}{text}{C.RESET}" if use_color else text

    cycle = result["cycle"]
    blockers = result["blockers_summary"]
    progress = result["progress_summary"]
    sbs = parse_systemic_bugs_status()

    pending_tasks = blockers.get("pending_decision_tasks", [])
    open_sbs = sbs.get("open_ids", [])
    recurring_sbs = sbs.get("recurring_ids", [])

    if diff_fence:
        # Markdown ```diff format — operator-verified to render red(-)/green(+)/neutral.
        # Sections per SB-061 + SB-075 (journey/plan/cursor) + SB-076 (multi-branch).
        # Glyphs: ⊘ blocked, ✓ done, ⚠ signal, → next, · point
        from datetime import datetime as _dt_stamp
        bar = "═" * 63
        ts = _dt_stamp.now().strftime("%H:%M:%S")
        print("```diff")
        print(f"  {bar}")
        print(f"  ROOT-GHOSTPROXY · STATUS · {ts} · mode={cycle.get('mode', 'none')}")
        print(f"  {bar}")
        print()
        loop_state = 'alive' if cycle.get('valid') else 'no-mode'
        # `+` green when alive; `-` red when no-mode (broken state)
        prefix = '+' if cycle.get('valid') else '-'
        print(f"{prefix} LOOP   {loop_state}    MODE   {cycle.get('name', '(none)')}")
        print()
        # JOURNEY — recent logs, deduplicated by slug with ×N count suffix
        # `@@` prefix renders magenta (hunk-header) in ```diff fence
        print(f"@@ JOURNEY (recent wiki/log/) @@")
        recent_logs = progress.get("recent_logs_count", 0)
        try:
            from tools.progress import collect_recent_logs
            seen: dict[str, int] = {}
            ordered: list[str] = []
            # Pull more (10) to survive dedup collapse; show up to 5 distinct
            for fname in collect_recent_logs(10):
                short = fname.replace(".md", "").lstrip("0123456789-")[:60]
                if short not in seen:
                    seen[short] = 1
                    ordered.append(short)
                else:
                    seen[short] += 1
            for short in ordered[:5]:
                count = seen[short]
                suffix = f"  ×{count}" if count > 1 else ""
                # `#` prefix → comment-grey in ```diff (historical/reference)
                print(f"# · {short}{suffix}")
        except Exception:
            print(f"# · (recent-logs read unavailable; {recent_logs} logs counted)")
        print()
        # PLAN — operator-stated logical order (hardcoded ordering; counts computed)
        print(f"@@ PLAN (operator's logical order) @@")
        sb_pct = round(100 * (sbs.get("verified", 0) + sbs.get("structurally-fixed", 0)) / max(1, sbs.get("total", 1)))
        sb_bar = ("█" * (sb_pct // 7)).ljust(14, "░")
        # `!` orange = active iteration; `#` grey = operator-gated/pending
        print(f"! 1. systemic bugs       {sb_bar}  ~{sb_pct}% · {sbs.get('open', 0)} open · {sbs.get('recurring', 0)} recurring")
        print(f"# 2. ccstatusline (M011) ░░░░░░░░░░░░░░  prelim · impl=operator-driven future-session")
        print(f"# 3. pipelock   (M014)   ░░░░░░░░░░░░░░  prelim done · impl=operator-driven future-session")
        print()
        # BLOCKED — concise; semantic color: 0 = green (good), >0 = red (bad)
        print(f"@@ ⊘ BLOCKED · count · location @@")
        if pending_tasks:
            print(f"- {len(pending_tasks)} pending-operator-decision   wiki/backlog/tasks/{{{','.join(pending_tasks)}}}.md")
        else:
            print(f"+ 0 pending-operator-decision")
        if open_sbs:
            print(f"- {len(open_sbs)} open SBs  ({','.join(open_sbs)})")
        else:
            print(f"+ 0 open SBs")
        if recurring_sbs:
            print(f"- {len(recurring_sbs)} recurring SBs  {','.join(recurring_sbs)}")
        else:
            print(f"+ 0 recurring SBs")
        print()
        # PROGRESS — totals; `+` prefix → diff-fence renders green
        p = progress
        print(f"+ ✓ PROGRESS · epic {p['epic_readiness']}% · modules {p['module_count']} · tasks {p['task_total']} ({p['task_counts'].get('done', 0)} done · {p['task_counts'].get('not-started', 0)} not-started · {p['task_counts'].get('pending-operator-decision', 0)} pending)")
        print(f"+            SBs {sbs.get('total', 0)} ({sbs.get('verified', 0)} verified · {sbs.get('structurally-fixed', 0)} fixed-pending · {sbs.get('open', 0)} open · {sbs.get('recurring', 0)} recurring)")
        print()
        if result.get("lifecycle_signals"):
            print(f"  ⚠ LIFECYCLE SIGNALS")
            for s in result["lifecycle_signals"]:
                print(f"  · {s['scenario']}: {s['note']}")
            print()
        # CURSOR — `@@` magenta section header consistent with JOURNEY/PLAN
        print(f"@@ → CURSOR · NEXT @@")
        if open_sbs:
            print(f"! primary systemic pick:  {open_sbs[0]}")
        elif recurring_sbs:
            print(f"! recurring catch:        {recurring_sbs[0]}")
        else:
            print(f"! (no open/recurring SBs — feature work resumes)")
        print(f"! parallel branches:      see wiki/log/ + governance/{{progress,blockers,systemic-bugs}}.md")
        print(f"  {bar}")
        print("```")
        return

    bar = "═" * 63
    print(bar)
    title = f"ROOT-GHOSTPROXY · END-OF-CYCLE STATUS · mode={cycle.get('mode', 'none')}"
    print(color(title, C.BOLD + C.CYAN))
    print(bar)
    print()

    print(color("LOOP", C.BOLD) + f"        {'alive' if cycle.get('valid') else 'no-mode'}")
    print(color("MODE", C.BOLD) + f"        {cycle.get('name', '(none)')}")
    print()

    print(color("⊘ BLOCKED · count · location", C.BOLD + C.YELLOW))
    print(f"  pending-operator-decision   {len(pending_tasks):<3}  wiki/backlog/tasks/{{{','.join(pending_tasks)}}}.md")
    print(f"  open SBs                    {len(open_sbs):<3}  wiki/governance/systemic-bugs.md ({','.join(open_sbs[:6])}{'...' if len(open_sbs) > 6 else ''})")
    print(f"  recurring SBs               {len(recurring_sbs):<3}  {','.join(recurring_sbs)}")
    print()

    print(color("✓ PROGRESS", C.BOLD + C.GREEN))
    p = progress
    print(f"  epic readiness              {p['epic_readiness']}%")
    print(f"  modules                     {p['module_count']} total")
    print(f"  tasks                       {p['task_total']} total ({p['task_counts'].get('done', 0)} done / {p['task_counts'].get('not-started', 0)} not-started / {p['task_counts'].get('pending-operator-decision', 0)} pending-decision)")
    print(f"  systemic bugs               {sbs.get('total', 0)} total ({sbs.get('verified', 0)} verified / {sbs.get('structurally-fixed', 0)} fixed-pending / {sbs.get('open', 0)} open / {sbs.get('recurring', 0)} recurring)")
    print()

    if result.get("lifecycle_signals"):
        print(color("⚠ LIFECYCLE SIGNALS", C.BOLD + C.MAGENTA))
        for s in result["lifecycle_signals"]:
            print(f"  · {s['scenario']}: {s['note']}")
        print()

    print(color("→ NEXT PICK · systemic", C.BOLD))
    if open_sbs:
        print(f"  {open_sbs[0]} (highest-leverage open in tracker order)")
    elif recurring_sbs:
        print(f"  {recurring_sbs[0]} (operator-attention; recurring-behavior catch)")
    else:
        print("  (no open or recurring SBs — feature work resumes)")
    print()

    print(bar)


def main() -> int:
    parser = argparse.ArgumentParser(description="Cycle dispatch tool for root-modules")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--status-block", action="store_true", help="emit end-of-cycle status block (SB-061)")
    parser.add_argument("--color", action="store_true", help="use ANSI color codes (terminal mode)")
    parser.add_argument("--diff-fence", action="store_true", help="emit ```diff-fenced block (markdown chat / Claude Code — operator-verified color rendering, SB-063)")
    parser.add_argument("--ansi-fence", action="store_true", help="emit ```ansi-fenced block with ANSI escape codes (full color palette: red/green/orange/blue/magenta/cyan/dim/bold)")
    parser.add_argument("--ansi-horizontal", action="store_true", help="emit compact horizontal layout (single-line-per-section, ~6 lines) per SB-114")
    parser.add_argument("--highlight-deltas", action="store_true", help="T067 — annotate rows that changed since last fire's cached row-hashes (reads /tmp/.end-of-cycle-stamp-row-hashes.json)")
    parser.add_argument("--mode", choices=list(CYCLE_DEFINITIONS.keys()), help="override active mode")
    args = parser.parse_args()

    if args.mode:
        # Override the file-read with the explicit choice
        original_read = read_active_mode
        # bit ugly but for one-shot CLI it's fine
        result = evaluate_cycle()
        result["cycle"] = get_cycle_for_mode(args.mode)
        result["active_mode"] = args.mode
        result["override"] = True
    else:
        result = evaluate_cycle()

    if args.json:
        print(json.dumps(result, indent=2))
        return 0

    def _annotate_row_deltas(text: str) -> str:
        """T067 — annotate rows changed since last fire's cached row-hashes.

        Reads /tmp/.end-of-cycle-stamp-row-hashes.json (written by Stop hook
        after PRIOR fire's stamp). Computes current per-row hashes; for rows
        whose hash differs, prepends '▶ ' marker to the first line of that row
        section. New rows (not in cache) get '＋ '. Returns annotated text.
        """
        import hashlib as _hl
        import json as _json
        import re as _re
        import os as _os
        cache_p = "/tmp/.end-of-cycle-stamp-row-hashes.json"
        if not _os.path.exists(cache_p):
            return text  # no prior cache — nothing to diff (no markers)
        prev: dict = {}
        try:
            with open(cache_p) as _f:
                prev = _json.load(_f)
        except Exception:
            return text
        if not prev:
            return text  # empty cache file — no diff target
        # Strip volatile fields before hashing for parity with hook
        sem = _re.sub(r"\x1b\[[0-9;]*m", "", text)
        sem = _re.sub(r"\b\d{2}:\d{2}:\d{2}\b", "TIME", sem)
        sem = _re.sub(r"\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\b", "ISO", sem)
        labels = ("Status", "Journey", "Plan", "Priorities", "Questions",
                  "Tracker", "Progress", "Cursor", "Mission", "Focus",
                  "Impediment", "Blocked")
        label_re = _re.compile(rf"^[\s·@@\W]*({'|'.join(labels)})[\s·:]+", _re.MULTILINE)
        # Walk semantic text + raw text in lockstep; annotate raw lines
        sem_lines = sem.splitlines()
        raw_lines = text.splitlines()
        out_lines = list(raw_lines)
        cur_label: str | None = None
        cur_buf: list = []
        cur_first_idx: int = -1
        for i, sline in enumerate(sem_lines):
            m = label_re.match(sline)
            if m and m.group(1) in labels:
                # Flush prior section
                if cur_label is not None and cur_first_idx >= 0:
                    h = _hl.sha256("\n".join(cur_buf).encode()).hexdigest()
                    if cur_label not in prev:
                        out_lines[cur_first_idx] = "[+] " + out_lines[cur_first_idx]
                    elif prev.get(cur_label) != h:
                        out_lines[cur_first_idx] = "[Δ] " + out_lines[cur_first_idx]
                cur_label = m.group(1)
                cur_buf = [sline]
                cur_first_idx = i
            elif cur_label is not None:
                cur_buf.append(sline)
        # Flush final section
        if cur_label is not None and cur_first_idx >= 0:
            h = _hl.sha256("\n".join(cur_buf).encode()).hexdigest()
            if cur_label not in prev:
                out_lines[cur_first_idx] = "＋ " + out_lines[cur_first_idx]
            elif prev.get(cur_label) != h:
                out_lines[cur_first_idx] = "▶ " + out_lines[cur_first_idx]
        return "\n".join(out_lines)

    if args.ansi_horizontal:
        if args.highlight_deltas:
            import io as _io, sys as _sys
            _buf = _io.StringIO()
            _orig = _sys.stdout
            _sys.stdout = _buf
            try:
                emit_status_block_ansi_horizontal(result, fence=True)
            finally:
                _sys.stdout = _orig
            print(_annotate_row_deltas(_buf.getvalue()), end="")
        else:
            emit_status_block_ansi_horizontal(result, fence=True)
        return 0
    if args.ansi_fence:
        if args.highlight_deltas:
            import io as _io2, sys as _sys2
            _buf2 = _io2.StringIO()
            _orig2 = _sys2.stdout
            _sys2.stdout = _buf2
            try:
                emit_status_block_ansi(result, fence=True)
            finally:
                _sys2.stdout = _orig2
            print(_annotate_row_deltas(_buf2.getvalue()), end="")
        else:
            emit_status_block_ansi(result, fence=True)
        return 0
    if args.status_block and args.color and not args.diff_fence:
        # Raw ANSI to stdout — Bash tool output renders colors in Claude Code
        emit_status_block_ansi(result, fence=False)
        return 0
    if args.status_block or args.diff_fence:
        emit_status_block(result, use_color=args.color, diff_fence=args.diff_fence)
        return 0

    cycle = result["cycle"]
    if not cycle.get("valid"):
        print(f"⚠ {cycle['message']}")
        print()
        print("State:")
        for k, v in result["state"].items():
            print(f"  {k:<24}  {v}")
        return 0

    print(f"=== /cycle for active mode: {cycle['name']} ===")
    print(f"Lens: {', '.join(cycle['lens'])}")
    print(f"Steps:")
    for s in cycle["steps"]:
        print(f"  - {s}")
    print(f"Report emphasis: {cycle['report_emphasis']}")
    print()
    print(f"State:")
    for k, v in result["state"].items():
        print(f"  {k:<24}  {v}")
    print()
    print(f"Blockers: {len(result['blockers_summary']['pending_decision_tasks'])} pending; in-sync={result['blockers_summary']['in_sync']}")
    p = result["progress_summary"]
    print(f"Progress: epic readiness {p['epic_readiness']}%; {p['module_count']} modules; {p['task_total']} tasks ({p['task_counts'].get('done', 0)} done / {p['task_counts'].get('not-started', 0)} not-started / {p['task_counts'].get('pending-operator-decision', 0)} pending-decision)")

    if result["lifecycle_signals"]:
        print()
        print(f"Lifecycle signals (per loop-cron-lifecycle.md):")
        for s in result["lifecycle_signals"]:
            print(f"  ⚠ {s['scenario']}: {s['note']}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
