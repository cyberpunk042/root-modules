#!/usr/bin/env bash
# aidlc-impediment.sh — surface IMPEDIMENT (block on focus, comes-and-goes) on statusline.
# DRAFT v1 — agent-authored 2026-05-06 per SB-095 + UX-design pass Phase 1a.
# Independent widget so impediment can render in distinct red color when active,
# silent when unblocked (file empty/absent).
# Smart-abbrev: word-boundary truncate at 80 chars only.
# Output: "⚠ <abbreviated impediment>" or empty if unset/empty (focus unblocked).
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

if ! rgp_is_in_root_context; then exit 0; fi

PROJ="$(rm_resolve_project)"
IMPEDIMENT_FILE="${ROOT_MODULES_ACTIVE_IMPEDIMENT:-${ROOT_GHOSTPROXY_ACTIVE_IMPEDIMENT:-${PROJ}}/.claude/active-impediment}"

[[ -r "${IMPEDIMENT_FILE}" ]] || exit 0
impediment="$(head -1 "${IMPEDIMENT_FILE}" | tr -d '\r')"
[[ -n "${impediment}" ]] || exit 0

# Word-boundary truncate at 80 chars (no em-dash split — impediment text is rarely structured)
if [[ ${#impediment} -gt 80 ]]; then
    truncated="${impediment:0:79}"
    truncated="${truncated% *}"
    impediment="${truncated}…"
fi

printf '⚠ %s' "${impediment}"
