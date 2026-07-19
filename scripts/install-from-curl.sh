#!/usr/bin/env bash
# install-from-curl.sh
# ----------------------------------------------------------------------
# One-liner bootstrap for root-modules. Designed for `curl … | bash`.
#
# Naturally does the right thing:
#   • TTY detected (interactive possible) → asks mode + target upfront, then
#     executes the chosen path one-shot (including post-checkout merge when MODE=A)
#   • No TTY (script piped from non-tty source) → MODE=B safe default
#     (clone to subdir; $HOME untouched; no merge needed)
#
# Modes:
#   MODE=B  (default safe) — clone to TARGET subdir; $HOME UNTOUCHED.
#                            No merge needed. Repo lands as a self-contained
#                            workspace; install.sh handles deployment later.
#
#   MODE=A  (advanced)     — git init in $HOME + remote + checkout -f.
#                            Backs up conflict points to .pre-ghostproxy.bak/
#                            FIRST, then runs scripts/merge-from-backup.sh
#                            in --apply mode (per-change confirmation) to
#                            reconcile additive changes back from your backup.
#                            Validates JSON post-merge.
#
# Flags:
#   --interactive    force interactive prompts even if TTY auto-detect fails
#   --auto           force non-interactive defaults (MODE=B, no prompts)
#   -h, --help
#
# Environment overrides (skip prompts for that field):
#   REPO_URL    https://github.com/cyberpunk042/root-modules.git
#   BRANCH      main
#   MODE        B | A    (skip mode prompt)
#   TARGET      <path>   (only used in MODE=B; skip target prompt)
#   ASSUME_YES  1        (skip MODE=A risk-confirmation prompt)
#
# One-shot examples:
#   curl … | bash                                        # interactive if TTY, else MODE=B
#   curl … | MODE=A bash                                 # force MODE=A (still prompts for risks unless ASSUME_YES=1)
#   curl … | MODE=B TARGET=$HOME/rgp bash                # MODE=B to a custom target
#   curl … | bash -s -- --auto                           # force non-interactive
#   curl … | bash -s -- --interactive                    # force prompts
# ----------------------------------------------------------------------

set -euo pipefail

# ---------- Defaults ----------
REPO_URL="${REPO_URL:-https://github.com/cyberpunk042/root-modules.git}"
BRANCH="${BRANCH:-main}"
MODE="${MODE:-}"
TARGET="${TARGET:-}"
ASSUME_YES="${ASSUME_YES:-0}"
# Install scope choices (env-overridable; prompted in interactive mode)
INSTALL_PROFILE="${INSTALL_PROFILE:-}"        # base | full | interactive | skip (no install run)
GHOSTPROXY_MODE="${GHOSTPROXY_MODE:-}"        # bridge | endpoint | hybrid | auto
STATUSLINE_PROFILE="${STATUSLINE_PROFILE:-}"  # none | base | standard | project | intermediary | full-aidlc
INSTALL_DRY_RUN="${INSTALL_DRY_RUN:-}"        # 1 = pass --dry-run to install.sh (default: 1 for safety)

# ---------- Args ----------
INTERACTIVE_FORCE=""
for arg in "$@"; do
  case "$arg" in
    --interactive) INTERACTIVE_FORCE="yes" ;;
    --auto)        INTERACTIVE_FORCE="no" ;;
    -h|--help)     sed -n '2,40p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *)             echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# ---------- Helpers ----------
say()   { printf "  %s\n" "$*"; }
hdr()   { printf "\n──── %s ────\n" "$*"; }
ok()    { printf "  ✓ %s\n" "$*"; }
warn()  { printf "  ⚠ %s\n" "$*"; }
fail()  { printf "  ✗ %s\n" "$*" >&2; exit 1; }
info()  { printf "  i %s\n" "$*"; }

# Detect interactive: TTY readable (handles curl|bash where stdin is the
# script content but /dev/tty may still be available)
INTERACTIVE=0
if [ -n "$INTERACTIVE_FORCE" ]; then
  [ "$INTERACTIVE_FORCE" = "yes" ] && INTERACTIVE=1
