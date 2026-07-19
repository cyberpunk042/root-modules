#!/usr/bin/env bash
# $HOME/templates/ccstatusline-widgets/progress.sh
# ccstatusline Custom Text widget data source — root-modules "progress %" field.
#
# Output: epic readiness % from tools.progress (e.g., "10%") or "?" if unavailable.
# Source: python3 -m tools.progress --json (computed live from frontmatter scan).
#
# Per M011 T064. Stage: scaffold (preliminary).

set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"


readonly TOOLS_PYTHON="$(rm_resolve_python)"
readonly TOOLS_DIR="$(rm_resolve_project)"

if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/progress.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    pct=$("${TOOLS_PYTHON}" -m tools.progress --json 2>/dev/null \
        | "${TOOLS_PYTHON}" -c "import json,sys
try:
    print(json.load(sys.stdin)['epic']['readiness'])
except Exception:
    pass" 2>/dev/null || true)
    if [[ -n "${pct:-}" ]]; then
        printf 'P:%s%%' "${pct}"
        exit 0
    fi
fi

# Fallback: average readiness across all tasks (works for any project with
# wiki/backlog/tasks/T*.md frontmatter — covers /opt second-brain)
TASKS_DIR="${TOOLS_DIR}/wiki/backlog/tasks"
if [[ -d "${TASKS_DIR}" ]]; then
    avg=$( { grep -hE "^readiness:" "${TASKS_DIR}"/T*.md 2>/dev/null || true; } \
        | awk '{sum+=$2; n++} END {if (n>0) printf "%d", sum/n}')
    if [[ -n "${avg:-}" ]]; then
        printf 'P:%s%%' "${avg}"
        exit 0
    fi
fi

printf 'P:?'
