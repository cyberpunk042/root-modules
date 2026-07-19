#!/usr/bin/env bash
# aidlc-mode.sh — active agent mode (PM/Architect/Dual or none).
# Output: "Mode:dual" / "Mode:pm" / "Mode:architect" / "Mode:-"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly MODE_FILE="${ROOT_MODULES_ACTIVE_MODE:-${ROOT_GHOSTPROXY_ACTIVE_MODE:-$(rm_resolve_project)/.claude/active-mode}}"
if [[ -r "${MODE_FILE}" ]]; then
    m=$(head -1 "${MODE_FILE}" | tr -d '[:space:]')
    case "${m}" in
        pm-scrum-master)   printf 'Mode: PM Scrum Master'; exit 0 ;;
        devops-architect)  printf 'Mode: DevOps Architect'; exit 0 ;;
        dual-expert)       printf 'Mode: Dual Expert'; exit 0 ;;
        "")                printf 'Mode: none'; exit 0 ;;
        *)                 printf 'Mode: %s' "${m}"; exit 0 ;;
    esac
fi
printf 'Mode: none'
