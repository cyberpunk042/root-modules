#!/usr/bin/env bash
# merge-from-backup.sh — SURGICAL post-Path-A reconciliation tool with
# security-scan + audit-trail + follow-up-task governance.
#
# Default = DIFF mode: shows differences. NO CHANGES.
# --apply = per-change confirmation. Each apply session writes an audit log
#          + creates a follow-up review task per the governance design.
#
# Per operator directive 2026-05-05 (governance): "merges should generate
# tasks and Epics for review and making sure we properly synthesize and
# always keep clean and not contradictory or unsecure". This script is
# the surgical merge + governance layer.
#
# Flags:
#   (no flag)              diff mode (default)
#   --apply                apply changes, per-change confirmation
#   --validate             validate JSON only (no diff, no merge)
#   --skip <key>           skip category: settings|opencode|gitignore|hooks|rules|claudeignore|mcp
#   --accept-security-flags
#                          allow HIGH-severity flagged changes to apply (audit trail records this)
#   --no-followup-task     skip generating wiki/backlog/tasks/<T>-post-merge-review-... task
#   --no-log               skip writing wiki/log/<date>-merge-from-backup-... audit log
#   -h, --help

set -euo pipefail

# ---------- Source libs ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
[ -d "$LIB_DIR" ] || { echo "ERROR: lib/ not found at $LIB_DIR" >&2; exit 1; }
# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/conflict-points.sh
source "$LIB_DIR/conflict-points.sh"
# shellcheck source=lib/json-merge.sh
source "$LIB_DIR/json-merge.sh"
# shellcheck source=lib/security-scan.sh
source "$LIB_DIR/security-scan.sh"
# shellcheck source=lib/merge-manifest.sh
source "$LIB_DIR/merge-manifest.sh"

# ---------- Args ----------
MODE="diff"
SKIPS=()
ACCEPT_SECURITY_FLAGS=0
NO_FOLLOWUP_TASK=0
NO_LOG=0

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)                  MODE="apply" ;;
    --validate)               MODE="validate" ;;
    --diff)                   MODE="diff" ;;
    --skip)                   shift; SKIPS+=("$1") ;;
    --accept-security-flags)  ACCEPT_SECURITY_FLAGS=1 ;;
    --no-followup-task)       NO_FOLLOWUP_TASK=1 ;;
    --no-log)                 NO_LOG=1 ;;
    -h|--help)                sed -n '2,30p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *)                        echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

is_skipped() {
  local key="$1"
  for s in "${SKIPS[@]:-}"; do [ "$s" = "$key" ] && return 0; done
  return 1
}

# ---------- Pre-flight ----------
hdr "Pre-flight"
[ "$(pwd)" = "$HOME" ] || fail "Must run from \$HOME (cwd=$(pwd))"
ok "cwd is \$HOME ($HOME)"

BACKUP_DIR="$RM_BACKUP_DIR_DEFAULT"
if [ "$MODE" != "validate" ]; then
  [ -d "$BACKUP_DIR" ] || fail "$BACKUP_DIR not found — nothing to merge"
  ok "backup dir present: $BACKUP_DIR"
fi
[ -d .git ] || warn ".git not found — script assumes Path A post-checkout state"

case "$MODE" in
  diff)     info "MODE: diff (no changes will be made)" ;;
  apply)    info "MODE: apply (per-change confirmation; security flags reviewed; audit log + follow-up task generated)" ;;
  validate) info "MODE: validate (no diff, no merge)" ;;
esac

# ---------- VALIDATE-ONLY EARLY EXIT ----------
if [ "$MODE" = "validate" ]; then
  hdr "Validate current \$HOME JSON files"
  any_invalid=0
  for f in .claude/settings.json .config/opencode/opencode.json .mcp.json; do
    if [ -f "$f" ]; then
      if validate_json "$f"; then
        ok "$f: valid JSON"
      else
        warn "$f: INVALID JSON"
        any_invalid=1
      fi
    fi
  done
  if [ "$any_invalid" = "1" ]; then
    info "to recover: cp -a $BACKUP_DIR/<file> <file>"
  fi
  exit 0
fi

# ---------- Apply-mode init manifest ----------
if [ "$MODE" = "apply" ]; then
  manifest_init
fi

