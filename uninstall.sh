#!/usr/bin/env bash
# $HOME/uninstall.sh — root-modules foundation uninstaller (SCAFFOLD STAGE).
#
# Companion to install.sh. Reverses operations install.sh applied — by mode + profile,
# with same orthogonal axes (per SB-074):
#   - --profile base|full|interactive   reverse install scope
#   - --mode bridge|endpoint|hybrid|auto  which ops apply on this host
#   - per-op toggles --no-X / --with-X
#
# Default behavior: REMOVE-WITH-BACKUP — every removed file is mv'd to <path>.ghostproxy.removed.<UTC-ts>
# rather than deleted. Restore by mv-ing back. --purge flag deletes outright (require --yes).
#
# This is GREENFIELD per T011 decision. Prior $HOME/uninstall.sh debris backed up to
# uninstall.sh.prior-debris.bak.<ts>.
#
# CURRENT STAGE: scaffold — operations are STUBS. Implement-stage will fill the actual
# removal logic for each op-category.

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────
# Globals + defaults
# ────────────────────────────────────────────────────────────────────────

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="0.0.1-scaffold"

DEST_HOME="${HOME}"
DEST_CLAUDE="${DEST_HOME}/.claude"
DEST_OPENCODE="${DEST_HOME}/.config/opencode"

DRY_RUN=0
PURGE=0
VERBOSE=0
ASSUME_YES=0

# Profile + mode + per-op toggles (mirror install.sh semantics)
PROFILE=""
MODE="auto"
WITH_HOOKS=""
WITH_OPENCODE=""
WITH_BRIDGE=""
WITH_WIFI=""
WITH_INTEGRITY=""

readonly REMOVED_TS="$(date -u +%Y%m%dT%H%M%SZ)"
readonly REMOVED_SUFFIX=".ghostproxy.removed.${REMOVED_TS}"

DETECTED_MODE=""

# ────────────────────────────────────────────────────────────────────────
# Logging helpers
# ────────────────────────────────────────────────────────────────────────

log_info()  { printf '[uninstall.sh] %s\n' "$*" >&2; }
log_warn()  { printf '[uninstall.sh][WARN] %s\n' "$*" >&2; }
log_error() { printf '[uninstall.sh][ERROR] %s\n' "$*" >&2; }
log_dry()   { printf '[uninstall.sh][DRY-RUN] would: %s\n' "$*" >&2; }

# ────────────────────────────────────────────────────────────────────────
# Help
# ────────────────────────────────────────────────────────────────────────

print_help() {
    cat <<EOF
${SCRIPT_NAME} ${VERSION} — root-modules foundation uninstaller (greenfield, scaffold-stage)

USAGE:
    ${SCRIPT_NAME} [FLAGS]

FLAGS:
    --dry-run                Preview operations; no state changes.
    --purge                  Delete outright instead of backup-and-rename. Requires --yes.
    --dest <path>            Uninstall from alternate prefix (default: \$HOME).
    --profile <name>         base | full | interactive (mirror install.sh semantics)
    --mode <name>            bridge | endpoint | hybrid | auto
    --with-X / --no-X        Per-op overrides: hooks, opencode, bridge, wifi, integrity
    --verbose                Verbose logging.
    --yes, -y                Assume yes for prompts.
    --version                Print version + exit.
    --help, -h               Show this help.

DEFAULT BEHAVIOR (REMOVE-WITH-BACKUP):
    Each removed file is mv'd to <path>${REMOVED_SUFFIX} rather than deleted.
    To fully purge: --purge --yes (irreversible).

EXIT CODES:
    0   success or no-op
    1   generic failure
    2   prerequisite missing
    3   user aborted (purge without --yes)

EOF
}

