#!/usr/bin/env bash
# aidlc-objective.sh — surface MISSION + FOCUS + IMPEDIMENT + P1 priority on statusline.
# Per SB-118 + SB-127 + SB-124b (statusline integration of compound layers).
# Output (compact for line 2): "✦M:<short> ◉F:<short> ⚠I:<short> ⚡P1:<short>"
# Empty fields are dropped. Length-bounded to ~120 chars to fit one statusline column.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

PROJ="$(rm_resolve_project)"
MISSION_FILE="${ROOT_MODULES_ACTIVE_MISSION:-${ROOT_GHOSTPROXY_ACTIVE_MISSION:-${PROJ}}/.claude/active-mission}"
FOCUS_FILE="${ROOT_MODULES_ACTIVE_FOCUS:-${ROOT_GHOSTPROXY_ACTIVE_FOCUS:-${PROJ}}/.claude/active-focus}"
IMPEDIMENT_FILE="${ROOT_MODULES_ACTIVE_IMPEDIMENT:-${ROOT_GHOSTPROXY_ACTIVE_IMPEDIMENT:-${PROJ}}/.claude/active-impediment}"
PRIORITIES_FILE="${ROOT_MODULES_ACTIVE_PRIORITIES:-${ROOT_GHOSTPROXY_ACTIVE_PRIORITIES:-${PROJ}}/.claude/active-priorities}"

shorten() {
    local txt="$1" max="${2:-30}"
    txt="${txt%$'\n'}"
    if [[ ${#txt} -gt ${max} ]]; then
        printf '%s…' "${txt:0:$((max-1))}"
    else
        printf '%s' "${txt}"
    fi
}

read_first() {
    local f="$1"
    [[ -r "${f}" ]] || return 0
    head -1 "${f}" | tr -d '\r'
}

parts=()
mission="$(read_first "${MISSION_FILE}")"
focus="$(read_first "${FOCUS_FILE}")"
impediment="$(read_first "${IMPEDIMENT_FILE}")"
p1="$(read_first "${PRIORITIES_FILE}")"

[[ -n "${mission}" ]] && parts+=("✦M:$(shorten "${mission}" 25)")
[[ -n "${focus}" ]] && parts+=("◉F:$(shorten "${focus}" 25)")
[[ -n "${impediment}" ]] && parts+=("⚠I:$(shorten "${impediment}" 25)")
[[ -n "${p1}" ]] && parts+=("⚡P1:$(shorten "${p1}" 30)")

if [[ ${#parts[@]} -eq 0 ]]; then
    printf '(no objective set)'
else
    IFS=' ' printf '%s' "${parts[*]}"
fi
