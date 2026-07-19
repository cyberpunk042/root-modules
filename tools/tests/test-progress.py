#!/usr/bin/env python3
"""Regression tests for tools/progress.py — the journey / progress computation.

progress.py aggregates the backlog into the journey callout (/progress,
/sync-progress, wiki/governance/progress.md) and its compute_progress() backs
the root_progress MCP tool. The aggregation — module status/SFIF distributions,
task status counts, epic readiness — is where a silent regression would
misreport how far along the project is. Zero coverage until now.

Isolation: progress.py resolves its globs from module globals derived from the
repo root (MODULES_GLOB / TASKS_GLOB / LOG_GLOB / EPIC_PATH / ROOT). These tests
run IN-PROCESS and repoint those globals at a fixture backlog tree, so the real
backlog is never read. parse_frontmatter_field takes a path arg and is tested
directly.

Emits the canonical `Result: N/M passed` line consumed by tools.run-tests.
Exit 0 iff all pass.
"""
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import tools.progress as pr  # noqa: E402

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, cond: bool, detail: str = "") -> None:
    if cond:
        PASSED.append(label)
        print(f"  PASS {label}")
    else:
        FAILED.append((label, detail))
        print(f"  FAIL {label}" + (f" — {detail}" if detail else ""))


def fm(**fields: str) -> str:
    body = "\n".join(f"{k}: {v}" for k, v in fields.items())
    title = fields.get("title", "X")
    return f"---\n{body}\n---\n\n# {title}\n\nbody\n"


def test_parse_frontmatter_field() -> None:
    d = Path(tempfile.mkdtemp(prefix="progress-test-"))
    p = d / "m.md"
    p.write_text(fm(title='"Quoted Title"', status="in-progress", readiness="40"))
    check("field extracts value", pr.parse_frontmatter_field(str(p), "status") == "in-progress")
    check("field strips quotes", pr.parse_frontmatter_field(str(p), "title") == "Quoted Title")
    check("missing field → ''", pr.parse_frontmatter_field(str(p), "nope") == "")
    check("missing file → ''", pr.parse_frontmatter_field(str(d / "gone.md"), "status") == "")
    nf = d / "nofm.md"
    nf.write_text("# no frontmatter\n")
    check("no-frontmatter file → ''", pr.parse_frontmatter_field(str(nf), "status") == "")


def build_backlog() -> Path:
    """A fixture backlog tree: 3 modules, 4 tasks, 1 epic, 2 logs."""
    d = Path(tempfile.mkdtemp(prefix="progress-backlog-"))
    (d / "modules").mkdir()
    (d / "tasks").mkdir()
    (d / "epics").mkdir()
    (d / "log").mkdir()
    # modules — mix of status + sfif_stage
    (d / "modules" / "root-modules-m001-a.md").write_text(fm(title="A", status="done", current_stage="test", readiness="100", sfif_stage="Scaffold"))
    (d / "modules" / "root-modules-m002-b.md").write_text(fm(title="B", status="in-progress", current_stage="implement", readiness="80", sfif_stage="Foundation"))
    (d / "modules" / "root-modules-m003-c.md").write_text(fm(title="C", status="in-progress", current_stage="scaffold", readiness="50", sfif_stage="Foundation"))
    # tasks — status distribution
    (d / "tasks" / "T001-a.md").write_text(fm(title="T1", status="done"))
    (d / "tasks" / "T002-b.md").write_text(fm(title="T2", status="not-started"))
    (d / "tasks" / "T003-c.md").write_text(fm(title="T3", status="not-started"))
    (d / "tasks" / "T004-d.md").write_text(fm(title="T4", status="in-progress"))
    # epic
    (d / "epics" / "sfif.md").write_text(fm(title="SFIF Rollout", status="active", readiness="35"))
    # logs
    (d / "log" / "2026-01-01-x.md").write_text("log x")
    (d / "log" / "2026-01-02-y.md").write_text("log y")
    return d


def with_backlog(d: Path) -> None:
    pr.MODULES_GLOB = str(d / "modules" / "root-modules-m*.md")
    pr.TASKS_GLOB = str(d / "tasks" / "T*.md")
    pr.LOG_GLOB = str(d / "log" / "*.md")
    pr.EPIC_PATH = str(d / "epics" / "sfif.md")
    pr.ROOT = d  # non-git → recent_commits returns the no-git sentinel


def test_compute_progress_modules() -> None:
    with_backlog(build_backlog())
    p = pr.compute_progress()
    check("modules total counted", p["modules"]["total"] == 3)
    check("module status distribution", p["modules"]["by_status"] == {"done": 1, "in-progress": 2})
    check("module SFIF-stage distribution", p["modules"]["by_sfif_stage"] == {"Scaffold": 1, "Foundation": 2})


def test_compute_progress_tasks_and_epic() -> None:
    with_backlog(build_backlog())
    p = pr.compute_progress()
    check("tasks total counted", p["tasks"]["total"] == 4)
    check("task status distribution", p["tasks"]["by_status"] == {"done": 1, "not-started": 2, "in-progress": 1})
    check("epic readiness surfaced", p["epic"]["readiness"] == "35")
    check("epic title surfaced", p["epic"]["title"] == "SFIF Rollout")


def test_compute_progress_logs_and_commits() -> None:
    with_backlog(build_backlog())
    p = pr.compute_progress()
    check("recent_logs lists fixture log filenames", set(p["recent_logs"]) == {"2026-01-01-x.md", "2026-01-02-y.md"})
    check("recent_commits handles non-git fixture gracefully", p["recent_commits"] == ["(no git repo)"])


def test_empty_backlog() -> None:
    d = Path(tempfile.mkdtemp(prefix="progress-empty-"))
    (d / "modules").mkdir(); (d / "tasks").mkdir(); (d / "epics").mkdir(); (d / "log").mkdir()
    (d / "epics" / "sfif.md").write_text(fm(title="E", status="draft", readiness="0"))
    with_backlog(d)
    p = pr.compute_progress()
    check("empty modules → total 0", p["modules"]["total"] == 0)
    check("empty tasks → total 0", p["tasks"]["total"] == 0)
    check("no logs → empty list", p["recent_logs"] == [])


def main() -> int:
    print("=== tools.progress regression tests ===")
    for t in (
        test_parse_frontmatter_field, test_compute_progress_modules,
        test_compute_progress_tasks_and_epic, test_compute_progress_logs_and_commits,
        test_empty_backlog,
    ):
        t()
    total = len(PASSED) + len(FAILED)
    print()
    print(f"Result: {len(PASSED)}/{total} passed")
    for label, detail in FAILED:
        print(f"  - {label}: {detail}")
    return 0 if not FAILED else 1


if __name__ == "__main__":
    sys.exit(main())
