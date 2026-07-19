#!/usr/bin/env bash
# aidlc-model.sh — methodology model active for selected task (via parent_module's task_type).
# Output: "M:feature-dev" / "M:bug-fix" / "M:?"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly STATE_FILE="${ROOT_MODULES_ACTIVE_TASK:-${ROOT_GHOSTPROXY_ACTIVE_TASK:-$(rm_resolve_project)/.claude/active-task}}"
readonly TASKS_DIR="${ROOT_MODULES_TASKS_DIR:-${ROOT_GHOSTPROXY_TASKS_DIR:-$(rm_resolve_project)/wiki/backlog/tasks}}"
readonly MODULES_DIR="${ROOT_MODULES_MODULES_DIR:-${ROOT_GHOSTPROXY_MODULES_DIR:-$(rm_resolve_project)/wiki/backlog/modules}}"

task=""
[[ -r "${STATE_FILE}" ]] && task=$(head -1 "${STATE_FILE}" | tr -d '[:space:]') || true

model=""
parent_module=""

if [[ -n "${task}" ]] && [[ -d "${TASKS_DIR}" ]]; then
    f=$(ls "${TASKS_DIR}/${task}-"*.md 2>/dev/null | head -1)
    if [[ -f "${f}" ]]; then
        model=$(grep -m1 "^task_type:" "${f}" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
        parent_module=$(grep -m1 "^parent_module:" "${f}" 2>/dev/null | awk -F'"' '{print $2}') || true
    fi
fi

if [[ -z "${model}" ]] && [[ -n "${parent_module}" ]] && [[ -d "${MODULES_DIR}" ]]; then
    mf="${MODULES_DIR}/${parent_module}.md"
    [[ -f "${mf}" ]] || mf=$(ls "${MODULES_DIR}/${parent_module}"*.md 2>/dev/null | head -1)
    if [[ -f "${mf}" ]]; then
        model=$(grep -m1 "^task_type:" "${mf}" 2>/dev/null | awk '{print $2}' | tr -d '"') || true
        [[ "${model}" == "module" ]] && model="feature-dev"
    fi
fi

case "${model}" in
    feature-development) model="feature-dev" ;;
    bug-fix) model="bug-fix" ;;
    refactor) model="refactor" ;;
    integration) model="integration" ;;
    documentation) model="doc" ;;
    project-lifecycle) model="lifecycle" ;;
esac

printf 'Model: %s' "${model:-?}"