elif [ -r /dev/tty ]; then
  # Verify we can actually read from it (some sandboxed environments expose
  # /dev/tty but reads block forever)
  INTERACTIVE=1
fi

# Read from /dev/tty (works under curl|bash); fall back to default if non-interactive
ask() {
  # ask "<prompt>" "<default>"  — returns user input or default if non-interactive
  local prompt="$1" default="$2" ans
  if [ "$INTERACTIVE" = "1" ]; then
    read -r -p "  $prompt [$default]: " ans </dev/tty || ans="$default"
    [ -z "$ans" ] && ans="$default"
    echo "$ans"
  else
    echo "$default"
  fi
}

confirm() {
  # confirm "<prompt>"  — y/N; non-interactive returns NO (safety-first)
  local ans
  if [ "$INTERACTIVE" = "1" ]; then
    read -r -p "  $1 (y/N): " ans </dev/tty || ans="N"
    case "$ans" in y|Y|yes) return 0 ;; *) return 1 ;; esac
  else
    return 1
  fi
}

# run_install_and_statusline <repo-dir>
#   After clone/checkout, invokes install.sh with chosen profile/mode/options,
#   then activates the statusline profile via switch-profile.sh if applicable.
run_install_and_statusline() {
  local repo_dir="$1"
  local install_sh="$repo_dir/install.sh"

  if [ "$INSTALL_PROFILE" = "skip" ]; then
    info "INSTALL_PROFILE=skip — install.sh NOT invoked. Run it manually when ready:"
    info "  cd $repo_dir && ./install.sh --wizard       # state-aware 'where you are + what to do next' report"
    info "  cd $repo_dir && ./install.sh --help         # all flags + profiles + examples"
    info "  cd $repo_dir && ./install.sh --dry-run      # preview default base profile install"
    return 0
  fi

  if [ ! -x "$install_sh" ]; then
    warn "$install_sh not found or not executable — skipping install step"
    return 0
  fi

  local install_args=(--profile "$INSTALL_PROFILE" --mode "$GHOSTPROXY_MODE")
  [ "$STATUSLINE_PROFILE" != "none" ] && install_args+=(--with-ccstatusline)
  [ "$INSTALL_DRY_RUN" = "1" ] && install_args+=(--dry-run)
  [ "$ASSUME_YES" = "1" ] && install_args+=(--yes)

  hdr "Run install.sh"
  info "command: $install_sh ${install_args[*]}"
  if bash "$install_sh" "${install_args[@]}"; then
    ok "install.sh completed"

    # P7 of wizard design: post-install handoff. Surface the state-aware
    # "where you are + what to do next" report so operator sees the natural
    # progression from base install → optional follow-ups (wifi, integrity,
    # ccstatusline, per-project install, drift-check). Skip in --dry-run since
    # post-install state isn't real.
    if [ "$INSTALL_DRY_RUN" != "1" ]; then
      hdr "Wizard handoff"
      info "Running: $install_sh --wizard (state-aware next-best-actions report)"
      bash "$install_sh" --wizard 2>&1 || true
    fi
  else
    warn "install.sh exited non-zero — review output above"
    info "Try: $install_sh --wizard (state-aware report) OR $install_sh --check (drift report)"
  fi

  if [ "$STATUSLINE_PROFILE" != "none" ]; then
    if [ "$INSTALL_DRY_RUN" = "1" ]; then
      info "STATUSLINE_PROFILE=$STATUSLINE_PROFILE chosen but install was --dry-run; switch-profile.sh deferred"
      info "to activate later (after real install): bash $repo_dir/templates/ccstatusline-config/switch-profile.sh $STATUSLINE_PROFILE"
    else
      hdr "Activate statusline profile: $STATUSLINE_PROFILE"
      local switch_sh="$repo_dir/templates/ccstatusline-config/switch-profile.sh"
      if [ ! -x "$switch_sh" ]; then
        warn "switch-profile.sh not found at $switch_sh — statusline profile NOT activated"
      elif [ ! -f "$HOME/.config/ccstatusline/profile-$STATUSLINE_PROFILE.json" ]; then
        warn "$HOME/.config/ccstatusline/profile-$STATUSLINE_PROFILE.json not found"
        warn "install.sh --with-ccstatusline op may still be scaffold (templates not yet copied)."
        warn "manual stop-gap:"
        warn "  mkdir -p \$HOME/.config/ccstatusline"
        warn "  cp -a $repo_dir/templates/ccstatusline-config/profile-*.json \$HOME/.config/ccstatusline/"
        warn "  cp -a $repo_dir/templates/ccstatusline-config/claude-code-statusline-wrapper.sh \$HOME/.config/ccstatusline/"
        warn "then: bash $switch_sh $STATUSLINE_PROFILE"
      else
        if bash "$switch_sh" "$STATUSLINE_PROFILE"; then
          ok "statusline profile activated: $STATUSLINE_PROFILE"
        else
          warn "switch-profile.sh failed — review output"
        fi
      fi
    fi
  fi
}

