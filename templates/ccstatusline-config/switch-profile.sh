#!/usr/bin/env bash
# $HOME/templates/ccstatusline-config/switch-profile.sh — M011 profile switcher.
#
# Operator-named profiles: "project" (project-aware) | "standard" (session-aware)
# Future-extensible: any profile-NAME.json file in the config dir is selectable.
#
# Per T063 mechanism A (operator-approved cycle 17 recommendation): env var
# CC_STATUSLINE_CONFIG points at the active profile's config file. ccstatusline
# is invoked with --config "$CC_STATUSLINE_CONFIG" by Claude Code's statusLine.
#
# Usage:
#   switch-profile.sh                 # show current profile
#   switch-profile.sh project         # activate project-aware profile
#   switch-profile.sh standard        # activate session-aware profile
#   switch-profile.sh list            # list available profiles
#   switch-profile.sh path            # print the active config file path
#
# Persistence: writes the active profile to ~/.config/ccstatusline/active-profile
# (single line: profile name). Claude Code's statusLine wrapper reads this file.

set -euo pipefail

readonly CONFIG_DIR="${ROOT_GHOSTPROXY_CCSTATUSLINE_DIR:-${HOME}/.config/ccstatusline}"
readonly STATE_FILE="${CONFIG_DIR}/active-profile"
readonly DEFAULT_PROFILE="standard"

usage() {
    cat <<EOF
ccstatusline profile switcher (root-modules M011)

Usage:
    $(basename "$0")                  show current profile
    $(basename "$0") <profile>        activate <profile> (writes ${STATE_FILE})
    $(basename "$0") list             list available profiles in ${CONFIG_DIR}
    $(basename "$0") path             print the active config file path

Profiles available (any profile-<name>.json file in ${CONFIG_DIR}):
EOF
    list_profiles
}

list_profiles() {
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        echo "    (no config dir at ${CONFIG_DIR})"
        return
    fi
    local f name
    for f in "${CONFIG_DIR}"/profile-*.json; do
        [[ -f "${f}" ]] || continue
        name="$(basename "${f}" .json)"
        name="${name#profile-}"
        echo "    - ${name}"
    done
}

current_profile() {
    if [[ -r "${STATE_FILE}" ]]; then
        head -1 "${STATE_FILE}" | tr -d '[:space:]'
    else
        echo "${DEFAULT_PROFILE}"
    fi
}

active_path() {
    local profile="$1"
    echo "${CONFIG_DIR}/profile-${profile}.json"
}

set_profile() {
    local profile="$1"
    local target_path
    target_path="$(active_path "${profile}")"
    if [[ ! -f "${target_path}" ]]; then
        echo "error: profile config not found at ${target_path}" >&2
        echo "available profiles:" >&2
        list_profiles >&2
        exit 2
    fi
    mkdir -p "${CONFIG_DIR}"
    echo "${profile}" > "${STATE_FILE}"
    echo "active profile: ${profile} (config: ${target_path})"
}

main() {
    case "${1:-}" in
        ""|status|current)
            local p
            p="$(current_profile)"
            echo "active profile: ${p}"
            echo "config file: $(active_path "${p}")"
            ;;
        list)
            echo "available profiles in ${CONFIG_DIR}:"
            list_profiles
            ;;
        path)
            active_path "$(current_profile)"
            ;;
        --help|-h|help)
            usage
            ;;
        *)
            set_profile "$1"
            ;;
    esac
}

main "$@"
