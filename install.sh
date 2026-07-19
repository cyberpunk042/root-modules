#!/usr/bin/env bash
# $HOME/install.sh — root-modules foundation installer (SCAFFOLD STAGE — T012).
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
# $HOME/install.sh debris was backed up to install.sh.prior-debris.bak.<ts> per
# T006 (leave-in-place: backup-not-delete) before this file was authored.
#
# CURRENT STAGE: implement (readiness 98). Foundation install ops fully
# implemented (settings + hooks + brain pieces + opencode + bridge config +
# wifi + integrity + ccstatusline + tools deploy + per-project profile
# + wizard + granular group/item flags). shellcheck PASS. Pending: bridge
# FORWARD/OUTPUT nftables rules (T013 operator-decision); idempotency test
# (T016); P4 wizard interactive picker.

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────
# Globals + defaults
# ────────────────────────────────────────────────────────────────────────

# shellcheck disable=SC2155  # readonly+command-sub: basename/dirname always succeed; mask risk = nil
readonly SCRIPT_NAME="$(basename "$0")"
# shellcheck disable=SC2155
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="0.0.3-implement-partial"

# Source of policy files = the directory containing install.sh (i.e., a
# checkout of the root-modules repo). Destination defaults to $HOME.
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
WIZARD_MODE=0   # --wizard: state-aware frame + suggested-next-actions report (no install action)
# shellcheck disable=SC2034  # VERBOSE: documented in --help; logging hooks pending wire-up
VERBOSE=0
# shellcheck disable=SC2034  # ASSUME_YES: documented in --help; --interactive prompt wire-up pending
ASSUME_YES=0

# Profile + per-operation toggles (default: profile=base unless overridden)
PROFILE=""
WITH_HOOKS=""        # "" = profile decides; "1" = on; "0" = off
WITH_OPENCODE=""
WITH_BRIDGE=""
WITH_WIFI=""
WITH_INTEGRITY=""
WITH_CCSTATUSLINE="" # M011 ccstatusline integration (npm-based)
WITH_TOOLS=""        # /tools/*.py — autopilot Python modules (tools.cycle, tools.stamp, etc.)

# Granular install — group selection (P5 of wizard design).
# Format: comma-separated group names. Empty = profile-default selection.
# See GROUP_DEFINITIONS in granular_select_groups() for the 16 groups.
WITH_GROUPS=""       # comma-sep: --with-group security,stamp → "security,stamp"
NO_GROUPS=""         # comma-sep: --no-group commands-mode → "commands-mode"

# Granular install — item-level inclusion/exclusion (P6 of wizard design).
# Comma-separated lists of file basenames (without extension for hooks: e.g.
# `policy-block` or `policy-block.sh` both accepted; for commands/rules/agents/
# modes: stem of *.md). Item-level filters compose with profile + groups:
# whitelist = "only these"; blacklist = "these excluded" (blacklist wins on conflict).
WITH_HOOKS_LIST=""    # --with-hook policy-block --with-hook malware-block → "policy-block,malware-block"
NO_HOOKS_LIST=""      # --no-hook opt-write-block → "opt-write-block"
WITH_COMMANDS_LIST="" # --with-command orient
NO_COMMANDS_LIST=""
WITH_RULES_LIST=""
NO_RULES_LIST=""
WITH_AGENTS_LIST=""
NO_AGENTS_LIST=""
WITH_MODES_LIST=""
NO_MODES_LIST=""
WITH_SKILLS_LIST=""
NO_SKILLS_LIST=""
WITH_TOOLS_LIST=""
NO_TOOLS_LIST=""

# Detected OS family (set by detect_os_family)
OS_ID=""
OS_VERSION_ID=""
OS_FAMILY=""       # "debian" | "rhel" | "arch" | "unknown"

# Ghostproxy runtime mode (separate from install profile per SB-074)
# Values: bridge | endpoint | hybrid | auto (default = auto)
MODE="auto"
DETECTED_MODE=""   # set by detect_ghostproxy_mode

# Backup timestamp (UTC, ISO 8601-ish, safe-for-filename)
# shellcheck disable=SC2155  # readonly+command-sub: date always succeeds
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
${SCRIPT_NAME} ${VERSION} — root-modules foundation installer (greenfield, implement-stage)

USAGE:
    ${SCRIPT_NAME} [FLAGS]