# ---------- Header ----------
cat <<'EOF'

╔══════════════════════════════════════════════════════════════════════╗
║          root-modules — curl-bash bootstrap (one-shot)            ║
╚══════════════════════════════════════════════════════════════════════╝
EOF

if [ "$INTERACTIVE" = "1" ]; then
  info "TTY detected — interactive mode"
else
  info "non-interactive mode (no TTY or --auto) — MODE=B safe default will be used unless MODE env var set"
fi
say "REPO_URL : $REPO_URL"
say "BRANCH   : $BRANCH"

# ---------- Pre-flight: git ----------
hdr "Pre-flight"
if ! command -v git >/dev/null 2>&1; then
  warn "git not installed"
  if [ "$INTERACTIVE" = "1" ] && [ -f /etc/debian_version ]; then
    if confirm "install git via apt-get?"; then
      sudo apt-get update && sudo apt-get install -y git || fail "apt-get install git failed"
    else
      fail "git missing — install manually and re-run"
    fi
  else
    fail "git missing — install manually and re-run (non-interactive mode skips auto-install)"
  fi
fi
ok "git: $(git --version)"

# Check repo reachable
if ! git ls-remote --exit-code "$REPO_URL" "$BRANCH" >/dev/null 2>&1; then
  fail "cannot reach $REPO_URL branch=$BRANCH (private repo? need auth? wrong URL?)"
fi
ok "remote $REPO_URL branch=$BRANCH reachable"

# ---------- Choose MODE ----------
hdr "Mode selection"
if [ -z "$MODE" ]; then
  if [ "$INTERACTIVE" = "1" ]; then
    cat <<'EOF'
  Two installation modes:

    [B] safe default  — clone repo to a subdirectory ($HOME/root-modules/).
                        $HOME UNTOUCHED. Read + test the repo there.
                        install.sh handles deployment when ready.

    [A] advanced      — git init in $HOME so $HOME == repo working tree.
                        Backs up your .claude/settings.json + .config/opencode/
                        opencode.json + a few others to .pre-ghostproxy.bak/
                        FIRST, then checkout -f overwrites them with repo
                        versions, THEN runs the surgical merge script to
                        reconcile additive changes back from your backup.

EOF
    MODE_CHOICE=$(ask "Mode (B safe / A advanced)" "B")
    case "$MODE_CHOICE" in
      A|a) MODE=A ;;
      *)   MODE=B ;;
    esac
  else
    MODE=B
    info "non-interactive — defaulting to MODE=B (safe)"
  fi
fi
ok "MODE = $MODE"

# ---------- Choose TARGET (MODE=B only) ----------
if [ "$MODE" = "B" ] && [ -z "$TARGET" ]; then
  if [ "$INTERACTIVE" = "1" ]; then
    TARGET=$(ask "Clone target dir" "$HOME/root-modules")
  else
    TARGET="$HOME/root-modules"
  fi
