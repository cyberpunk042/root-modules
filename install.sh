#!/usr/bin/env bash
# /root/install.sh — root-ghostproxy foundation installer (SCAFFOLD STAGE — T012).
#
# OS scope: Linux, Debian-family supported (Debian 11+, Ubuntu 20.04+, derivatives).
# Broader Linux (Fedora/RHEL/Arch) — TBD per operator.
# User scope: any user with $HOME — type=root means SCOPE (configures OS-level), not USER.
# Some operations may require root via sudo prompts; install.sh detects + asks per-op.
#
# Per operator directive 2026-05-05 (SB-073): "this project is not limited to
# being on debian 13.. ubuntu too is debian and its not always the user root
# and its not always a bridge... and its not always..."
#
# OPERATIONS (each independently toggleable; profile-driven default sets):
#   - endpoint: AI agent safety policy at ~/.claude/ (settings.json + hooks)
#   - opencode: bridge plugin at ~/.config/opencode/
#   - bridge:   network bridge topology + nftables rules (OPTIONAL)
#   - wifi:     management wifi config (outbound-only) (OPTIONAL)
#   - integrity: integrity sentinel registration
#
# Profiles (--profile <name>) — operator-stated names per CLAUDE.md Hard Rule #4:
#   - base         foundation only (no modules)
#   - full         base + ALL facultative modules (Suricata, PolarProxy when M005; ccstatusline when M011; pipelock when M014)
#   - interactive  TUI-prompts operator for each choice (per-operation toggle interactively)
#
# Ghostproxy MODE (--mode <name>) — orthogonal to profile (per SB-074). Profile decides
# install scope; mode decides which foundation ops are APPLICABLE on this host:
#   - bridge       host acts as transparent L2 IPS (bridge config + wifi mgmt apply)
#   - endpoint     host runs Claude Code/opencode locally; no bridge ops
#   - hybrid       both — endpoint AI + bridge IPS on same host
#   - auto         detect from interface count + bridge tools (default)
#
# Composition: an op is installed iff (profile says yes) AND (mode_includes(op)).
# Per-op flags (--with-X / --no-X) override the composition for that op.
#
# Operator verbatim 2026-05-04: "first there is no modules then 1 then 2 and later
# more but they are all facultative as much as if I do a full install they would
# all be installed". Base = foundation standalone; full = base + all modules.
#
# Per-op toggles (override profile):
#   --with-bridge / --no-bridge     network bridge config
#   --with-wifi   / --no-wifi       management wifi config
#   --with-opencode / --no-opencode opencode bridge plugin
#   --with-hooks    / --no-hooks    Claude Code hook scripts
#   --with-integrity / --no-integrity integrity sentinel
#
# This is GREENFIELD per T011 decision (operator verbatim 2026-05-05): "imagine
# virgin... build from bottom-up... STOP working in reverse". The prior
# /root/install.sh debris was backed up to install.sh.prior-debris.bak.<ts> per
# T006 (leave-in-place: backup-not-delete) before this file was authored.
#
# CURRENT STAGE: scaffold (readiness 50). Implementations are STUBS marked TODO;
# full implementation is implement-stage work per methodology.yaml. Operator
# runs --dry-run to confirm structure; actual host-modification steps require
# implement-stage approval.

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────
# Globals + defaults
# ────────────────────────────────────────────────────────────────────────

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="0.0.2-implement-partial"

# Source of policy files = the directory containing install.sh (i.e., a
# checkout of the root-ghostproxy repo). Destination defaults to $HOME.
# When SRC == DEST_HOME (e.g., installing on the dev host itself),
# install_file() treats matching files as unchanged + skips.
readonly SRC="${SCRIPT_DIR}"

# Default install prefix (overridable via --dest)
DEST_HOME="${HOME}"
DEST_CLAUDE="${DEST_HOME}/.claude"
DEST_OPENCODE="${DEST_HOME}/.config/opencode"

# Flags
DRY_RUN=0
CHECK_MODE=0
VERBOSE=0
ASSUME_YES=0

# Profile + per-operation toggles (default: profile=base unless overridden)
PROFILE=""
WITH_HOOKS=""        # "" = profile decides; "1" = on; "0" = off
WITH_OPENCODE=""
WITH_BRIDGE=""
WITH_WIFI=""
WITH_INTEGRITY=""
WITH_CCSTATUSLINE="" # M011 ccstatusline integration (npm-based)

# Detected OS family (set by detect_os_family)
OS_ID=""
OS_VERSION_ID=""
OS_FAMILY=""       # "debian" | "rhel" | "arch" | "unknown"

# Ghostproxy runtime mode (separate from install profile per SB-074)
# Values: bridge | endpoint | hybrid | auto (default = auto)
MODE="auto"
DETECTED_MODE=""   # set by detect_ghostproxy_mode

# Backup timestamp (UTC, ISO 8601-ish, safe-for-filename)
readonly BACKUP_TS="$(date -u +%Y%m%dT%H%M%SZ)"
readonly BACKUP_SUFFIX=".ghostproxy.bak.${BACKUP_TS}"

# ────────────────────────────────────────────────────────────────────────
# Logging helpers
# ────────────────────────────────────────────────────────────────────────

log_info()  { printf '[install.sh] %s\n' "$*" >&2; }
log_warn()  { printf '[install.sh][WARN] %s\n' "$*" >&2; }
log_error() { printf '[install.sh][ERROR] %s\n' "$*" >&2; }
log_dry()   { printf '[install.sh][DRY-RUN] would: %s\n' "$*" >&2; }
log_check() { printf '[install.sh][CHECK] %s: %s\n' "$1" "$2" >&2; }

# ────────────────────────────────────────────────────────────────────────
# Help
# ────────────────────────────────────────────────────────────────────────

