#!/usr/bin/env bash
# aidlc-blockers.sh — count of pending-operator-decision tasks (per tools.blockers).
# Output: "Bk:0" / "Bk:6" / "Bk:?"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly TOOLS_PYTHON="$(rm_resolve_python)"
readonly TOOLS_DIR="$(rm_resolve_project)"

# Path 1: tools.blockers (works for $HOME)
if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/blockers.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    n=$("${TOOLS_PYTHON}" -c "
import json, subprocess, sys
try:
    out = subprocess.check_output([sys.executable, '-m', 'tools.blockers', '--json'], stderr=subprocess.DEVNULL)
    p = json.loads(out)
    print(len(p.get('live_pending_decision_tasks', [])))
except Exception:
    pass" 2>/dev/null || true)
    if [[ -n "${n:-}" ]]; then printf 'Blockers: %s' "${n}"; exit 0; fi
fi

# Path 2: count tasks with status: blocked in <project>/wiki/backlog/tasks/
TASKS_DIR="${TOOLS_DIR}/wiki/backlog/tasks"
if [[ -d "${TASKS_DIR}" ]]; then
    n=$( { grep -lE '^status: (blocked|pending-operator-decision)$' "${TASKS_DIR}"/T*.md 2>/dev/null || true; } | wc -l)
    n=${n//[[:space:]]/}
    printf 'Blockers: %s' "${n:-0}"
    exit 0
fi

printf 'Blockers: ?'
