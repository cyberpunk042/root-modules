"""tools/_paths.py — project-root + second-brain path resolution.

Resolves all project + cross-project paths DYNAMICALLY so $HOME/tools/*.py
modules work regardless of where root-modules is cloned ($HOME, $HOME,
or anywhere). No `$HOME/...` or `/opt/devops-solutions-information-hub/...`
literals appear elsewhere in tools/.

PROJECT_ROOT       — derived from __file__; the directory containing tools/.
                      = $HOME on Path A install (root or jfortin user).
                      = $TARGET on Path B install.

SECOND_BRAIN_ROOT  — resolved at import time:
                      1. $RGP_SECOND_BRAIN_ROOT env var (operator override)
                      2. $HOME/devops-solutions-information-hub  (default)
                      3. /opt/devops-solutions-information-hub  (legacy)
                      4. fallback to $HOME default even if missing
                         (callers handle the "not reachable" case via .exists())

All other paths are derived from these two roots — never hardcoded.

Composes-with:
- ALL other tools/*.py modules import from this module (PROJECT_ROOT, SECOND_BRAIN_ROOT,
  TASKS_GLOB, MODULES_GLOB, LOG_GLOB, EPIC_DOC, DECISIONS_DOC, etc.)
- Hooks ($HOME/.claude/hooks/*.sh) import via sys.path.insert + tools._paths
- MCP server (mcp_server.py) inherits paths transitively

Idempotency invariant: pure read-time path resolution; no side effects on import;
re-import = same paths returned.

Action vocabulary (Hard Rule 14): N/A — utility module; not a cycle-action emitter.

Test file: implicit (every other tool's import test exercises this module).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import os
from pathlib import Path

# ---------- Project root ----------
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def _resolve_second_brain() -> Path:
    env = os.environ.get("RGP_SECOND_BRAIN_ROOT")
    if env:
        return Path(env).expanduser().resolve()
    home_candidate = Path.home() / "devops-solutions-information-hub"
    if home_candidate.exists():
        return home_candidate
    opt_candidate = Path("/opt/devops-solutions-information-hub")
    if opt_candidate.exists():
        return opt_candidate
    return home_candidate  # default; caller checks .exists()


SECOND_BRAIN_ROOT = _resolve_second_brain()


# ---------- Common project paths ----------
WIKI = PROJECT_ROOT / "wiki"
WIKI_BACKLOG = WIKI / "backlog"
WIKI_BACKLOG_EPICS = WIKI_BACKLOG / "epics"
WIKI_BACKLOG_MODULES = WIKI_BACKLOG / "modules"
WIKI_BACKLOG_TASKS = WIKI_BACKLOG / "tasks"
WIKI_GOVERNANCE = WIKI / "governance"
WIKI_LOG = WIKI / "log"

# Common docs
BLOCKERS_DOC = WIKI_GOVERNANCE / "blockers.md"
DECISIONS_DOC = WIKI_GOVERNANCE / "decisions.md"
PROGRESS_DOC = WIKI_GOVERNANCE / "progress.md"
SYSTEMIC_BUGS_DOC = WIKI_GOVERNANCE / "systemic-bugs.md"
EPIC_DOC = WIKI_BACKLOG_EPICS / "sfif-rollout-and-second-brain-integration.md"

# Glob patterns (string form for glob.glob() callers)
TASKS_GLOB = str(WIKI_BACKLOG_TASKS / "T*.md")
MODULES_GLOB = str(WIKI_BACKLOG_MODULES / "root-modules-m*.md")
LOG_GLOB = str(WIKI_LOG / "*.md")


# ---------- Cross-project paths (second-brain) ----------
# Derived. Callers should check second_brain_reachable() before use.
SECOND_BRAIN_RAW_NOTES = SECOND_BRAIN_ROOT / "raw" / "notes"
SECOND_BRAIN_VENV_PYTHON = SECOND_BRAIN_ROOT / ".venv" / "bin" / "python"


def second_brain_reachable() -> bool:
    """True if the second-brain root exists locally."""
    return SECOND_BRAIN_ROOT.exists()


def __repr__():
    return (
        f"PROJECT_ROOT={PROJECT_ROOT}\n"
        f"SECOND_BRAIN_ROOT={SECOND_BRAIN_ROOT} (reachable={second_brain_reachable()})"
    )
