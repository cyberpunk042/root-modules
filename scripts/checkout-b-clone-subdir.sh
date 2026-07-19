#!/usr/bin/env bash
# checkout-b-clone-subdir.sh
# ----------------------------------------------------------------------
# PATH B: clone root-modules into a SUBDIRECTORY of $HOME (or anywhere).
# Doesn't touch $HOME files. Repo is its own workspace; install.sh
# (when ready) handles the actual deployment into $HOME.
#
# For: operators wanting to read/work with the repo as a separate project,
# without conflating $HOME state with repo working tree.
#
# Run on TARGET MACHINE:
#   bash /tmp/checkout-b-clone-subdir.sh [REPO_URL] [TARGET_DIR]
#
# Defaults:
#   REPO_URL    : (none — must provide as $1)
#   TARGET_DIR  : $HOME/root-modules
#
# What this does:
#   1. Pre-flight: REPO_URL provided, TARGET_DIR doesn't already exist
#      (or is empty), git installed
#   2. git clone REPO_URL TARGET_DIR
#   3. Print discovery summary (key files for orientation)
#   4. Surface install.sh / uninstall.sh state + caveats
#
# Default: DRY-RUN. Pass --execute to actually mutate.
# ----------------------------------------------------------------------

set -euo pipefail

EXECUTE=0
REPO_URL=""
TARGET_DIR=""
for arg in "$@"; do
  case "$arg" in
    --execute) EXECUTE=1 ;;
    -h|--help)
      sed -n '2,28p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    --*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *)
      if [ -z "$REPO_URL" ]; then REPO_URL="$arg"
      elif [ -z "$TARGET_DIR" ]; then TARGET_DIR="$arg"
      else fail "too many positional args"
      fi
      ;;
  esac
done

[ -z "$TARGET_DIR" ] && TARGET_DIR="$HOME/root-modules"

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
hdr "Pre-flight (Path B: clone to subdir)"

[ -z "$REPO_URL" ] && fail "REPO_URL not provided. Usage: bash $0 [--execute] <repo-url> [target-dir]"
ok "REPO_URL    = $REPO_URL"
ok "TARGET_DIR  = $TARGET_DIR"

if [ -e "$TARGET_DIR" ]; then
  if [ -d "$TARGET_DIR" ] && [ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
    ok "TARGET_DIR exists but is empty — clone OK"
  else
    fail "TARGET_DIR exists and is non-empty: $TARGET_DIR — pick another path or remove first"
  fi
fi

command -v git >/dev/null || fail "git not installed"
ok "git: $(git --version)"

# ---------- Step 1 — clone ----------
hdr "Step 1 — clone"
run "git clone '$REPO_URL' '$TARGET_DIR'"

# ---------- Step 2 — discovery summary ----------
hdr "Step 2 — discovery summary"
if [ "$EXECUTE" = "1" ]; then
  cd "$TARGET_DIR"
  say "Top-level entries:"
  ls -A | head -25 | sed 's/^/    /'
  say ""
  if [ -f README.md ]; then
    say "README.md size: $(wc -c < README.md) bytes, $(wc -l < README.md) lines"
    say "First heading: $(grep -m1 '^# ' README.md || echo '(none)')"
  fi
  if [ -f BOOTSTRAP.md ]; then
    say "BOOTSTRAP.md present — read this first for cold-pickup orientation"
  fi
  if [ -f CLAUDE.md ]; then
    say "CLAUDE.md present — operational program for Claude Code"
  fi
  if [ -f install.sh ]; then
    say "install.sh present (size: $(wc -c < install.sh) bytes, executable: $([ -x install.sh ] && echo yes || echo no))"
  fi
  if [ -f LICENSE ]; then
    LICENSE_TYPE=$(head -1 LICENSE 2>/dev/null || echo "unknown")
    say "LICENSE present: $LICENSE_TYPE"
  fi
fi

# ---------- Step 3 — install.sh caveats ----------
hdr "Step 3 — install.sh deployment caveats"
cat <<'EOF'
  This is Path B — REPO is in a subdir, $HOME is UNTOUCHED.
  install.sh deploys content into the actual host config:

  - Currently install.sh is at SCAFFOLD stage (per project's SFIF model).
  - Foundation hardening (M003) + Infrastructure tooling (M004) + vendor
    mapping / fresh-machine install (M012) are pending.
  - install.sh --dry-run should work; full end-to-end install pending those
    modules.

  When install.sh is deployment-ready, run from $TARGET_DIR:
    cd $TARGET_DIR
    ./install.sh --dry-run     # preview
    ./install.sh               # actually install (when ready)

  In the meantime, you can:
  - Read brain files (BOOTSTRAP.md, README.md, CLAUDE.md, AGENTS.md, etc.)
  - Browse wiki/{config,backlog,log}/ for methodology + tasks + history
  - Test individual hooks/scripts manually

  The repo's deny-all-then-whitelist .gitignore is calibrated for $HOME=
  repo-root (Path A scenario). At this subdir location, the .gitignore
  still works correctly (it's relative to the repo root, which is now
  $TARGET_DIR), but you'll see the deny-all behavior only WITHIN that
  subdir tree — your $HOME is unaffected.

EOF

# ---------- Done ----------
hdr "Done"
if [ "$EXECUTE" = "1" ]; then
  ok "Path B complete: $REPO_URL cloned to $TARGET_DIR"
  say "next: read $TARGET_DIR/BOOTSTRAP.md, then $TARGET_DIR/README.md"
  say "      run install.sh --dry-run when you want to test deployment"
else
  say "Dry-run complete. Re-run with --execute to actually clone."
fi
