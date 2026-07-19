#!/usr/bin/env bash
# aidlc-decisions.sh — count of decisions in logbook + latest D-ID.
# Output: "D:24 (D024)" / "D:?"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly TOOLS_PYTHON="$(rm_resolve_python)"
readonly TOOLS_DIR="$(rm_resolve_project)"

# Path 1: tools.decisions (works for $HOME which has tools/decisions.py)
if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/decisions.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    out=$("${TOOLS_PYTHON}" -m tools.decisions list 2>/dev/null || true)
    n=$( { echo "${out}" | grep -cE "^\s+D[0-9]+" || true; })
    n=${n//[[:space:]]/}
    latest=$( { echo "${out}" | grep -oE "D[0-9]+" || true; } | head -1)
    if [[ -n "${n:-}" && "${n:-0}" -gt 0 ]]; then
        printf 'D:%s(%s)' "${n}" "${latest:-?}"
        exit 0
    fi
fi

# Path 2: count rows in <project>/wiki/backlog/operator-decision-queue.md
# Format observed: `| <num> | <q> | <src> | <impact> |` for open decisions;
# `| ~~<num>~~ | ~~<q>~~ **RESOLVED:** ... |` for closed. Count open ones
# (rows starting with `| <digits-or-range> |` without `~~` strike marker).
DECISIONS_FILE="${TOOLS_DIR}/wiki/backlog/operator-decision-queue.md"
if [[ -f "${DECISIONS_FILE}" ]]; then
    open_n=$( { grep -cE "^\| [0-9][0-9-]* \| " "${DECISIONS_FILE}" 2>/dev/null || true; } | head -1)
    open_n=${open_n//[[:space:]]/}
    if [[ -n "${open_n:-}" && "${open_n:-0}" -gt 0 ]]; then
        printf 'D:%s' "${open_n}"
        exit 0
    fi
fi

printf 'D:?'
