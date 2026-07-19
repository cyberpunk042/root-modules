#!/usr/bin/env bash
# scripts/lib/merge-manifest.sh — collects merge manifest + writes audit log +
# creates follow-up review task in the project's backlog.
#
# Per operator directive 2026-05-05: "merges should generate tasks and Epics
# for review and making sure we properly synthesize and always keep clean
# and not contradictory or unsecure". This lib is the governance layer.
#
# Pattern of use (from merge-from-backup.sh):
#
#   source "$LIB_DIR/merge-manifest.sh"
#   manifest_init
#   manifest_record applied "settings.json:permissions-union" "12 entries union'd"
#   manifest_record surfaced "gitignore:unique-lines" "3 lines surfaced for manual review"
#   manifest_record flagged "HIGH:perm-unbounded-wildcard" "Bash(*)"
#   ...
#   manifest_finalize  # writes log + task
#
# Requires: lib/common.sh + lib/security-scan.sh sourced first.
#
# Re-source guard:
[ -n "${RM_LIB_MERGE_MANIFEST_SOURCED:-}" ] && return 0
RM_LIB_MERGE_MANIFEST_SOURCED=1

# ---------- Internal state ----------
RM_MANIFEST_APPLIED=()
RM_MANIFEST_SURFACED=()
RM_MANIFEST_FLAGGED=()
RM_MANIFEST_SKIPPED=()
RM_MANIFEST_TIMESTAMP=""
RM_MANIFEST_HOSTNAME=""

# ---------- API ----------

# manifest_init
#   Resets manifest state. Call once at the start of an --apply session.
manifest_init() {
  RM_MANIFEST_APPLIED=()
  RM_MANIFEST_SURFACED=()
  RM_MANIFEST_FLAGGED=()
  RM_MANIFEST_SKIPPED=()
  RM_MANIFEST_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  RM_MANIFEST_HOSTNAME="$(hostname -s 2>/dev/null || echo unknown-host)"
}

# manifest_record <category> <key> <detail>
#   category ∈ applied | surfaced | flagged | skipped
manifest_record() {
  local cat="$1" key="$2" detail="${3:-}"
  local entry
  entry="${key}|${detail}"
  case "$cat" in
    applied)  RM_MANIFEST_APPLIED+=("$entry") ;;
    surfaced) RM_MANIFEST_SURFACED+=("$entry") ;;
    flagged)  RM_MANIFEST_FLAGGED+=("$entry") ;;
    skipped)  RM_MANIFEST_SKIPPED+=("$entry") ;;
    *)        warn "manifest_record: unknown category '$cat'" ;;
  esac
}

# manifest_has_high_flags
#   Returns 0 if any flag entry starts with "HIGH:"
manifest_has_high_flags() {
  for entry in "${RM_MANIFEST_FLAGGED[@]:-}"; do
    case "$entry" in HIGH:*) return 0 ;; esac
  done
  return 1
}

# manifest_count <category>
manifest_count() {
  local cat="$1"
  case "$cat" in
    applied)  echo ${#RM_MANIFEST_APPLIED[@]} ;;
    surfaced) echo ${#RM_MANIFEST_SURFACED[@]} ;;
    flagged)  echo ${#RM_MANIFEST_FLAGGED[@]} ;;
    skipped)  echo ${#RM_MANIFEST_SKIPPED[@]} ;;
    *)        echo 0 ;;
  esac
}

# _next_task_number <tasks-dir>
_next_task_number() {
  local tasks_dir="$1"
  local max=0 n
  for f in "$tasks_dir"/T*.md; do
    [ -f "$f" ] || continue
    n=$(basename "$f" | sed -nE 's/^T0*([0-9]+).*/\1/p')
    [ -n "$n" ] && [ "$n" -gt "$max" ] && max=$n
  done
  echo $((max + 1))
}

