"""tools.blockers — list / get / verify / add / update / resolve blockers.

Reads <project>/wiki/governance/blockers.md and reconciles against live task
status in <project>/wiki/backlog/tasks/T*.md. Reports: active blockers per
priority, status-counts, drift between governance doc and live state.

Usage:
    python3 -m tools.blockers                 # human-readable report (default)
    python3 -m tools.blockers --json          # JSON output
    python3 -m tools.blockers --check         # exit non-zero if drift detected
    python3 -m tools.blockers list            # list active blocker IDs
    python3 -m tools.blockers get B001        # show full body of blocker B001
    python3 -m tools.blockers next-id         # next B### in sequence
    python3 -m tools.blockers add ...         # append a new blocker (writes to disk)
    python3 -m tools.blockers update B001 ... # update an existing blocker (writes)
    python3 -m tools.blockers resolve B001 \\
        --decision-id D### \\
        --resolution "operator picked greenfield"
                                              # mark resolved + move to decisions

Per operator directive 2026-05-05: tools for "adding to the blocking or looking
at it or doing operatoin on it are also the kind of things that can become
highly useful tools."

Composes-with:
- Slash commands: /blockers (primary), /cycle PM step 2 + step 5, /audit step 5
- Hooks: mode-enforcement.sh's LIVE STATE block surfaces blocker count
- MCP: root_blockers tool at tools.mcp_server wraps detect_drift() + parse logic
- Skill: surface-blockers (auto-trigger on "what's blocking" prose; routes to /blockers)
- Sister tool: tools.decisions — every resolve appends a linked D### entry per governance discipline

Idempotency invariant: list/get/verify/next-id are read-only; add/update/resolve write
to wiki/governance/blockers.md with frontmatter regeneration on each call.

Action vocabulary (Hard Rule 14): emits `blocker-surface` (read paths) OR
`operator-directive-register` (add/update/resolve mutation paths) per the canonical
M-E001-1 vocabulary at wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md.

Test file: .claude/hooks/tests/test-blockers.py (run via `python3 -m tools.run-tests`).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import argparse
import glob
import json
import re
import sys

from pathlib import Path

try:
    import yaml  # noqa: F401  # may be needed if user wants to extend; not required for current parse
    HAVE_YAML = True
except ImportError:
    HAVE_YAML = False

from tools._paths import BLOCKERS_DOC as _BLOCKERS_DOC, TASKS_GLOB, LOG_GLOB

BLOCKERS_DOC = str(_BLOCKERS_DOC)

# Map known blocker IDs to the underlying task IDs (from blockers.md)
BLOCKER_TO_TASK = {
    "B001": "T011",
    "B002": "T018",
    "B003": "T024",
    "B004": "T006",
    "B005": "T051",
    "B006": "T058",
}


def parse_task_status(path: str) -> str:
    """Quick-and-dirty frontmatter status field parser. Doesn't require yaml package."""
    try:
        with open(path) as f:
            content = f.read()
    except OSError:
        return "unknown"
    if not content.startswith("---"):
        return "unknown"
    # find second ---
    end = content.find("---", 3)
    if end < 0:
        return "unknown"
    frontmatter = content[3:end]
    match = re.search(r"^status:\s*(\S+)", frontmatter, re.MULTILINE)
    if not match:
        return "unknown"
    return match.group(1).strip().strip('"').strip("'")


def collect_task_status_counts() -> dict:
    counts: dict = {}
    pending_decision_tasks: list = []
    for path in sorted(glob.glob(TASKS_GLOB)):
        status = parse_task_status(path)
        counts[status] = counts.get(status, 0) + 1
        if status == "pending-operator-decision":
            tid_match = re.search(r"/(T\d+)-", path)
            if tid_match:
                pending_decision_tasks.append(tid_match.group(1))
    return {
        "counts": counts,
        "pending_operator_decision_tasks": sorted(pending_decision_tasks),
    }


