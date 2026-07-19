#!/usr/bin/env bash
# aidlc-readiness.sh — readiness % on selected task (or epic if no task selected).
# Output: "Readiness: 25%" / "Readiness: ?"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly TOOLS_DIR="$(rm_resolve_project)"
readonly STATE_FILE="${ROOT_MODULES_ACTIVE_TASK:-${ROOT_GHOSTPROXY_ACTIVE_TASK:-${TOOLS_DIR}}/.claude/active-task}"
readonly TOOLS_PYTHON="$(rm_resolve_python)"
task=""
[[ -r "${STATE_FILE}" ]] && task=$(head -1 "${STATE_FILE}" | tr -d '[:space:]')

if [[ -n "${task}" ]] && [[ -d ${TOOLS_DIR}/wiki/backlog/tasks ]]; then
    f=$(ls ${TOOLS_DIR}/wiki/backlog/tasks/${task}-*.md 2>/dev/null | head -1 || true)
    if [[ -n "${f:-}" ]] && [[ -f "${f}" ]]; then
        rdy=$( { grep -m1 "^readiness:" "${f}" 2>/dev/null || true; } | awk '{print $2}' | tr -d '"')
        [[ -n "${rdy:-}" ]] && { printf 'Readiness: %s%%' "${rdy}"; exit 0; }
    fi
fi

# Fallback path 1: tools.progress (works for $HOME)
if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/progress.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    pct=$("${TOOLS_PYTHON}" -m tools.progress --json 2>/dev/null | "${TOOLS_PYTHON}" -c "import json,sys
try:
    print(json.load(sys.stdin)['epic']['readiness'])
except Exception:
    pass" 2>/dev/null || true)
    [[ -n "${pct:-}" ]] && { printf 'Readiness: %s%%' "${pct}"; exit 0; }
fi

# Fallback path 2: average readiness across all tasks (works for any project
# with wiki/backlog/tasks/T*.md frontmatter)
TASKS_DIR="${TOOLS_DIR}/wiki/backlog/tasks"
if [[ -d "${TASKS_DIR}" ]]; then
    avg=$( { grep -hE "^readiness:" "${TASKS_DIR}"/T*.md 2>/dev/null || true; } \
        | awk '{sum+=$2; n++} END {if (n>0) printf "%d", sum/n}')
    if [[ -n "${avg:-}" ]]; then
        printf 'Readiness: %s%%' "${avg}"
        exit 0
    fi
fi

printf 'Readiness: ?'
