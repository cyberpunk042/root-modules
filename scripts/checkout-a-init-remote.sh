#!/usr/bin/env bash
# checkout-a-init-remote.sh
# ----------------------------------------------------------------------
# PATH A: checkout root-modules directly INTO $HOME via git init + remote.
# For: operators wanting their $HOME == repo working tree (active dev mode).
#
# Run on TARGET MACHINE, FROM $HOME:
#   cd $HOME
#   bash /tmp/checkout-a-init-remote.sh [REPO_URL]
#
# What this does:
#   1. Pre-flight: cwd is $HOME, $HOME is non-empty, REPO_URL provided,
#      gh CLI ready (for credential fetch if needed)
#   2. Backup CONFLICT POINTS (.claude/settings.json, .config/opencode/opencode.json,
#      and a few other potentially-overlapping files) into .pre-ghostproxy.bak/
#   3. git init + remote add + fetch
#   4. git checkout -f origin/main  (forces over name-conflicts; UNTRACKED files
#      in $HOME are completely untouched per the repo's deny-all .gitignore)
#   5. Rename branch master → main (if needed)
#   6. Set upstream, commit-author config check
#   7. Print MERGE-FROM-BACKUP instructions (manual step — operator merges
#      .claude/settings.json + .config/opencode/opencode.json from backup if
#      they had pre-existing config)
#
# Default: DRY-RUN. Pass --execute to actually mutate.
# ----------------------------------------------------------------------

set -euo pipefail

EXECUTE=0
REPO_URL=""
for arg in "$@"; do
  case "$arg" in
    --execute) EXECUTE=1 ;;
    -h|--help)
      sed -n '2,32p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    --*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) REPO_URL="$arg" ;;
  esac
done

say()  { printf "  %s\n" "$*"; }
hdr()  { printf "\n──── %s ────\n" "$*"; }
ok()   { printf "  ✓ %s\n" "$*"; }
warn() { printf "  ⚠ %s\n" "$*"; }
fail() { printf "  ✗ %s\n" "$*" >&2; exit 1; }
run()  {
  if [ "$EXECUTE" = "1" ]; then printf "  $ %s\n" "$*"; eval "$*"
  else printf "  [DRY-RUN] $ %s\n" "$*"; fi
}

# ---------- Pre-flight ----------
hdr "Pre-flight (Path A: init + remote into existing \$HOME)"

[ -z "$REPO_URL" ] && fail "REPO_URL not provided. Usage: bash $0 [--execute] <repo-url>"
ok "REPO_URL = $REPO_URL"

[ "$(pwd)" = "$HOME" ] || fail "Must run from \$HOME (cwd=$(pwd), HOME=$HOME)"
ok "cwd is \$HOME ($HOME)"

[ -d .git ] && fail ".git already exists in \$HOME — this script is for first-time checkout. Delete .git or run from elsewhere."
ok "no existing .git"

command -v git >/dev/null || fail "git not installed"
ok "git: $(git --version)"

# ---------- Step 1 — backup conflict points ----------
hdr "Step 1 — backup conflict points"

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

BACKUP_DIR=".pre-ghostproxy.bak"
ANY_BACKED_UP=0

for f in "${CONFLICT_FILES[@]}"; do
  if [ -f "$f" ]; then
    say "found existing $f"
    run "mkdir -p '$BACKUP_DIR/$(dirname "$f")'"
    run "cp -a '$f' '$BACKUP_DIR/$f'"
    ANY_BACKED_UP=1
  fi
done

for d in "${CONFLICT_DIRS_FOR_HOOKS_RULES[@]}"; do
  if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
    say "found non-empty $d/"
    run "mkdir -p '$BACKUP_DIR/$d-existing'"
    run "cp -a '$d/.' '$BACKUP_DIR/$d-existing/'"
    ANY_BACKED_UP=1
  fi
done

if [ "$ANY_BACKED_UP" = "0" ]; then
  ok "no conflict points present in \$HOME — clean checkout expected"
else
  ok "conflict points backed up to $BACKUP_DIR/ — manual merge needed post-checkout (Step 8)"
fi

# ---------- Step 2 — git init ----------
hdr "Step 2 — git init"
run "git init -b main"
ok "initialized empty repo on branch 'main'"