# ────────────────────────────────────────────────────────────────────────
# Argument parsing
# ────────────────────────────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)         DRY_RUN=1; shift ;;
            --purge)           PURGE=1; shift ;;
            --dest)            DEST_HOME="$2"; DEST_CLAUDE="${DEST_HOME}/.claude"; DEST_OPENCODE="${DEST_HOME}/.config/opencode"; shift 2 ;;
            --profile)         PROFILE="$2"; shift 2 ;;
            --mode)            MODE="$2"; shift 2 ;;
            --with-hooks)      WITH_HOOKS=1; shift ;;
            --no-hooks)        WITH_HOOKS=0; shift ;;
            --with-opencode)   WITH_OPENCODE=1; shift ;;
            --no-opencode)     WITH_OPENCODE=0; shift ;;
            --with-bridge)     WITH_BRIDGE=1; shift ;;
            --no-bridge)       WITH_BRIDGE=0; shift ;;
            --with-wifi)       WITH_WIFI=1; shift ;;
            --no-wifi)         WITH_WIFI=0; shift ;;
            --with-integrity)  WITH_INTEGRITY=1; shift ;;
            --no-integrity)    WITH_INTEGRITY=0; shift ;;
            --verbose)         VERBOSE=1; shift ;;
            --yes|-y)          ASSUME_YES=1; shift ;;
            --version)         printf '%s %s\n' "${SCRIPT_NAME}" "${VERSION}"; exit 0 ;;
            --help|-h)         print_help; exit 0 ;;
            *)                 log_error "unknown flag: $1"; print_help; exit 1 ;;
        esac
    done

    if [[ "${PURGE}" -eq 1 && "${ASSUME_YES}" -ne 1 ]]; then
        log_error "--purge is irreversible; require --yes to proceed."
        exit 3
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Mode detect (mirrors install.sh — same heuristics)
# ────────────────────────────────────────────────────────────────────────

detect_ghostproxy_mode() {
    local eth_count=0
    local has_bridge_tools=0
    if command -v ip >/dev/null 2>&1; then
        eth_count=$(ip -o link show 2>/dev/null | grep -cE ': (en|eth)' || true)
    fi
    if command -v brctl >/dev/null 2>&1 || ip link add type bridge name __pl_test__ 2>/dev/null; then
        has_bridge_tools=1
        ip link delete __pl_test__ 2>/dev/null || true
    fi
    if [[ "${eth_count}" -ge 2 && "${has_bridge_tools}" -eq 1 ]]; then
        DETECTED_MODE="bridge"
    elif [[ "${eth_count}" -ge 2 ]]; then
        DETECTED_MODE="bridge-capable-no-tools"
    else
        DETECTED_MODE="endpoint"
    fi
    if [[ "${MODE}" == "auto" ]]; then
        MODE="${DETECTED_MODE/bridge-capable-no-tools/endpoint}"
        log_info "mode auto-detected: ${MODE}"
    else
        log_info "mode explicit: ${MODE} (auto would have detected: ${DETECTED_MODE})"
    fi
}

mode_includes() {
    local op="$1"
    case "${op}:${MODE}" in
        bridge:bridge|bridge:hybrid)  return 0 ;;
        wifi:bridge|wifi:hybrid)      return 0 ;;
        bridge:*|wifi:*)              return 1 ;;
        hooks:*|opencode:*|integrity:*) return 0 ;;
    esac
    return 0
}

apply_profile() {
    local p="${PROFILE:-base}"
    local d_hooks d_opencode d_bridge d_wifi d_integrity
    case "${p}" in
        base|full|interactive)
            d_hooks=1; d_opencode=1; d_bridge=1; d_wifi=1; d_integrity=1
            ;;
        *) log_error "unknown profile: ${p}. Valid: base / full / interactive"; exit 2 ;;
    esac
    : "${WITH_HOOKS:=${d_hooks}}"
    : "${WITH_OPENCODE:=${d_opencode}}"
    : "${WITH_BRIDGE:=${d_bridge}}"
    : "${WITH_WIFI:=${d_wifi}}"
    : "${WITH_INTEGRITY:=${d_integrity}}"
    mode_includes bridge || WITH_BRIDGE=0
    mode_includes wifi   || WITH_WIFI=0
    log_info "profile=${p} mode=${MODE} → reverse: hooks=${WITH_HOOKS} opencode=${WITH_OPENCODE} bridge=${WITH_BRIDGE} wifi=${WITH_WIFI} integrity=${WITH_INTEGRITY}"
}