print_help() {
    cat <<EOF
${SCRIPT_NAME} ${VERSION} — root-ghostproxy foundation installer (greenfield, scaffold-stage)

USAGE:
    ${SCRIPT_NAME} [FLAGS]

FLAGS:
    --dry-run        Preview operations; no state changes.
    --check          Verify installed state matches expected. Exit non-zero on drift.
    --dest <path>    Install to alternate prefix (default: \$HOME). For testing.
    --verbose        Verbose logging.
    --yes, -y        Assume yes for any prompts.
    --help, -h       Show this help.
    --version        Print version + exit.

OPERATIONS (executed in sequence on real install):
    1. Endpoint AI agent safety policy (~/.claude/settings.json + hooks)
    2. Opencode bridge plugin (~/.config/opencode/)
    3. Network bridge topology + nftables rules
    4. Management wifi config (outbound-only)
    5. Integrity sentinel registration
    6. Post-install verification

EXIT CODES:
    0   success or no-op (idempotent re-run, --check passed)
    1   generic failure
    2   prerequisite missing (e.g., not Debian 13, not root, missing dep)
    3   --check found drift
    4   user aborted

NOTES:
    - This installer is IDEMPOTENT: re-run = no-op when state matches.
    - Out-of-sync files are backed up to <path>${BACKUP_SUFFIX} before overwrite.
    - For uninstall, use companion ${SCRIPT_DIR}/uninstall.sh.
    - SCAFFOLD STAGE: operations are STUBS. Implement-stage work fills them.

REFERENCES:
    - Foundation hardening module: wiki/backlog/modules/root-ghostproxy-m003-*.md
    - Methodology stage gates:     wiki/config/methodology.yaml
    - Brain files:                 README.md, CLAUDE.md, AGENTS.md, ARCHITECTURE.md
EOF
}

# ────────────────────────────────────────────────────────────────────────
# Argument parsing
# ────────────────────────────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)         DRY_RUN=1; shift ;;
            --check)           CHECK_MODE=1; shift ;;
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
            --with-ccstatusline) WITH_CCSTATUSLINE=1; shift ;;
            --no-ccstatusline)   WITH_CCSTATUSLINE=0; shift ;;
            --verbose)         VERBOSE=1; shift ;;
            --yes|-y)          ASSUME_YES=1; shift ;;
            --version)         printf '%s %s\n' "${SCRIPT_NAME}" "${VERSION}"; exit 0 ;;
            --help|-h)         print_help; exit 0 ;;
            *)                 log_error "unknown flag: $1"; print_help; exit 1 ;;
        esac
    done
}

# Detect ghostproxy runtime mode (per SB-074 — orthogonal to install profile).
# Heuristics (per operator-approved recommendation cycle 24):
#   bridge   = 2+ ethernet interfaces UP + bridge tools installed (brctl OR `ip link add type bridge` works)
#   endpoint = single ethernet OR no bridge tools
#   hybrid   = 2+ ethernet interfaces + currently-running endpoint AI (Claude Code / opencode visible)
#   auto     = run detection; result feeds DETECTED_MODE
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
        MODE="${DETECTED_MODE/bridge-capable-no-tools/endpoint}"  # fail-safe: no tools → endpoint
        log_info "mode auto-detected: ${MODE} (eth_count=${eth_count}, has_bridge_tools=${has_bridge_tools})"
    else
        log_info "mode explicit: ${MODE} (auto-detected: ${DETECTED_MODE})"
    fi
    case "${MODE}" in
        bridge|endpoint|hybrid) ;;
        *) log_error "unknown mode: ${MODE}. Valid: bridge / endpoint / hybrid / auto"; exit 2 ;;
    esac
}

# Per-op applicability — does the current ghostproxy mode include this op?
mode_includes() {
    local op="$1"
    case "${op}:${MODE}" in
        # bridge-related ops apply only when mode includes bridge
        bridge:bridge|bridge:hybrid)  return 0 ;;
        wifi:bridge|wifi:hybrid)      return 0 ;;
        bridge:*|wifi:*)              return 1 ;;
        # endpoint-related + integrity always apply (foundation regardless of mode)
        hooks:*|opencode:*|integrity:*) return 0 ;;
    esac
    return 0
}

apply_profile() {
    # Apply profile defaults per operator-stated profile names (base / full / interactive).
    # PROFILE = install scope (foundation-only vs foundation+modules); orthogonal to MODE.
    # Per-op toggles override profile defaults.
    # Final applicability = (profile says yes) AND (mode_includes(op))
    local p="${PROFILE:-base}"
    local d_hooks d_opencode d_bridge d_wifi d_integrity
    local d_ccstatusline
    case "${p}" in
        base)
            # Foundation operations only — no Features modules. ccstatusline=0 since it's Features-tier.
            d_hooks=1; d_opencode=1; d_bridge=1; d_wifi=1; d_integrity=1
            d_ccstatusline=0
            ;;
        full)
            # Base + ALL facultative modules including Features (ccstatusline, future Suricata/PolarProxy).
            # Per operator: "if I do a full install they would all be installed."
            d_hooks=1; d_opencode=1; d_bridge=1; d_wifi=1; d_integrity=1
            d_ccstatusline=1
            ;;
        interactive)
            log_warn "STUB: interactive profile prompts not implemented (scaffold stage); falling through to base defaults"
            d_hooks=1; d_opencode=1; d_bridge=1; d_wifi=1; d_integrity=1
            d_ccstatusline=0
            ;;
        *)
            log_error "unknown profile: ${p}. Valid: base / full / interactive"; exit 2
            ;;
    esac
    # Apply profile defaults only where per-op flag wasn't set
    : "${WITH_HOOKS:=${d_hooks}}"
    : "${WITH_OPENCODE:=${d_opencode}}"
    : "${WITH_BRIDGE:=${d_bridge}}"
    : "${WITH_WIFI:=${d_wifi}}"
    : "${WITH_INTEGRITY:=${d_integrity}}"
    : "${WITH_CCSTATUSLINE:=${d_ccstatusline}}"
    # Filter via mode_includes — profile-on AND mode-applicable
    mode_includes bridge || WITH_BRIDGE=0
    mode_includes wifi   || WITH_WIFI=0
    log_info "profile=${p} mode=${MODE} → hooks=${WITH_HOOKS} opencode=${WITH_OPENCODE} bridge=${WITH_BRIDGE} wifi=${WITH_WIFI} integrity=${WITH_INTEGRITY} ccstatusline=${WITH_CCSTATUSLINE}"
}