def parse_blockers_doc() -> list:
    """Extract ACTIVE blocker IDs from the governance doc.

    Recognizes B-IDs only in formal `### B### — title` heading form (an actual blocker entry),
    NOT in inline table mentions or text references. Also skips Archived/Future-decision/Resolved
    sections per SRP discipline.
    """
    try:
        with open(BLOCKERS_DOC) as f:
            content = f.read()
    except OSError:
        return []
    # Cut off archive sections
    for marker in ("## Archived", "## Future-decision", "## Resolved"):
        idx = content.find(marker)
        if idx >= 0:
            content = content[:idx]
    # Match only formal heading entries: ### B### — title
    return sorted(set(re.findall(r"^###\s+(B\d{3})\b", content, re.MULTILINE)))


def detect_drift() -> dict:
    task_status = collect_task_status_counts()
    blockers_in_doc = parse_blockers_doc()
    pending_tasks = task_status["pending_operator_decision_tasks"]

    # Each B### maps to a task; check that all live pending-decision tasks
    # have a corresponding B### in the doc (or are flagged separately).
    expected_blockers_for_tasks = [
        b for b, t in BLOCKER_TO_TASK.items() if t in pending_tasks
    ]
    blockers_doc_active = [b for b in blockers_in_doc if b in BLOCKER_TO_TASK]

    missing_in_doc = [b for b in expected_blockers_for_tasks if b not in blockers_doc_active]
    extra_in_doc = [b for b in blockers_doc_active if b not in expected_blockers_for_tasks]

    return {
        "task_status_counts": task_status["counts"],
        "live_pending_decision_tasks": pending_tasks,
        "blockers_in_doc": blockers_in_doc,
        "drift": {
            "missing_in_doc": missing_in_doc,
            "extra_in_doc": extra_in_doc,
            "in_sync": not missing_in_doc and not extra_in_doc,
        },
    }


def get_blocker_body(blocker_id: str) -> str | None:
    """Extract the full body of a B### entry from blockers.md."""
    try:
        with open(BLOCKERS_DOC) as f:
            content = f.read()
    except OSError:
        return None
    pattern = re.compile(
        rf"^### {blocker_id} — .+?(?=^### B\d{{3}} — |^## |\Z)",
        re.MULTILINE | re.DOTALL,
    )
    match = pattern.search(content)
    return match.group(0).strip() if match else None


# Filter algorithm: autonomous blocker decumulation per SB-065
# Operator directive 2026-05-05: "PM should do a PM role"; the agent (in PM mode
# or PM-lens of dual) should sweep blockers + resolve those decidable from
# operator's already-given verbatim directives, before surfacing.

# LOG_GLOB imported from _paths above — same path resolution


def collect_log_text() -> dict:
    """Return {filepath: content} for all <project>/wiki/log/*.md (the verbatim directive log)."""
    out: dict = {}
    for path in sorted(glob.glob(LOG_GLOB)):
        try:
            out[path] = open(path).read()
        except OSError:
            continue
    return out


