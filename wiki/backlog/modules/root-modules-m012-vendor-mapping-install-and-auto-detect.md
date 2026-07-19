---
title: "root-modules M012 — Vendor mapping, fresh-machine install path, and auto-detect features"
aliases:
  - "M012 — vendor manifest + install + auto-detect"
type: module
domain: backlog
status: draft
priority: P1
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 5
progress: 0
sfif_stage: Infrastructure
sfif_ordering: "Stream 2, Infrastructure tier — co-located with M004 (Infrastructure tooling). Drives the install path completeness for fresh-machine deploys + the auto-detect features."
stages_completed: []
artifacts: []
confidence: medium
created: 2026-05-05
updated: 2026-05-05
sources:
  - id: operator-directive-2026-05-05-gitignore-and-spec-driven
    type: directive
    file: /opt/devops-solutions-information-hub/raw/notes/2026-05-05-gitignore-audit-vendor-mapping-spec-driven-development.md
  - id: parent-epic
    type: wiki
    file: wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md
tags: [module, p1, root-modules, sfif-infrastructure, m012, vendor-mapping, install-on-fresh-machine, auto-detect, spec-driven-development, gitignore-completeness]
---

# M012 — Vendor mapping, fresh-machine install, auto-detect

## Summary

Three related concerns that fall out of the spec-driven-development doctrine: (1) **fresh-machine install path** — `git clone` + `./install.sh` on a clean host reconstitutes a working root-modules state, including the host-context files at `~/.claude/` and `~/.config/opencode/`; (2) **vendor mapping** — for vendors (Suricata, PolarProxy, future IDS rule sources, etc.), the spec records identity + version + integrity hash + install method; vendor binaries/sources are NOT stored in the repo; (3) **auto-detect features** — runtime detection that flags large-file downloads or new-vendor introductions before they enter the repo by accident.

## Operator directive (verbatim, 2026-05-05)

> "I will also want to check that we didn't miss any file and folder in the git ignore and that we have a solution for the gitignored ones that need to have mapping that are not gitignored and are able to be installed normally on a new machine with a fresh checkout that we explain to the user how to put into the $home context and how to install and possibly have the auto features like the detect of a large file download or a new vender that could maybe be registered as vendor but clearly not added as complete source into my own root project source."

## Scope

Three sub-modules / phases:

### Phase A — `.gitignore` whitelist completeness audit + fix

The current `.gitignore` deny-all + whitelist EXCLUDES the brain files (10), the rules files (6), the entire `wiki/` tree, the `docs/` folder, `open-interfaces.template`. A `git init && git add .` would silently lose all the spec authored this session. Operator must approve the whitelist additions; this module captures the gap + the proposed fix list.

### Phase B — fresh-machine install path

After `git clone` lands the spec on a fresh Debian 13 host:

1. `./install.sh --check` reports what's missing (vendors not yet downloaded, configs not yet hydrated, host policy not yet applied).
2. `./install.sh` (with appropriate flags) executes:
   - Copies brain files / `.claude/rules/` to canonical locations (or symlinks them — design decision)
   - Hydrates `~/.claude/settings.json` from the repo template (interpolating host-specific values)
   - Installs hooks at `~/.claude/hooks/` (the 5 wired Python scripts named `*.sh`)
   - Installs `~/.config/opencode/opencode.json` + plugin files
   - Downloads + verifies vendor binaries (Suricata, PolarProxy when those modules are enabled) per vendor manifest
   - Configures network bridge per `wiki/config/` spec
3. `./install.sh --check` after install reports OK (state matches spec).
4. Documentation in README.md "Setup Path" walks the user through the entire flow.

### Phase C — vendor manifest + install method

Define a vendor-manifest format (likely YAML at `wiki/config/vendors.yaml`) where each vendor entry has:

- `id` (e.g., `suricata`, `polarproxy`)
- `version` (pin)
- `integrity_hash` (SHA256 / GPG signature reference)
- `install_method` (apt / source-build / binary-download / git-tag)
- `install_url` (where to fetch from)
- `verify_command` (post-install: how to confirm vendor is healthy)
- `module` (which module owns the vendor — M005 for Suricata/PolarProxy first feature)
- `notes` (free-text for license tier, traffic-volume considerations, etc.)

