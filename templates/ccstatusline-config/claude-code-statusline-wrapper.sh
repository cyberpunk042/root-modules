#!/usr/bin/env bash
# $HOME/templates/ccstatusline-config/claude-code-statusline-wrapper.sh
#
# Wrapper invoked by Claude Code's statusLine.command setting.
# Reads active-profile state file + invokes ccstatusline with the right --config.
#
# Per M011 T063 + T064 (operator-approved cycle 17 recommendation A: env-var
# multiple-config-files mechanism). Active profile lives at
# ~/.config/ccstatusline/active-profile (single-line: profile name).
#
# To wire into Claude Code: add to ~/.claude/settings.json:
#   "statusLine": {
#     "type": "command",
#     "command": "bash $HOME/templates/ccstatusline-config/claude-code-statusline-wrapper.sh"
#   }
#
# Path policy: every path is $HOME-relative or env-var-overridable. No hardcoded
# absolute paths to $HOME. The wrapper renders root-modules's statusline
# content unconditionally — when invoked from any session (including sister
# project sessions where this wrapper is the user-level fallback), it shows
# root-modules state. Sister projects that want their own statusLine should
# author one in their project-level settings.json (overrides this fallback).

set -euo pipefail

# === Diagnostic logging (opt-in via env var) ==================================
# Enable with ROOT_GHOSTPROXY_STATUSLINE_DEBUG=1 to write per-invocation diag
# entries to /tmp/ccstatusline-wrapper.log. Off by default (no disk churn).
DBG_LOG="${ROOT_GHOSTPROXY_STATUSLINE_LOG:-/tmp/ccstatusline-wrapper.log}"
DBG_ENABLED=0  # off by default; enable per-invocation via ROOT_GHOSTPROXY_STATUSLINE_DEBUG=1
[[ "${ROOT_GHOSTPROXY_STATUSLINE_DEBUG:-0}" == "1" ]] && DBG_ENABLED=1

dbg() {
    [[ "${DBG_ENABLED}" == "1" ]] || return 0
    {
        printf '[%s] %s pid=%d pwd=%s home=%s claude_proj=%s reason=%s\n' \
            "$(date +%FT%T)" "${1:-trace}" "$$" "${PWD:-}" "${HOME:-}" \
            "${CLAUDE_PROJECT_DIR:-}" "${2:-}"
    } >> "${DBG_LOG}" 2>/dev/null || true
}

dbg start "entered"

# === Resolve config dir (flexible) ============================================
# Override hierarchy:
#   1. ROOT_GHOSTPROXY_CCSTATUSLINE_DIR — explicit operator override
#   2. ${HOME}/.config/ccstatusline — default (XDG-style under user $HOME)
readonly CONFIG_DIR="${ROOT_GHOSTPROXY_CCSTATUSLINE_DIR:-${HOME}/.config/ccstatusline}"
readonly STATE_FILE="${CONFIG_DIR}/active-profile"
readonly DEFAULT_PROFILE="${ROOT_GHOSTPROXY_CCSTATUSLINE_DEFAULT_PROFILE:-base}"

# === Read active profile ======================================================
profile="${DEFAULT_PROFILE}"
if [[ -r "${STATE_FILE}" ]]; then
    profile="$(head -1 "${STATE_FILE}" | tr -d '[:space:]')"
    [[ -n "${profile}" ]] || profile="${DEFAULT_PROFILE}"
fi

config_file="${CONFIG_DIR}/profile-${profile}.json"

# === Fall back gracefully if active profile config missing ====================
if [[ ! -f "${config_file}" ]]; then
    config_file="${CONFIG_DIR}/profile-${DEFAULT_PROFILE}.json"
    if [[ ! -f "${config_file}" ]]; then
        for f in "${CONFIG_DIR}"/profile-*.json; do
            [[ -f "${f}" ]] && { config_file="${f}"; break; }
        done
    fi
    if [[ ! -f "${config_file}" ]]; then
        dbg config "no profile config found in ${CONFIG_DIR}"
        echo "(ccstatusline not configured · install M011)"
        exit 0
    fi
fi

dbg config "using profile=${profile} config=${config_file}"

# === Invoke ccstatusline ======================================================
# Path A collision (type=root, $HOME == project-root) means /opt second-brain
# session falls through to $HOME user-level statusLine, which is THIS wrapper.
# Claude Code's session JSON for that fall-through case reports cwd=$HOME
# even though the agent's project is /opt second-brain. ccstatusline's cwd
# widget then shows $HOME in the /opt session statusline — wrong context.
#
# Fix: transform stdin JSON to override cwd with workspace.project_dir (the
# session's actual project) before piping to ccstatusline. For $HOME sessions
# the override is a no-op (project_dir == cwd). For /opt session, cwd becomes
# /opt/devops-solutions-information-hub.

if ! command -v ccstatusline >/dev/null 2>&1; then
    dbg invoke "ccstatusline binary not found"
    echo "(ccstatusline binary not found · npm install -g ccstatusline)"
    exit 0
fi

dbg invoke "transforming stdin (project_dir → cwd) + piping to ccstatusline --config ${config_file}"

# Use python3 (always present) for JSON transform — robust against escape codes.
python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    pd = (d.get("workspace") or {}).get("project_dir")
    if pd:
        d["cwd"] = pd
        if "workspace" in d and isinstance(d["workspace"], dict):
            d["workspace"]["current_dir"] = pd
    print(json.dumps(d))
except Exception:
    # If transform fails, pass empty JSON — ccstatusline handles gracefully
    print("{}")
' | ccstatusline --config "${config_file}"
