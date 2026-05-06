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
        "lifecycle_signals": lifecycle_signals,
    }


from tools._paths import SYSTEMIC_BUGS_DOC as SYSTEMIC_BUGS_PATH


def parse_systemic_bugs_status() -> dict:
    """Parse status counts from systemic-bugs.md tracker."""
    if not SYSTEMIC_BUGS_PATH.exists():
        return {"open": 0, "structurally-fixed": 0, "verified": 0, "recurring": 0, "total": 0}
    content = SYSTEMIC_BUGS_PATH.read_text()
    import re
    rows = re.findall(r"^\| (SB-\d+) \| .+? \| ([a-z\-]+) \|", content, re.MULTILINE)
    counts: dict = {}
    open_ids: list = []
    recurring_ids: list = []
    for sb_id, status in rows:
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
    """Compact horizontal stamp — single-line-per-section, ~6 lines total.
    Per SB-114 sub-req (a): operator wants horizontal mode that puts sections
    horizontally instead of vertically (stacked).
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

    if fence:
        print("```ansi")

    # STATUS line: timestamp + mode + LOOP + MODE
    loop_state = "alive" if cycle.get("valid") else "no-mode"
    loop_color = G if cycle.get("valid") else R
    print(f"{BO}{K}[STATUS]{X} {D}{ts}{X} · mode={cycle.get('mode', 'none')} · {loop_color}LOOP:{loop_state}{X} · {BO}MODE:{cycle.get('name', '(none)')}{X}")

    # JOURNEY line: deduped recent log slugs joined by · separator
    journey_slugs = []
    try:
        from tools.progress import collect_recent_logs
        seen: dict[str, int] = {}
        ordered: list[str] = []
        for fname in collect_recent_logs(10):
            short = fname.replace(".md", "").lstrip("0123456789-")[:50]
            if short not in seen:
                seen[short] = 1
                ordered.append(short)
            else:
                seen[short] += 1
        for short in ordered[:5]:
            count = seen[short]
            suffix = f"×{count}" if count > 1 else ""
            journey_slugs.append(f"{short}{suffix}")
    except Exception:
        journey_slugs = ["(unavailable)"]
    print(f"{M}{BO}[JOURNEY]{X} {D}" + " · ".join(journey_slugs) + f"{X}")

    # PLAN line: 3 priorities inline
    sb_pct = round(100 * (sbs.get("verified", 0) + sbs.get("structurally-fixed", 0)) / max(1, sbs.get("total", 1)))
    print(f"{M}{BO}[PLAN]{X} {Y}SB:{sb_pct}%({sbs.get('open', 0)}o/{sbs.get('recurring', 0)}r){X} · {D}M011:prelim · M014:prelim-done{X}")

    # BLOCKED line: pending + open + recurring all inline
    pending_str = f"{G}0p{X}" if not pending_tasks else f"{R}{len(pending_tasks)}p{X}"
    open_str = f"{G}0o{X}" if not open_sbs else f"{R}{len(open_sbs)}o{X}({','.join(open_sbs[:3])}{'...' if len(open_sbs) > 3 else ''})"
    rec_str = f"{G}0r{X}" if not recurring_sbs else f"{R}{len(recurring_sbs)}r{X}({','.join(recurring_sbs[:3])}{'...' if len(recurring_sbs) > 3 else ''})"
    print(f"{M}{BO}[BLOCKED]{X} {pending_str} · {open_str} · {rec_str}")

    # PROGRESS line: all counts inline
    p = progress
    print(f"{M}{BO}[PROGRESS]{X} {G}epic:{p['epic_readiness']}% · mod:{p['module_count']} · tasks:{p['task_total']}({p['task_counts'].get('done', 0)}d/{p['task_counts'].get('not-started', 0)}n/{p['task_counts'].get('pending-operator-decision', 0)}p) · SB:{sbs.get('total', 0)}({sbs.get('verified', 0)}v/{sbs.get('structurally-fixed', 0)}f/{sbs.get('open', 0)}o/{sbs.get('recurring', 0)}r){X}")

    # NEXT line: cursor pick + branches
    next_pick = open_sbs[0] if open_sbs else (recurring_sbs[0] if recurring_sbs else "(none)")
    print(f"{M}{BO}[NEXT]{X} {Y}{next_pick}{X} · {B}branches:wiki/log+governance{X}")

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
    print(f"{loop_color}LOOP   {loop_state}{X}    {BO}MODE   {cycle.get('name', '(none)')}{X}")
    print()
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
    print(f"{Y}1. systemic bugs       {sb_bar}  ~{sb_pct}% · {sbs.get('open', 0)} open · {sbs.get('recurring', 0)} recurring{X}")
    print(f"{D}2. ccstatusline (M011) ░░░░░░░░░░░░░░  prelim · impl=operator-driven future-session{X}")
    print(f"{D}3. pipelock   (M014)   ░░░░░░░░░░░░░░  prelim done · impl=operator-driven future-session{X}")
    print()
    print(f"{M}{BO}@@ ⊘ BLOCKED · count · location @@{X}")
    if pending_tasks:
        print(f"{R}{len(pending_tasks)} pending-operator-decision   wiki/backlog/tasks/{{{','.join(pending_tasks)}}}.md{X}")
    else:
        print(f"{G}0 pending-operator-decision{X}")
    if open_sbs:
        print(f"{R}{len(open_sbs)} open SBs  ({','.join(open_sbs)}){X}")
    else:
        print(f"{G}0 open SBs{X}")
    if recurring_sbs:
        print(f"{R}{len(recurring_sbs)} recurring SBs  {','.join(recurring_sbs)}{X}")
    else:
        print(f"{G}0 recurring SBs{X}")
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
    parser = argparse.ArgumentParser(description="Cycle dispatch tool for root-ghostproxy")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--status-block", action="store_true", help="emit end-of-cycle status block (SB-061)")
    parser.add_argument("--color", action="store_true", help="use ANSI color codes (terminal mode)")
    parser.add_argument("--diff-fence", action="store_true", help="emit ```diff-fenced block (markdown chat / Claude Code — operator-verified color rendering, SB-063)")
    parser.add_argument("--ansi-fence", action="store_true", help="emit ```ansi-fenced block with ANSI escape codes (full color palette: red/green/orange/blue/magenta/cyan/dim/bold)")
    parser.add_argument("--ansi-horizontal", action="store_true", help="emit compact horizontal layout (single-line-per-section, ~6 lines) per SB-114")
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

    if args.ansi_horizontal:
        emit_status_block_ansi_horizontal(result, fence=True)
        return 0
    if args.ansi_fence:
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