# Operation 6: ccstatusline (M011 — Features tier; npm-based)
op_install_ccstatusline() {
    local src_widgets="${SRC}/templates/ccstatusline-widgets"
    local src_config="${SRC}/templates/ccstatusline-config"
    local dst_widgets="${DEST_HOME}/.local/share/ccstatusline-widgets"
    local dst_config="${DEST_HOME}/.config/ccstatusline"
    local dst_settings="${DEST_HOME}/.claude/settings.json"

    if [[ ! -d "${src_widgets}" || ! -d "${src_config}" ]]; then
        log_warn "ccstatusline templates not found at ${src_widgets} or ${src_config} — skipping"
        return 0
    fi

    # npm availability check
    if ! command -v npm >/dev/null 2>&1; then
        log_warn "npm not available; ccstatusline binary install skipped (template files still deployed below)"
    else
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "npm install -g ccstatusline (if not already installed)"
        elif ! command -v ccstatusline >/dev/null 2>&1; then
            log_info "installing ccstatusline via npm (global)"
            npm install -g ccstatusline 2>&1 || log_warn "npm install ccstatusline failed; continuing with template deploy"
        else
            log_info "ccstatusline already present: $(command -v ccstatusline)"
        fi
    fi

    # Deploy widget shell scripts
    local f
    for f in "${src_widgets}"/*.sh; do
        [[ -e "${f}" ]] || continue
        install_file "${f}" "${dst_widgets}/$(basename "${f}")" 0755
    done

    # Deploy config profiles + switcher + Claude Code wrapper
    for f in "${src_config}"/*.json; do
        [[ -e "${f}" ]] || continue
        install_file "${f}" "${dst_config}/$(basename "${f}")" 0644
    done
    for f in "${src_config}"/*.sh; do
        [[ -e "${f}" ]] || continue
        install_file "${f}" "${dst_config}/$(basename "${f}")" 0755
    done

    # Default active profile = base (1-column tier; operator-mandated naming cycle 41).
    # Operator picks via switch-profile.sh: base / intermediary / full-aidlc.
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "set default active profile = base at ${dst_config}/active-profile (if missing)"
    elif [[ ! -e "${dst_config}/active-profile" ]]; then
        echo "base" > "${dst_config}/active-profile"
        log_info "set default active profile: base"
    fi

    # Wire statusLine.command into ~/.claude/settings.json (idempotent jq patch).
    local wrapper_path="${dst_config}/claude-code-statusline-wrapper.sh"
    if [[ ! -f "${dst_settings}" ]]; then
        log_warn "${dst_settings} not present; statusLine wiring skipped (run with --with-hooks first or ensure endpoint policy installed)"
        return 0
    fi
    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq not available; statusLine wiring skipped (settings.json edit deferred to operator)"
        return 0
    fi
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "patch ${dst_settings}: add statusLine.command = ${wrapper_path}"
    else
        # Idempotent: only patch if statusLine isn't already set OR points at the wrong path
        local current
        current=$(jq -r '.statusLine.command // empty' "${dst_settings}" 2>/dev/null || echo "")
        if [[ "${current}" == "${wrapper_path}" ]]; then
            log_info "statusLine already wired in ${dst_settings} (unchanged)"
        else
            backup_if_exists "${dst_settings}"
            local tmp
            tmp="$(mktemp)"
            jq --arg cmd "${wrapper_path}" '.statusLine = {type: "command", command: $cmd}' "${dst_settings}" > "${tmp}" \
                && mv "${tmp}" "${dst_settings}" \
                && log_info "wired statusLine.command in ${dst_settings} → ${wrapper_path}"
        fi
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Pre-checks
# ────────────────────────────────────────────────────────────────────────

detect_os_family() {
    # Parse /etc/os-release; classify into supported family
    if [[ ! -r /etc/os-release ]]; then
        log_warn "STUB: /etc/os-release not readable; OS detection deferred (scaffold stage)"
        return 0
    fi
    # shellcheck disable=SC1091
    . /etc/os-release 2>/dev/null || true
    OS_ID="${ID:-unknown}"
    OS_VERSION_ID="${VERSION_ID:-unknown}"
    case "${OS_ID}" in
        debian|ubuntu|raspbian|linuxmint|pop|elementary|kali) OS_FAMILY="debian" ;;
        rhel|centos|fedora|rocky|almalinux)                   OS_FAMILY="rhel" ;;
        arch|manjaro|endeavouros)                             OS_FAMILY="arch" ;;
        *)                                                    OS_FAMILY="unknown" ;;
    esac
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "OS detected: ${OS_ID} ${OS_VERSION_ID} (family=${OS_FAMILY})"
    else
        log_info "OS detected: ${OS_ID} ${OS_VERSION_ID} (family=${OS_FAMILY})"
    fi
    if [[ "${OS_FAMILY}" == "unknown" ]]; then
        log_warn "OS family unrecognized (${OS_ID}). Operations will best-effort; some may not apply."
    fi
}

# Translate generic dependency name → distro-specific package name for the install hint.
# Args: <family> <dep1> [dep2 ...]
# Stdout: space-separated package names
_translate_pkg_names() {
    local family="$1"; shift
    local d out=""
    for d in "$@"; do
        case "${family}:${d}" in
            *:nft)                                   out+="nftables " ;;
            debian:ip)                               out+="iproute2 " ;;
            rhel:ip)                                 out+="iproute " ;;
            arch:ip)                                 out+="iproute2 " ;;
            debian:wpa_supplicant)                   out+="wpasupplicant " ;;
            rhel:wpa_supplicant|arch:wpa_supplicant) out+="wpa_supplicant " ;;
            *)                                       out+="${d} " ;;
        esac
    done
    printf '%s' "${out% }"
}

require_dependencies() {
    # Verify required CLI tools are present BEFORE running ops. Required set
    # depends on enabled ops (per profile + per-op toggles after apply_profile).
    # Hint OS-family-specific install command when something is missing so the
    # operator can resolve quickly. In --dry-run mode, missing deps WARN only;
    # in real-install mode, missing required deps EXIT with code 2 (per --help
    # exit-code semantics: "prerequisite missing").
    #
    # Required-set composition:
    #   core (always):        python3, jq
    #   if WITH_BRIDGE=1:     nft, ip
    #   if WITH_WIFI=1:       wpa_supplicant
    # Hooks/opencode/integrity ops add no extra deps beyond core.
    # ccstatusline check (npm) is already done inside op_install_ccstatusline.
    local -a req_core=(python3 jq)
    local -a req_optional=()
    [[ "${WITH_BRIDGE}" == "1" ]] && req_optional+=(nft ip)
    [[ "${WITH_WIFI}"   == "1" ]] && req_optional+=(wpa_supplicant)

    local -a missing=()
    local d
    for d in "${req_core[@]}" "${req_optional[@]}"; do
        if ! command -v "${d}" >/dev/null 2>&1; then
            missing+=("${d}")
        fi
    done

    local checked="${req_core[*]}${req_optional:+ ${req_optional[*]}}"
    if [[ "${#missing[@]}" -eq 0 ]]; then
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "verify dependencies present: ${checked}"
        else
            log_info "dependencies OK: ${checked}"
        fi
        return 0
    fi

    # Build family-aware install hint
    local hint pkgs
    case "${OS_FAMILY}" in
        debian) pkgs=$(_translate_pkg_names debian "${missing[@]}"); hint="apt-get install ${pkgs}" ;;
        rhel)   pkgs=$(_translate_pkg_names rhel   "${missing[@]}"); hint="dnf install ${pkgs}" ;;
        arch)   pkgs=$(_translate_pkg_names arch   "${missing[@]}"); hint="pacman -S ${pkgs}" ;;
        *)      hint="install via your distro's package manager: ${missing[*]}" ;;
    esac

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_warn "dry-run: missing dependencies (${missing[*]}); install with: ${hint}"
        return 0
    fi
    log_error "missing required dependencies: ${missing[*]}"
    log_error "install with: ${hint}"
    exit 2
}

# ────────────────────────────────────────────────────────────────────────
# Operations (STUBS — implement stage will fill)
# ────────────────────────────────────────────────────────────────────────

# Operation 1: Endpoint AI agent safety policy (IMPLEMENT-stage cycle 27, T014 accepted state)
op_install_endpoint_safety_policy() {
    local src_settings="${SRC}/.claude/settings.json"
    local src_hooks_dir="${SRC}/.claude/hooks"
    local tgt_settings="${DEST_CLAUDE}/settings.json"
    local tgt_hooks_dir="${DEST_CLAUDE}/hooks"

    if [[ ! -d "${src_hooks_dir}" ]]; then
        log_warn "source ${src_hooks_dir} not found — skipping endpoint safety policy"
        return 0
    fi

    install_file "${src_settings}" "${tgt_settings}" 0644

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "ensure ${tgt_hooks_dir} exists + install hook scripts"
    else
        mkdir -p "${tgt_hooks_dir}"
    fi

    local f
    for f in "${src_hooks_dir}"/*.sh "${src_hooks_dir}"/*.py; do
        [[ -e "${f}" ]] || continue
        local basename
        basename="$(basename "${f}")"
        local mode=0644
        [[ "${basename}" =~ \.sh$ ]] && mode=0755
        install_file "${f}" "${tgt_hooks_dir}/${basename}" "${mode}"
    done
}

# Operation 2: Opencode bridge plugin (IMPLEMENT-stage cycle 27)
op_install_opencode_bridge() {
    local src_oc_json="${SRC}/.config/opencode/opencode.json"
    local src_plugin_dir="${SRC}/.config/opencode/plugin"

    if [[ ! -f "${src_oc_json}" ]]; then
        log_warn "source ${src_oc_json} not found — skipping opencode bridge"
        return 0
    fi

    install_file "${src_oc_json}" "${DEST_OPENCODE}/opencode.json" 0644

    if [[ -d "${src_plugin_dir}" ]]; then
        local f
        for f in "${src_plugin_dir}"/*.ts "${src_plugin_dir}"/*.json; do
            [[ -e "${f}" ]] || continue
            install_file "${f}" "${DEST_OPENCODE}/plugin/$(basename "${f}")" 0644
        done
    fi
}

# Operation 3: Network bridge topology (IMPLEMENT-stage cycle 28 — systemd-networkd per T013)
op_install_network_bridge() {
    local src_dir="${SRC}/templates/systemd-networkd"
    local dst_dir="/etc/systemd/network"

    if [[ ! -d "${src_dir}" ]]; then
        log_warn "source ${src_dir} not found — skipping network bridge"
        return 0
    fi

    # Bridge config is system-level — requires root
    if [[ "${EUID}" -ne 0 && "${DRY_RUN}" -ne 1 ]]; then
        log_warn "op_install_network_bridge requires root (currently EUID=${EUID}); skipping"
        log_info "  rerun with sudo or as root to install bridge config"
        return 0
    fi

    install_file "${src_dir}/30-ghostproxy-bridge.netdev"           "${dst_dir}/30-ghostproxy-bridge.netdev"           0644
    install_file "${src_dir}/30-ghostproxy-bridge.network"          "${dst_dir}/30-ghostproxy-bridge.network"          0644
    install_file "${src_dir}/40-ghostproxy-bridge-members.network"  "${dst_dir}/40-ghostproxy-bridge-members.network"  0644

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "networkctl reload (apply systemd-networkd config)"
        log_dry "networkctl up gpbr0 (bring up bridge)"
        log_dry "(operator may need to customize 40-ghostproxy-bridge-members.network for non-en* interface naming)"
    else
        if command -v networkctl >/dev/null 2>&1; then
            networkctl reload
            log_info "networkctl reload applied"
        else
            log_warn "networkctl not available; bridge config deployed but not activated"
        fi
    fi

    # nftables rules (INPUT/FORWARD/OUTPUT) — implement-stage TODO; needs separate template
    log_info "TODO (implement-stage continuation): nftables INPUT/FORWARD/OUTPUT chain rules"
}

# Operation 4: Management wifi (outbound-only)
#
# Per operator invariant 2026-05-04 (T013, M003): management wifi is the
# host's edge-network connection (operator's existing network), used for
# OUTBOUND ops (SSH-out, apt updates, monitoring push). MUST NOT accept
# inbound — INPUT chain drops everything except established/related.
#
# Deploy:
#   1. /etc/wpa_supplicant/wpa_supplicant-mgmt0.conf (TEMPLATE — operator
#      MUST fill SSID + PSK + country code BEFORE service starts)
#   2. /etc/nftables.d/management-wifi-outbound-only.nft (deterministic
#      from operator's outbound-only invariant; no operator config needed)
#
# NOT deployed (out of foundation scope; T013 operator-decision pending):
#   - Bridge FORWARD chain default-policy (default-accept vs default-drop —
#     threat-model question per T013)
#   - NetworkManager integration (operator-decision: wpa_supplicant direct
#     OR NetworkManager; current default = wpa_supplicant direct)
#
# Idempotency: install_file() detects unchanged-content + skips; backs up
# divergent existing file to <path>.ghostproxy.bak.<ts> before overwrite.
op_install_management_wifi() {
    local src_wpa="${SRC}/templates/wpa_supplicant/wpa_supplicant-mgmt0.conf.template"
    local src_nft="${SRC}/templates/nftables/management-wifi-outbound-only.nft"
    local tgt_wpa="/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf"
    local tgt_nft="/etc/nftables.d/management-wifi-outbound-only.nft"

    if [[ ! -f "${src_wpa}" ]]; then
        log_warn "source ${src_wpa} not found — skipping management wifi"
        return 0
    fi
    if [[ ! -f "${src_nft}" ]]; then
        log_warn "source ${src_nft} not found — skipping management wifi"
        return 0
    fi

    # Both deploys are system-level — require root unless dry-run.
    if [[ "${EUID}" -ne 0 && "${DRY_RUN}" -ne 1 ]]; then
        log_warn "op_install_management_wifi requires root (currently EUID=${EUID}); skipping"
        log_info "  rerun with sudo or as root to install wifi config"
        return 0
    fi

    # 1. Deploy wpa_supplicant template. install_file() respects --dry-run.
    install_file "${src_wpa}" "${tgt_wpa}" 0600

    # Operator-config reminder: only print if the deployed file still has the
    # placeholder strings (i.e., operator hasn't filled it in yet).
    if [[ "${DRY_RUN}" -ne 1 && -r "${tgt_wpa}" ]] \
        && grep -q "__OPERATOR_SSID__\|__OPERATOR_PSK_OR_HEX__\|__COUNTRY_CODE__" "${tgt_wpa}" 2>/dev/null; then
        log_warn "wpa_supplicant config has placeholders — operator must fill before starting service:"
        log_warn "  edit ${tgt_wpa} and replace __OPERATOR_SSID__, __OPERATOR_PSK_OR_HEX__, __COUNTRY_CODE__"
        log_warn "  use \`wpa_passphrase <ssid> <passphrase>\` to generate hex-PSK (recommended)"
    fi

    # 2. Deploy nftables ruleset. /etc/nftables.d/ must exist (some distros
    # don't create it; create idempotently).
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "ensure /etc/nftables.d/ exists"
    else
        mkdir -p /etc/nftables.d
    fi
    install_file "${src_nft}" "${tgt_nft}" 0644

    # 3. Syntax-check the deployed nft file (no commit). Surfaces template
    # errors before they reach the running ruleset.
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "syntax-check: nft -c -f ${tgt_nft}"
    elif command -v nft >/dev/null 2>&1; then
        if nft -c -f "${tgt_nft}" 2>&1; then
            log_info "nftables syntax OK: ${tgt_nft}"
        else
            log_error "nftables syntax check FAILED on ${tgt_nft}"
            log_error "  ruleset NOT loaded; operator must fix template + re-run install"
            return 1
        fi
    else
        log_warn "nft binary not present; skipping syntax check (op should have caught this in require_dependencies)"
    fi

    # 4. Reload nftables service so the new ruleset takes effect. Don't
    # reload if dry-run. Don't reload if main /etc/nftables.conf doesn't
    # include /etc/nftables.d/* (we'd be deploying a file that's not loaded).
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "if /etc/nftables.conf includes /etc/nftables.d/*: systemctl reload nftables"
    elif [[ -r /etc/nftables.conf ]] && grep -qE '^[[:space:]]*include[[:space:]]+"?/etc/nftables\.d' /etc/nftables.conf 2>/dev/null; then
        if command -v systemctl >/dev/null 2>&1; then
            systemctl reload nftables 2>&1 || log_warn "systemctl reload nftables failed (may need: nft -f /etc/nftables.conf)"
        else
            log_warn "systemctl not present; operator must reload nftables manually:"
            log_warn "  nft -f /etc/nftables.conf"
        fi
    else
        log_warn "/etc/nftables.conf does NOT include /etc/nftables.d/* — deployed file won't be loaded"
        log_warn "  operator should add: \`include \"/etc/nftables.d/*.nft\"\` to /etc/nftables.conf"
    fi

    log_info "management wifi config deployed (template at ${tgt_wpa}; nftables at ${tgt_nft})"
}

# Operation 5: Integrity sentinel
op_install_integrity_sentinel() {
    # Implement-stage: compute SHA256 baselines for safety-policy artefacts
    # and register them at ${DEST_CLAUDE}/integrity.json. The runtime check
    # in ${DEST_CLAUDE}/hooks/integrity.py validates STRUCTURE (file presence,
    # min sizes, deny-rule count, etc.); this baseline registers the EXPECTED
    # CONTENT hash so a future verification-mode check can detect tampering
    # below the structural threshold.
    #
    # Files baselined: the REQUIRED_HOOK_FILES from integrity.py + integrity.py
    # itself + settings.json. Same set the runtime check enforces.

    local sentinel="${DEST_CLAUDE}/integrity.json"
    local hooks_dir="${DEST_CLAUDE}/hooks"
    local files_to_hash=(
        "${hooks_dir}/policy-block.sh"
        "${hooks_dir}/malware-block.sh"
        "${hooks_dir}/leak-detector.sh"
        "${hooks_dir}/integrity.py"
        "${DEST_CLAUDE}/settings.json"
    )

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "compute SHA256 baselines for ${#files_to_hash[@]} safety-policy artefacts"
        for f in "${files_to_hash[@]}"; do
            log_dry "  baseline: ${f}"
        done
        log_dry "register sentinel state at ${sentinel}"
        return 0
    fi

    if ! command -v sha256sum >/dev/null 2>&1; then
        log_error "sha256sum not found; cannot register integrity sentinel"
        return 1
    fi

    log_info "computing integrity baselines (${#files_to_hash[@]} artefacts)"

    # Build a JSON object of {path: sha256} pairs. Use python3 if available
    # (handles JSON quoting cleanly); fall back to manual jq-free emit.
    local tmp; tmp=$(mktemp -t rgp-integrity.XXXXXX.json)
    trap 'rm -f "${tmp}"' RETURN

    if command -v python3 >/dev/null 2>&1; then
        python3 - "${files_to_hash[@]}" >"${tmp}" <<'PYEOF'
import hashlib, json, os, sys, time
files = sys.argv[1:]
baseline = {}
for path in files:
    try:
        with open(path, 'rb') as f:
            baseline[path] = hashlib.sha256(f.read()).hexdigest()
    except OSError as e:
        baseline[path] = f"<missing:{e.strerror or 'unknown'}>"
out = {
    "version": 1,
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "tool": "install.sh op_install_integrity_sentinel",
    "baselines": baseline,
}
print(json.dumps(out, indent=2))
PYEOF
    else
        # Bash-only fallback: emit JSON manually
        {
            printf '{\n  "version": 1,\n  "generated_at": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf '  "tool": "install.sh op_install_integrity_sentinel",\n'
            printf '  "baselines": {\n'
            local first=1
            for f in "${files_to_hash[@]}"; do
                local hash="<missing>"
                if [[ -r "${f}" ]]; then
                    hash="$(sha256sum "${f}" | awk '{print $1}')"
                fi
                if [[ ${first} -eq 1 ]]; then
                    first=0
                else
                    printf ',\n'
                fi
                printf '    "%s": "%s"' "${f}" "${hash}"
            done
            printf '\n  }\n}\n'
        } >"${tmp}"
    fi

    # Atomic move into place
    if [[ -f "${sentinel}" ]]; then
        backup_if_exists "${sentinel}"
    fi
    install -m 0644 "${tmp}" "${sentinel}"
    log_info "integrity sentinel registered: ${sentinel}"
}

# Post-install: verify the install actually landed correctly. Returns 0 on
# all-green, non-zero on any failure (caller decides whether to fail the
# install or just warn). Implementation: run a chain of checks scoped to
# what was installed (per WITH_* toggles) and emit per-check status.
op_verify() {
    local checks=0 passed=0 failed=0
    local fail_reasons=()

    _verify_check() {
        # _verify_check <label> <command-string>
        # Runs command; increments counters; logs result.
        checks=$((checks + 1))
        local label="$1"; shift
        if "$@" >/dev/null 2>&1; then
            passed=$((passed + 1))
            log_check "${label}" "PASS"
        else
            failed=$((failed + 1))
            fail_reasons+=("${label}")
            log_check "${label}" "FAIL"
        fi
    }

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "verify ~/.claude/settings.json exists + parses as JSON"
        log_dry "verify hook scripts present + executable (policy-block, malware-block, leak-detector)"
        log_dry "verify integrity sentinel exists at ${DEST_CLAUDE}/integrity.json (if --with-integrity)"
        log_dry "verify integrity baselines match current file hashes (if --with-integrity)"
        log_dry "verify opencode bridge resolves (if --with-opencode)"
        log_dry "verify bridge interfaces UP (if --with-bridge)"
        return 0
    fi

    log_info "running post-install verification"

    # Always-check: settings.json valid + hook structural integrity (uses the
    # same integrity_check() the runtime hooks use — a single source of truth).
    if [[ -f "${DEST_CLAUDE}/settings.json" ]]; then
        _verify_check "settings.json parses" \
            python3 -c "import json; json.load(open('${DEST_CLAUDE}/settings.json'))"
    else
        checks=$((checks + 1))
        failed=$((failed + 1))
        fail_reasons+=("settings.json missing")
        log_check "settings.json missing" "FAIL"
    fi

    # Hook script presence + executability
    for fname in policy-block.sh malware-block.sh leak-detector.sh; do
        if [[ -x "${DEST_CLAUDE}/hooks/${fname}" ]]; then
            _verify_check "${fname} executable" true
        else
            checks=$((checks + 1))
            failed=$((failed + 1))
            fail_reasons+=("${fname} missing or not executable")
            log_check "${fname}" "FAIL (not executable)"
        fi
    done

    # Runtime integrity check (same as malware-block.sh fires per tool call)
    if [[ -r "${DEST_CLAUDE}/hooks/integrity.py" ]]; then
        local panic
        panic=$(cd "${DEST_CLAUDE}/hooks" && python3 -c "
from integrity import integrity_check
r = integrity_check()
print(r if r else 'OK')
" 2>&1)
        if [[ "${panic}" == "OK" ]]; then
            _verify_check "integrity_check()" true
        else
            checks=$((checks + 1))
            failed=$((failed + 1))
            fail_reasons+=("integrity_check: ${panic}")
            log_check "integrity_check" "FAIL: ${panic}"
        fi
    fi

    # If --with-integrity: verify baseline file present + matches current hashes
    if [[ "${WITH_INTEGRITY:-0}" == "1" ]]; then
        local sentinel="${DEST_CLAUDE}/integrity.json"
        if [[ -r "${sentinel}" ]]; then
            local mismatch_count
            mismatch_count=$(python3 -c "
import hashlib, json, sys
try:
    d = json.load(open('${sentinel}'))
    mismatches = []
    for path, expected in d.get('baselines', {}).items():
        if expected.startswith('<missing'):
            continue
        try:
            actual = hashlib.sha256(open(path, 'rb').read()).hexdigest()
            if actual != expected:
                mismatches.append(path)
        except OSError:
            mismatches.append(path + ' (unreadable)')
    print(len(mismatches))
    for m in mismatches:
        print('  drifted:', m, file=sys.stderr)
except Exception as e:
    print('?')
    print(e, file=sys.stderr)
" 2>&1 | head -1)
            if [[ "${mismatch_count}" == "0" ]]; then
                _verify_check "integrity baselines match" true
            else
                checks=$((checks + 1))
                failed=$((failed + 1))
                fail_reasons+=("integrity baselines: ${mismatch_count} drifted")
                log_check "integrity baselines" "FAIL: ${mismatch_count} drifted"
            fi
        else
            checks=$((checks + 1))
            failed=$((failed + 1))
            fail_reasons+=("integrity sentinel missing at ${sentinel}")
            log_check "integrity sentinel" "FAIL: missing"
        fi
    fi

    # If --with-opencode: verify bridge plugin resolves
    if [[ "${WITH_OPENCODE:-0}" == "1" ]]; then
        if command -v opencode >/dev/null 2>&1; then
            if opencode debug config 2>/dev/null | grep -q "claude-bridge"; then
                _verify_check "opencode bridge resolves" true
            else
                checks=$((checks + 1))
                failed=$((failed + 1))
                fail_reasons+=("opencode bridge plugin not resolved")
                log_check "opencode bridge" "FAIL: not in resolved config"
            fi
        else
            log_check "opencode bridge" "SKIP (opencode not installed)"
        fi
    fi

    # If --with-bridge: verify network interfaces present + UP. Implementation
    # gated on br0 existing (the configured bridge name in M003 templates).
    if [[ "${WITH_BRIDGE:-0}" == "1" ]]; then
        if command -v ip >/dev/null 2>&1 && ip link show br0 >/dev/null 2>&1; then
            if ip link show br0 | grep -q "state UP"; then
                _verify_check "br0 UP" true
            else
                checks=$((checks + 1))
                failed=$((failed + 1))
                fail_reasons+=("br0 exists but not UP")
                log_check "br0" "FAIL: not UP"
            fi
        else
            log_check "br0" "SKIP (interface not present yet)"
        fi
    fi

    # Summary
    log_info "verify: ${passed}/${checks} passed${failed:+, ${failed} failed}"
    if [[ "${failed}" -gt 0 ]]; then
        log_warn "verify failures:"
        for r in "${fail_reasons[@]}"; do
            log_warn "  - ${r}"
        done
        return 1
    fi
    return 0
}

# ────────────────────────────────────────────────────────────────────────
# --check mode (read-only; reports drift)
# ────────────────────────────────────────────────────────────────────────

run_check() {
    # --check mode: read-only verification + drift report. Reuses op_verify
    # infrastructure (the per-check helpers + integrity baseline comparison)
    # to report what's installed vs. what should be, without modifying anything.
    # Exit code: 0 if everything aligned, 1 if drift detected.

    log_check "stage" "implement-stage (op_verify + integrity baseline)"
    log_check "DEST_CLAUDE" "${DEST_CLAUDE}"
    log_check "DEST_OPENCODE" "${DEST_OPENCODE}"
    log_check "PROFILE" "${PROFILE:-base}"
    log_check "MODE" "${MODE}${DETECTED_MODE:+ (detected=${DETECTED_MODE})}"

    # Compute SRC vs DEST drift for each safety-policy artefact (the same
    # files install_file() reconciles). Reports:
    #   - in-sync   : SHA256 matches between SRC and DEST
    #   - drifted   : DEST exists but content differs from SRC
    #   - missing   : DEST file absent
    local synced=0 drifted=0 missing=0
    local drift_paths=()

    _check_artefact() {
        # _check_artefact <relative-path-under-SRC> <DEST-path>
        local src_rel="$1"
        local dest_path="$2"
        local src_path="${SRC}/${src_rel}"
        if [[ ! -f "${src_path}" ]]; then
            return  # source absent → not our concern (e.g. optional artefact)
        fi
        if [[ ! -f "${dest_path}" ]]; then
            missing=$((missing + 1))
            drift_paths+=("MISSING: ${dest_path}")
            return
        fi
        local src_hash dest_hash
        src_hash=$(sha256sum "${src_path}" 2>/dev/null | awk '{print $1}')
        dest_hash=$(sha256sum "${dest_path}" 2>/dev/null | awk '{print $1}')
        if [[ "${src_hash}" == "${dest_hash}" ]]; then
            synced=$((synced + 1))
        else
            drifted=$((drifted + 1))
            drift_paths+=("DRIFTED: ${dest_path}")
        fi
    }

    # Hook scripts (always relevant)
    for fname in policy-block.sh malware-block.sh leak-detector.sh integrity.py \
                 deny-secret-files.sh post-compact.sh pre-compact.sh \
                 session-orient.sh session-start.sh session-summary.sh \
                 opt-write-block.sh; do
        _check_artefact ".claude/hooks/${fname}" "${DEST_CLAUDE}/hooks/${fname}"
    done

    # settings.json (CRITICAL — but a slight DEST-side delta is expected because
    # operator may have added project-specific allow rules). Report drift but
    # don't fail on it; operator decides if the drift is intentional.
    if [[ -f "${SRC}/.claude/settings.json" ]] && [[ -f "${DEST_CLAUDE}/settings.json" ]]; then
        local src_hash dest_hash
        src_hash=$(sha256sum "${SRC}/.claude/settings.json" 2>/dev/null | awk '{print $1}')
        dest_hash=$(sha256sum "${DEST_CLAUDE}/settings.json" 2>/dev/null | awk '{print $1}')
        if [[ "${src_hash}" == "${dest_hash}" ]]; then
            log_check "settings.json" "in-sync"
        else
            log_check "settings.json" "DRIFT (operator may have customized; not a failure)"
        fi
    fi

    log_check "hooks-in-sync" "${synced}"
    log_check "hooks-drifted" "${drifted}"
    log_check "hooks-missing" "${missing}"

    if [[ "${drifted}" -gt 0 ]] || [[ "${missing}" -gt 0 ]]; then
        log_warn "drift detected:"
        for p in "${drift_paths[@]}"; do
            log_warn "  - ${p}"
        done
    fi

    # Run op_verify in non-modifying mode for the structural checks
    log_info "running op_verify (read-only check)"
    if op_verify; then
        log_check "op_verify" "PASS"
    else
        log_check "op_verify" "FAIL"
        return 1
    fi

    # Integrity baseline drift check (only meaningful if --with-integrity ran)
    local sentinel="${DEST_CLAUDE}/integrity.json"
    if [[ -f "${sentinel}" ]]; then
        local age_seconds=$(( $(date +%s) - $(stat -c %Y "${sentinel}" 2>/dev/null || echo 0) ))
        local age_days=$((age_seconds / 86400))
        log_check "integrity sentinel age" "${age_days} days"
        if [[ "${age_days}" -gt 30 ]]; then
            log_warn "integrity baseline >30 days old; consider re-running --with-integrity"
        fi
    else
        log_check "integrity sentinel" "absent (not registered yet; run --with-integrity)"
    fi

    if [[ "${drifted}" -gt 0 ]] || [[ "${missing}" -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ────────────────────────────────────────────────────────────────────────
# Backup helper (used before overwrite of out-of-sync files)
# ────────────────────────────────────────────────────────────────────────

backup_if_exists() {
    local path="$1"
    if [[ -e "${path}" ]]; then
        local backup="${path}${BACKUP_SUFFIX}"
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "backup ${path} -> ${backup}"
        else
            cp -p "${path}" "${backup}"
            log_info "backed up ${path} -> ${backup}"
        fi
    fi
}

# install_file: idempotent file copy with backup-on-change.
# - If dst doesn't exist: copy src->dst with permissions
# - If dst exists and matches src: no-op (idempotent)
# - If dst exists and differs from src: backup then overwrite
install_file() {
    local src="$1"
    local dst="$2"
    local mode="${3:-0644}"
    if [[ ! -f "${src}" ]]; then
        log_warn "source missing: ${src} — skipping"
        return 0
    fi
    if [[ -e "${dst}" ]] && cmp -s "${src}" "${dst}" 2>/dev/null; then
        log_info "unchanged: ${dst}"
        return 0
    fi
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        if [[ -e "${dst}" ]]; then
            log_dry "backup + overwrite: ${dst} (changed from ${src})"
        else
            log_dry "install fresh: ${src} -> ${dst}"
        fi
        return 0
    fi
    backup_if_exists "${dst}"
    mkdir -p "$(dirname "${dst}")"
    cp "${src}" "${dst}"
    chmod "${mode}" "${dst}"
    log_info "installed: ${dst}"
}

# ────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"

    log_info "${SCRIPT_NAME} ${VERSION} starting (scaffold-stage stub)"

    if [[ "${CHECK_MODE}" -eq 1 ]]; then
        run_check
        exit 0
    fi

    detect_os_family
    detect_ghostproxy_mode
    apply_profile
    # apply_profile must run BEFORE require_dependencies so WITH_BRIDGE / WITH_WIFI
    # are set per profile + mode_includes filtering — require_dependencies adds
    # nft/ip/wpa_supplicant to the required set only when those ops are enabled.
    require_dependencies

    [[ "${WITH_HOOKS}"        == "1" ]] && op_install_endpoint_safety_policy || log_info "skip: endpoint safety policy (per profile/toggle)"
    [[ "${WITH_OPENCODE}"     == "1" ]] && op_install_opencode_bridge        || log_info "skip: opencode bridge (per profile/toggle)"
    [[ "${WITH_BRIDGE}"       == "1" ]] && op_install_network_bridge         || log_info "skip: network bridge (per profile/toggle)"
    [[ "${WITH_WIFI}"         == "1" ]] && op_install_management_wifi        || log_info "skip: management wifi (per profile/toggle)"
    [[ "${WITH_INTEGRITY}"    == "1" ]] && op_install_integrity_sentinel     || log_info "skip: integrity sentinel (per profile/toggle)"
    [[ "${WITH_CCSTATUSLINE}" == "1" ]] && op_install_ccstatusline           || log_info "skip: ccstatusline (per profile/toggle — Features tier)"
    op_verify

    log_info "${SCRIPT_NAME} done${DRY_RUN:+ (dry-run; no state changes)}"
    log_info "stage=scaffold; operations are STUBS — implement-stage required for real install"
}

main "$@"