fi

# ---------- Choose INSTALL_PROFILE ----------
hdr "Install scope (which level of install do you want?)"
if [ -z "$INSTALL_PROFILE" ]; then
  if [ "$INTERACTIVE" = "1" ]; then
    cat <<'EOF'
  Install scope determines what install.sh runs after the clone:

    [skip]         clone only, do NOT run install.sh
                   (operator inspects + decides later; recommended for first encounter)
    [base]         foundation only — endpoint AI safety policy + opencode bridge
                   + integrity sentinel. No facultative network/IPS modules.
    [full]         base + ALL facultative modules (Suricata IPS, PolarProxy TLS,
                   ccstatusline, etc.) — currently implement-stage per M005/M011/M014.
    [interactive]  install.sh prompts per-operation (TUI inside install.sh).

  Note: install.sh is currently SCAFFOLD-TIER. Implementations are stubs (TODOs).
  Running it now is safe (--dry-run will be applied by default). Full execution
  requires M003+M004+M011+M012 modules to land.

EOF
    INSTALL_PROFILE_CHOICE=$(ask "Install scope (skip / base / full / interactive)" "skip")
    case "$INSTALL_PROFILE_CHOICE" in
      base|full|interactive|skip) INSTALL_PROFILE="$INSTALL_PROFILE_CHOICE" ;;
      *) info "unrecognized; defaulting to skip"; INSTALL_PROFILE="skip" ;;
    esac
  else
    INSTALL_PROFILE="skip"
    info "non-interactive — defaulting to INSTALL_PROFILE=skip (clone only)"
  fi
fi
ok "INSTALL_PROFILE = $INSTALL_PROFILE"

# ---------- Choose GHOSTPROXY_MODE + STATUSLINE_PROFILE (only if running install) ----------
if [ "$INSTALL_PROFILE" != "skip" ]; then
  hdr "Ghostproxy mode (which OS-config role on this host)"
  if [ -z "$GHOSTPROXY_MODE" ]; then
    if [ "$INTERACTIVE" = "1" ]; then
      cat <<'EOF'
  Ghostproxy mode determines which install.sh operations apply:

    [auto]      detect from host (interface count, bridge tools available)
    [endpoint]  this host runs Claude Code/opencode locally; no L2 bridge ops
    [bridge]    this host acts as transparent L2 IPS bridge (network ops apply)
    [hybrid]    both — endpoint AI safety + bridge IPS on same host

EOF
      GP_CHOICE=$(ask "Ghostproxy mode (auto / endpoint / bridge / hybrid)" "auto")
      case "$GP_CHOICE" in
        auto|endpoint|bridge|hybrid) GHOSTPROXY_MODE="$GP_CHOICE" ;;
        *) info "unrecognized; defaulting to auto"; GHOSTPROXY_MODE="auto" ;;
      esac
    else
      GHOSTPROXY_MODE="auto"
    fi
  fi
  ok "GHOSTPROXY_MODE = $GHOSTPROXY_MODE"

  hdr "Statusline profile (M011 — ccstatusline custom widget)"
  if [ -z "$STATUSLINE_PROFILE" ]; then
    if [ "$INTERACTIVE" = "1" ]; then
      cat <<'EOF'
  Statusline profile picks which Claude Code statusline config to activate.
  Profile JSONs live at templates/ccstatusline-config/ in the cloned repo.

    [none]          do not install or activate ccstatusline
    [base]          minimal — model + mode + cost (always-useful core widgets)
    [standard]      session-aware — base + tokens, branch, version
    [project]       project-aware — adds selected-task + stage progress (M011 widget set)
    [intermediary]  standard + a few aidlc widgets (model, sfif, readiness)
    [full-aidlc]    project + full aidlc widget set (blockers, decisions, sfif,
                    readiness, tasks-progress, mode, model, open-sbs)

  Choosing anything other than [none] adds --with-ccstatusline to the install.sh
  invocation + activates the chosen profile via switch-profile.sh after install.

