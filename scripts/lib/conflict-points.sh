#!/usr/bin/env bash
# scripts/lib/conflict-points.sh — single source of truth for conflict points.
#
# When root-modules is checked out into an existing $HOME (Path A flow),
# certain files in the repo's whitelist may collide with files the operator
# already has. These arrays enumerate exactly which paths matter.
#
# CONFLICT_FILES                 — files that get backed up + may be overwritten
#                                  by `git checkout -f origin/main`. The merge
#                                  script reconciles backup ↔ checked-out state.
#
# CONFLICT_DIRS_FOR_HOOKS_RULES  — directories holding operator-custom hooks /
#                                  rules. Backup preserves them; merge surfaces
#                                  unique items the operator can manually copy
#                                  back if desired.
#
# Files NOT in either array are NOT in the repo's `.gitignore` whitelist, so
# `git checkout` doesn't touch them. Things like .bashrc, .profile, .ssh/,
# .gitconfig, .cache/, .local/, .npm/, etc. stay untouched on Path A.
#
# Re-source guard:
[ -n "${RGP_LIB_CONFLICT_POINTS_SOURCED:-}" ] && return 0
RGP_LIB_CONFLICT_POINTS_SOURCED=1

CONFLICT_FILES=(
  ".claude/settings.json"
  ".config/opencode/opencode.json"
  ".gitignore"
  ".claudeignore"
  ".mcp.json"
)

CONFLICT_DIRS_FOR_HOOKS_RULES=(
  ".claude/hooks"
  ".claude/rules"
)

# Standard backup directory name.
RGP_BACKUP_DIR_DEFAULT=".pre-ghostproxy.bak"
