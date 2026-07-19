"""tools.progress — compute current SFIF stage + module/task readiness from live state.

Doesn't read <project>/wiki/governance/progress.md (that's the human-readable doc;
this tool computes the underlying state empirically). Use:

    python3 -m tools.progress              # human-readable report
    python3 -m tools.progress --json       # JSON output
    python3 -m tools.progress --callout    # just the "Current position" callout block

Composes-with:
- Slash commands: /progress, /sync-progress (drift detect + apply), /cycle (every mode's step),
  /audit step 4
- Hooks: pre-compact.sh reads compute_progress() output to include in its auto-snapshot;
  mode-enforcement banner surfaces stage from this output
- MCP: root_progress tool at tools.mcp_server wraps compute_progress()
- Sister tool: tools.cycle imports compute_progress() for cycle-status block

Operator-authority surfaces (read this tool's output when operator invokes them; agent
does NOT auto-invoke these): /handoff, /terminate, /finish-smoothly are operator-typed
session-control commands; they collect state via tools.progress when run.

Idempotency invariant: read-only; reads frontmatter from wiki/backlog/{tasks,modules}/*.md +
EPIC_DOC; computes counts; never mutates filesystem.

Action vocabulary (Hard Rule 14): emits `read-only-audit` (default) OR
`drift-fix-with-empirical` action type when used as drift-detector by /sync-progress
per Hard Rule 14 + the M-E001-1 vocabulary.

Test file: implicit (currently exercised via /cycle integration tests).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import argparse
import glob
import json
import re
import subprocess
import sys
from pathlib import Path

from tools._paths import PROJECT_ROOT, TASKS_GLOB, MODULES_GLOB, LOG_GLOB, EPIC_DOC

ROOT = PROJECT_ROOT
EPIC_PATH = str(EPIC_DOC)


def parse_frontmatter_field(path: str, field: str) -> str:
    try:
        with open(path) as f:
            content = f.read()
    except OSError:
        return ""
    if not content.startswith("---"):
        return ""
    end = content.find("---", 3)
    if end < 0:
        return ""
    frontmatter = content[3:end]
    match = re.search(rf"^{re.escape(field)}:\s*(.+?)$", frontmatter, re.MULTILINE)
    if not match:
        return ""
    return match.group(1).strip().strip('"').strip("'")


def collect_modules() -> list:
    modules = []
    for path in sorted(glob.glob(MODULES_GLOB)):
        modules.append({
            "path": path,
            "id": Path(path).stem.split("-author-")[0].split("-")[1] if "root-modules-" in path else "?",
            "title": parse_frontmatter_field(path, "title"),
            "status": parse_frontmatter_field(path, "status"),
            "current_stage": parse_frontmatter_field(path, "current_stage"),
            "readiness": parse_frontmatter_field(path, "readiness"),
            "sfif_stage": parse_frontmatter_field(path, "sfif_stage"),
        })
    return modules


def collect_tasks_status() -> dict:
    counts: dict = {}
    for path in sorted(glob.glob(TASKS_GLOB)):
        status = parse_frontmatter_field(path, "status")
        counts[status] = counts.get(status, 0) + 1
    return counts


def collect_recent_logs(n: int = 5) -> list:
    import os
    # Sort by mtime descending (most-recent first) — within same date-prefix the suffix
    # alone doesn't give chronological order, so use mtime for true recency.
    paths = sorted(glob.glob(LOG_GLOB), key=os.path.getmtime, reverse=True)[:n]
    return [Path(p).name for p in paths]


def collect_recent_commits(n: int = 5) -> list:
    if not (ROOT / ".git").exists():
        return ["(no git repo)"]
    try:
        result = subprocess.run(
            ["git", "-C", str(ROOT), "log", "--oneline", f"-{n}"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode != 0:
            return ["(no commits yet)"]
        lines = [line for line in result.stdout.splitlines() if line.strip()]
        return lines if lines else ["(no commits yet)"]
    except (subprocess.SubprocessError, OSError):
        return ["(error reading commits)"]


def compute_progress() -> dict:
    modules = collect_modules()
    task_counts = collect_tasks_status()
    epic_readiness = parse_frontmatter_field(EPIC_PATH, "readiness")

    sfif_stage_dist: dict = {}
    for m in modules:
        sfif = m["sfif_stage"]
        sfif_stage_dist[sfif] = sfif_stage_dist.get(sfif, 0) + 1

    module_status_dist: dict = {}
    for m in modules:
        s = m["status"]
        module_status_dist[s] = module_status_dist.get(s, 0) + 1

    return {
        "epic": {
            "title": parse_frontmatter_field(EPIC_PATH, "title"),
            "status": parse_frontmatter_field(EPIC_PATH, "status"),
            "readiness": epic_readiness,
        },
        "modules": {
            "total": len(modules),
            "by_status": module_status_dist,
            "by_sfif_stage": sfif_stage_dist,
            "list": [
                {"id": m["id"], "title": m["title"], "status": m["status"], "sfif": m["sfif_stage"]}
                for m in modules
            ],
        },
        "tasks": {
            "total": sum(task_counts.values()),
            "by_status": task_counts,
        },
        "recent_logs": collect_recent_logs(),
        "recent_commits": collect_recent_commits(),
    }


def print_callout(p: dict) -> None:
    print("═════════════════════════════════════════════════════════════════════════")
    print(f"ROOT-GHOSTPROXY — CURRENT POSITION")
    print("═════════════════════════════════════════════════════════════════════════")
    epic = p["epic"]
    print(f"Epic:              {epic['title']}")
    print(f"Epic readiness:    {epic['readiness']}%  ({epic['status']})")
    print()
    print(f"Modules ({p['modules']['total']} total):")
    for s, c in sorted(p["modules"]["by_status"].items()):
        print(f"  {s:<20}  {c}")
    print(f"Tasks ({p['tasks']['total']} total):")
    for s, c in sorted(p["tasks"]["by_status"].items()):
        print(f"  {s:<28}  {c}")
    print()
    print("Recent logs:")
    for name in p["recent_logs"]:
        print(f"  {name}")
    print()
    print("Recent commits:")
    for line in p["recent_commits"]:
        print(f"  {line}")
    print("═════════════════════════════════════════════════════════════════════════")


def main() -> int:
    parser = argparse.ArgumentParser(description="Compute current progress for root-modules")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--callout", action="store_true", help="just the current-position callout")
    args = parser.parse_args()

    progress = compute_progress()

    if args.json:
        print(json.dumps(progress, indent=2))
        return 0

    if args.callout:
        print_callout(progress)
        return 0

    # Full report
    print_callout(progress)
    print()
    print("Modules per SFIF stage:")
    for s, c in sorted(progress["modules"]["by_sfif_stage"].items()):
        print(f"  {s:<25}  {c}")
    print()
    print("All modules:")
    for m in progress["modules"]["list"]:
        print(f"  {m['id']:<6}  {m['status']:<10}  {m['sfif']:<25}  {m['title']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