# manifest_finalize [--no-task] [--no-log]
#   Writes audit log + (default) creates follow-up task in backlog.
#   Returns 0 on success, non-zero if writes failed.
#
# Emits:
#   wiki/log/<date>-merge-from-backup-<host>.md (audit trail)
#   wiki/backlog/tasks/T<NEXT>-post-merge-review-<date>-<host>.md (follow-up task)
manifest_finalize() {
  local no_task=0 no_log=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-task) no_task=1 ;;
      --no-log)  no_log=1 ;;
    esac
    shift
  done

  local date_iso
  date_iso="$(date -u +%Y-%m-%d)"
  local short_host="$RM_MANIFEST_HOSTNAME"

  # Resolve project root: $HOME if there's a wiki/ there (Path A), else cwd
  local proj_root
  if [ -d "$HOME/wiki/log" ]; then
    proj_root="$HOME"
  elif [ -d "$(pwd)/wiki/log" ]; then
    proj_root="$(pwd)"
  else
    warn "no wiki/log/ found at \$HOME or cwd — manifest will print to stdout only"
    proj_root=""
  fi

  # ---------- Compose log content ----------
  local log_content
  log_content=$(cat <<EOF
---
title: "Merge audit — \`$date_iso\` on \`$short_host\` (post-Path-A reconciliation)"
type: log
domain: cross-domain
status: active
confidence: high
created: $date_iso
updated: $date_iso
tags: [log, merge-audit, security-review, governance, $short_host, post-path-a]
---

# Merge audit — $date_iso on $short_host

## Run metadata

- **Timestamp (UTC)**: $RM_MANIFEST_TIMESTAMP
- **Host**: $RM_MANIFEST_HOSTNAME
- **Mode**: \`merge-from-backup.sh --apply\` (post-Path-A reconciliation)
- **Backup source**: \`\$HOME/$RM_BACKUP_DIR_DEFAULT/\`

## Summary

| Category | Count |
|---|---|
| Applied (additive merges that landed in the working tree) | $(manifest_count applied) |
| Surfaced (items operator must decide manually) | $(manifest_count surfaced) |
| Flagged (security/consistency concerns detected) | $(manifest_count flagged) |
| Skipped (no backup or no diff) | $(manifest_count skipped) |

## Applied changes

EOF
)
  if [ ${#RM_MANIFEST_APPLIED[@]} -eq 0 ]; then
    log_content+=$'\nNone.\n'
  else
    log_content+=$'\n| Key | Detail |\n|---|---|\n'
    for entry in "${RM_MANIFEST_APPLIED[@]}"; do
      local k="${entry%%|*}"
      local d="${entry#*|}"
      log_content+="| \`$k\` | $d |"$'\n'
    done
  fi

  log_content+=$'\n## Surfaced for manual review\n'
  if [ ${#RM_MANIFEST_SURFACED[@]} -eq 0 ]; then
    log_content+=$'\nNone.\n'
  else
    log_content+=$'\n| Key | Detail |\n|---|---|\n'
    for entry in "${RM_MANIFEST_SURFACED[@]}"; do
      local k="${entry%%|*}"
      local d="${entry#*|}"
      log_content+="| \`$k\` | $d |"$'\n'
    done
  fi

  log_content+=$'\n## Security flags\n'
  if [ ${#RM_MANIFEST_FLAGGED[@]} -eq 0 ]; then
    log_content+=$'\nNone.\n'
  else
    log_content+=$'\n| Severity | Category | Detail |\n|---|---|---|\n'
    for entry in "${RM_MANIFEST_FLAGGED[@]}"; do
      local k="${entry%%|*}"
      local d="${entry#*|}"
      local sev="${k%%:*}"
      local cat="${k#*:}"
      log_content+="| **$sev** | \`$cat\` | $d |"$'\n'
    done
  fi

  log_content+=$'\n## Skipped\n'
  if [ ${#RM_MANIFEST_SKIPPED[@]} -eq 0 ]; then
    log_content+=$'\nNone.\n'
  else
    log_content+=$'\n'
    for entry in "${RM_MANIFEST_SKIPPED[@]}"; do
      local k="${entry%%|*}"
      local d="${entry#*|}"
      log_content+="- \`$k\`: $d"$'\n'
    done
  fi

  log_content+=$'\n## Recovery\n\n- Backup directory (prior config): `$HOME/'"$RM_BACKUP_DIR_DEFAULT"$'/`\n- Per-file pre-swap backups: `*.pre-merge.bak` in-place\n- Restore single file: `cp -a $HOME/'"$RM_BACKUP_DIR_DEFAULT"$'/<file> $HOME/<file>`\n- Re-validate: `bash scripts/merge-from-backup.sh --validate`\n'

  log_content+=$'\n## Cross-references\n\n- Companion follow-up task (this run): see `wiki/backlog/tasks/T<NEXT>-post-merge-review-'"$date_iso"$'-'"$short_host"$'.md` (if generated)\n- Merge tool: `scripts/merge-from-backup.sh`\n- Security scanner: `scripts/lib/security-scan.sh`\n- Conflict-points source-of-truth: `scripts/lib/conflict-points.sh`\n- Scripts ecosystem: `scripts/README.md`\n'

  # ---------- Write log ----------
  local log_path=""
  if [ -n "$proj_root" ] && [ "$no_log" = "0" ]; then
    log_path="$proj_root/wiki/log/$date_iso-merge-from-backup-$short_host.md"
    # If exists, append a timestamp suffix to avoid clobbering
    if [ -e "$log_path" ]; then
      local ts
      ts=$(date -u +%H%M%S)
      log_path="$proj_root/wiki/log/$date_iso-merge-from-backup-$short_host-$ts.md"
    fi
    printf "%s" "$log_content" > "$log_path"
    ok "audit log written: $log_path"
  fi

  # ---------- Generate follow-up task ----------
  local task_path=""
  if [ -n "$proj_root" ] && [ "$no_task" = "0" ]; then
    local tasks_dir="$proj_root/wiki/backlog/tasks"
    if [ -d "$tasks_dir" ]; then
      local n
      n=$(_next_task_number "$tasks_dir")
      local task_id
      task_id=$(printf "T%03d" "$n")
      task_path="$tasks_dir/$task_id-post-merge-review-$date_iso-$short_host.md"

      local high_count med_count
      high_count=0; med_count=0
      for entry in "${RM_MANIFEST_FLAGGED[@]:-}"; do
        case "$entry" in
          HIGH:*) high_count=$((high_count+1)) ;;
          MED:*)  med_count=$((med_count+1)) ;;
        esac
      done

      local task_priority="P2"
      [ "$high_count" -gt 0 ] && task_priority="P0"
      [ "$task_priority" = "P2" ] && [ "$med_count" -gt 0 ] && task_priority="P1"

      cat > "$task_path" <<EOF
---
title: "$task_id — Post-merge review ($date_iso, $short_host)"
type: task
status: not-started
priority: $task_priority
parent_module: "cross-project-merge-governance"
current_stage: document
readiness: 0
created: $date_iso
updated: $date_iso
tags: [task, $task_priority, ${task_id,,}, post-merge-review, security-review, governance, $short_host]
---

# $task_id — Post-merge review ($date_iso, $short_host)

## Description

A merge-from-backup.sh \`--apply\` run on \`$short_host\` produced changes to the working tree. This task captures the operator/AI review work to ensure the merged state is clean, non-contradictory, and secure.

**Audit log**: \`$([ -n "$log_path" ] && basename "$log_path" || echo "(see merge run output)")\`

## Counts

- Applied changes: $(manifest_count applied)
- Surfaced for manual decision: $(manifest_count surfaced)
- Security flags: $(manifest_count flagged) ($high_count HIGH, $med_count MED)
- Skipped (no diff): $(manifest_count skipped)

## Done When

- [ ] Read the audit log entry: \`wiki/log/$date_iso-merge-from-backup-$short_host.md\`
EOF

      if [ "$high_count" -gt 0 ]; then
        cat >> "$task_path" <<EOF
- [ ] **HIGH-severity security flags resolved**: investigate each \`HIGH\` flag from the audit log; either confirm intentional + document rationale, OR revert via \`.pre-merge.bak\` / \`$RM_BACKUP_DIR_DEFAULT/\`
EOF
      fi
      if [ "$med_count" -gt 0 ]; then
        cat >> "$task_path" <<EOF
- [ ] **MED-severity flags reviewed**: each \`MED\` flag — confirm intentional or take corrective action
EOF
      fi

      cat >> "$task_path" <<EOF
- [ ] Each applied change reviewed for:
  - [ ] Security: does it grant capabilities the agent shouldn't have?
  - [ ] Consistency: does it contradict the project's spec (CLAUDE.md, AGENTS.md, methodology engine)?
  - [ ] Synthesis: should it be promoted into the project's spec for future installs (so it's not just per-machine drift)?
- [ ] Each surfaced item triaged:
  - [ ] Custom hooks: vetted (no curl-pipe-shell, no rev-shell, no history-wipe) and either copied back, kept in backup, or discarded
  - [ ] Custom rules: reviewed and copied back if alignment is good
  - [ ] \`.gitignore\` additions: reconciled with the deny-all-then-whitelist invariant or rejected
- [ ] If recurring patterns emerge across multiple merge runs (different machines):
  - [ ] Open an epic \`cross-project-merge-governance\` (or extend if exists) to track the pattern
  - [ ] Consider promoting recurring items into the project's spec
- [ ] Validate post-review: \`bash scripts/merge-from-backup.sh --validate\`
- [ ] Update task status to \`done\` once review complete

## Dependencies

- \`scripts/merge-from-backup.sh --apply\` run (already complete — this task is generated by it)
- Operator availability for security-flag triage (if any HIGH flags)

## Anti-patterns to avoid

- Don't auto-accept all merged changes without per-item security review
- Don't delete \`$RM_BACKUP_DIR_DEFAULT/\` until the full review is signed off
- Don't promote per-machine state into project spec without operator confirmation (drift accumulates fast)
- Don't ignore HIGH flags — those block the apply by default; if you saw them applied via \`--accept-security-flags\`, they need explicit justification

## Relationships

- COMPANION TO: audit log at \`wiki/log/$date_iso-merge-from-backup-$short_host.md\`
- PART OF: \`cross-project-merge-governance\` (parent module — create if first)
- INFORMS: project spec evolution if patterns recur (per spec-driven-evolution principle)
- USED BY: operator/AI agent post-merge synthesis cycle
EOF
      ok "follow-up task written: $task_path"

      # Append cross-reference back to the log if we wrote it
      if [ -n "$log_path" ]; then
        local task_basename
        task_basename=$(basename "$task_path" .md)
        sed -i "s|wiki/backlog/tasks/T<NEXT>-post-merge-review-$date_iso-$short_host.md|wiki/backlog/tasks/$task_basename.md|g" "$log_path"
      fi
    else
      warn "tasks dir $tasks_dir not found — skipping task generation"
    fi
  fi

  # ---------- Print summary ----------
  hdr "Merge governance summary"
  say "Applied:  $(manifest_count applied)"
  say "Surfaced: $(manifest_count surfaced) (manual decision needed)"
  say "Flagged:  $(manifest_count flagged) (security review)"
  say "Skipped:  $(manifest_count skipped)"
  if [ -n "$log_path" ]; then
    say ""
    ok "Audit log:    $log_path"
  fi
  if [ -n "$task_path" ]; then
    ok "Follow-up:    $task_path"
  fi
  if manifest_has_high_flags; then
    warn "HIGH-severity flags detected — see follow-up task; resolve before declaring merge clean"
  fi
}