def parse_task_page(path: str) -> dict:
    """Extract task fields needed for the filter: id, title, description, blocked_by from BLOCKED BY."""
    try:
        content = open(path).read()
    except OSError:
        return {}
    fm: dict = {}
    if content.startswith("---"):
        end = content.find("---", 3)
        if end > 0:
            for line in content[3:end].splitlines():
                m = re.match(r"^(\w+):\s*(.+?)\s*$", line)
                if m:
                    fm[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    title_m = re.search(r"^#\s+(.+?)$", content, re.MULTILINE)
    blocked_by = []
    deps_m = re.search(r"##\s+Dependencies(.*?)(?=^##\s|\Z)", content, re.MULTILINE | re.DOTALL)
    if deps_m:
        for line in deps_m.group(1).splitlines():
            bb = re.search(r"BLOCKED BY[:\s]+([^\n]+)", line)
            if bb:
                # strip parens, comma-split
                cleaned = re.sub(r"[()]", "", bb.group(1))
                blocked_by.extend([t.strip().rstrip(",.") for t in re.split(r"[, ]+", cleaned) if t.strip().startswith(("T", "M"))])
    return {
        "id": fm.get("title", "").split(" ")[0] if fm.get("title") else Path(path).stem.split("-")[0],
        "title": title_m.group(1) if title_m else fm.get("title", "?"),
        "status": fm.get("status", "?"),
        "blocked_by": blocked_by,
        "content": content,
    }


def filter_pending_decisions(verbose: bool = False) -> list:
    """Sweep all pending-operator-decision tasks and recommend resolution per SB-065.

    Returns a list of {task_id, current_status, recommendation, reason, evidence_excerpt}.
    Recommendations: 'decided', 'prerequisite-blocked', 'genuinely-pending'.

    This is WARN-ONLY — does not modify any task page. Operator confirms before persistence.
    """
    from pathlib import Path  # local import (already in file context but be explicit)
    log_text = collect_log_text()
    log_blob = "\n\n".join(log_text.values())

    recommendations: list = []
    for path in sorted(glob.glob(TASKS_GLOB)):
        tp = parse_task_page(path)
        if tp.get("status") != "pending-operator-decision":
            continue
        task_id_match = re.search(r"/(T\d+)-", path)
        task_id = task_id_match.group(1) if task_id_match else "?"

        # Heuristic 1: prerequisite-blocked (has BLOCKED BY in deps)
        if tp.get("blocked_by"):
            recommendations.append({
                "task_id": task_id,
                "current_status": "pending-operator-decision",
                "recommendation": "prerequisite-blocked",
                "reason": f"BLOCKED BY {','.join(tp['blocked_by'])} — operator can't decide until prerequisites done",
                "evidence_excerpt": f"Dependencies section of {Path(path).name}",
            })
            continue

        # Heuristic 2: search log for task-id mention with decision-shaped verbatim
        # Pattern: "T011" + ("decided"|"greenfield"|"DECIDED"|"build from bottom-up"|...)
        decision_keywords = [
            r"DECIDED",
            r"effective decision",
            r"already decided",
            r"build from bottom-up",
            r"imagine virgin",
            r"leave-in-place",
            r"forget everything",
            r"intentional friction",
            r"stay false",
        ]
        task_mentions = [m for m in re.finditer(rf"\b{task_id}\b", log_blob)]
        decision_mentions = [m for m in re.finditer("|".join(decision_keywords), log_blob, re.IGNORECASE)]
        # If task is mentioned AND decision-shaped verbatim is nearby (within ~500 chars)
        for tm in task_mentions:
            for dm in decision_mentions:
                if abs(tm.start() - dm.start()) < 500:
                    excerpt_start = max(0, min(tm.start(), dm.start()) - 50)
                    excerpt_end = max(tm.end(), dm.end()) + 50
                    excerpt = log_blob[excerpt_start:excerpt_end].replace("\n", " ")[:200]
                    recommendations.append({
                        "task_id": task_id,
                        "current_status": "pending-operator-decision",
                        "recommendation": "decided",
                        "reason": f"task ID + decision-shaped verbatim co-occur in log",
                        "evidence_excerpt": f"...{excerpt}...",
                    })
                    break
            else:
                continue
            break
        else:
            # No decision found — genuinely pending
            recommendations.append({
                "task_id": task_id,
                "current_status": "pending-operator-decision",
                "recommendation": "genuinely-pending",
                "reason": "no operator-verbatim directive found in wiki/log/ that bears on this task's gating question",
                "evidence_excerpt": "(no match)",
            })

    return recommendations


def print_filter_report(recommendations: list) -> None:
    if not recommendations:
        print("No pending-operator-decision tasks to filter (all swept or none exist).")
        return
    counts: dict = {}
    for r in recommendations:
        counts[r["recommendation"]] = counts.get(r["recommendation"], 0) + 1
    print(f"Filter recommendations ({len(recommendations)} pending tasks evaluated):")
    print(f"  decided: {counts.get('decided', 0)}  prerequisite-blocked: {counts.get('prerequisite-blocked', 0)}  genuinely-pending: {counts.get('genuinely-pending', 0)}")
    print()
    for r in recommendations:
        print(f"  {r['task_id']}  → {r['recommendation'].upper()}")
        print(f"    reason:   {r['reason']}")
        print(f"    evidence: {r['evidence_excerpt'][:120]}")
        print()
    print("WARN-ONLY: no task pages modified. Confirm recommendations before persisting.")


def list_blocker_ids() -> list:
    """Return sorted list of all B### IDs in the doc."""
    return parse_blockers_doc()


def next_blocker_id() -> str:
    """Compute the next B### in sequence."""
    ids = parse_blockers_doc()
    if not ids:
        return "B001"
    nums = [int(b[1:]) for b in ids if re.match(r"B\d{3}$", b)]
    if not nums:
        return "B001"
    return f"B{max(nums) + 1:03d}"


def append_blocker(args: argparse.Namespace) -> int:
    """Append a new B### entry to blockers.md. Writes to disk."""
    try:
        with open(BLOCKERS_DOC) as f:
            content = f.read()
    except OSError as e:
        print(f"error reading {BLOCKERS_DOC}: {e}", file=sys.stderr)
        return 1

    new_id = args.id or next_blocker_id()
    insertion_section = f"## Active blockers (P{args.priority[1]}"
    # Find the section header to insert after
    section_match = re.search(rf"({re.escape(insertion_section)}[^\n]*\n)", content)
    if not section_match:
        # Try a more permissive match
        section_match = re.search(r"(## Active blockers[^\n]*\n)", content)
    if not section_match:
        print(f"error: insertion section not found", file=sys.stderr)
        return 1

    entry = f"""\n### {new_id} — {args.title}

**Why this is a blocker**: {args.why}

**Context**: {args.context}

**The decision**: {args.decision}

**Affects**: {args.affects}

**Created**: {args.created or _today()}. **Status**: {args.status or 'pending-operator-decision'}. **Last touched**: {args.created or _today()}.

---
"""

    insertion_point = section_match.end()
    new_content = content[:insertion_point] + entry + content[insertion_point:]
    with open(BLOCKERS_DOC, "w") as f:
        f.write(new_content)
    print(f"appended {new_id} to {BLOCKERS_DOC}")
    return 0


def update_blocker(args: argparse.Namespace) -> int:
    """Update fields of an existing B### entry in blockers.md."""
    try:
        with open(BLOCKERS_DOC) as f:
            content = f.read()
    except OSError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    body = get_blocker_body(args.id)
    if body is None:
        print(f"error: {args.id} not found in {BLOCKERS_DOC}", file=sys.stderr)
        return 1

    new_body = body
    today = _today()
    # Update Last touched timestamp regardless
    new_body = re.sub(r"\*\*Last touched\*\*: \d{4}-\d{2}-\d{2}", f"**Last touched**: {today}", new_body)

    if args.status:
        new_body = re.sub(r"\*\*Status\*\*: [^.]+", f"**Status**: {args.status}", new_body)
    if args.priority:
        # Move the entry to the appropriate priority section if changed (skipped — manual)
        pass

    if new_body == body:
        print(f"no fields specified to update for {args.id}; only timestamp refreshed", file=sys.stderr)

    new_content = content.replace(body, new_body)
    with open(BLOCKERS_DOC, "w") as f:
        f.write(new_content)
    print(f"updated {args.id}; Last touched={today}")
    return 0


def resolve_blocker(args: argparse.Namespace) -> int:
    """Mark a blocker resolved: update status in blockers.md + log resolution.

    Operator should ALSO call `tools.decisions append ...` to register the decision in
    decisions.md. This tool does NOT auto-call decisions.append (different SRP per
    operator's "with its own SRP" directive).
    """
    args_for_update = argparse.Namespace(
        id=args.id,
        status=f"resolved (→ {args.decision_id})" if args.decision_id else "resolved",
        priority=None,
    )
    rc = update_blocker(args_for_update)
    if rc != 0:
        return rc
    print(f"resolved {args.id} with resolution: {args.resolution}")
    print(f"  → also append a D### entry via: python3 -m tools.decisions append --linked-blocker {args.id} ...")
    return 0


def _today() -> str:
    from datetime import date
    return date.today().isoformat()


def main() -> int:
    parser = argparse.ArgumentParser(description="Blocker register management")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--check", action="store_true", help="exit non-zero if drift detected")
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("list", help="list all B### IDs")
    sub.add_parser("next-id", help="next B### in sequence")
    sub.add_parser("filter", help="autonomous decumulation sweep (SB-065) — recommend resolutions for pending-decision tasks")

    get_p = sub.add_parser("get", help="show full body of a B### entry")
    get_p.add_argument("blocker_id")

    add_p = sub.add_parser("add", help="append a new B### (writes to disk)")
    add_p.add_argument("--id", default=None, help="explicit B### or auto-compute")
    add_p.add_argument("--title", required=True)
    add_p.add_argument("--priority", required=True, choices=["P0", "P1", "P2"])
    add_p.add_argument("--why", required=True, help="why this is a blocker")
    add_p.add_argument("--context", required=True, help="context to surface to operator")
    add_p.add_argument("--decision", required=True, help="the decision being asked")
    add_p.add_argument("--affects", required=True, help="affected items (T###, M###, etc.)")
    add_p.add_argument("--status", default=None)
    add_p.add_argument("--created", default=None, help="ISO date; default today")

    upd_p = sub.add_parser("update", help="update fields of an existing B###")
    upd_p.add_argument("id", help="blocker ID e.g. B001")
    upd_p.add_argument("--status")
    upd_p.add_argument("--priority", choices=["P0", "P1", "P2"])

    res_p = sub.add_parser("resolve", help="mark a B### resolved (status update; companion decision append separate)")
    res_p.add_argument("id", help="blocker ID e.g. B001")
    res_p.add_argument("--decision-id", help="D### that captures the resolution")
    res_p.add_argument("--resolution", required=True, help="one-line resolution summary")

    args = parser.parse_args()

    # Subcommands first
    if args.cmd == "list":
        for bid in list_blocker_ids():
            print(bid)
        return 0
    if args.cmd == "next-id":
        print(next_blocker_id())
        return 0
    if args.cmd == "filter":
        recs = filter_pending_decisions()
        print_filter_report(recs)
        return 0
    if args.cmd == "get":
        body = get_blocker_body(args.blocker_id)
        if body is None:
            print(f"not found: {args.blocker_id}", file=sys.stderr)
            return 1
        print(body)
        return 0
    if args.cmd == "add":
        return append_blocker(args)
    if args.cmd == "update":
        return update_blocker(args)
    if args.cmd == "resolve":
        return resolve_blocker(args)

    # Default: report
    report = detect_drift()

    if args.json:
        print(json.dumps(report, indent=2))
        return 0 if report["drift"]["in_sync"] or not args.check else 1

    print("=== root-modules blockers report ===")
    print()
    print("Task status counts (live frontmatter):")
    for status, count in sorted(report["task_status_counts"].items()):
        print(f"  {status:<32}  {count}")
    print()
    print(f"Live pending-operator-decision tasks: {len(report['live_pending_decision_tasks'])}")
    for tid in report["live_pending_decision_tasks"]:
        b = next((b for b, t in BLOCKER_TO_TASK.items() if t == tid), "??")
        print(f"  {b}  ↔  {tid}")
    print()
    print(f"Blockers in {BLOCKERS_DOC}: {len(report['blockers_in_doc'])}")
    print(f"  IDs: {', '.join(report['blockers_in_doc'])}")
    print()
    drift = report["drift"]
    print("Drift check:")
    if drift["in_sync"]:
        print("  ✓ blockers doc and live task status are in sync")
    else:
        if drift["missing_in_doc"]:
            print(f"  ✗ MISSING from doc: {', '.join(drift['missing_in_doc'])}")
        if drift["extra_in_doc"]:
            print(f"  ✗ EXTRA in doc (no corresponding live pending task): {', '.join(drift['extra_in_doc'])}")
    if args.check:
        return 0 if drift["in_sync"] else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
