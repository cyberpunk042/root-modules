#!/usr/bin/env bash
# aidlc-open-sbs.sh — count of open + recurring systemic bugs (from systemic-bugs.md tracker).
# Output: "SB:10/3" (open/recurring) / "SB:?"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly SB_FILE="${ROOT_MODULES_SB_FILE:-${ROOT_GHOSTPROXY_SB_FILE:-$(rm_resolve_project)/wiki/governance/systemic-bugs.md}}"
if [[ -r "${SB_FILE}" ]]; then
    open=$(grep -cE "^\| SB-[0-9]+ \|.*\| open \|" "${SB_FILE}" 2>/dev/null || echo 0)
    recurring=$(grep -cE "^\| SB-[0-9]+ \|.*\| recurring \|" "${SB_FILE}" 2>/dev/null || echo 0)
    printf 'Bugs: %s/%s' "${open}" "${recurring}"
    exit 0
fi

# Fallback for projects without governance/systemic-bugs.md (e.g. /opt
# second-brain): count lessons in /wiki/lessons/01_drafts/ as a proxy for
# active-bug-equivalent-tracking. If not present either, render context-correct
# absence note.
LESSONS_DIR="$(rm_resolve_project)/wiki/lessons/01_drafts"
if [[ -d "${LESSONS_DIR}" ]]; then
    n=$(ls "${LESSONS_DIR}"/*.md 2>/dev/null | wc -l || true)
    n=${n//[[:space:]]/}
    if [[ -n "${n:-0}" && "${n:-0}" -gt 0 ]]; then
        printf 'Drafts: %s' "${n}"
        exit 0
    fi
fi

printf 'Bugs: ?'