FLAGS:
    --dry-run                 Preview operations; no state changes.
    --check                   Verify installed state matches expected. Exit non-zero on drift.
    --wizard                  State-aware "where you are" + "what to do next" report (read-only; no install action). Detects route (curl-bootstrap / post-clone / partial / drift / maintenance) and surfaces prioritized next-best-actions.
    --dest <path>             Install to alternate prefix (default: \$HOME).
    --profile <name>          Install profile: base | full | project | interactive (default: base)
    --mode <name>             Ghostproxy runtime mode: bridge | endpoint | hybrid | auto (default: auto)
    --with-hooks / --no-hooks       Include/exclude agent brain (settings + hooks + rules + commands + agents + modes + skills)
    --with-opencode / --no-opencode Include/exclude opencode bridge plugin
    --with-bridge / --no-bridge     Include/exclude network bridge config
    --with-wifi / --no-wifi         Include/exclude management wifi (outbound-only)
    --with-integrity / --no-integrity Include/exclude integrity sentinel + baselines
    --with-ccstatusline / --no-ccstatusline Include/exclude ccstatusline (Features tier)
    --with-tools / --no-tools       Include/exclude /tools/*.py Python autopilot modules
    --with-group <name>             Granular: enable a group (security / session-lifecycle / agent-discipline / stamp / bridge / opencode / wifi / integrity / ccstatusline / tools-{core,cycle,stamp,objective,all}). Repeatable.
    --no-group <name>               Granular: disable a group. Repeatable.
    --with-hook <name>              Granular item-level: whitelist a specific hook by name (basename or stem). Sets whitelist mode — only listed hooks deploy. Repeatable.
    --no-hook <name>                Granular item-level: blacklist a specific hook (always wins over whitelist). Repeatable.
    --with-command <name>           Whitelist a specific command (.md file stem). Repeatable.
    --no-command <name>             Blacklist a specific command. Repeatable.
    --with-rule <name>              Whitelist a specific rule. Repeatable.
    --no-rule <name>                Blacklist a specific rule. Repeatable.
    --with-agent <name>             Whitelist a specific subagent. Repeatable.
    --no-agent <name>               Blacklist a specific subagent. Repeatable.
    --with-mode <name>              Whitelist a specific mode. Repeatable.
    --no-mode <name>                Blacklist a specific mode. Repeatable.
    --with-skill <name>             Whitelist a specific skill (directory name). Repeatable.
    --no-skill <name>               Blacklist a specific skill. Repeatable.
    --with-tool <name>              Whitelist a specific tool (.py file stem). Repeatable.
    --no-tool <name>                Blacklist a specific tool. Repeatable.
    --verbose                 Verbose logging.
    --yes, -y                 Assume yes for any prompts.
    --help, -h                Show this help.
    --version                 Print version + exit.

PROFILES:
    base         Foundation only (hooks + bridge + wifi + integrity); no Features.
    full         Base + ALL facultative modules (ccstatusline, future Suricata/PolarProxy).
    project      Per-project deploy: agent brain + tools to a sister project.
                   Disables OS-level ops (bridge/wifi/integrity/ccstatusline/opencode).
                   Use with --dest <project-path>. Slash command equivalent:
                   /install-agent-brain <project-path>
    interactive  TUI prompts per-operation (STUB; falls through to base).

OPERATIONS (executed in sequence on real install):
    1. Endpoint AI agent brain (settings + hooks + rules + commands + agents + modes + skills)
    1b. /tools/*.py Python autopilot modules
    2. Opencode bridge plugin (~/.config/opencode/)
    3. Network bridge topology + nftables rules (bridge mode only)
    4. Management wifi config + outbound-only nftables (bridge/hybrid mode only)
    5. Integrity sentinel registration (SHA256 baselines)
    6. ccstatusline (Features tier; npm-based; full profile only)
    7. Post-install verification (op_verify — runs same checks as --check)

EXAMPLES:
    # Wizard: state-aware "where you are + what to do next" report
    ${SCRIPT_NAME} --wizard                     # safe to run from any state (curl-bootstrap / clone / partial / maintenance)

    # OS-root install (this dev host, default)
    ${SCRIPT_NAME} --dry-run --profile base
    ${SCRIPT_NAME} --profile full --with-ccstatusline

    # Project install (deploy agent brain into a sister project)
    ${SCRIPT_NAME} --profile project --dest /opt/devops-solutions-information-hub --dry-run
    ${SCRIPT_NAME} --profile project --dest /home/jfortin/openarms

    # Endpoint-only host (no bridge config; just safety + opencode)
    ${SCRIPT_NAME} --profile base --mode endpoint

    # Granular group-level (composes with --profile)
    ${SCRIPT_NAME} --profile base --no-group wifi --no-group integrity   # base minus 2 groups
    ${SCRIPT_NAME} --profile base --with-group ccstatusline              # add a Features group

    # Granular item-level (whitelist + blacklist; blacklist wins)
    ${SCRIPT_NAME} --profile project --dest /opt/proj \\
        --no-hook opt-write-block                            # exclude one hook
    ${SCRIPT_NAME} --profile project --dest /opt/proj \\
        --with-command orient --with-command handoff         # whitelist: only those commands

    # Drift check after install
    ${SCRIPT_NAME} --check

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
    - Pending implement-stage gaps: bridge FORWARD/OUTPUT nftables rules
      (operator-decision: default-accept vs default-drop FORWARD policy per
      T013 threat model); shellcheck pass; idempotency invariant test (T016).

REFERENCES:
    - Foundation hardening module: wiki/backlog/modules/root-modules-m003-*.md
    - Methodology stage gates:     wiki/config/methodology.yaml
    - Brain files:                 README.md, CLAUDE.md, AGENTS.md, ARCHITECTURE.md
EOF
}

# ────────────────────────────────────────────────────────────────────────
# Argument parsing
# ────────────────────────────────────────────────────────────────────────

parse_args() {
    # shellcheck disable=SC2034  # VERBOSE + ASSUME_YES wire-up pending; documented in --help
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)         DRY_RUN=1; shift ;;
            --check)           CHECK_MODE=1; shift ;;
            --wizard)          WIZARD_MODE=1; shift ;;
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
            --with-tools)        WITH_TOOLS=1; shift ;;
            --no-tools)          WITH_TOOLS=0; shift ;;
            --with-group)        WITH_GROUPS="${WITH_GROUPS:+${WITH_GROUPS},}$2"; shift 2 ;;
            --no-group)          NO_GROUPS="${NO_GROUPS:+${NO_GROUPS},}$2"; shift 2 ;;
            --with-hook)         WITH_HOOKS_LIST="${WITH_HOOKS_LIST:+${WITH_HOOKS_LIST},}$2"; shift 2 ;;
            --no-hook)           NO_HOOKS_LIST="${NO_HOOKS_LIST:+${NO_HOOKS_LIST},}$2"; shift 2 ;;
            --with-command)      WITH_COMMANDS_LIST="${WITH_COMMANDS_LIST:+${WITH_COMMANDS_LIST},}$2"; shift 2 ;;
            --no-command)        NO_COMMANDS_LIST="${NO_COMMANDS_LIST:+${NO_COMMANDS_LIST},}$2"; shift 2 ;;
            --with-rule)         WITH_RULES_LIST="${WITH_RULES_LIST:+${WITH_RULES_LIST},}$2"; shift 2 ;;
            --no-rule)           NO_RULES_LIST="${NO_RULES_LIST:+${NO_RULES_LIST},}$2"; shift 2 ;;
            --with-agent)        WITH_AGENTS_LIST="${WITH_AGENTS_LIST:+${WITH_AGENTS_LIST},}$2"; shift 2 ;;
            --no-agent)          NO_AGENTS_LIST="${NO_AGENTS_LIST:+${NO_AGENTS_LIST},}$2"; shift 2 ;;
            --with-mode)         WITH_MODES_LIST="${WITH_MODES_LIST:+${WITH_MODES_LIST},}$2"; shift 2 ;;
            --no-mode)           NO_MODES_LIST="${NO_MODES_LIST:+${NO_MODES_LIST},}$2"; shift 2 ;;
            --with-skill)        WITH_SKILLS_LIST="${WITH_SKILLS_LIST:+${WITH_SKILLS_LIST},}$2"; shift 2 ;;
            --no-skill)          NO_SKILLS_LIST="${NO_SKILLS_LIST:+${NO_SKILLS_LIST},}$2"; shift 2 ;;
            --with-tool)         WITH_TOOLS_LIST="${WITH_TOOLS_LIST:+${WITH_TOOLS_LIST},}$2"; shift 2 ;;
            --no-tool)           NO_TOOLS_LIST="${NO_TOOLS_LIST:+${NO_TOOLS_LIST},}$2"; shift 2 ;;
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
            d_ccstatusline=0; d_tools=1
            ;;
        full)
            # Base + ALL facultative modules including Features (ccstatusline, future Suricata/PolarProxy).
            # Per operator: "if I do a full install they would all be installed."
            d_hooks=1; d_opencode=1; d_bridge=1; d_wifi=1; d_integrity=1
            d_ccstatusline=1; d_tools=1
            ;;
        project)
            # Per-project install — operator opts in to deploy the agent brain
            # (settings + hooks + rules + commands + agents + modes + skills +
            # tools) INTO a sister project, NOT at OS-root level. Disables
            # OS-level ops (bridge/wifi/integrity/ccstatusline/opencode-bridge)
            # since those are scope=root-only. Per operator directive 2026-05-06:
            # "this should also probably be part of the things we can chose to
            # install into project and not only the root... not necessarily a
            # by default since hooks are bit more intrusive". Explicit opt-in
            # via `--profile project --dest <project-path>`.
            d_hooks=1; d_opencode=0; d_bridge=0; d_wifi=0; d_integrity=0
            d_ccstatusline=0; d_tools=1
            ;;
        interactive)
            log_warn "STUB: interactive profile prompts not implemented (scaffold stage); falling through to base defaults"
            d_hooks=1; d_opencode=1; d_bridge=1; d_wifi=1; d_integrity=1
            d_ccstatusline=0; d_tools=1
            ;;
        *)
            log_error "unknown profile: ${p}. Valid: base / full / project / interactive"; exit 2
            ;;
    esac
    # Apply profile defaults only where per-op flag wasn't set
    : "${WITH_HOOKS:=${d_hooks}}"
    : "${WITH_OPENCODE:=${d_opencode}}"
    : "${WITH_BRIDGE:=${d_bridge}}"
    : "${WITH_WIFI:=${d_wifi}}"
    : "${WITH_INTEGRITY:=${d_integrity}}"
    : "${WITH_CCSTATUSLINE:=${d_ccstatusline}}"
    : "${WITH_TOOLS:=${d_tools}}"
    # Filter via mode_includes — profile-on AND mode-applicable
    mode_includes bridge || WITH_BRIDGE=0
    mode_includes wifi   || WITH_WIFI=0
    log_info "profile=${p} mode=${MODE} → hooks=${WITH_HOOKS} opencode=${WITH_OPENCODE} bridge=${WITH_BRIDGE} wifi=${WITH_WIFI} integrity=${WITH_INTEGRITY} ccstatusline=${WITH_CCSTATUSLINE} tools=${WITH_TOOLS}"
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

# Operation 1: Endpoint AI agent policy (settings + hooks + brain pieces)
#
# Deploys the full agent-config envelope:
#   - settings.json: Claude Code permissions + hook wiring
#   - hooks/*.sh|*.py: Claude Code hook scripts (security envelope)
#   - rules/*.md: on-demand topic rules (loaded when work touches the topic)
#   - commands/*.md: operator-invoked slash commands (/orient, /handoff, etc.)
#   - agents/*.md: brain-loaded subagent definitions (per SB-081)
#   - modes/*.md: persona modes (PM Scrum Master, DevOps Architect, Dual)
#   - skills/<name>/SKILL.md: auto-trigger skills (description-match)
#
# Path A note (where SRC == DEST_HOME, e.g., $HOME=$HOME install on this dev
# host): install_file() detects identical content + skips silently. So this
# op is a no-op on Path A; for non-Path-A installs ($HOME != $HOME, e.g.,
# /home/jfortin/), this is the canonical deployment.
#
# Coverage gap fix 2026-05-06 per operator question on install-readiness for
# fresh machines: prior implementation deployed ONLY settings.json + hooks/,
# leaving commands/agents/modes/skills/rules undeployed → fresh install would
# have safety hooks but no /orient, no /handoff, no /mode-*, no surface-state.
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

    # Hooks — apply P6 item-level filter (--with-hook / --no-hook).
    local f
    for f in "${src_hooks_dir}"/*.sh "${src_hooks_dir}"/*.py; do
        [[ -e "${f}" ]] || continue
        local basename
        basename="$(basename "${f}")"
        if ! should_install_item "${basename}" "${WITH_HOOKS_LIST}" "${NO_HOOKS_LIST}"; then
            log_info "skip hook (item-filter): ${basename}"
            continue
        fi
        local mode=0644
        [[ "${basename}" =~ \.sh$ ]] && mode=0755
        install_file "${f}" "${tgt_hooks_dir}/${basename}" "${mode}"
    done

    # Brain pieces — flat *.md per dir (rules, commands, agents, modes).
    # Each dir uses its own item-level WITH/NO list per P6.
    local subdir basename
    for subdir in rules commands agents modes; do
        local src_subdir="${SRC}/.claude/${subdir}"
        local tgt_subdir="${DEST_CLAUDE}/${subdir}"
        [[ -d "${src_subdir}" ]] || continue
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "ensure ${tgt_subdir} exists + install ${subdir}/*.md"
        else
            mkdir -p "${tgt_subdir}"
        fi
        # Pick the right WITH/NO list per subdir
        local _with _no
        case "${subdir}" in
            rules)    _with="${WITH_RULES_LIST}";    _no="${NO_RULES_LIST}" ;;
            commands) _with="${WITH_COMMANDS_LIST}"; _no="${NO_COMMANDS_LIST}" ;;
            agents)   _with="${WITH_AGENTS_LIST}";   _no="${NO_AGENTS_LIST}" ;;
            modes)    _with="${WITH_MODES_LIST}";    _no="${NO_MODES_LIST}" ;;
        esac
        for f in "${src_subdir}"/*.md; do
            [[ -e "${f}" ]] || continue
            basename="$(basename "${f}")"
            if ! should_install_item "${basename}" "${_with}" "${_no}"; then
                log_info "skip ${subdir%s} (item-filter): ${basename}"
                continue
            fi
            install_file "${f}" "${tgt_subdir}/${basename}" 0644
        done
    done

    # Skills — nested: each skill is a subdir containing SKILL.md (+ optional
    # supporting markdown). Per Claude Code skills convention.
    # P6 filter applies per-skill (skill name = directory basename).
    local src_skills="${SRC}/.claude/skills"
    local tgt_skills="${DEST_CLAUDE}/skills"
    if [[ -d "${src_skills}" ]]; then
        if [[ "${DRY_RUN}" -eq 1 ]]; then
            log_dry "ensure ${tgt_skills} exists + install per-skill SKILL.md"
        else
            mkdir -p "${tgt_skills}"
        fi
        local skill_dir skill_name
        for skill_dir in "${src_skills}"/*/; do
            [[ -d "${skill_dir}" ]] || continue
            skill_name="$(basename "${skill_dir}")"
            if ! should_install_item "${skill_name}" "${WITH_SKILLS_LIST}" "${NO_SKILLS_LIST}"; then
                log_info "skip skill (item-filter): ${skill_name}"
                continue
            fi
            if [[ "${DRY_RUN}" -eq 1 ]]; then
                log_dry "ensure ${tgt_skills}/${skill_name}/ exists"
            else
                mkdir -p "${tgt_skills}/${skill_name}"
            fi
            for f in "${skill_dir}"*.md; do
                [[ -e "${f}" ]] || continue
                basename="$(basename "${f}")"
                install_file "${f}" "${tgt_skills}/${skill_name}/${basename}" 0644
            done
        done
    fi
}

