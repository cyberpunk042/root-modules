#!/usr/bin/env bash
# _lib.sh — shared helpers for ccstatusline widget shell-outs.
#
# Sourced by the AIDLC widgets that need to invoke the second-brain venv's
# Python (with $HOME/tools.* importable). Centralizes the resolution chain so
# we don't repeat 11x and don't leave hardcoded /opt paths embedded.
#
# Usage:
#   source "$(dirname "$0")/_lib.sh"
#   TOOLS_PYTHON="$(rgp_resolve_python)"
#   TOOLS_DIR="$(rgp_resolve_project)"

# Resolve the Python interpreter that has the project's tools.* importable.
# Order:
#   1. ROOT_GHOSTPROXY_PYTHON — operator override
#   2. RGP_SECOND_BRAIN_ROOT/.venv/bin/python — env-var-resolved second brain
#   3. $HOME/devops-solutions-information-hub/.venv/bin/python — default new install
#   4. /opt/devops-solutions-information-hub/.venv/bin/python — legacy fallback
#   5. python3 — last-resort system python (may lack venv-only deps)
rgp_resolve_python() {
    if [[ -n "${ROOT_GHOSTPROXY_PYTHON:-}" && -x "${ROOT_GHOSTPROXY_PYTHON}" ]]; then
        printf '%s' "${ROOT_GHOSTPROXY_PYTHON}"
        return 0
    fi
    if [[ -n "${RGP_SECOND_BRAIN_ROOT:-}" ]]; then
        local cand="${RGP_SECOND_BRAIN_ROOT%/}/.venv/bin/python"
        if [[ -x "${cand}" ]]; then
            printf '%s' "${cand}"
            return 0
        fi
    fi
    if [[ -x "${HOME}/devops-solutions-information-hub/.venv/bin/python" ]]; then
        printf '%s' "${HOME}/devops-solutions-information-hub/.venv/bin/python"
        return 0
    fi
    if [[ -x /opt/devops-solutions-information-hub/.venv/bin/python ]]; then
        printf '%s' /opt/devops-solutions-information-hub/.venv/bin/python
        return 0
    fi
    command -v python3 || printf 'python3'
}

# Check if the calling session is operating in root-modules's project context.
# Returns 0 (true) if yes, 1 (false) if not. Used by /root-specific widgets to
# gate their rendering — when called from a sister-project session (e.g. /opt
# second-brain), the widget should exit silently rather than render $HOME state
# (which would be wrong-context per operator directive 2026-05-05).
#
# Detection: CLAUDE_PROJECT_DIR set by Claude Code per session. If it matches
# root-modules's home (== $HOME or starts with $HOME + "/"), we're in $HOME.
# If unset (legacy / non-Claude-Code invoker), default to true (preserve
# pre-fix behavior).
rgp_is_in_root_context() {
    local rgp_root="${ROOT_GHOSTPROXY_PROJECT_ROOT:-${HOME}}"
    rgp_root="${rgp_root%/}"
    local proj="${CLAUDE_PROJECT_DIR:-}"
    proj="${proj%/}"
    if [[ -z "${proj}" ]]; then
        return 0  # legacy fallback: assume in-context
    fi
    if [[ "${proj}" == "${rgp_root}" || "${proj}" == "${rgp_root}/"* ]]; then
        return 0
    fi
    return 1
}

# Resolve the project root for the calling SESSION (per operator directive
# 2026-05-05: widgets must render session-context-correct state, not $HOME
# state forced into sister sessions). This means $HOME session reads $HOME,
# /opt second-brain session reads /opt, etc.
#
# Order:
#   1. ROOT_GHOSTPROXY_DIR — explicit operator override (force a specific root)
#   2. CLAUDE_PROJECT_DIR — Claude Code's per-session project root (PRIMARY:
#      this is what makes widgets context-aware)
#   3. $HOME — fallback for non-Claude-Code invokers / legacy sessions
rgp_resolve_project() {
    if [[ -n "${ROOT_GHOSTPROXY_DIR:-}" ]]; then
        printf '%s' "${ROOT_GHOSTPROXY_DIR}"
        return 0
    fi
    if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
        printf '%s' "${CLAUDE_PROJECT_DIR}"
        return 0
    fi
    printf '%s' "${HOME}"
}