# ---------- Step 3 — remote add ----------
hdr "Step 3 — remote add"
run "git remote add origin $REPO_URL"
ok "remote 'origin' = $REPO_URL"

# ---------- Step 4 — fetch ----------
hdr "Step 4 — fetch"
run "git fetch origin"
if [ "$EXECUTE" = "1" ]; then
  REMOTE_BRANCH=$(git ls-remote --heads origin | awk '{print $2}' | sed 's|refs/heads/||' | grep -E '^(main|master)$' | head -1)
  [ -z "$REMOTE_BRANCH" ] && fail "could not detect remote default branch"
  ok "remote default branch: $REMOTE_BRANCH"
else
  REMOTE_BRANCH="main"
  say "[DRY-RUN] assuming remote branch = main"
fi

# ---------- Step 5 — checkout -f ----------
hdr "Step 5 — checkout -f origin/$REMOTE_BRANCH"
say "files in repo's whitelist that exist in \$HOME will be OVERWRITTEN."
say "files NOT in repo's whitelist (.bashrc, .ssh/, .cache/, .gitconfig, etc.) UNTOUCHED."
run "git checkout -f origin/$REMOTE_BRANCH"
ok "working tree synced with origin/$REMOTE_BRANCH"

# Branch alignment
if [ "$REMOTE_BRANCH" = "master" ]; then
  warn "remote uses 'master' but local is 'main' — aligning"
  run "git branch -m main master"
fi
run "git branch --set-upstream-to=origin/$REMOTE_BRANCH"

# ---------- Step 6 — git config sanity ----------
hdr "Step 6 — git config sanity"
if [ -z "$(git config user.name 2>/dev/null)" ]; then
  warn "git user.name unset — set it before committing"
  say "  git config user.name 'Your Name'"
fi
if [ -z "$(git config user.email 2>/dev/null)" ]; then
  warn "git user.email unset — set it before committing"
  say "  git config user.email 'you@example.com'"
fi

# ---------- Step 7 — verify clean state ----------
hdr "Step 7 — verify clean state"
if [ "$EXECUTE" = "1" ]; then
  STATUS=$(git status --porcelain 2>/dev/null | wc -l)
  if [ "$STATUS" = "0" ]; then
    ok "git status clean — repo + \$HOME aligned"
  else
    warn "git status shows $STATUS modified/staged paths — review before committing"
  fi
fi

# ---------- Step 8 — manual merge instructions ----------
hdr "Step 8 — POST-CHECKOUT MERGE (manual)"
if [ "$ANY_BACKED_UP" = "1" ]; then
  cat <<EOF
  Backups in $BACKUP_DIR/ contain your prior config.
  The repo's versions are now in place. Manual merge needed:

  1. .claude/settings.json
       Compare $BACKUP_DIR/.claude/settings.json (yours) with current .claude/settings.json (repo's).
       Merge: keep repo's hooks; preserve your custom permissions allow-list.
       Suggested: vimdiff or jq-based merge.

  2. .config/opencode/opencode.json
       Same pattern — keep repo's bridge plugin config; preserve your custom settings.

  3. .claude/hooks-existing/ + .claude/rules-existing/
       Custom hooks/rules you had that DON'T conflict with repo names — copy back:
         cp -a $BACKUP_DIR/.claude/hooks-existing/your-custom-hook.sh .claude/hooks/
         cp -a $BACKUP_DIR/.claude/rules-existing/your-custom-rule.md .claude/rules/

  4. .gitignore (rare in \$HOME)
       Repo's deny-all-then-whitelist supersedes yours. If you had personal exclusions,
       add them to repo's .gitignore (operator's policy decision).

  After manual merge, verify .claude/settings.json is valid JSON:
    python3 -c "import json; json.load(open('.claude/settings.json'))"

  If you'd rather skip the merge, your prior config is preserved in $BACKUP_DIR/
  for future reference.
EOF
else
  ok "no conflict points existed — no merge needed"
fi

# ---------- Done ----------
hdr "Done"
if [ "$EXECUTE" = "1" ]; then
  ok "Path A complete: \$HOME is now a working tree of $REPO_URL on branch $REMOTE_BRANCH"
  say "next: review .claude/ + .config/opencode/ merges, then 'git pull' for updates"
else
  say "Dry-run complete. Re-run with --execute to actually checkout."
fi