# Operation 1b: /tools/ Python modules (autopilot infrastructure)
#
# Deploys /tools/*.py to ${DEST_HOME}/tools/. Slash commands (/cycle, /stamp-*,
# /handoff, /audit, etc.) invoke `python3 -m tools.<module>`, so the modules
# must be importable from the project's working directory. For Path A install
# (SRC == DEST_HOME, e.g., $HOME install on this dev host), this op is a no-op
# because tools/ is already in place. For non-Path-A or project-profile
# installs, this op deploys tools/ alongside the agent brain so slash commands
# work out-of-the-box.
#
# Includes both top-level *.py and the package marker __init__.py.
op_install_tools() {
    local src_tools="${SRC}/tools"
    local tgt_tools="${DEST_HOME}/tools"

    if [[ ! -d "${src_tools}" ]]; then
        log_warn "source ${src_tools} not found — skipping tools deploy"
        return 0
    fi

    # Path A short-circuit: src == dest, nothing to copy.
    if [[ "${src_tools}" == "${tgt_tools}" ]]; then
        log_info "tools/ already in place (Path A, SRC==DEST); no-op"
        return 0
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "ensure ${tgt_tools} exists + install tools/*.py"
    else
        mkdir -p "${tgt_tools}"
    fi

    # Apply P6 item-level filter (--with-tool / --no-tool).
    local f basename
    for f in "${src_tools}"/*.py; do
        [[ -e "${f}" ]] || continue
        basename="$(basename "${f}")"
        if ! should_install_item "${basename}" "${WITH_TOOLS_LIST}" "${NO_TOOLS_LIST}"; then
            log_info "skip tool (item-filter): ${basename}"
            continue
        fi
        install_file "${f}" "${tgt_tools}/${basename}" 0644
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
# Helper: ensure /etc/nftables.conf includes /etc/nftables.d/*.nft so any
# files deployed there (wifi rules + future bridge rules) actually load.
# Idempotent: detects existing include directive (multiple syntaxes), no-op
# if present. If /etc/nftables.conf doesn't exist, creates a minimal sane
# default with `flush ruleset` + the include directive. If exists without
# include, BACKS UP the operator's file (per backup_if_exists) then appends
# the include line at end with a clear comment marker.
#
# Bug-B fix 2026-05-06 per operator install-readiness audit: prior install.sh
# only WARNED if include missing; deployed wifi rules were dead-letter on
# fresh Debian (default /etc/nftables.conf has no include directive).
ensure_nftables_d_include() {
    local conf="/etc/nftables.conf"
    local include_pattern='^[[:space:]]*include[[:space:]]+"?/etc/nftables\.d'

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        if [[ -r "${conf}" ]] && grep -qE "${include_pattern}" "${conf}" 2>/dev/null; then
            log_dry "${conf} already includes /etc/nftables.d/* (no change)"
        elif [[ -r "${conf}" ]]; then
            log_dry "${conf} exists without /etc/nftables.d/* include; would back up + append include line"
        else
            log_dry "${conf} missing; would create with sane default + include /etc/nftables.d/*.nft"
        fi
        return 0
    fi

    if [[ -r "${conf}" ]] && grep -qE "${include_pattern}" "${conf}" 2>/dev/null; then
        log_info "${conf} already includes /etc/nftables.d/* (unchanged)"
        return 0
    fi

    if [[ ! -r "${conf}" ]]; then
        # Create a minimal sane default. Empty `flush ruleset` + include dir.
        # Operator can extend later; we don't impose policy here, only the
        # mechanism to load /etc/nftables.d/*.nft files we deploy.
        cat > "${conf}" <<'EOF'
#!/usr/sbin/nft -f
# Provisioned by $HOME/install.sh on first install — extend as operator wishes.
flush ruleset

# Load all rulesets from /etc/nftables.d/*.nft (canonical Debian convention).
# Files there are deployed by ghostproxy ops (e.g., management-wifi rules).
include "/etc/nftables.d/*.nft"
EOF
        chmod 0644 "${conf}"
        log_info "provisioned ${conf} (minimal default + /etc/nftables.d/* include)"
        return 0
    fi

    # File exists, no include directive — back up + append.
    backup_if_exists "${conf}"
    {
        printf '\n# --- ghostproxy install.sh added %s ---\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf '# Loads /etc/nftables.d/*.nft (canonical multi-file convention).\n'
        printf 'include "/etc/nftables.d/*.nft"\n'
    } >> "${conf}"
    log_info "appended /etc/nftables.d/*.nft include to ${conf} (backup at ${conf}${BACKUP_SUFFIX})"
}

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

    # 4. Ensure /etc/nftables.conf actually loads /etc/nftables.d/*.nft —
    # without this include directive the deployed file is dead-letter.
    # Idempotent: helper detects existing include + no-ops, OR creates the
    # file with sane default, OR appends the include line (backup-first).
    ensure_nftables_d_include

    # 5. Reload nftables service so the new ruleset takes effect.
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "systemctl reload nftables (apply new /etc/nftables.d/* rulesets)"
    elif command -v systemctl >/dev/null 2>&1; then
        systemctl reload nftables 2>&1 || log_warn "systemctl reload nftables failed (may need: nft -f /etc/nftables.conf)"
    else
        log_warn "systemctl not present; operator must reload nftables manually:"
        log_warn "  nft -f /etc/nftables.conf"
    fi

    # 6. Enable systemd template unit `wpa_supplicant@mgmt0.service`. The
    # wpasupplicant package provides this unit; we just enable + start it so
    # the wifi association comes up at boot and after install. Idempotent:
    # systemctl enable returns success if already enabled.
    #
    # Skip the start if the operator hasn't filled the SSID/PSK placeholders
    # yet — starting wpa_supplicant against a placeholder config produces
    # an authentication-loop noise in the journal. Only enable (boot-up) +
    # leave start as a manual step until placeholders are filled.
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_dry "systemctl enable wpa_supplicant@mgmt0.service (boot-up start)"
        log_dry "if SSID/PSK filled in: systemctl start wpa_supplicant@mgmt0.service"
    elif command -v systemctl >/dev/null 2>&1; then
        # Confirm the template unit is available (provided by wpasupplicant pkg)
        if systemctl cat wpa_supplicant@.service >/dev/null 2>&1; then
            systemctl enable wpa_supplicant@mgmt0.service 2>&1 || \
                log_warn "systemctl enable wpa_supplicant@mgmt0.service failed"

            # Auto-start only if placeholders have been filled in. Otherwise
            # leave start as a manual operator step (avoids auth-failure log spam).
            if grep -q "__OPERATOR_SSID__\|__OPERATOR_PSK_OR_HEX__\|__COUNTRY_CODE__" "${tgt_wpa}" 2>/dev/null; then
                log_warn "wpa_supplicant@mgmt0.service ENABLED (boot-up); NOT started yet"
                log_warn "  fill placeholders in ${tgt_wpa} first, then:"
                log_warn "  systemctl start wpa_supplicant@mgmt0.service"
            else
                systemctl start wpa_supplicant@mgmt0.service 2>&1 || \
                    log_warn "systemctl start wpa_supplicant@mgmt0.service failed (check journalctl)"
                log_info "wpa_supplicant@mgmt0.service enabled + started"
            fi
        else
            log_warn "wpa_supplicant@.service template unit NOT FOUND — wpasupplicant package may not be installed"
            log_warn "  install: apt-get install wpasupplicant (or distro equivalent)"
        fi
    else
        log_warn "systemctl not present; operator must enable + start wpa_supplicant manually"
    fi

    log_info "management wifi config deployed (template at ${tgt_wpa}; nftables at ${tgt_nft})"
    log_info "  interface naming: if your wifi adapter is not 'mgmt0' (default for Predictable Naming),"
    log_info "  add /etc/systemd/network/10-mgmt0.link to rename it (operator-host-specific)"
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
    trap 'rm -f "${tmp:-}"' RETURN

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

    # If --with-wifi: verify wpa_supplicant config deployed + nftables rules
    # loaded. Service-status check is conditional on placeholders being filled
    # (we don't fail the install if operator hasn't filled SSID/PSK yet —
    # that's documented as a manual step).
    if [[ "${WITH_WIFI:-0}" == "1" ]]; then
        local wpa_conf="/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf"
        local nft_file="/etc/nftables.d/management-wifi-outbound-only.nft"

        if [[ -r "${wpa_conf}" ]]; then
            _verify_check "wpa_supplicant-mgmt0.conf deployed" true
        else
            checks=$((checks + 1))
            failed=$((failed + 1))
            fail_reasons+=("wpa_supplicant config missing at ${wpa_conf}")
            log_check "wpa_supplicant-mgmt0.conf" "FAIL: missing"
        fi

        if [[ -r "${nft_file}" ]]; then
            _verify_check "wifi nftables ruleset deployed" true
        else
            checks=$((checks + 1))
            failed=$((failed + 1))
            fail_reasons+=("wifi nftables ruleset missing at ${nft_file}")
            log_check "wifi nftables" "FAIL: missing"
        fi

        # Verify the ruleset is actually LOADED in the kernel (not just on disk).
        if command -v nft >/dev/null 2>&1; then
            if nft list ruleset 2>/dev/null | grep -q "table inet ghp_mgmt_wifi"; then
                _verify_check "wifi ghp_mgmt_wifi table loaded" true
            else
                checks=$((checks + 1))
                failed=$((failed + 1))
                fail_reasons+=("wifi ruleset deployed but ghp_mgmt_wifi table not in kernel ruleset")
                log_check "ghp_mgmt_wifi table" "FAIL: not loaded — check /etc/nftables.conf includes /etc/nftables.d/*"
            fi
        fi

        # Service status — only check if placeholders filled (operator-config
        # done). Otherwise SKIP — that's the documented manual-step state.
        if [[ -r "${wpa_conf}" ]] && ! grep -q "__OPERATOR_SSID__\|__OPERATOR_PSK_OR_HEX__" "${wpa_conf}" 2>/dev/null; then
            if command -v systemctl >/dev/null 2>&1; then
                if systemctl is-enabled wpa_supplicant@mgmt0.service >/dev/null 2>&1; then
                    _verify_check "wpa_supplicant@mgmt0 enabled" true
                else
                    checks=$((checks + 1))
                    failed=$((failed + 1))
                    fail_reasons+=("wpa_supplicant@mgmt0.service not enabled")
                    log_check "wpa_supplicant@mgmt0 enabled" "FAIL"
                fi
            fi
        else
            log_check "wpa_supplicant service" "SKIP (placeholders not yet filled by operator)"
        fi
    fi

    # Git audit sub-step (T015 Done When) — only meaningful at SRC (the repo
    # root); when DEST != SRC, target is a deployed brain and `git status`
    # there is unrelated to the spec repo. Skip silently if no .git/ at SRC.
    if [[ -d "${SRC}/.git" ]]; then
        if command -v git >/dev/null 2>&1; then
            local git_changes
            git_changes=$(cd "${SRC}" && git status --porcelain 2>/dev/null | wc -l)
            if [[ "${git_changes}" -eq 0 ]]; then
                _verify_check "git tree clean (${SRC})" true
            else
                # Modified-or-untracked files — not a hard fail (active work)
                # but surface so operator knows verification flag is showing
                # the active dev state, not a violation.
                log_check "git tree" "INFO: ${git_changes} modified/untracked files in ${SRC} (active work)"
            fi
        fi
    fi

    # Brain pieces (rules/commands/agents/modes/skills) — verify presence.
    # These are deployed by op_install_endpoint_safety_policy; absence here
    # would mean install partial-failed even if hooks landed.
    if [[ "${WITH_HOOKS:-0}" == "1" ]]; then
        local brain_dir count
        for brain_dir in rules commands agents modes; do
            local tgt="${DEST_CLAUDE}/${brain_dir}"
            count=$(find "${tgt}" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
            if [[ "${count}" -gt 0 ]]; then
                _verify_check "${brain_dir}/ deployed (${count} files)" true
            else
                # Treat empty rules/commands/agents/modes as a soft warning, not
                # a hard fail — fresh install with no operator brain pieces is
                # technically valid (security envelope still works).
                log_check "${brain_dir}/" "WARN: empty (operator may not have authored any yet)"
            fi
        done

        # skills/ — count subdirs containing SKILL.md
        local skill_count
        skill_count=$(find "${DEST_CLAUDE}/skills" -maxdepth 2 -name "SKILL.md" -type f 2>/dev/null | wc -l)
        if [[ "${skill_count}" -gt 0 ]]; then
            _verify_check "skills/ deployed (${skill_count} skills)" true
        else
            log_check "skills/" "WARN: empty (no SKILL.md found)"
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
    # Renamed from {synced,drifted,missing} to avoid shellcheck SC2178 false-
    # positive (the dep-check function `require_dependencies` uses `missing` as
    # an array; same name in different scope still triggers the warning).
    local synced_count=0 drifted_count=0 missing_count=0
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
            missing_count=$((missing_count + 1))
            drift_paths+=("MISSING: ${dest_path}")
            return
        fi
        local src_hash dest_hash
        src_hash=$(sha256sum "${src_path}" 2>/dev/null | awk '{print $1}')
        dest_hash=$(sha256sum "${dest_path}" 2>/dev/null | awk '{print $1}')
        if [[ "${src_hash}" == "${dest_hash}" ]]; then
            synced_count=$((synced_count + 1))
        else
            drifted_count=$((drifted_count + 1))
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

    log_check "hooks-in-sync" "${synced_count}"
    log_check "hooks-drifted" "${drifted_count}"
    log_check "hooks-missing" "${missing_count}"

    if [[ "${drifted_count}" -gt 0 ]] || [[ "${missing_count}" -gt 0 ]]; then
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

    if [[ "${drifted_count}" -gt 0 ]] || [[ "${missing_count}" -gt 0 ]]; then
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
# Granular install — group definitions + selector (P5 of wizard design).
# Per /wiki/log/2026-05-06-install-wizard-granular-state-aware-design.md.
# Composes with profile-level toggles: profile sets baseline; --with-group /
# --no-group narrows; --with-X / --no-X further override individual items.
# ────────────────────────────────────────────────────────────────────────

# Group → toggle expansions. When a group is selected via --with-group <name>,
# the listed WITH_* toggles are forced to 1; when unselected via --no-group,
# forced to 0. Item-level flags (--with-bridge / --no-wifi / etc.) compose
# AFTER group expansion (item-level wins). Hooks/commands/rules/agents/modes/
# skills/tools are deployed by op_install_endpoint_safety_policy + op_install_tools
# whenever WITH_HOOKS=1; the `brain-*` and `commands-*` and `tools-*` group
# names below are documentation pointers for future fine-grained P6 (item-level
# per-file selection inside the brain dirs — pending).
group_apply() {
    # group_apply <group_name> <on_off>  (on_off = 1 to enable, 0 to disable)
    local g="$1" v="$2"
    case "${g}" in
        # Hook groups (force WITH_HOOKS on, since hooks are atomic in current op)
        security|session-lifecycle|agent-discipline|stamp)
            [[ "${v}" == "1" ]] && WITH_HOOKS=1 ;;  # group enables hook deploy
        # Brain-piece groups (commands/rules/agents/modes/skills) — currently
        # all-or-nothing per op_install_endpoint_safety_policy. P6 will split.
        brain-rules-core|brain-rules-all|commands-core|commands-mode|commands-stamp|commands-objective|commands-all)
            [[ "${v}" == "1" ]] && WITH_HOOKS=1 ;;  # brain pieces co-deploy with hooks
        # Tool groups
        tools-core|tools-cycle|tools-stamp|tools-objective|tools-all)
            WITH_TOOLS="${v}" ;;
        # OS-level op groups (1:1 with toggles)
        bridge|opencode|wifi|integrity|ccstatusline)
            case "${g}" in
                bridge)        WITH_BRIDGE="${v}" ;;
                opencode)      WITH_OPENCODE="${v}" ;;
                wifi)          WITH_WIFI="${v}" ;;
                integrity)     WITH_INTEGRITY="${v}" ;;
                ccstatusline)  WITH_CCSTATUSLINE="${v}" ;;
            esac ;;
        *)
            log_warn "unknown group: ${g} — valid: security session-lifecycle agent-discipline stamp brain-rules-{core,all} commands-{core,mode,stamp,objective,all} tools-{core,cycle,stamp,objective,all} bridge opencode wifi integrity ccstatusline"
            return 1 ;;
    esac
    return 0
}

# Item-level filter helper. Returns 0 (install) or 1 (skip) for a given
# basename + categorized include/exclude lists. Logic:
#   - If a NO_*_LIST entry matches → skip (blacklist wins).
#   - Else if WITH_*_LIST is non-empty AND no entry matches → skip (whitelist mode).
#   - Else → install.
#
# Stem-tolerant matching: accepts both "policy-block" and "policy-block.sh"
# (or "orient" / "orient.md") — strips the extension before comparing.
should_install_item() {
    # should_install_item <basename> <with_list> <no_list>
    local item="$1"
    local with="$2"
    local no="$3"

    # Strip common extensions for tolerant matching
    local item_stem="${item%.sh}"
    item_stem="${item_stem%.py}"
    item_stem="${item_stem%.md}"

    # Blacklist wins
    if [[ -n "${no}" ]]; then
        IFS=',' read -ra _arr <<<"${no}"
        for x in "${_arr[@]}"; do
            local x_stem="${x%.sh}"; x_stem="${x_stem%.py}"; x_stem="${x_stem%.md}"
            [[ "${x_stem}" == "${item_stem}" ]] && return 1
        done
    fi

    # Whitelist mode (only when WITH list is non-empty)
    if [[ -n "${with}" ]]; then
        IFS=',' read -ra _arr <<<"${with}"
        for x in "${_arr[@]}"; do
            local x_stem="${x%.sh}"; x_stem="${x_stem%.py}"; x_stem="${x_stem%.md}"
            [[ "${x_stem}" == "${item_stem}" ]] && return 0
        done
        return 1  # whitelist set + no match → skip
    fi

    return 0  # default: install
}

# Apply --with-group / --no-group selections after apply_profile (so groups
# override profile defaults; per-op flags then override groups).
apply_groups() {
    local g
    if [[ -n "${WITH_GROUPS}" ]]; then
        IFS=',' read -ra _arr <<<"${WITH_GROUPS}"
        for g in "${_arr[@]}"; do
            [[ -z "${g}" ]] && continue
            group_apply "${g}" 1
        done
    fi
    if [[ -n "${NO_GROUPS}" ]]; then
        IFS=',' read -ra _arr <<<"${NO_GROUPS}"
        for g in "${_arr[@]}"; do
            [[ -z "${g}" ]] && continue
            group_apply "${g}" 0
        done
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Wizard mode (per /wiki/log/2026-05-06-install-wizard-granular-state-aware-design.md)
# P1+P2 MVP: state detection + position frame + options offer (non-interactive).
# Triggered via --wizard flag. Writes a structured "where you are + what to do
# next" report; takes no install action. Operator runs the suggested commands
# afterward.
# ────────────────────────────────────────────────────────────────────────

# Layer 1 — State detection. Reads filesystem; sets WIZARD_STATE_* vars.
# Pure read-only (no state changes). Designed to run safely from any route
# (curl-bootstrap, post-clone, post-install, drift, etc.).
detect_install_state() {
    # Repo state
    WIZARD_STATE_REPO_PRESENT=$([[ -f "${SRC}/install.sh" ]] && echo 1 || echo 0)

    # Base install state — settings.json + hooks
    WIZARD_STATE_BASE_INSTALLED=$([[ -f "${DEST_CLAUDE}/settings.json" ]] && echo 1 || echo 0)
    WIZARD_STATE_HOOKS_DEPLOYED=$(find "${DEST_CLAUDE}/hooks" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.py" \) 2>/dev/null | wc -l)

    # Brain pieces deployed counts
    local d
    WIZARD_STATE_RULES_DEPLOYED=$(find "${DEST_CLAUDE}/rules" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    WIZARD_STATE_COMMANDS_DEPLOYED=$(find "${DEST_CLAUDE}/commands" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    WIZARD_STATE_AGENTS_DEPLOYED=$(find "${DEST_CLAUDE}/agents" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    WIZARD_STATE_MODES_DEPLOYED=$(find "${DEST_CLAUDE}/modes" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    WIZARD_STATE_SKILLS_DEPLOYED=$(find "${DEST_CLAUDE}/skills" -maxdepth 2 -name "SKILL.md" -type f 2>/dev/null | wc -l)
    WIZARD_STATE_TOOLS_DEPLOYED=$(find "${DEST_HOME}/tools" -maxdepth 1 -name "*.py" -type f 2>/dev/null | wc -l)

    # OS-level deployment state
    WIZARD_STATE_BRIDGE_CONFIGURED=$([[ -f /etc/systemd/network/30-ghostproxy-bridge.netdev ]] && echo 1 || echo 0)
    WIZARD_STATE_WIFI_CONFIGURED=$([[ -f /etc/wpa_supplicant/wpa_supplicant-mgmt0.conf ]] && echo 1 || echo 0)
    WIZARD_STATE_INTEGRITY_REGISTERED=$([[ -f "${DEST_CLAUDE}/integrity.json" ]] && echo 1 || echo 0)
    WIZARD_STATE_CCSTATUSLINE_INSTALLED=$(command -v ccstatusline >/dev/null 2>&1 && echo 1 || echo 0)
    WIZARD_STATE_OPENCODE_BRIDGE_DEPLOYED=$([[ -f "${DEST_OPENCODE}/plugin/claude-bridge.ts" ]] && echo 1 || echo 0)

    # Drift detection (only meaningful when base installed)
    WIZARD_STATE_HOOKS_DRIFTED=0
    if [[ "${WIZARD_STATE_BASE_INSTALLED}" == "1" ]]; then
        for d in "${SRC}/.claude/hooks/"*.{sh,py}; do
            [[ -e "${d}" ]] || continue
            local b
            b="${DEST_CLAUDE}/hooks/$(basename "${d}")"
            if [[ -f "${b}" ]]; then
                local h_src h_dst
                h_src=$(sha256sum "${d}" 2>/dev/null | awk '{print $1}')
                h_dst=$(sha256sum "${b}" 2>/dev/null | awk '{print $1}')
                [[ "${h_src}" != "${h_dst}" ]] && WIZARD_STATE_HOOKS_DRIFTED=$((WIZARD_STATE_HOOKS_DRIFTED + 1))
            fi
        done
    fi

    # Route detection (Q7 — conservative heuristic)
    if [[ "${WIZARD_STATE_REPO_PRESENT}" != "1" ]]; then
        WIZARD_ROUTE="repo-incomplete"
    elif [[ "${WIZARD_STATE_BASE_INSTALLED}" != "1" ]]; then
        WIZARD_ROUTE="post-clone-pre-install"
    elif [[ "${WIZARD_STATE_HOOKS_DRIFTED}" != "0" ]]; then
        WIZARD_ROUTE="drift-detected"
    elif [[ "${WIZARD_STATE_INTEGRITY_REGISTERED}" != "1" || "${WIZARD_STATE_WIFI_CONFIGURED}" != "1" ]]; then
        WIZARD_ROUTE="partial-install"
    else
        WIZARD_ROUTE="post-install-maintenance"
    fi
}

# Layer 2 — Position frame. "Where you are" report, terse default.
frame_position() {
    local bar="═══════════════════════════════════════════════════════════════════════"
    echo
    echo "${bar}"
    echo "INSTALL WIZARD · root-modules · type=root + group=operating-system-setup"
    echo "${bar}"
    echo
    echo "Where you are: route=${WIZARD_ROUTE}"
    echo

    local sym_ok="✓" sym_warn="⚠" sym_off="⊘"
    [[ "${WIZARD_STATE_REPO_PRESENT}" == "1" ]] \
        && echo "  ${sym_ok} Repo present at ${SRC}" \
        || echo "  ${sym_warn} Repo NOT detected (install.sh missing at SRC=${SRC})"

    if [[ "${WIZARD_STATE_BASE_INSTALLED}" == "1" ]]; then
        echo "  ${sym_ok} Base install at ${DEST_CLAUDE}/ (${WIZARD_STATE_HOOKS_DEPLOYED} hooks · ${WIZARD_STATE_RULES_DEPLOYED} rules · ${WIZARD_STATE_COMMANDS_DEPLOYED} commands · ${WIZARD_STATE_AGENTS_DEPLOYED} agents · ${WIZARD_STATE_MODES_DEPLOYED} modes · ${WIZARD_STATE_SKILLS_DEPLOYED} skills · ${WIZARD_STATE_TOOLS_DEPLOYED} tools)"
        if [[ "${WIZARD_STATE_HOOKS_DRIFTED}" != "0" ]]; then
            echo "  ${sym_warn} ${WIZARD_STATE_HOOKS_DRIFTED} hook(s) drifted from spec — run \`install.sh --check\` for detail"
        fi
    else
        echo "  ${sym_off} Base install NOT yet performed (no settings.json at ${DEST_CLAUDE}/)"
    fi

    [[ "${WIZARD_STATE_BRIDGE_CONFIGURED}" == "1" ]] \
        && echo "  ${sym_ok} Network bridge config deployed (/etc/systemd/network/)" \
        || echo "  ${sym_off} Network bridge NOT configured"

    [[ "${WIZARD_STATE_WIFI_CONFIGURED}" == "1" ]] \
        && echo "  ${sym_ok} Management wifi configured (/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf)" \
        || echo "  ${sym_off} Management wifi NOT configured (--with-wifi disabled)"

    [[ "${WIZARD_STATE_INTEGRITY_REGISTERED}" == "1" ]] \
        && echo "  ${sym_ok} Integrity sentinel registered" \
        || echo "  ${sym_off} Integrity sentinel NOT registered (--with-integrity disabled)"

    [[ "${WIZARD_STATE_CCSTATUSLINE_INSTALLED}" == "1" ]] \
        && echo "  ${sym_ok} ccstatusline installed (Features tier)" \
        || echo "  ${sym_off} ccstatusline NOT installed"

    [[ "${WIZARD_STATE_OPENCODE_BRIDGE_DEPLOYED}" == "1" ]] \
        && echo "  ${sym_ok} opencode bridge plugin deployed" \
        || echo "  ${sym_off} opencode bridge plugin NOT deployed"

    echo
    echo "Host context: OS=${OS_ID:-unknown} ${OS_VERSION_ID:-} (family=${OS_FAMILY:-unknown}) · Mode=${MODE:-auto}${DETECTED_MODE:+ (detected=${DETECTED_MODE})} · EUID=${EUID}"
    echo
}

# Layer 3 — Options offer. "What you can do next" prioritized recommendations.
offer_options() {
    local bar="═══════════════════════════════════════════════════════════════════════"
    echo "${bar}"
    echo "What you can do next:"
    echo "${bar}"
    echo

    local n=1

    case "${WIZARD_ROUTE}" in
        repo-incomplete)
            echo "  [${n}] Re-clone the repo (install.sh missing at expected SRC)"
            echo "        → git clone <url> && cd <repo> && ./install.sh --wizard"
            n=$((n + 1))
            ;;
        post-clone-pre-install)
            echo "  [${n}] Run base install (foundation tier — recommended first step)"
            echo "        → ./install.sh --dry-run --profile base   # preview first"
            echo "        → sudo ./install.sh --profile base         # apply"
            n=$((n + 1))
            echo "  [${n}] Run full install (base + ccstatusline Features tier)"
            echo "        → sudo ./install.sh --profile full"
            n=$((n + 1))
            echo "  [${n}] Endpoint-only install (no bridge/wifi ops; Claude Code + opencode safety only)"
            echo "        → sudo ./install.sh --profile base --mode endpoint"
            n=$((n + 1))
            ;;
        drift-detected)
            echo "  [${n}] Run drift-check for full diff between repo + deployed state"
            echo "        → ./install.sh --check"
            n=$((n + 1))
            echo "  [${n}] Re-apply install (idempotent; will back up divergent files)"
            echo "        → sudo ./install.sh"
            n=$((n + 1))
            ;;
        partial-install|post-install-maintenance)
            if [[ "${WIZARD_STATE_WIFI_CONFIGURED}" != "1" ]]; then
                echo "  [${n}] Enable management wifi (recommended for type=root install)"
                echo "        → sudo ./install.sh --with-wifi"
                n=$((n + 1))
            fi
            if [[ "${WIZARD_STATE_INTEGRITY_REGISTERED}" != "1" ]]; then
                echo "  [${n}] Register integrity sentinel (SHA256 baselines for safety policy)"
                echo "        → sudo ./install.sh --with-integrity"
                n=$((n + 1))
            fi
            if [[ "${WIZARD_STATE_CCSTATUSLINE_INSTALLED}" != "1" ]]; then
                echo "  [${n}] Install ccstatusline (Features tier; npm-based)"
                echo "        → sudo ./install.sh --with-ccstatusline"
                n=$((n + 1))
            fi
            echo "  [${n}] Deploy agent brain into a sister project (per-project install)"
            echo "        → ./install.sh --profile project --dest <target-path>"
            echo "        → /install-agent-brain <target-path>   # slash-command equivalent"
            n=$((n + 1))
            echo "  [${n}] Run drift-check on current install state"
            echo "        → ./install.sh --check"
            n=$((n + 1))
            ;;
    esac

    echo "  [${n}] Granular install (pick specific hooks/commands/rules/tools or groups)"
    echo "        → ./install.sh --granular   # interactive group-picker (P4 — pending)"
    echo "        → ./install.sh --with-hook policy-block --no-hook opt-write-block ..."
    n=$((n + 1))

    echo "  [Q] Quit (no changes)"
    echo
    echo "Pending operator decisions (T013 et al — see wiki/governance/blockers.md for full list):"
    echo "  · Bridge FORWARD/OUTPUT default policy (default-accept vs default-drop, threat-model)"
    echo "  · See: wiki/governance/blockers.md + wiki/governance/decisions.md"
    echo
    echo "${bar}"
    echo "(MVP wizard P1+P2: report-only. Interactive picker = P4 pending.)"
    echo "${bar}"
    echo
}

# ────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────

main() {
    parse_args "$@"

    log_info "${SCRIPT_NAME} ${VERSION} starting (implement-stage)"

    # OS family + mode detection + profile application BEFORE --check or
    # real-install branch. --check mode needs WITH_* toggles set so the
    # per-op verifications (wifi, bridge, brain pieces, etc.) know what
    # to verify. Without apply_profile, all WITH_* are empty → checks skip.
    detect_os_family
    detect_ghostproxy_mode
    apply_profile
    # Apply --with-group / --no-group selections AFTER profile so groups override
    # profile defaults; per-op --with-X / --no-X flags then compose on top.
    apply_groups

    # Wizard mode (P1+P2 MVP): state-aware position frame + suggested-next-actions.
    # Read-only — no install action. Operator runs the suggested commands themselves.
    if [[ "${WIZARD_MODE}" -eq 1 ]]; then
        detect_install_state
        frame_position
        offer_options
        exit 0
    fi

    if [[ "${CHECK_MODE}" -eq 1 ]]; then
        run_check
        exit 0
    fi
    require_dependencies

    # shellcheck disable=SC2015  # set -euo pipefail: op_* failure exits before || branch runs
    [[ "${WITH_HOOKS}"        == "1" ]] && op_install_endpoint_safety_policy || log_info "skip: endpoint safety policy (per profile/toggle)"
    # shellcheck disable=SC2015
    [[ "${WITH_TOOLS}"        == "1" ]] && op_install_tools                  || log_info "skip: tools/ (per profile/toggle)"
    # shellcheck disable=SC2015
    [[ "${WITH_OPENCODE}"     == "1" ]] && op_install_opencode_bridge        || log_info "skip: opencode bridge (per profile/toggle)"
    # shellcheck disable=SC2015
    [[ "${WITH_BRIDGE}"       == "1" ]] && op_install_network_bridge         || log_info "skip: network bridge (per profile/toggle)"
    # shellcheck disable=SC2015
    [[ "${WITH_WIFI}"         == "1" ]] && op_install_management_wifi        || log_info "skip: management wifi (per profile/toggle)"
    # shellcheck disable=SC2015
    [[ "${WITH_INTEGRITY}"    == "1" ]] && op_install_integrity_sentinel     || log_info "skip: integrity sentinel (per profile/toggle)"
    # shellcheck disable=SC2015
    [[ "${WITH_CCSTATUSLINE}" == "1" ]] && op_install_ccstatusline           || log_info "skip: ccstatusline (per profile/toggle — Features tier)"
    op_verify

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log_info "${SCRIPT_NAME} done (dry-run; no state changes)"
    else
        log_info "${SCRIPT_NAME} done"
    fi
}

main "$@"