`install.sh` reads this manifest and orchestrates fetch + verify + install. Vendor source/binaries are NOT in the repo.

### Phase D — auto-detect features (optional, future)

Runtime hooks that flag:

- **Large-file download** detection: PreToolUse on Bash matching `wget`, `curl -O`, `git clone <large>` — log + warn + offer "register as vendor" path.
- **New vendor registration** detection: when an unfamiliar binary or daemon appears at runtime — log + prompt operator to add a vendor-manifest entry.

These live in `$HOME/.claude/hooks/` as additions to the existing 5 wired hooks, OR in `$HOME/.config/opencode/plugin/` for opencode-side detection.

Operator's framing: *"possibly have the auto features"* — Phase D is research / design, not commitment. May ship as a follow-up module if Phase A-C land first.

## Done When

- [ ] **Phase A**: `.gitignore` whitelist audit complete; gap list documented; operator approves additions; `.gitignore` updated; `git init && git add .` from a fresh state would track all spec files (and only spec files).
- [ ] **Phase B**: `install.sh --check` and `install.sh` (apply mode) work end-to-end on a clean Debian 13 host; README.md "Setup Path" is accurate (not aspirational); a fresh `git clone` + `./install.sh` produces a working host state.
- [ ] **Phase C**: `wiki/config/vendors.yaml` exists with at least Suricata + PolarProxy entries; `install.sh` reads the manifest; integrity hashes are pinned + verified; vendor source is NOT in the repo.
- [ ] **Phase D**: at least one auto-detect feature shipped (large-file download warn) OR explicitly punted to a follow-up module.

## Dependencies

- M001-M002 done (brain files + methodology layer in place)
- M003 (Foundation hardening) for the `install.sh` skeleton + host policy mechanics
- M004 (Infrastructure tooling) for the verifier / `--check` mode
- T006 (prior-debris reconciliation) — the existing `$HOME/install.sh` may be partial debris; M012 work either extends it or replaces it per T006 outcome

## Open questions

> [!question] Phase A — does the operator want the brain files / wiki/ checked in, or does install.sh GENERATE them from a spec?
> Two viable models. Model 1: brain files are spec, checked in directly. Model 2: brain files are generated by install.sh from a higher-level YAML spec (more meta, more complex). Model 1 is simpler + matches the second brain's pattern. Operator decides.

> [!question] Phase B — copy or symlink for `~/.claude/` files?
> Copy: install.sh copies `$HOME/.claude/settings.json` → `~/.claude/settings.json`. Survives repo deletion; can drift. Symlink: ln -sf — never drifts; breaks if repo deleted. Hybrid: copy on first install, symlink on `--symlink-mode`. Operator decides.

> [!question] Phase C — what vendor-manifest format?
> YAML (matches second brain), TOML (fewer surprises), or JSON (universal). YAML preferred for consistency. Operator confirms.

> [!question] Phase D — implement now or punt?
> Operator's "possibly" suggests punt-acceptable. Recommend: scope Phase D as a follow-up module (M013?) if Phase A-C complete and operator wants it. Don't block A-C on D.

## Tasks

(No atomic task pages T### yet — this module enters as draft. Atomic tasks authored when operator gives go-ahead.)

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- BUILDS ON: [[root-modules-m003-foundation-hardening|M003 — Foundation hardening]] (install.sh skeleton)
- BUILDS ON: [[root-modules-m004-infrastructure-tooling|M004 — Infrastructure tooling]] (verifier / --check)
- RELATES TO: [[root-modules-m005-first-specialized-feature-module|M005]] (Suricata/PolarProxy as the first vendors entering the manifest)
- RELATES TO: T006 — prior-debris reconciliation; the existing `$HOME/install.sh` is M012's starting-or-replacement point
- IMPLEMENTS: Spec-Driven Development doctrine (per operator directive 2026-05-05)

## Backlinks

[[Epic — root-modules SFIF Rollout]]
[[M003 — Foundation hardening]]
[[M004 — Infrastructure tooling]]
[[M005 — First specialized feature module]]