# ---------- 1. .claude/settings.json ----------
if ! is_skipped settings; then
  hdr "settings.json — per-key diff"
  BAK="$BACKUP_DIR/.claude/settings.json"
  CUR=".claude/settings.json"

  if [ ! -f "$BAK" ]; then
    info "no backup of $CUR — skipping"
    [ "$MODE" = "apply" ] && manifest_record skipped "settings.json" "no backup"
  elif [ ! -f "$CUR" ]; then
    warn "$CUR missing in repo working tree — skipping"
    [ "$MODE" = "apply" ] && manifest_record skipped "settings.json" "current missing"
  elif ! validate_json "$BAK" || ! validate_json "$CUR"; then
    warn "one of $BAK or $CUR is not valid JSON — skipping"
    [ "$MODE" = "apply" ] && manifest_record skipped "settings.json" "invalid JSON in backup or current"
  else
    diff_settings "$BAK" "$CUR"

    if [ "$MODE" = "apply" ]; then
      say ""
      info "settings.json apply: ONLY permissions.allow/deny/ask UNION (purely additive)"
      info "Hooks block + custom keys: NOT touched (manual editing only)"

      # Pre-apply security scan: extract proposed allow entries from backup that
      # WOULD be added (in backup but not in repo), scan them.
      hdr "Security scan — proposed permission additions"
      PROPOSED_ALLOW=$(python3 - "$BAK" "$CUR" <<'PYEOF'
import json, sys
bak = json.load(open(sys.argv[1]))
cur = json.load(open(sys.argv[2]))
b_allow = set((bak.get("permissions") or {}).get("allow", []) or [])
c_allow = set((cur.get("permissions") or {}).get("allow", []) or [])
for entry in sorted(b_allow - c_allow):
    print(entry)
PYEOF
)
      SCAN_FLAGS=""
      if [ -n "$PROPOSED_ALLOW" ]; then
        SCAN_FLAGS=$(echo "$PROPOSED_ALLOW" | scan_permission_entries || true)
      fi
      if [ -z "$SCAN_FLAGS" ]; then
        ok "no security flags in proposed permission additions"
      else
        warn "security flags detected in proposed permission additions:"
        while IFS=$'\t' read -r sev cat detail; do
          [ -z "$sev" ] && continue
          say "  [$sev] [$cat] $detail"
          manifest_record flagged "${sev}:${cat}" "settings.permissions.allow: $detail"
        done <<< "$SCAN_FLAGS"
      fi

      # Block on HIGH unless --accept-security-flags
      HAS_HIGH=0
      echo "$SCAN_FLAGS" | grep -q '^HIGH' && HAS_HIGH=1
      if [ "$HAS_HIGH" = "1" ] && [ "$ACCEPT_SECURITY_FLAGS" != "1" ]; then
        warn "HIGH-severity flags BLOCK this apply (use --accept-security-flags to override + audit-trail-record)"
        manifest_record skipped "settings.json:permissions-union" "blocked by HIGH security flags"
      else
        if [ "$HAS_HIGH" = "1" ]; then
          warn "HIGH flags present + --accept-security-flags set — will record this in audit log"
        fi
        if confirm "apply permissions.allow + permissions.deny + permissions.ask union?"; then
          STAGED="$CUR.merged"
          permissions_union_settings "$BAK" "$CUR" "$STAGED"
          if stage_swap "$STAGED" "$CUR"; then
            ok "permissions union applied. Hooks/other keys UNCHANGED."
            local_count=$(echo "$PROPOSED_ALLOW" | grep -cE '.' || echo 0)
            manifest_record applied "settings.json:permissions-union" "$local_count entries added (deny+ask unioned similarly)"
          else
            manifest_record skipped "settings.json:permissions-union" "stage_swap failed (validation)"
          fi
        else
          info "permissions union NOT applied (operator declined)"
          manifest_record skipped "settings.json:permissions-union" "operator declined"
        fi
      fi
    fi
  fi
fi

