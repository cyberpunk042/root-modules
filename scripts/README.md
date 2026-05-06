# `scripts/` — root-ghostproxy deployment + maintenance toolkit

This directory holds the bash scripts that ship with root-ghostproxy and the shared library functions they depend on.

> **Looking for a one-liner install?** From an ALREADY-PUBLISHED repo:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/<owner>/root-ghostproxy/main/scripts/install-from-curl.sh | bash
> ```
>
> Defaults to **MODE=B** (clone to `$HOME/root-ghostproxy/`, your `$HOME` is UNTOUCHED). Read [Modes](#modes) below before choosing MODE=A.

---

## Contents

```
scripts/
├── README.md                    # this file
├── install-from-curl.sh         # one-shot bootstrap (curl-bash entry point)
├── checkout-a-init-remote.sh    # standalone Path A (init+remote into $HOME)
├── checkout-b-clone-subdir.sh   # standalone Path B (clone to subdir)
├── merge-from-backup.sh         # surgical post-Path-A reconciliation w/ governance
└── lib/
    ├── common.sh                # logging + TTY detection + ask/confirm
    ├── conflict-points.sh       # CONFLICT_FILES + CONFLICT_DIRS (single source of truth)
    ├── backup.sh                # backup_conflict_points() function
    ├── json-merge.sh            # validate_json + stage_swap + per-merge primitives
    ├── security-scan.sh         # flags suspicious permissions / hooks / gitignore patterns
    └── merge-manifest.sh        # collects merge manifest + writes audit log + creates follow-up task
