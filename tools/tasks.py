"""tools.tasks — drill-down view into individual tasks: status + module + Done When.

Addresses F-eval-8 (operator-flagged gap 2026-05-05): "if tools dont give you a
view yet into the tasks and what is to be done you have to report it and it needs
to be addressed". `tools.progress` shows aggregate counts; `tools.blockers` shows
operator-decision pending only. This tool surfaces individual tasks with their
title, module, status, priority, current_stage, readiness, and a count of Done
When checkboxes (total / checked / unchecked).

Usage:
    python3 -m tools.tasks list                       # all tasks, condensed
    python3 -m tools.tasks list --status not-started  # filter by status
    python3 -m tools.tasks list --module M003         # tasks in module M003
    python3 -m tools.tasks list --priority P0         # tasks at priority P0
    python3 -m tools.tasks list --json                # JSON output
    python3 -m tools.tasks get T011                   # single task with Done When detail
    python3 -m tools.tasks claimable                  # not-started tasks with no BLOCKED BY

active-task state file (SB-124d audit — task cursor management):
    python3 -m tools.tasks active show                # print current active-task + drill-down
    python3 -m tools.tasks active set T012            # set active task (validates ID exists)
    python3 -m tools.tasks active clear               # empty state file
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
from pathlib import Path

from tools._paths import TASKS_GLOB

ACTIVE_TASK_FILE = Path(os.environ.get("HOME", "/root")) / ".claude" / "active-task"


def parse_frontmatter(path: str) -> dict:
    try:
        content = Path(path).read_text()
    except OSError:
        return {}
    if not content.startswith("---"):
        return {}
    end = content.find("---", 3)
    if end < 0:
        return {}
    fm = {}
    for line in content[3:end].splitlines():
        m = re.match(r"^(\w+):\s*(.+?)\s*$", line)
        if m:
            fm[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return fm


def parse_done_when(path: str) -> dict:
    """Count Done When checkboxes: total, checked [x], unchecked [ ]."""
    try:
        content = Path(path).read_text()
    except OSError:
        return {"total": 0, "checked": 0, "unchecked": 0}
    # Find Done When section
    m = re.search(r"##\s+Done When(.*?)(?=^##\s|\Z)", content, re.MULTILINE | re.DOTALL)
    if not m:
        return {"total": 0, "checked": 0, "unchecked": 0}
    section = m.group(1)
    checked = len(re.findall(r"^\s*-\s+\[x\]", section, re.MULTILINE | re.IGNORECASE))
    unchecked = len(re.findall(r"^\s*-\s+\[ \]", section, re.MULTILINE))
    return {"total": checked + unchecked, "checked": checked, "unchecked": unchecked}


def parse_blocked_by(path: str) -> list:
    """Parse Dependencies section for BLOCKED BY references."""
    try:
        content = Path(path).read_text()
    except OSError:
        return []
    m = re.search(r"##\s+Dependencies(.*?)(?=^##\s|\Z)", content, re.MULTILINE | re.DOTALL)
    if not m:
        return []
    section = m.group(1)
    blockers = re.findall(r"BLOCKED BY[:\s]+([T0-9, ]+)", section)
    out: list = []
    for b in blockers:
        out.extend(t.strip() for t in b.split(",") if t.strip())
    return out


def collect_task(path: str) -> dict:
    fm = parse_frontmatter(path)
    dw = parse_done_when(path)
    blocked = parse_blocked_by(path)
    task_id = Path(path).stem.split("-")[0]  # T001 from T001-foo.md
    title_match = re.search(r"^#\s+(.+?)$", Path(path).read_text(), re.MULTILINE)
    return {
        "id": task_id,
        "path": path,
        "title": title_match.group(1) if title_match else fm.get("title", "?"),
        "status": fm.get("status", "?"),
        "priority": fm.get("priority", "?"),
        "parent_module": fm.get("parent_module", "?"),
        "current_stage": fm.get("current_stage", "?"),
        "readiness": fm.get("readiness", "0"),
        "sfif_stage": fm.get("sfif_stage", "?"),
        "done_when": dw,
        "blocked_by": blocked,
    }


def collect_all_tasks() -> list:
    return sorted(
        (collect_task(p) for p in glob.glob(TASKS_GLOB)),
        key=lambda t: t["id"],
    )


def filter_tasks(tasks: list, status: str = "", module: str = "", priority: str = "") -> list:
    out = tasks
    if status:
        out = [t for t in out if t["status"] == status]
    if module:
        out = [t for t in out if module.lower() in t["parent_module"].lower()]
    if priority:
        out = [t for t in out if t["priority"] == priority]
    return out


def claimable_tasks(tasks: list) -> list:
    return [t for t in tasks if t["status"] == "not-started" and not t["blocked_by"]]


def print_task_line(t: dict) -> None:
    dw = t["done_when"]
    dw_str = f"{dw['checked']}/{dw['total']}" if dw["total"] else "-"
    blocked = f" [BLOCKED BY {','.join(t['blocked_by'])}]" if t["blocked_by"] else ""
    print(
        f"  {t['id']:<6}  {t['priority']:<3}  {t['status']:<28}  "
        f"{t['current_stage']:<10}  rdy={t['readiness']:<3}  "
        f"DW={dw_str:<6}  {t['title'][:60]}{blocked}"
    )


def print_task_detail(t: dict) -> None:
    print(f"=== {t['id']} ===")
    print(f"Title:         {t['title']}")
    print(f"Path:          {t['path']}")
    print(f"Status:        {t['status']}")
    print(f"Priority:      {t['priority']}")
    print(f"Module:        {t['parent_module']}")
    print(f"Stage:         {t['current_stage']} (readiness {t['readiness']})")
    print(f"SFIF stage:    {t['sfif_stage']}")
    dw = t["done_when"]
    print(f"Done When:     {dw['checked']}/{dw['total']} checked, {dw['unchecked']} unchecked")
    if t["blocked_by"]:
        print(f"BLOCKED BY:    {', '.join(t['blocked_by'])}")
    else:
        print("BLOCKED BY:    (none)")


def main() -> int:
    parser = argparse.ArgumentParser(description="Drill-down view into individual tasks")
    sub = parser.add_subparsers(dest="cmd", required=True)

    list_p = sub.add_parser("list", help="list tasks, condensed")
    list_p.add_argument("--status", default="", help="filter by status (e.g., not-started)")
    list_p.add_argument("--module", default="", help="filter by parent_module substring")
    list_p.add_argument("--priority", default="", help="filter by priority (P0/P1/P2)")
    list_p.add_argument("--json", action="store_true")

    get_p = sub.add_parser("get", help="single task detail")
    get_p.add_argument("task_id")

    sub.add_parser("claimable", help="not-started tasks with no BLOCKED BY")

    active_p = sub.add_parser("active", help="manage $HOME/.claude/active-task cursor")
    active_sub = active_p.add_subparsers(dest="active_cmd", required=True)
    active_sub.add_parser("show", help="print current active task + drill-down")
    active_set = active_sub.add_parser("set", help="set active task to given ID (validates)")
    active_set.add_argument("task_id")
    active_sub.add_parser("clear", help="empty active-task state file")

    args = parser.parse_args()
    tasks = collect_all_tasks()

    if args.cmd == "list":
        filtered = filter_tasks(tasks, args.status, args.module, args.priority)
        if args.json:
            print(json.dumps(filtered, indent=2))
            return 0
        print(f"Tasks ({len(filtered)}/{len(tasks)} shown):")
        print(f"  {'ID':<6}  {'pri':<3}  {'status':<28}  {'stage':<10}  rdy=    DW=     title")
        for t in filtered:
            print_task_line(t)
        return 0

    if args.cmd == "get":
        match = next((t for t in tasks if t["id"].lower() == args.task_id.lower()), None)
        if not match:
            print(f"not found: {args.task_id}", file=sys.stderr)
            return 1
        print_task_detail(match)
        return 0

    if args.cmd == "claimable":
        claimable = claimable_tasks(tasks)
        print(f"Claimable tasks ({len(claimable)} of {len(tasks)} not-blocked, not-started):")
        for t in claimable:
            print_task_line(t)
        return 0

    if args.cmd == "active":
        if args.active_cmd == "show":
            current = ""
            if ACTIVE_TASK_FILE.exists():
                current = ACTIVE_TASK_FILE.read_text().strip()
            if not current:
                print("active-task: (none)")
                return 0
            match = next((t for t in tasks if t["id"].lower() == current.lower()), None)
            if not match:
                print(f"active-task: {current}  (not found in backlog — stale cursor)")
                return 0
            print(f"active-task: {current}")
            print()
            print_task_detail(match)
            return 0

        if args.active_cmd == "set":
            tid = args.task_id.strip()
            match = next((t for t in tasks if t["id"].lower() == tid.lower()), None)
            if not match:
                print(f"refused: task '{tid}' not in backlog", file=sys.stderr)
                return 1
            ACTIVE_TASK_FILE.parent.mkdir(parents=True, exist_ok=True)
            ACTIVE_TASK_FILE.write_text(match["id"] + "\n")
            print(f"active-task → {match['id']}: {match['title'][:60]}")
            return 0

        if args.active_cmd == "clear":
            if ACTIVE_TASK_FILE.exists():
                ACTIVE_TASK_FILE.write_text("")
            print("active-task: cleared")
            return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
