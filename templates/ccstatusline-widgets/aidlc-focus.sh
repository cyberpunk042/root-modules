#!/usr/bin/env bash
# aidlc-focus.sh — surface FOCUS (sub-objective within mission) on statusline.
# DRAFT v1 — agent-authored 2026-05-06 per SB-095 + UX-design pass Phase 1a.
# Independent widget so ccstatusline allocates per-layer flex.
# Smart-abbrev: first-clause-before-em-dash → fallback word-boundary at 80.
# Output: "◉ <abbreviated focus>" or empty if unset.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

if ! rgp_is_in_root_context; then exit 0; fi

PROJ="$(rm_resolve_project)"
FOCUS_FILE="${ROOT_MODULES_ACTIVE_FOCUS:-${ROOT_GHOSTPROXY_ACTIVE_FOCUS:-${PROJ}}/.claude/active-focus}"

[[ -r "${FOCUS_FILE}" ]] || exit 0
focus="$(head -1 "${FOCUS_FILE}" | tr -d '\r')"
[[ -n "${focus}" ]] || exit 0

abbreviated="${focus%% — *}"
[[ "${abbreviated}" == "${focus}" ]] && abbreviated="${focus%% - *}"
[[ "${abbreviated}" == "${focus}" ]] && abbreviated="${focus%% : *}"

if [[ ${#abbreviated} -gt 80 ]]; then
    truncated="${abbreviated:0:79}"
    truncated="${truncated% *}"
    abbreviated="${truncated}…"
fi

printf '◉ %s' "${abbreviated}"
