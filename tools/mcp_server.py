"""root-modules MCP Server — exposes governance operations as native MCP tools.

Read-only surface. Lets sub-agents, the second brain, and any AI tool consuming
$HOME query the project's governance state (active mode, blockers, progress,
decisions) without invoking subprocess CLI.

Run: python3 -m tools.mcp_server
Or via .mcp.json in $HOME (stdio transport).

Per operator directive 2026-05-05: "MCP we must not overflow especially with
things that are useless or confusing or useless or we dont even refer to
anywhere so will never be used..." — this server registers ONLY 4 tools, each
backed by a corresponding `tools.<module>` script that's already used by
slash commands. Defensible scope: every MCP tool here has a downstream caller.

Wiring (operator action):
    Add to $HOME/.mcp.json (or ~/.claude.json):
        {
          "mcpServers": {
            "root-modules": {
              "command": "python3",
              "args": ["-m", "tools.mcp_server"],
              "cwd": "$HOME"
            }
          }
        }
    Then verify in a fresh $HOME session via Claude Code's MCP listing.

Tool surface (10 root_* tools as of 2026-05-06 evening; empirically counted via
`@server.tool()` decorator scan; closes phantom-count drift per TOOLS.md):
    root_state                — active mode + git + reachability checks
    root_blockers             — drift detection vs governance/blockers.md
    root_progress             — SFIF stage + module/task readiness
    root_decisions_list       — list D### entries
    root_decisions_get        — get a specific D### with full body
    root_decisions_next_id    — next D### in sequence
    root_decisions_verify     — format-integrity check
    root_objective            — mission/focus/impediment state-files (SB-118)
    root_questions            — agent-pending questions (SB-134)
    root_orient               — composite tool (state + blockers + progress + objective + questions)

Composes-with:
- Sister tools: imports tools.state, tools.blockers, tools.progress, tools.decisions,
  and (when wired) tools.objective + tools.questions for read-side surface
- Sub-agents: brain-loaded sub-agents in .claude/agents/ consume these MCP tools
  during their delegated work (cross-process structured returns)
- Slash commands: /orient surfaces what's available; /audit verifies registration

Read-only contract: this server exposes ONLY read operations (no write tools). Per
operator directive 2026-05-05 *"MCP we must not overflow especially with things that
are useless or confusing or useless or we dont even refer to anywhere so will never
be used..."* — every tool here has a downstream caller; defensible scope.

Idempotency invariant: pure read-side; same filesystem state = same JSON returns.

Action vocabulary (Hard Rule 14): each tool emits `read-only-audit` action type per
the M-E001-1 vocabulary at wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md.

Test file: implicit (server registration verified by `tools.gateway` orient --orient-as
sister from /opt second-brain).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import json
import sys

try:
    from mcp.server.fastmcp import FastMCP  # type: ignore[import]
except ImportError:
    print(
        "mcp.server.fastmcp not available — install via `pip install mcp` first.\n"
        "This server file is authored but not yet wired; operator action required.",
        file=sys.stderr,
    )
    sys.exit(1)

from tools.state import read_state
from tools.blockers import detect_drift
from tools.progress import compute_progress
from tools.decisions import parse_entries, get_entry, next_id, verify

# ---------------------------------------------------------------------------
# Server setup
# ---------------------------------------------------------------------------

server = FastMCP(
    name="root-modules",
    instructions=(
        "root-modules governance tools. Read-only surface for active mode + "
        "blockers + progress + decisions. Use root_orient first if uncertain "
        "about project state. All tools backed by <project>/tools/<module>.py CLI "
        "scripts (composable: command can call CLI; MCP equivalent here for "
        "structured returns)."
    ),
)


# ---------------------------------------------------------------------------
# State tool
# ---------------------------------------------------------------------------

@server.tool()
def root_state() -> str:
    """Read project state: active mode + git state + reachability checks.

    Returns JSON: active-mode (str), git-state (str: not-init|clean|uncommitted|error),
    git-uncommitted (int), bootstrap-exists (bool), second-brain-reachable (bool).
    """
    return json.dumps(read_state(), indent=2)


# ---------------------------------------------------------------------------
# Blockers tools
# ---------------------------------------------------------------------------

@server.tool()
def root_blockers() -> str:
    """List active blockers + drift check vs governance/blockers.md.

    Returns JSON: task_status_counts, live_pending_decision_tasks (T###),
    blockers_in_doc (B###), drift (missing_in_doc, extra_in_doc, in_sync).
    """
    return json.dumps(detect_drift(), indent=2)


# ---------------------------------------------------------------------------
# Progress tool
# ---------------------------------------------------------------------------

@server.tool()
def root_progress() -> str:
    """Compute current SFIF stage + module/task readiness from live frontmatter.

    Returns JSON: epic (title, status, readiness), modules (total + by_status +
    by_sfif_stage + list), tasks (total + by_status), recent_logs, recent_commits.
    """
    return json.dumps(compute_progress(), indent=2)


# ---------------------------------------------------------------------------
# Decisions tools
# ---------------------------------------------------------------------------

@server.tool()
def root_decisions_list() -> str:
    """List all D### decisions in the logbook.

    Returns JSON array of {id, date, summary} entries, newest first.
    """
    return json.dumps(parse_entries(), indent=2)


@server.tool()
def root_decisions_get(decision_id: str) -> str:
    """Get the full body of a specific D### decision entry.

    Args:
        decision_id: e.g. "D018"

    Returns markdown of the entry or an error message.
    """
    body = get_entry(decision_id)
    if body is None:
        return json.dumps({"error": f"not found: {decision_id}"})
    return body


@server.tool()
def root_decisions_verify() -> str:
    """Verify decisions logbook integrity (sequential IDs, format compliance).

    Returns JSON: entries (count), issues (list), ok (bool).
    """
    return json.dumps(verify(), indent=2)


@server.tool()
def root_decisions_next_id() -> str:
    """Compute the next D### in sequence (for appending a new decision)."""
    return next_id()


# ---------------------------------------------------------------------------
# Objective tool — mission/focus/impediment + priorities (SB-118 + SB-127)
# ---------------------------------------------------------------------------

@server.tool()
def root_objective() -> str:
    """Read operator-explicit objective layers + priorities queue.

    Returns JSON:
        mission (str): multi-cycle objective from $HOME/.claude/active-mission
        focus (str): sub-objective from $HOME/.claude/active-focus
        impediment (str): block on focus from $HOME/.claude/active-impediment
        priorities (list[str]): imminent-work queue from $HOME/.claude/active-priorities

    Empty fields = unset. Per SB-118 (mission/focus/impediment) + SB-127 (priorities).
    """
    from pathlib import Path
    base = Path.home() / ".claude"
    obj = {"mission": "", "focus": "", "impediment": "", "priorities": []}
    for layer in ("mission", "focus", "impediment"):
        p = base / f"active-{layer}"
        if p.exists():
            try:
                obj[layer] = p.read_text().strip()
            except Exception:
                pass
    pp = base / "active-priorities"
    if pp.exists():
        try:
            obj["priorities"] = [ln.strip() for ln in pp.read_text().splitlines() if ln.strip()]
        except Exception:
            pass
    return json.dumps(obj, indent=2)


# ---------------------------------------------------------------------------
# Questions tool — agent-pending questions retention layer (SB-134)
# ---------------------------------------------------------------------------

@server.tool()
def root_questions() -> str:
    """Read agent-pending questions queue (operator directive 2026-05-06, SB-134).

    Returns JSON:
        questions (list[str]): pending agent → operator questions from $HOME/.claude/active-questions
        count (int): number of pending questions

    Empty list = no pending. Surfaces in mode-enforcement banner + horizontal +
    vertical stamp + pre-compact handoff + /handoff doc per the 6-channel
    visibility design (SB-134 closure).
    """
    from pathlib import Path
    qp = Path.home() / ".claude" / "active-questions"
    items: list = []
    if qp.exists():
        try:
            items = [ln.strip() for ln in qp.read_text().splitlines() if ln.strip()]
        except Exception:
            pass
    return json.dumps({"questions": items, "count": len(items)}, indent=2)


# ---------------------------------------------------------------------------
# Composite tool — orient
# ---------------------------------------------------------------------------

@server.tool()
def root_orient() -> str:
    """One-shot orientation: combines state + blockers + progress + objective for a fresh agent.

    Equivalent to invoking root_state + root_blockers + root_progress + root_objective
    and composing them. Use this if you need a single MCP call to understand
    current $HOME state including operator-explicit objective + priorities.
    """
    from pathlib import Path
    base = Path.home() / ".claude"
    obj = {"mission": "", "focus": "", "impediment": "", "priorities": []}
    for layer in ("mission", "focus", "impediment"):
        p = base / f"active-{layer}"
        if p.exists():
            try:
                obj[layer] = p.read_text().strip()
            except Exception:
                pass
    pp = base / "active-priorities"
    if pp.exists():
        try:
            obj["priorities"] = [ln.strip() for ln in pp.read_text().splitlines() if ln.strip()]
        except Exception:
            pass
    qp = base / "active-questions"
    questions: list = []
    if qp.exists():
        try:
            questions = [ln.strip() for ln in qp.read_text().splitlines() if ln.strip()]
        except Exception:
            pass
    return json.dumps({
        "state": read_state(),
        "blockers": detect_drift(),
        "progress": compute_progress(),
        "objective": obj,
        "questions": questions,
    }, indent=2)


# ---------------------------------------------------------------------------
# Run server
# ---------------------------------------------------------------------------

def main() -> int:
    server.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