EOF
      SL_CHOICE=$(ask "Statusline profile (none / base / standard / project / intermediary / full-aidlc)" "none")
      case "$SL_CHOICE" in
        none|base|standard|project|intermediary|full-aidlc) STATUSLINE_PROFILE="$SL_CHOICE" ;;
        *) info "unrecognized; defaulting to none"; STATUSLINE_PROFILE="none" ;;
      esac
    else
      STATUSLINE_PROFILE="none"
    fi
  fi
  ok "STATUSLINE_PROFILE = $STATUSLINE_PROFILE"

  if [ -z "$INSTALL_DRY_RUN" ]; then
    if [ "$INTERACTIVE" = "1" ]; then
      if confirm "Pass --dry-run to install.sh (preview only)? — STRONGLY RECOMMENDED while install.sh is scaffold"; then
        INSTALL_DRY_RUN=1
      else
        INSTALL_DRY_RUN=0
      fi
    else
      INSTALL_DRY_RUN=1
    fi
  fi
  ok "INSTALL_DRY_RUN = $INSTALL_DRY_RUN"
fi

# ---------- MODE=B: clone to subdir ----------
if [ "$MODE" = "B" ]; then
  hdr "MODE=B — clone to $TARGET"
  if [ -e "$TARGET" ]; then
    if [ -d "$TARGET" ] && [ -z "$(ls -A "$TARGET" 2>/dev/null)" ]; then
      ok "$TARGET exists but is empty — clone OK"
    else
      fail "$TARGET exists and is non-empty. Set TARGET=<other-path> or remove first."
    fi
  fi

  git clone --branch "$BRANCH" "$REPO_URL" "$TARGET"
  ok "cloned to $TARGET"
  cd "$TARGET"

  hdr "Discovery"
  say "Top-level entries:"
  ls -A | head -25 | sed 's/^/    /'
  if [ -f BOOTSTRAP.md ]; then say "BOOTSTRAP.md present — read first for cold-pickup orientation"; fi
  if [ -f install.sh ];   then say "install.sh present (currently implement-stage; --dry-run works)"; fi
  if [ -f LICENSE ];      then say "LICENSE present"; fi

  # Run install.sh with chosen profile/mode/options + activate statusline
  run_install_and_statusline "$TARGET"

  hdr "Done"
  ok "MODE=B complete. \$HOME UNTOUCHED."
  cat <<EOF
  Next steps:
    cd $TARGET
    less BOOTSTRAP.md
    ./install.sh --help            # see all install options
    ./install.sh --dry-run         # preview what install.sh would do

  To upgrade to MODE=A later (\$HOME == repo working tree):
    cd $HOME
    bash $TARGET/scripts/checkout-a-init-remote.sh --execute $REPO_URL
    bash $TARGET/scripts/merge-from-backup.sh                # diff first
    bash $TARGET/scripts/merge-from-backup.sh --apply        # then per-change apply

  To switch statusline profile later:
    bash $TARGET/templates/ccstatusline-config/switch-profile.sh list
    bash $TARGET/templates/ccstatusline-config/switch-profile.sh <profile>

EOF
  exit 0
fi

# ---------- MODE=A: full one-shot flow ----------
hdr "MODE=A — full flow (backup → checkout → merge → validate)"

if [ "$ASSUME_YES" != "1" ]; then
  cat <<EOF
  MODE=A will:
    1. Backup .claude/settings.json + .config/opencode/opencode.json + a few
       other potentially-conflicting files to \$HOME/.pre-ghostproxy.bak/
    2. git init in \$HOME + remote add + git checkout -f origin/$BRANCH
       (overrides repo-whitelisted files in \$HOME with repo versions; files
        NOT in repo whitelist — .bashrc, .ssh/, .gitconfig, .cache/, etc. —
        stay UNTOUCHED)
    3. Run scripts/merge-from-backup.sh --apply (interactive per-change
       prompts) to reconcile your customizations from backup back into the
       repo's settings.json + opencode.json (additive only; surgical)
    4. Validate JSON files post-merge

  RECOVERY: .pre-ghostproxy.bak/ keeps your prior config intact.
            If anything looks wrong post-flow, restore from there.

