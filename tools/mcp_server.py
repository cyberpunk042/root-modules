"""root-ghostproxy MCP Server — exposes governance operations as native MCP tools.

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
            "root-ghostproxy": {
              "command": "python3",
              "args": ["-m", "tools.mcp_server"],
              "cwd": "$HOME"
            }
          }
        }
    Then verify in a fresh $HOME session via Claude Code's MCP listing.
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
    name="root-ghostproxy",
    instructions=(
        "root-ghostproxy governance tools. Read-only surface for active mode + "
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
    return json.dumps({
        "state": read_state(),
        "blockers": detect_drift(),
        "progress": compute_progress(),
        "objective": obj,
    }, indent=2)


# ---------------------------------------------------------------------------
# Run server
# ---------------------------------------------------------------------------

def main() -> int:
    server.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