```

The `install-from-curl.sh` is mostly self-contained (must run via `curl … | bash` BEFORE `lib/` is on disk). The other three scripts source `lib/` for DRY + consistency.

---

## Quick reference

| Script | Audience | When to run | Default behavior |
|---|---|---|---|
| **`install-from-curl.sh`** | new operator (typical user) | first-time setup of root-ghostproxy on a target machine | TTY → ask MODE; no TTY → MODE=B safe |
| **`checkout-b-clone-subdir.sh`** | operator who wants explicit Path B without prompts | when scripting Path B around custom orchestration | dry-run; pass `--execute` to clone |
| **`checkout-a-init-remote.sh`** | operator who wants explicit Path A without the install-from-curl wrapper | when fine-grained control over the Path A flow is needed | dry-run; `--execute` to apply |
| **`merge-from-backup.sh`** | operator OR AI agent reconciling after Path A checkout | after `.pre-ghostproxy.bak/` has been created | diff-only; `--apply` for per-change confirmation |

---

## Modes

root-ghostproxy supports two checkout modes for getting the repo onto a target machine. Pick based on intent.

### MODE=B — clone to subdirectory (safe default)

- Repo lands at `$TARGET/` (default `$HOME/root-ghostproxy/`)
- `$HOME` is **completely untouched**
- No conflict handling needed
- `install.sh` handles deployment via `--profile {base|full|project|interactive}` (implement-stage; `--dry-run` + `--check` available)

**Choose MODE=B when:**
- You want to read / inspect / test the repo without touching your live config
- Your `$HOME` already has Claude Code / opencode setup you want to keep separate
- You're a contributor who'll later run `install.sh` explicitly

### MODE=A — init in `$HOME` (advanced)

- `$HOME` becomes the repo working tree (`git init` + remote + checkout)
- Conflict points (`.claude/settings.json`, `.config/opencode/opencode.json`, `.gitignore`, `.claudeignore`, `.mcp.json`, custom hooks/rules) are **backed up** to `.pre-ghostproxy.bak/` BEFORE checkout
- Then `git checkout -f origin/$BRANCH` overwrites repo-whitelisted files with repo versions
- Then `merge-from-backup.sh --apply` runs to surgically reconcile additive customizations from the backup back into the working tree
- JSON files validated post-merge

**Choose MODE=A when:**
- You explicitly want `$HOME` to BE the repo working tree (active dev model)
- You're comfortable with the backup-then-checkout-then-merge dance
- You understand that files NOT in the repo whitelist (`.bashrc`, `.ssh/`, `.gitconfig`, `.cache/`, `.local/`, `.npm/`, etc.) stay untouched

**Recovery if anything breaks:** `.pre-ghostproxy.bak/` retains your prior config; per-file `.pre-merge.bak` files retain just-before-swap state.

See [Conflict surface](#conflict-surface) below for exactly which files are touched.

---

## Conflict surface

When MODE=A overwrites your `$HOME` files, only these paths are at risk:

| Path | Repo whitelist? | What MODE=A does |
|---|---|---|
| `.claude/settings.json` | ✓ | Backup → overwrite → merge `permissions.allow/deny/ask` UNION back |
| `.config/opencode/opencode.json` | ✓ | Backup → overwrite → merge operator-unique keys back |
| `.gitignore` | ✓ | Backup → overwrite. Merge surfaces unique lines but NEVER auto-applies (operator decides manually). |
| `.claudeignore` | ✓ | Backup → overwrite. Merge shows diff only. |
| `.mcp.json` | ✓ | Backup → overwrite. Merge shows diff only. |
| `.claude/hooks/*.sh` `.claude/hooks/*.py` | ✓ | Backup as `.claude/hooks-existing/` → overwrite. Merge surfaces unique custom hooks for manual `cp`. |
| `.claude/rules/*.md` | ✓ | Backup as `.claude/rules-existing/` → overwrite. Merge surfaces unique custom rules for manual `cp`. |
| Top-level docs (`README.md`, `CLAUDE.md`, `AGENTS.md`, etc.) | ✓ | Land cleanly on fresh `$HOME`; overwrite if pre-existing (uncommon). |
| `install.sh`, `uninstall.sh` | ✓ | Same — land cleanly on fresh `$HOME`. |
| `tools/`, `templates/`, `wiki/`, `docs/`, `scripts/` | ✓ | Land cleanly (operator unlikely to have these as directories with lowercase names). |
| **Everything else** (`.bashrc`, `.profile`, `.ssh/`, `.gitconfig`, `.cache/`, `.local/`, `.npm/`, `.gnupg/`, `.bash_history`, etc.) | ✗ | **NEVER touched** — outside repo whitelist |

The repo's `.gitignore` uses a **deny-all-then-whitelist** pattern. `git checkout -f` only affects files in the whitelist; everything else is invisible to git.

---

## `merge-from-backup.sh` — surgical reconciliation

The merge tool is **safety-first by design**:

| Mode | Behavior | Default |
|---|---|---|
| `--diff` (default) | Per-file analysis. **NO CHANGES.** Shows what would happen. | ✓ |
| `--apply` | Per-change confirmation. Only purely-additive merges (permission union, operator-unique keys) are offered. Custom hooks, hooks-block changes, `.gitignore` additions are **surfaced but never auto-applied**. |  |
| `--validate` | Just check JSON validity of current files. No diff, no merge. |  |

**Atomic merge pattern** for every applied change:
1. Stage proposed result to `<file>.merged`
2. Validate (JSON parse for `.json` files); refuse to swap if invalid
3. Atomic swap with `<file>.pre-merge.bak` preservation of prior version

**There is no `--auto` flag.** Per-change confirmation is structurally required.

**Backup is never auto-deleted.** `.pre-ghostproxy.bak/` and `.pre-merge.bak` files remain after merge for manual cleanup once the operator has verified everything works.

### Governance — every `--apply` session generates artefacts

Per operator directive 2026-05-05: merges can compound into a nightmare without governance. The script enforces:

**1. Security scanning** during apply. Every proposed merge input is scanned by `lib/security-scan.sh`:

| Severity | Examples | Behavior |
|---|---|---|
| **HIGH** | `Bash(*)`, `Bash(rm -rf*)`, `Bash(sudo *)`, curl-pipe-shell, reverse-shell shapes in custom hooks, credential-shaped values in opencode keys, `.gitignore` `!*.env` (un-deny secrets), `!.ssh` | **Blocks the apply** unless `--accept-security-flags` (audit-trail records the override) |
| **MED** | Writes to `/etc`/`/usr`/`/boot`, broad `WebFetch(domain:*)`, hooks writing to system paths, hooks mutating `PATH`, `.gitignore` broad allows | Warns + records flag, does NOT block |
| **LOW** | (informational only — currently unused) | Records, no action |

**2. Audit log** written every apply session at `wiki/log/<date>-merge-from-backup-<host>.md`. Contains:
- Run metadata (timestamp, host, mode)
- Counts: applied / surfaced / flagged / skipped
- Per-category tables of what landed, what's pending operator decision, what was flagged
- Recovery instructions

**3. Follow-up review task** auto-generated at `wiki/backlog/tasks/T<NEXT>-post-merge-review-<date>-<host>.md`. Priority computed from flags:
- `P0` if any HIGH flag
- `P1` if any MED flag (no HIGH)
- `P2` if no flags

The follow-up task has a Done-When checklist for the operator/AI agent to:
- Resolve every HIGH-severity flag (confirm intentional with rationale, OR revert via backup)
- Review every MED-severity flag
- Review each applied change for security / consistency / synthesis (should it be promoted into project spec?)
- Triage surfaced items (custom hooks, custom rules, `.gitignore` additions)
- Recognize recurring patterns → open `cross-project-merge-governance` epic when 3+ merge sessions accumulate
- Validate post-review

**4. Refuse-on-flag policy** by default. Apply HIGH-flagged changes only with explicit `--accept-security-flags` (audit-trail records this).

**Flags to skip governance writes**:
- `--no-followup-task` — skip the task generation (still writes audit log)
- `--no-log` — skip the audit log (still creates task if applicable)
- `--accept-security-flags` — allow HIGH flags to apply (with audit recording)

---

## `lib/` — library design

The library files are **sourced**, not executed. Each has a re-source guard (`RGP_LIB_<NAME>_SOURCED`) that prevents double-sourcing when multiple scripts in the same shell session source the same lib.

### `lib/common.sh`

Logging + interactive helpers. Used by all lib-using scripts.

| Function | Purpose |
|---|---|
| `say "..."` | indented info line |
| `hdr "..."` | section header |
| `ok "..."` / `warn "..."` / `info "..."` | status indicators |
| `fail "..."` | error + exit 1 |
| `ask "<prompt>" "<default>"` | reads from `/dev/tty`; returns default if non-interactive |
| `confirm "<prompt>"` | y/N prompt; non-interactive defaults NO |
| `require_cmd <cmd> [<install-hint>]` | fails if cmd not in PATH |

Variables: `RGP_INTERACTIVE` (auto-detected; override before sourcing).

### `lib/conflict-points.sh`

**Single source of truth** for what counts as a "conflict point" during MODE=A checkout.

| Variable | Type | Purpose |
|---|---|---|
| `CONFLICT_FILES` | array | files backed up + may be overwritten by checkout |
| `CONFLICT_DIRS_FOR_HOOKS_RULES` | array | directories of operator-custom hooks/rules |
| `RGP_BACKUP_DIR_DEFAULT` | string | default backup-dir name (`.pre-ghostproxy.bak`) |

When the conflict surface changes (e.g., a new whitelisted config file), update **only this file**.

### `lib/backup.sh`

`backup_conflict_points [<backup-dir>]` — reads `CONFLICT_FILES` + `CONFLICT_DIRS_FOR_HOOKS_RULES` from `lib/conflict-points.sh` and copies them into the backup dir (default `$RGP_BACKUP_DIR_DEFAULT`). Idempotent in the sense of "re-running re-copies"; caller's responsibility to avoid that.

### `lib/json-merge.sh`

JSON validation + atomic stage-then-swap + per-merge primitives.

| Function | Purpose |
|---|---|
| `validate_json <file>` | exit 0 if valid JSON, non-zero otherwise |
| `stage_swap <staged> <target>` | validates staged (if `.json`), preserves target as `.pre-merge.bak`, atomically swaps. Refuses on validation failure. |
| `permissions_union_settings <bak> <cur> <out>` | produces merged `settings.json` with permissions UNION |
| `operator_unique_keys_opencode <bak> <cur> <out>` | merges only operator-unique keys into `opencode.json` |
| `diff_settings <bak> <cur>` | per-key diff analysis (printed) |
| `diff_opencode <bak> <cur>` | unique-keys diff analysis (printed) |

### `lib/security-scan.sh`

Detects flags in candidate-merge content. Emits one flag per line as `<SEVERITY>\t<category>\t<detail>`.

| Function | Inputs | Detects |
|---|---|---|
| `scan_permission_entries` | one entry per line on stdin | unbounded wildcards, rm-recursive, sudo, curl-pipe-shell, system-path writes, broad `WebFetch(domain:*)` |
| `scan_opencode_unique_keys <bak> <cur>` | files | values matching credential patterns (`sk_*`, `gh_*`, `xox*`, AWS keys, Google API keys, base64-ish, hex-token), credential-named keys with string values |
| `scan_gitignore_additions` | one line per line on stdin | un-deny of secrets (`!*.env`, `!*.pem`, `!*credentials*`, `!*.ssh`), broad allows (`!*…*`) |
| `scan_custom_hook_file <file>` | path | curl-pipe-shell inside hooks, `/dev/tcp` reverse shells, history wipes, system-path writes, PATH mutation |
| `format_flags_summary` | flags on stdin | counts + summary; returns 0 (clean), 1 (MED), 2 (HIGH) |

### `lib/merge-manifest.sh`

Collects merge manifest as state during apply, then writes audit log + creates follow-up review task.

| Function | Purpose |
|---|---|
| `manifest_init` | reset manifest; call once at start of apply session |
| `manifest_record <category> <key> <detail>` | category ∈ `applied`/`surfaced`/`flagged`/`skipped` |
| `manifest_has_high_flags` | returns 0 if any flag entry starts with `HIGH:` |
| `manifest_count <category>` | echo count of entries in category |
| `manifest_finalize [--no-task] [--no-log]` | writes `wiki/log/<date>-merge-from-backup-<host>.md` + creates follow-up task in `wiki/backlog/tasks/T<NEXT>-post-merge-review-...` |

---

## How to use the scripts together

### Typical user — first-time setup

```bash
# Pick whichever fits:
curl -fsSL https://raw.githubusercontent.com/<owner>/root-ghostproxy/main/scripts/install-from-curl.sh | bash
curl -fsSL .../scripts/install-from-curl.sh | MODE=A bash         # advanced
```

### Power user — explicit Path A control

```bash
# 1. Clone or download the script first
git clone <repo-url> $HOME/root-ghostproxy && cd $HOME

# 2. Run the standalone Path A script
bash $HOME/root-ghostproxy/scripts/checkout-a-init-remote.sh           # dry-run
bash $HOME/root-ghostproxy/scripts/checkout-a-init-remote.sh --execute <repo-url>

# 3. Run the surgical merge
bash $HOME/root-ghostproxy/scripts/merge-from-backup.sh                # diff
bash $HOME/root-ghostproxy/scripts/merge-from-backup.sh --apply        # apply

# 4. Validate
bash $HOME/root-ghostproxy/scripts/merge-from-backup.sh --validate
```

### AI agent automating MODE=B

```bash
curl -fsSL .../scripts/install-from-curl.sh | bash -s -- --auto
# MODE=B, no prompts, repo at $HOME/root-ghostproxy/
```

---

## Standards

These scripts ship as part of the project's deliverable. Authoring conventions:

- `set -euo pipefail` at the top
- Default to dry-run / diff-mode; explicit `--execute` / `--apply` to mutate
- No `--auto` global bypass on safety-critical flows (the merge script has none)
- Use `lib/common.sh` for logging — consistent UX across scripts
- Use `lib/conflict-points.sh` for any reference to the conflict file list — never hardcode
- Validate JSON before atomic swaps via `lib/json-merge.sh`
- Preserve prior versions in `.pre-merge.bak` files; never silently overwrite
- Print recovery instructions at end of mutating flows
- Comment headers: usage, flags, env-var overrides, examples

---

## Cross-references

- Project README: [`/README.md`](../README.md) — what root-ghostproxy IS
- Bootstrap guide: [`/BOOTSTRAP.md`](../BOOTSTRAP.md) — cold-pickup orientation
- Architecture: [`/ARCHITECTURE.md`](../ARCHITECTURE.md) — system design
- Security envelope: [`/SECURITY.md`](../SECURITY.md) — host-level safety controls
- `install.sh` / `uninstall.sh` at repo root — host configuration deployers (implement-stage 98%; `--profile {base|full|project|interactive}` × `--mode {bridge|endpoint|hybrid|auto}` × per-op toggles; `--dry-run` + `--check`; shellcheck PASS)
- `.gitignore` whitelist for `/scripts/` lives in section 4.7 of [`/.gitignore`](../.gitignore)
- Cross-project channel for second-brain notifications: [`/wiki/log/`](../wiki/log/) — second-brain agent writes handoff notes here, picked up by `/orient` step 11

## Maintenance

When adding a new script to `scripts/`:

1. Place at top level (or `lib/` if it's a sourced helper)
2. Use `set -euo pipefail`
3. Source `lib/common.sh` for logging
4. Default to safe (dry-run / diff)
5. Document at the top: purpose, flags, env vars, examples
6. Add an entry to [Quick reference](#quick-reference) above
7. Update root project's `.gitignore` if extension differs from `.sh`
8. Cross-reference from `/CLAUDE.md` routing if the script is operator-invokable

When changing the conflict surface (adding/removing a file from `CONFLICT_FILES`):

1. Edit only `lib/conflict-points.sh`
2. Update the [Conflict surface](#conflict-surface) table in this file
3. Update `/.gitignore` whitelist if the new file requires it
4. Verify the publish script's auto-patch (`/tmp/publish-root-ghostproxy.sh` — operator-side ephemeral) covers it
