"""tools — root-modules autopilot toolkit (15 modules).

Per operator directive 2026-05-05: tools are deterministic non-LLM Python
modules that empower / interact with / exploit the project. Commands compose
tools; tools do the work. Each module is invokable via `python3 -m tools.<name>`
from any working directory (paths resolved dynamically via `tools._paths`).

Inventory (15 modules empirically verified 2026-05-07):
    _paths        — project-root + second-brain path resolution
    state         — read project state (active mode + git + paths)
    blockers      — list/get/verify/add/update/resolve blockers (B###)
    progress      — compute SFIF stage + module/task readiness
    decisions     — list/append decisions logbook (D###)
    cycle         — read active mode + dispatch per-mode cycle reads/checks
    tasks         — drill-down + active-task cursor + create-under-* (M-E002-1)
    stamp         — persistent stamp config (SB-115 redesign)
    objective     — mission/focus/impediment state-file management (SB-118)
    priorities    — top-priorities imminent-work list (SB-127)
    questions     — agent-pending-questions retention layer (SB-134)
    group         — chain/group/tree composition primitive (E003 Layer A; DRAFT v1)
    run-tests     — unified runner for $HOME hook + tool regression tests
    mcp_server    — MCP server exposing 10 root_* governance tools

Composes-with:
- Slash commands ($HOME/.claude/commands/) consume these via Bash dispatch
- Hooks ($HOME/.claude/hooks/) read via subprocess
- MCP server (mcp_server.py) wraps for structured AI consumers
- Sub-agents ($HOME/.claude/agents/) inherit via brain-load profile

Brain-inheritance pattern: $HOME source-of-truth for operational tooling;
sister projects inherit via `/install-agent-brain` per operator-opt-in.

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
Action vocabulary (Hard Rule 14): each tool emits one of 9 canonical M-E001-1
productive-cycle action types when invoked from /cycle. See
wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md
"""
