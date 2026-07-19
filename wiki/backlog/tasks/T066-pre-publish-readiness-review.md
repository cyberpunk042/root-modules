---
title: "T066 — Pre-publish readiness review + post-publish checkout workflow verification"
type: task
status: in-progress
priority: P1
current_stage: document
readiness: 60
from: second-brain
for: root-modules
created: 2026-05-05
updated: 2026-05-05
tags: [task, p1, t066, from-second-brain, cross-project, document]
---

# T066 — Pre-publish readiness review + post-publish checkout workflow verification

## Cross-project metadata

- **From**: /opt second-brain (devops-solutions-information-hub)
- **For**: root-modules
- **Channel**: tools.cross_project_task (operator-granted, 2026-05-05)
- **Companion note** (if exists): see most-recent `wiki/log/<date>-from-second-brain-*.md`

## Description

Pre-publish readiness review for root-modules + post-publish workflow verification. The /opt second-brain agent has prepared the publish tooling (one-shot at `/tmp/`) and the project-deliverable checkout/bootstrap scripts (committed at `$HOME/scripts/`). This task captures what operator should verify / do.

This task is delivered via the operator-granted cross-project channel (tools.cross_project_task at /opt). Companion narrative note: see most-recent `wiki/log/<date>-from-second-brain-pre-publish-handoff.md`.

## Done When

- [x] Reviewed `/tmp/publish-root-ghostproxy.sh` — dry-run executed cycle 52; pre-flight 8/9 PASS, 1 BLOCKER (git config user.name+email not set)
- [x] Reviewed `$HOME/scripts/*` — install-from-curl.sh / checkout-a-init-remote.sh / checkout-b-clone-subdir.sh / merge-from-backup.sh + lib/ helpers + README.md present, executable, dry-run-default with --execute opt-in. install-from-curl.sh has TTY detection + MODE=A/B + env-var overrides
- [x] Confirmed pre-flight checks pass (cwd=$HOME ✓, gh authenticated as cyberpunk042 ✓, core files present ✓, no pre-staged changes ✓, no existing commits ✓, sensitive files correctly gitignored ✓, repo name `cyberpunk042/root-ghostproxy` available on GitHub ✓; ✗ git config user.name+email NOT set — operator action required per work-mode "NEVER update the git config")
- [ ] Operator-decision: VISIBILITY (private vs public) — recommend private first, flip later
- [ ] Operator-decision: LICENSE_TYPE (apache-2.0 default) — confirm or override
- [ ] Operator-decision: REPO_NAME (root-modules default) — confirm or override
- [ ] Operator runs `bash /tmp/publish-root-ghostproxy.sh --execute` (or with env-var overrides). Publish script auto-patches `.gitignore` to whitelist `/tools/` + `/templates/`. `/scripts/` is already whitelisted (manually patched 2026-05-05).
- [ ] Publish succeeds — repo URL printed; pushed to origin/main
- [ ] Verify `.gitignore` now includes `/tools/`, `/templates/`, and `/scripts/` whitelist sections
- [ ] Verify `LICENSE` file present + correctly stamped with year + author
- [ ] Verify `$HOME/scripts/{install-from-curl,checkout-a-init-remote,checkout-b-clone-subdir}.sh` got committed + are visible on the GitHub repo
- [ ] Update `REPO_URL` default in `$HOME/scripts/install-from-curl.sh` if needed (currently `https://github.com/cyberpunk042/root-modules.git`); commit + push the update
- [ ] On the OTHER machine: pick the right path
  - [ ] Easiest (curl-bash one-liner): `curl -fsSL https://raw.githubusercontent.com/<owner>/root-modules/main/scripts/install-from-curl.sh | bash` (defaults to MODE=B clone-to-subdir, $HOME untouched)
  - [ ] Path A (init+remote into $HOME): `MODE=A` env var on the curl-bash one-liner, OR run `bash <repo>/scripts/checkout-a-init-remote.sh --execute <repo-url>` directly
  - [ ] Path B explicit (clone to subdir): `bash <repo>/scripts/checkout-b-clone-subdir.sh --execute <repo-url>` directly
- [ ] Post-checkout (Path A only): run `bash scripts/merge-from-backup.sh` (default = diff mode, NO changes). Review the diffs carefully.
- [ ] If you want to apply ANY changes after reviewing the diff: `bash scripts/merge-from-backup.sh --apply` (per-change confirmation prompts; no global auto-apply for safety).
- [ ] The script SURGICAL-MERGES only purely additive changes (permissions union, operator-unique opencode keys). Custom hooks, custom rules, hooks-block changes, and `.gitignore` additions are NEVER auto-applied — script surfaces them for manual operator decision.
- [ ] Validate JSON files post-merge: `bash scripts/merge-from-backup.sh --validate`
- [ ] Inspect `.pre-merge.bak` files (if any swaps happened) to compare against the merged state. Restore from `.pre-ghostproxy.bak/` if needed.
- [ ] Verify `install.sh --dry-run` works on the new machine (full install pending M003+M004+M012)

## Dependencies

- None. Operator-driven workflow.

## Context

This task accompanies a NOTE at `wiki/log/<date>-from-second-brain-pre-publish-handoff.md` which has the narrative + pointer table.

**Publish script (one-shot ephemeral)**:
- `/tmp/publish-root-ghostproxy.sh` — initial commit + LICENSE + .gitignore patches + gh repo create + push (run from $HOME cwd)

**Project-deliverable scripts (committed + shipped with repo at $HOME/scripts/)**:
- `install-from-curl.sh` — curl-bash one-liner bootstrap (the typical user entry-point)
- `checkout-a-init-remote.sh` — Path A advanced flow ($HOME == repo working tree)
- `checkout-b-clone-subdir.sh` — Path B explicit (clone to subdir, $HOME untouched)
- `merge-from-backup.sh` — post-Path-A merge facilitator (reconciles `.pre-ghostproxy.bak/` with checked-out repo; supports human-interactive AND AI-automated modes)

The `$HOME/scripts/` directory is whitelisted in `$HOME/.gitignore` as section 4.7 (added 2026-05-05).

All scripts default to dry-run / safe-default; explicit `--execute` or `MODE=A` flags required to mutate $HOME.

## Anti-patterns to avoid

- Don't run publish script from a directory other than $HOME — script enforces but warns.
- Don't try `git clone <url> $HOME` directly — git refuses (non-empty dir). Use Path A's git-init+remote flow instead.
- Don't blow away .pre-ghostproxy.bak/ after Path A checkout until you've reviewed + merged any pre-existing config (.claude/settings.json, .config/opencode/opencode.json).
- Don't expect end-to-end install.sh to work on a fresh-machine $HOME yet — that's M003+M004+M012 work, currently scaffold tier.

## Relationships

- COMPANION TO: most-recent `wiki/log/<date>-from-second-brain-pre-publish-handoff.md` (narrative side)
- DELIVERED VIA: tools.cross_project_task at /opt (operator-granted channel)
- INFORMS: future M013 (publish-readiness automation) if the manual workflow becomes recurring
- USED BY: operator's publish + checkout workflow on this session