# ---------- 2. .config/opencode/opencode.json ----------
if ! is_skipped opencode; then
  hdr "opencode.json — per-key diff"
  BAK="$BACKUP_DIR/.config/opencode/opencode.json"
  CUR=".config/opencode/opencode.json"

  if [ ! -f "$BAK" ]; then
    info "no backup of $CUR — skipping"
    [ "$MODE" = "apply" ] && manifest_record skipped "opencode.json" "no backup"
  elif [ ! -f "$CUR" ]; then
    warn "$CUR missing in repo working tree — skipping"
    [ "$MODE" = "apply" ] && manifest_record skipped "opencode.json" "current missing"
  elif ! validate_json "$BAK" || ! validate_json "$CUR"; then
    warn "one of $BAK or $CUR is not valid JSON — skipping"
    [ "$MODE" = "apply" ] && manifest_record skipped "opencode.json" "invalid JSON"
  else
    diff_opencode "$BAK" "$CUR"

    if [ "$MODE" = "apply" ]; then
      info "opencode.json apply: ONLY copies operator-unique keys (additive)"

      # Security scan for credential-shaped values
      hdr "Security scan — opencode unique keys"
      OPE_FLAGS=$(scan_opencode_unique_keys "$BAK" "$CUR" || true)
      if [ -z "$OPE_FLAGS" ]; then
        ok "no security flags in proposed opencode key additions"
      else
        warn "security flags detected:"
        while IFS=$'\t' read -r sev cat detail; do
          [ -z "$sev" ] && continue
          say "  [$sev] [$cat] $detail"
          manifest_record flagged "${sev}:${cat}" "opencode: $detail"
        done <<< "$OPE_FLAGS"
      fi

      OPE_HAS_HIGH=0
      echo "$OPE_FLAGS" | grep -q '^HIGH' && OPE_HAS_HIGH=1
      if [ "$OPE_HAS_HIGH" = "1" ] && [ "$ACCEPT_SECURITY_FLAGS" != "1" ]; then
        warn "HIGH-severity flags BLOCK opencode apply (use --accept-security-flags to override)"
        manifest_record skipped "opencode.json:unique-keys" "blocked by HIGH security flags"
      else
        if confirm "copy operator-unique keys from backup into opencode.json?"; then
          STAGED="$CUR.merged"
          operator_unique_keys_opencode "$BAK" "$CUR" "$STAGED"
          if stage_swap "$STAGED" "$CUR"; then
            ok "operator-unique keys copied"
            manifest_record applied "opencode.json:unique-keys" "operator-unique keys merged"
          else
            manifest_record skipped "opencode.json:unique-keys" "stage_swap failed"
          fi
        else
          info "no changes applied"
          manifest_record skipped "opencode.json:unique-keys" "operator declined"
        fi
      fi
    fi
  fi
fi

# ---------- 3. .gitignore — DIFF ONLY ----------
if ! is_skipped gitignore; then
  hdr ".gitignore — diff only (NEVER auto-merged)"
  BAK="$BACKUP_DIR/.gitignore"
  CUR=".gitignore"

  if [ ! -f "$BAK" ]; then
    info "no backup of $CUR — skipping"
  elif [ ! -f "$CUR" ]; then
    warn "$CUR missing in repo — skipping"
  else
    UNIQUE=$(comm -23 <(grep -vE '^\s*(#|$)' "$BAK" | sort -u) \
                     <(grep -vE '^\s*(#|$)' "$CUR" | sort -u) || true)
    if [ -z "$UNIQUE" ]; then
      ok "no unique non-comment lines in backup — repo .gitignore covers everything"
    else
      warn "Backup .gitignore has UNIQUE lines (NEVER auto-applied)."
      say "Suggested patch (manual review required):"
      echo "$UNIQUE" | sed 's/^/        /'

      # Security scan on gitignore additions
      GI_FLAGS=$(echo "$UNIQUE" | scan_gitignore_additions || true)
      if [ -n "$GI_FLAGS" ]; then
        warn "security flags detected in proposed .gitignore additions:"
        while IFS=$'\t' read -r sev cat detail; do
          [ -z "$sev" ] && continue
          say "  [$sev] [$cat] $detail"
          [ "$MODE" = "apply" ] && manifest_record flagged "${sev}:${cat}" ".gitignore: $detail"
        done <<< "$GI_FLAGS"
      fi

      if [ "$MODE" = "apply" ]; then
        local_count=$(echo "$UNIQUE" | grep -cE '.' || echo 0)
        manifest_record surfaced ".gitignore:unique-lines" "$local_count line(s) for manual review"
      fi
    fi
  fi
fi

