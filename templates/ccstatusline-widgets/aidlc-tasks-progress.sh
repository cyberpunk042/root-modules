#!/usr/bin/env bash
# aidlc-tasks-progress.sh — task counts done/in-progress/not-started.
# Output: "Tasks: 18/7/42" (done / in-progress / not-started)
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly TOOLS_PYTHON="$(rm_resolve_python)"
readonly TOOLS_DIR="$(rm_resolve_project)"

# Path 1: tools.progress (--json) — works for $HOME which has tools/progress.py
if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/progress.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    out=$("${TOOLS_PYTHON}" -c "
import json, subprocess, sys
try:
    out = subprocess.check_output([sys.executable, '-m', 'tools.progress', '--json'], stderr=subprocess.DEVNULL)
    p = json.loads(out)
    c = p.get('tasks', {}).get('by_status', {})
    print(f\"{c.get('done', 0)}/{c.get('in-progress', 0)}/{c.get('not-started', 0)}\")
except Exception:
    pass
" 2>/dev/null)
    [[ -n "${out:-}" ]] && { printf 'Tasks: %s' "${out}"; exit 0; }
fi

# Path 2: direct frontmatter scan of <project>/wiki/backlog/tasks/T*.md — works for any
# project that uses the same task-frontmatter-with-status convention (covers /opt
# second-brain which has tasks/ but a different toolset).
TASKS_DIR="${TOOLS_DIR}/wiki/backlog/tasks"
if [[ -d "${TASKS_DIR}" ]]; then
    # `{ grep ...; } || true` swallows grep no-match exit code so pipefail
    # doesn't kill the script via the active set -e. wc -l always outputs the
    # count (0 for empty input).
    done_n=$( { grep -lE '^status: done$' "${TASKS_DIR}"/T*.md 2>/dev/null || true; } | wc -l)
    inprog_n=$( { grep -lE '^status: (in-progress|active)$' "${TASKS_DIR}"/T*.md 2>/dev/null || true; } | wc -l)
    # "not-started" in $HOME vocabulary; /opt uses "draft" — count both
    notstarted_n=$( { grep -lE '^status: (not-started|draft)$' "${TASKS_DIR}"/T*.md 2>/dev/null || true; } | wc -l)
    # Strip whitespace from wc -l output for safe arithmetic comparison
    done_n=${done_n//[[:space:]]/}
    inprog_n=${inprog_n//[[:space:]]/}
    notstarted_n=${notstarted_n//[[:space:]]/}
    if [[ "${done_n:-0}" -gt 0 ]] || [[ "${inprog_n:-0}" -gt 0 ]] || [[ "${notstarted_n:-0}" -gt 0 ]]; then
        printf 'Tasks: %s/%s/%s' "${done_n:-0}" "${inprog_n:-0}" "${notstarted_n:-0}"
        exit 0
    fi
fi

printf 'Tasks: ?'
