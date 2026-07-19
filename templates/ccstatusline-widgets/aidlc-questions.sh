#!/usr/bin/env bash
# aidlc-questions.sh — count of agent-pending questions (per tools.questions / SB-134).
# DRAFT v1 — agent-authored 2026-05-06 per SB-095.
# Surfaces the agent-asked-questions queue (operator-pending input) — distinct from
# blockers (operator-decision-pending tasks) and decisions (closed-history audit trail).
# Output: "Q:0" / "Q:3" / "Q:?"
# Pattern: matches aidlc-blockers.sh shape (count-only, gateway-resolved Python, fallback path).
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

# /root-context-only — sister sessions read sister state, not $HOME state.
if ! rgp_is_in_root_context; then
    exit 0
fi

readonly TOOLS_PYTHON="$(rm_resolve_python)"
readonly TOOLS_DIR="$(rm_resolve_project)"

# Path 1: tools.questions show — read line-count from queue-file path.
if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/questions.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    n=$("${TOOLS_PYTHON}" -c "
import os, sys
qfile = os.path.expanduser(os.environ.get('ROOT_GHOSTPROXY_ACTIVE_QUESTIONS', '~/.claude/active-questions'))
try:
    with open(qfile) as f:
        lines = [l for l in f.read().splitlines() if l.strip()]
    print(len(lines))
except FileNotFoundError:
    print(0)
except Exception:
    pass" 2>/dev/null || true)
    if [[ -n "${n:-}" ]]; then printf 'Q:%s' "${n}"; exit 0; fi
fi

# Path 2: direct read of queue-file (no Python).
QFILE="${ROOT_MODULES_ACTIVE_QUESTIONS:-${ROOT_GHOSTPROXY_ACTIVE_QUESTIONS:-${TOOLS_DIR}}/.claude/active-questions}"
if [[ -r "${QFILE}" ]]; then
    n=$(grep -c -v '^[[:space:]]*$' "${QFILE}" 2>/dev/null || echo 0)
    printf 'Q:%s' "${n}"
    exit 0
fi

# No queue file = no pending questions.
printf 'Q:0'