# ────────────────────────────────────────────────────────────────────────
# Backup-then-remove helper
# ────────────────────────────────────────────────────────────────────────

remove_with_backup() {
    local path="$1"
    if [[ ! -e "${path}" ]]; then
        [[ "${VERBOSE}" -eq 1 ]] && log_info "skip (not present): ${path}"
        return 0
    fi
    if [[ "${PURGE}" -eq 1 ]]; then
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "purge (rm -rf): ${path}"
        else
            rm -rf "${path}"
            log_info "purged: ${path}"
        fi
    else
        local backup="${path}${REMOVED_SUFFIX}"
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "remove-with-backup: ${path} -> ${backup}"
        else
            mv "${path}" "${backup}"
            log_info "removed-with-backup: ${path} -> ${backup}"
        fi
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Operations (STUBS — implement stage will fill)
# ────────────────────────────────────────────────────────────────────────

op_uninstall_endpoint_safety_policy() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "remove ${DEST_CLAUDE}/settings.json (with backup or purge per flag)"
        log_dry "remove ${DEST_CLAUDE}/hooks/* (each with backup or purge)"
    else
        log_warn "STUB: op_uninstall_endpoint_safety_policy not implemented (scaffold stage)"
    fi
}

op_uninstall_opencode_bridge() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "remove ${DEST_OPENCODE}/opencode.json"
        log_dry "remove ${DEST_OPENCODE}/plugin/claude-bridge.ts"
        log_dry "remove ${DEST_OPENCODE}/plugin/package.json"
    else
        log_warn "STUB: op_uninstall_opencode_bridge not implemented (scaffold stage)"
    fi
}

op_uninstall_network_bridge() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "tear down nftables rules"
        log_dry "remove bridge interface config (per chosen tool)"
        log_dry "bring down bridge"
    else
        log_warn "STUB: op_uninstall_network_bridge not implemented (scaffold stage)"
    fi
}

op_uninstall_management_wifi() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "remove wpa_supplicant config (with backup)"
        log_dry "remove nftables wifi-input rules"
    else
        log_warn "STUB: op_uninstall_management_wifi not implemented (scaffold stage)"
    fi
}

op_uninstall_integrity_sentinel() {
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "remove integrity baseline state"
    else
        log_warn "STUB: op_uninstall_integrity_sentinel not implemented (scaffold stage)"
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"
    log_info "${SCRIPT_NAME} ${VERSION} starting (scaffold-stage stub)"

    detect_ghostproxy_mode
    apply_profile

    [[ "${WITH_HOOKS}"     == "1" ]] && op_uninstall_endpoint_safety_policy || log_info "skip: endpoint safety policy"
    [[ "${WITH_OPENCODE}"  == "1" ]] && op_uninstall_opencode_bridge        || log_info "skip: opencode bridge"
    [[ "${WITH_BRIDGE}"    == "1" ]] && op_uninstall_network_bridge         || log_info "skip: network bridge"
    [[ "${WITH_WIFI}"      == "1" ]] && op_uninstall_management_wifi        || log_info "skip: management wifi"
    [[ "${WITH_INTEGRITY}" == "1" ]] && op_uninstall_integrity_sentinel     || log_info "skip: integrity sentinel"

    log_info "${SCRIPT_NAME} done${DRY_RUN:+ (dry-run; no state changes)}"
    log_info "stage=scaffold; operations are STUBS — implement-stage required for real uninstall"
}

main "$@"
