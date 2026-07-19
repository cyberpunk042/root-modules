#!/usr/bin/env bash
# selected-task.sh — selected task with rich context (id + short-slug + readiness/status).
# Output: "T012:install.sh:50%" / "T011:foundation:done" / "T:(no-task)"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly STATE_FILE="${ROOT_MODULES_ACTIVE_TASK:-${ROOT_GHOSTPROXY_ACTIVE_TASK:-$(rm_resolve_project)/.claude/active-task}}"
readonly TASKS_DIR="${ROOT_MODULES_TASKS_DIR:-${ROOT_GHOSTPROXY_TASKS_DIR:-$(rm_resolve_project)/wiki/backlog/tasks}}"

task=""
[[ -r "${STATE_FILE}" ]] && task=$(head -1 "${STATE_FILE}" | tr -d '[:space:]')

if [[ -z "${task}" ]] && [[ -d "${TASKS_DIR}" ]]; then
    # `{ ... } || true` swallows grep no-match exit so pipefail+set-e doesn't kill us
    task=$( { grep -lE "^status:[ ]*(in-progress|active)" "${TASKS_DIR}"/T*.md 2>/dev/null || true; } \
        | xargs -r ls -t 2>/dev/null | head -1 | sed -E 's|.*/(T[0-9]+)-.*|\1|')
fi

if [[ -z "${task}" ]]; then printf 'Task: (no task selected)'; exit 0; fi

f=$(ls "${TASKS_DIR}/${task}-"*.md 2>/dev/null | head -1)
if [[ ! -f "${f}" ]]; then printf 'Task: %s' "${task}"; exit 0; fi

slug=$(basename "${f}" .md | sed -E "s/^${task}-//" | cut -c1-30)
rdy=$(grep -m1 "^readiness:" "${f}" 2>/dev/null | awk '{print $2}' | tr -d '"')
status=$(grep -m1 "^status:" "${f}" 2>/dev/null | awk '{print $2}' | tr -d '"')

case "${status}" in
    done) state="done" ;;
    pending-operator-decision) state="pending-operator" ;;
    *) state="${rdy:-?}%" ;;
esac

printf 'Task: %s %s [%s]' "${task}" "${slug}" "${state}"
