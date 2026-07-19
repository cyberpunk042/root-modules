#!/usr/bin/env bash
# aidlc-priority1.sh — surface P1 (top imminent priority per SB-127) on statusline.
# DRAFT v1 — agent-authored 2026-05-06 per SB-095 + UX-design pass Phase 1a.
# Independent widget so P1 can render with brightCyan ("call to action") color
# distinct from yellow-spam-overload across other widgets.
# Smart-abbrev: first-clause-before-em-dash → fallback word-boundary at 80.
# Output: "⚡ <abbreviated P1>" or empty if no priorities set.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

if ! rgp_is_in_root_context; then exit 0; fi

PROJ="$(rm_resolve_project)"
PRIORITIES_FILE="${ROOT_MODULES_ACTIVE_PRIORITIES:-${ROOT_GHOSTPROXY_ACTIVE_PRIORITIES:-${PROJ}}/.claude/active-priorities}"

[[ -r "${PRIORITIES_FILE}" ]] || exit 0
p1="$(head -1 "${PRIORITIES_FILE}" | tr -d '\r')"
[[ -n "${p1}" ]] || exit 0

abbreviated="${p1%% — *}"
[[ "${abbreviated}" == "${p1}" ]] && abbreviated="${p1%% - *}"
[[ "${abbreviated}" == "${p1}" ]] && abbreviated="${p1%% : *}"

if [[ ${#abbreviated} -gt 80 ]]; then
    truncated="${abbreviated:0:79}"
    truncated="${truncated% *}"
    abbreviated="${truncated}…"
fi

printf '⚡ %s' "${abbreviated}"
