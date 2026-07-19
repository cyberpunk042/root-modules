# 2026-07-19 — Rename follow-ups: RGP_* env prefix + second-brain path refresh

## Operator directive (verbatim, sacrosanct)

> "lets address those"

Context: said after PR #14 (root-ghostproxy → root-modules rename) merged and the agent flagged two follow-ups: *"the `RGP_*` env var prefix rename, and the second-brain-side rename of its `projects.root-ghostproxy` sister-projects key + `project_profiles/root-ghostproxy/` identity-profile path"*. Root rename directive: `wiki/log/2026-07-19-rename-root-modules-directive.md`.

## What landed in THIS repo

1. **Env var rename with backward compatibility** (adding ≠ discarding — old names keep working):
   - `RM_SECOND_BRAIN_ROOT` (canonical) with `RGP_SECOND_BRAIN_ROOT` legacy fallback — `tools/_paths.py`, `scripts/mcp-launcher.sh`, `.claude/hooks/opt-write-block.sh`, `.claude/hooks/pre-compact.sh`, `templates/ccstatusline-widgets/_lib.sh`
   - `RM_PROJECT_PYTHON` w/ `RGP_PROJECT_PYTHON` fallback — `pre-compact.sh`
   - `RM_INTERACTIVE` w/ `RGP_INTERACTIVE` fallback — `scripts/lib/common.sh`
   - `ROOT_MODULES_{PYTHON,ACTIVE_MODE,ACTIVE_TASK,TASKS_DIR,MODULES_DIR,SB_FILE}` w/ `ROOT_GHOSTPROXY_*` fallbacks — ccstatusline widgets
   - Internal-only identifiers renamed outright (no operator contract): `RGP_LIB_*_SOURCED` → `RM_LIB_*_SOURCED`, `RGP_MANIFEST_*` → `RM_MANIFEST_*`, `RGP_BACKUP_DIR_DEFAULT` → `RM_BACKUP_DIR_DEFAULT` (value `.pre-ghostproxy.bak` UNCHANGED — exists on operator hosts and "ghostproxy" is the module combo name), widget helpers `rgp_resolve_*` → `rm_resolve_*`
   - `test-opt-write-block.py` deliberately keeps pinning the legacy name — it now doubles as regression coverage for the fallback chain.
2. **Second-brain path refresh**: `project_profiles/root-ghostproxy/` → `project_profiles/root-modules/` and `projects.root-ghostproxy` → `projects.root-modules` across live docs, matching the second-brain-side rename (its sister-projects.yaml keeps `root-ghostproxy` as an alias). Historical records (`wiki/log/`, `docs/SESSION-*`, T053/T066 task records) untouched.

## Verification (inline per P4)

- `bash -n` on install.sh + uninstall.sh + all scripts/ + all widget/config templates: clean
- `python3 -m py_compile tools/*.py`: OK
- `HOME=<repo> python3 -m tools.run-tests`: **425/425 PASS across 24 files**
- Fallback smoke: `RGP_SECOND_BRAIN_ROOT=<path>` still resolves via `tools._paths`; `RM_SECOND_BRAIN_ROOT` takes precedence when both set (empirically run 2026-07-19)
