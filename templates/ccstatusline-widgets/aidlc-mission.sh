#!/usr/bin/env bash
# aidlc-mission.sh — surface MISSION (multi-cycle objective) on statusline.
# DRAFT v1 — agent-authored 2026-05-06 per SB-095 + UX-design pass Phase 1a.
# Replaces aidlc-objective.sh's monolithic mission portion with an independent
# widget so ccstatusline allocates flex per-layer rather than truncating all
# four layers at 25-30 chars.
# Smart-abbrev: first-clause-before-em-dash → fallback word-boundary at 80.
# Output: "✦ <abbreviated mission>" or empty if unset.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

if ! rgp_is_in_root_context; then exit 0; fi

PROJ="$(rm_resolve_project)"
MISSION_FILE="${ROOT_MODULES_ACTIVE_MISSION:-${ROOT_GHOSTPROXY_ACTIVE_MISSION:-${PROJ}}/.claude/active-mission}"

[[ -r "${MISSION_FILE}" ]] || exit 0
mission="$(head -1 "${MISSION_FILE}" | tr -d '\r')"
[[ -n "${mission}" ]] || exit 0

# Smart-abbrev tier 3: prefer first clause before em-dash (—) or " - " or " : "
abbreviated="${mission%% — *}"
[[ "${abbreviated}" == "${mission}" ]] && abbreviated="${mission%% - *}"
[[ "${abbreviated}" == "${mission}" ]] && abbreviated="${mission%% : *}"

# Smart-abbrev tier 2: word-boundary truncate at 80 chars (only if needed)
if [[ ${#abbreviated} -gt 80 ]]; then
    truncated="${abbreviated:0:79}"
    truncated="${truncated% *}"
    abbreviated="${truncated}…"
fi

printf '✦ %s' "${abbreviated}"
