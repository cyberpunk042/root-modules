#!/usr/bin/env bash
# scripts/mcp-launcher.sh — portable MCP server launcher.
#
# Resolves the project root + second-brain location dynamically so .mcp.json
# stays portable across machines (different $HOME, different second-brain
# install locations).
#
# Used by .mcp.json:
#   "command": "bash"
#   "args":    ["scripts/mcp-launcher.sh"]
#
# Resolution order for second-brain root (first hit wins):
#   1. $RM_SECOND_BRAIN_ROOT env var (operator override; legacy $RGP_SECOND_BRAIN_ROOT honored)
#   2. $HOME/devops-solutions-information-hub  (default for non-root install)
#   3. /opt/devops-solutions-information-hub  (legacy / dev-host location)
#
# Project root: derived from $BASH_SOURCE → script lives at <project>/scripts/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve second-brain root
if [ -n "${RM_SECOND_BRAIN_ROOT:-}" ]; then
  SECOND_BRAIN="$RM_SECOND_BRAIN_ROOT"
elif [ -n "${RGP_SECOND_BRAIN_ROOT:-}" ]; then
  SECOND_BRAIN="$RGP_SECOND_BRAIN_ROOT"
elif [ -d "$HOME/devops-solutions-information-hub" ]; then
  SECOND_BRAIN="$HOME/devops-solutions-information-hub"
elif [ -d "/opt/devops-solutions-information-hub" ]; then
  SECOND_BRAIN="/opt/devops-solutions-information-hub"
else
  echo "ERROR: second-brain not found." >&2
  echo "  Tried: \$RM_SECOND_BRAIN_ROOT (and legacy \$RGP_SECOND_BRAIN_ROOT), \$HOME/devops-solutions-information-hub, /opt/devops-solutions-information-hub" >&2
  echo "  Set RM_SECOND_BRAIN_ROOT=<path> or install second-brain at default location" >&2
  exit 1
fi

if [ ! -x "$SECOND_BRAIN/.venv/bin/python" ]; then
  echo "ERROR: second-brain venv not found at $SECOND_BRAIN/.venv/bin/python" >&2
  echo "  Run the second-brain's bootstrap (creates .venv) before launching MCP" >&2
  exit 1
fi

# Run from project root so `python -m tools.mcp_server` finds $HOME/tools/
cd "$PROJECT_ROOT"
exec "$SECOND_BRAIN/.venv/bin/python" -m tools.mcp_server "$@"
