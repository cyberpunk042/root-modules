#!/usr/bin/env bash
# scripts/lib/backup.sh — backup helper for Path A pre-checkout.
#
# Creates a backup of all CONFLICT_FILES + CONFLICT_DIRS_FOR_HOOKS_RULES
# (from conflict-points.sh) into a backup directory. Idempotent in the
# sense that re-running on already-backed-up state will overwrite the
# backup with the current state — caller's responsibility to avoid that.
#
# Requires: lib/common.sh + lib/conflict-points.sh sourced first.
#
# Re-source guard:
[ -n "${RM_LIB_BACKUP_SOURCED:-}" ] && return 0
RM_LIB_BACKUP_SOURCED=1

# backup_conflict_points [<backup-dir>]
#   Default backup-dir: $RM_BACKUP_DIR_DEFAULT (.pre-ghostproxy.bak)
#   Returns: 0 always; logs ok/info per item.
#   Requires cwd to be the directory whose conflict points to back up
#   (typically $HOME).
backup_conflict_points() {
  local backup_dir="${1:-$RM_BACKUP_DIR_DEFAULT}"
  local any_backed_up=0

  if [ -z "${CONFLICT_FILES[0]:-}" ]; then
    fail "CONFLICT_FILES array empty — did you source lib/conflict-points.sh?"
  fi

  for f in "${CONFLICT_FILES[@]}"; do
    if [ -f "$f" ]; then
      mkdir -p "$backup_dir/$(dirname "$f")"
      cp -a "$f" "$backup_dir/$f"
      ok "backed up: $f"
      any_backed_up=1
    fi
  done

  for d in "${CONFLICT_DIRS_FOR_HOOKS_RULES[@]}"; do
    if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
      mkdir -p "$backup_dir/$d-existing"
      cp -a "$d/." "$backup_dir/$d-existing/"
      ok "backed up: $d/"
      any_backed_up=1
    fi
  done

  if [ "$any_backed_up" = "0" ]; then
    info "no conflict points present — clean checkout expected"
  else
    info "conflict points backed up to $backup_dir/"
  fi

  return 0
}