# ---------- 4. Custom hooks / rules — DIFF ONLY (with security scan on hooks) ----------
for kind in hooks rules; do
  if is_skipped "$kind"; then continue; fi
  hdr "Custom $kind — diff only (NEVER auto-copied)"
  BAK_DIR="$BACKUP_DIR/.claude/$kind-existing"
  CUR_DIR=".claude/$kind"

  if [ ! -d "$BAK_DIR" ]; then
    info "no backup at $BAK_DIR — skipping"
    continue
  fi

  UNIQUE_LIST=()
  while IFS= read -r f; do
    base=$(basename "$f")
    [ -e "$CUR_DIR/$base" ] || UNIQUE_LIST+=("$f")
  done < <(find "$BAK_DIR" -maxdepth 1 -type f 2>/dev/null)

  if [ ${#UNIQUE_LIST[@]} -eq 0 ]; then
    ok "no custom $kind unique to backup"
  else
    say "Custom $kind in backup not present in repo:"
    for f in "${UNIQUE_LIST[@]}"; do say "  $(basename "$f") ($(wc -c <"$f") bytes)"; done

    # Security scan on each custom hook file
    if [ "$kind" = "hooks" ]; then
      hdr "Security scan — custom hooks"
      any_hook_flag=0
      for f in "${UNIQUE_LIST[@]}"; do
        HOOK_FLAGS=$(scan_custom_hook_file "$f" || true)
        if [ -n "$HOOK_FLAGS" ]; then
          any_hook_flag=1
          while IFS=$'\t' read -r sev cat detail; do
            [ -z "$sev" ] && continue
            say "  [$sev] [$cat] $detail"
            [ "$MODE" = "apply" ] && manifest_record flagged "${sev}:${cat}" "custom-hook: $detail"
          done <<< "$HOOK_FLAGS"
        fi
      done
      [ "$any_hook_flag" = "0" ] && ok "no security flags in custom hooks"
    fi

    say ""
    info "Manual copy commands (review each first):"
    for f in "${UNIQUE_LIST[@]}"; do
      say "  cp -a '$f' '$CUR_DIR/'"
    done
    if [ "$MODE" = "apply" ]; then
      manifest_record surfaced ".claude/$kind:custom" "${#UNIQUE_LIST[@]} item(s) for manual review"
    fi
  fi
done

# ---------- 5. .claudeignore + .mcp.json — DIFF ONLY ----------
for kind in claudeignore mcp; do
  if is_skipped "$kind"; then continue; fi
  case "$kind" in
    claudeignore) DOT=".claudeignore" ;;
    mcp)          DOT=".mcp.json" ;;
  esac
  hdr "$DOT — diff only"
  BAK="$BACKUP_DIR/$DOT"
  CUR="$DOT"

  if [ ! -f "$BAK" ]; then
    info "no backup of $DOT — skipping"
    continue
  fi
  if [ ! -f "$CUR" ]; then
    warn "$CUR missing in repo — skipping"
    continue
  fi

  if cmp -s "$BAK" "$CUR"; then
    ok "$DOT identical between backup and repo — no action needed"
  else
    say "Diff (backup → repo, first 40 lines):"
    diff -u "$BAK" "$CUR" 2>&1 | sed 's/^/    /' | head -40 || true
    if [ "$MODE" = "apply" ]; then
      manifest_record surfaced "$DOT" "diff present; manual decision"
    fi
  fi
done

# ---------- Apply-mode finalize: write log + create task ----------
if [ "$MODE" = "apply" ]; then
  finalize_args=()
  [ "$NO_FOLLOWUP_TASK" = "1" ] && finalize_args+=(--no-task)
  [ "$NO_LOG" = "1" ]            && finalize_args+=(--no-log)
  manifest_finalize "${finalize_args[@]}"
fi

# ---------- Recovery info ----------
hdr "Recovery info"
cat <<EOF
  ORIGINAL backup (your prior state):    $BACKUP_DIR/
  PRE-MERGE backup (per-file pre-swap):  *.pre-merge.bak files in-place

  Restore single file:  cp -a $BACKUP_DIR/<file> <file>
  Re-validate:          bash $0 --validate
EOF
if [ "$MODE" = "apply" ]; then
  cat <<EOF

  Audit + governance:
    • wiki/log/<date>-merge-from-backup-<host>.md       (audit trail)
    • wiki/backlog/tasks/T<NEXT>-post-merge-review-...  (follow-up task — review before declaring merge clean)
EOF
fi

# ---------- Done ----------
hdr "Done"
case "$MODE" in
  diff)
    say "Diff mode complete. NO CHANGES MADE."
    say "Re-run with --apply for per-change confirmation + governance log + follow-up task."
    ;;
  apply)
    if manifest_has_high_flags; then
      warn "Apply complete BUT HIGH-severity flags fired — see follow-up task before declaring merge clean."
      exit 3
    else
      ok "Apply complete. Audit log + follow-up task generated."
    fi
    ;;
esac
