#!/usr/bin/env bash
# scripts/lib/common.sh — shared helpers for root-modules scripts.
# Sourced by: checkout-a-init-remote.sh, checkout-b-clone-subdir.sh, merge-from-backup.sh
#
# Provides: logging (say/hdr/ok/warn/fail/info) + TTY detection + ask/confirm.
# Convention: this file should NOT have side effects on source — only define
# functions + lightweight variables.
#
# Re-source guard:
[ -n "${RGP_LIB_COMMON_SOURCED:-}" ] && return 0
RGP_LIB_COMMON_SOURCED=1

# ---------- Logging ----------
say()  { printf "  %s\n" "$*"; }
hdr()  { printf "\n──── %s ────\n" "$*"; }
ok()   { printf "  ✓ %s\n" "$*"; }
warn() { printf "  ⚠ %s\n" "$*"; }
fail() { printf "  ✗ %s\n" "$*" >&2; exit 1; }
info() { printf "  i %s\n" "$*"; }

# ---------- Interactive detection ----------
# Detect once, cache. Override by setting RGP_INTERACTIVE before sourcing.
if [ -z "${RGP_INTERACTIVE:-}" ]; then
  if [ -r /dev/tty ]; then
    RGP_INTERACTIVE=1
  else
    RGP_INTERACTIVE=0
  fi
fi

# ---------- Prompting ----------
# ask "<prompt>" "<default>"
#   Reads from /dev/tty (works under curl|bash). Returns default if non-interactive.
ask() {
  local prompt="$1" default="${2:-}" ans
  if [ "$RGP_INTERACTIVE" = "1" ]; then
    read -r -p "  $prompt [$default]: " ans </dev/tty || ans="$default"
    [ -z "$ans" ] && ans="$default"
    echo "$ans"
  else
    echo "$default"
  fi
}

# confirm "<prompt>"
#   Returns 0 (yes) / 1 (no). Non-interactive defaults to NO (safety-first).
confirm() {
  local ans
  if [ "$RGP_INTERACTIVE" = "1" ]; then
    read -r -p "  $1 (y/N): " ans </dev/tty || ans="N"
    case "$ans" in y|Y|yes) return 0 ;; *) return 1 ;; esac
  else
    return 1
  fi
}

# ---------- Misc ----------
# require_cmd <cmd> [<install-hint>]
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not installed${2:+ — $2}"
}