EOF
  if ! confirm "Proceed with MODE=A?"; then
    fail "aborted by user"
  fi
fi

cd "$HOME"
[ -d .git ] && fail ".git already exists in \$HOME — use scripts/checkout-a-init-remote.sh manually for advanced control"

# ---------- Step 1: backup ----------
hdr "Step 1 — backup conflict points"
BACKUP_DIR=".pre-ghostproxy.bak"
CONFLICT_FILES=(
  ".claude/settings.json"
  ".config/opencode/opencode.json"
  ".gitignore"
  ".claudeignore"
  ".mcp.json"
)
for f in "${CONFLICT_FILES[@]}"; do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp -a "$f" "$BACKUP_DIR/$f"
    ok "backed up: $f"
  fi
done
for d in .claude/hooks .claude/rules; do
  if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
    mkdir -p "$BACKUP_DIR/$d-existing"
    cp -a "$d/." "$BACKUP_DIR/$d-existing/"
    ok "backed up: $d/"
  fi
done

# ---------- Step 2: git init + checkout ----------
hdr "Step 2 — git init + remote + checkout"
git init -b "$BRANCH"
git remote add origin "$REPO_URL"
git fetch origin
git checkout -f "origin/$BRANCH"
git branch --set-upstream-to=origin/"$BRANCH" 2>/dev/null || true
ok "\$HOME is now a working tree of $REPO_URL on branch $BRANCH"

# ---------- Step 3: merge ----------
hdr "Step 3 — surgical merge from backup"
MERGE_SCRIPT="$HOME/scripts/merge-from-backup.sh"
if [ ! -x "$MERGE_SCRIPT" ]; then
  warn "$MERGE_SCRIPT not found or not executable — skipping merge step"
  warn "merge manually later: bash $MERGE_SCRIPT --apply"
else
  if [ "$INTERACTIVE" = "1" ]; then
    info "running merge-from-backup.sh --apply (per-change confirmation prompts)"
    bash "$MERGE_SCRIPT" --apply || warn "merge script exited non-zero — review output"
  else
    info "non-interactive — running merge-from-backup.sh in diff mode (no changes)"
    info "operator should run 'bash $MERGE_SCRIPT --apply' manually for actual merge"
    bash "$MERGE_SCRIPT" || true
  fi
fi

# ---------- Step 4: validate ----------
hdr "Step 4 — validate"
if [ -x "$MERGE_SCRIPT" ]; then
  bash "$MERGE_SCRIPT" --validate || warn "validation reported issues — review output"
else
  for f in .claude/settings.json .config/opencode/opencode.json .mcp.json; do
    if [ -f "$f" ]; then
      if python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
        ok "$f: valid JSON"
      else
        warn "$f: INVALID JSON — restore from $BACKUP_DIR/$f"
      fi
    fi
  done
fi

# ---------- Step 5: run install.sh + activate statusline ----------
run_install_and_statusline "$HOME"

# ---------- Done ----------
hdr "Done"
ok "MODE=A complete. \$HOME = working tree of $REPO_URL on branch $BRANCH"
cat <<EOF
  Backup retained at: \$HOME/$BACKUP_DIR/  (manual rm -rf when verified)
  Pre-merge versions: *.pre-merge.bak in-place (also manual cleanup)

  Next steps:
    cd \$HOME
    git status                                   # should show clean
    less BOOTSTRAP.md
    ./install.sh --dry-run                       # preview install.sh (implement-stage)

  Recovery if anything looks wrong:
    bash \$HOME/scripts/merge-from-backup.sh --validate     # check JSON
    diff -u \$HOME/$BACKUP_DIR/.claude/settings.json \$HOME/.claude/settings.json
    cp -a \$HOME/$BACKUP_DIR/.claude/settings.json \$HOME/.claude/settings.json   # restore

EOF
