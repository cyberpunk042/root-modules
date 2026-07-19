---
title: "T012 — Author $HOME/install.sh (idempotent, --dry-run, --check, --dest)"
type: task
status: in-progress
priority: P0
parent_module: "root-modules-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 98
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-06
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m003-foundation-hardening.md
  - id: tools-md
    type: wiki
    file: TOOLS.md
    description: "Planned install.sh invocations + invariants (idempotency, --dry-run support, exit codes, backups)"
tags: [task, p0, t012, foundation, install-sh, scaffold, m003]
---

# T012 — Author $HOME/install.sh

## Description

Author the foundation's idempotent installer. Takes a fresh Linux host (target: Debian 13) and brings it to foundation-tier root-modules state: endpoint AI agent safety policy installed at `~/.claude/`, bridge topology configured, management wifi configured, opencode bridge plugin installed.

## Done When

**Scaffold-stage (cycle 23 — partial):**
- [x] `$HOME/install.sh` exists, executable (`chmod 0755`) — greenfield authored cycle 23
- [x] `./install.sh --dry-run` previews; no state changes — STUBS list operations
- [x] `./install.sh --help` prints usage + all flags
- [x] `./install.sh --version` prints version
- [x] `./install.sh --check` mode wired (read-only stub)
- [x] `./install.sh --dest <path>` flag wired
- [x] Out-of-sync backup helper `backup_if_exists()` defined
- [x] Exit codes documented in --help (0/1/2/3/4 with semantics)
- [x] Prior `$HOME/install.sh` debris backed up to `install.sh.prior-debris.bak.<UTC-ts>` before greenfield overwrite (per T011 + T006 decisions)
- [x] Greenfield framing in file header explicitly cites T011 + T006 decisions

**Implement-stage (in-progress — partial completion):**
- [x] STUB: dependency check (python3, jq, nft, ip, wpa_supplicant) — implemented 2026-05-06; OS-family-aware install hint (debian/rhel/arch); conditional optional-deps per WITH_BRIDGE/WITH_WIFI; `--dry-run` warns on missing, real-install exits 2. Verified: 3 toggle scenarios produce correct required-set (`base mode=bridge` requires nft+ip+wpa_supplicant; `--no-wifi` drops wpa_supplicant; `--mode endpoint` drops bridge+wifi deps). brctl replaced by `ip` (iproute2) — modern alternative.
- [x] STUB: OS-family detection (Debian/RHEL/Arch) — implemented earlier (cycle ~22-24); detect_os_family parses /etc/os-release. Note: original Done When said "Debian 13 verification" — superseded per SB-073 to be OS-family-aware (operator: "this project is not limited to being on debian 13").
- [x] STUB: deploy `~/.claude/settings.json` + hook scripts + brain pieces (rules/commands/agents/modes/skills) — implemented (op_install_endpoint_safety_policy at install.sh:480). Coverage gap fix 2026-05-06 per operator install-readiness audit: prior implementation deployed only settings.json + hooks/, leaving 23 brain-piece files (15 slash commands, 3 brain-loaded subagents, 3 modes, 2 skills) undeployed → fresh non-Path-A install would have hooks but no /orient, /handoff, /mode-*, etc. Now deploys all 5 brain-piece subdirs (rules, commands, agents, modes, skills/<name>/SKILL.md). Verified via `--dry-run --dest /tmp/install-test-dest`: 50+ files correctly listed.
- [x] STUB: deploy opencode bridge plugin (`~/.config/opencode/`) — implemented (op_install_opencode_bridge at install.sh:446)
- [x] STUB: configure network bridge (systemd-networkd per T013) — implemented (op_install_network_bridge at install.sh:467)
- [ ] STUB: configure nftables rules (BRIDGE FORWARD/OUTPUT) — bridge-side rules pending T013 operator-decision (default-accept vs default-drop FORWARD policy, threat-model question). Wifi-side INPUT/FORWARD chain DONE (see wifi STUB below).
- [x] STUB: configure management wifi (outbound-only) — implemented 2026-05-06. Authored: `$HOME/templates/wpa_supplicant/wpa_supplicant-mgmt0.conf.template` (operator-fill placeholders for SSID/PSK/country); `$HOME/templates/nftables/management-wifi-outbound-only.nft` (deterministic per operator's outbound-only invariant: INPUT drops all except established/related + ICMP echo-reply, OUTPUT accept, FORWARD drops anything touching wifi ifaces). install.sh `op_install_management_wifi` 8-step flow: (1) deploy wpa_supplicant template; (2) ensure /etc/nftables.d/ exists; (3) deploy ruleset; (4) `nft -c` syntax-check; (5) `ensure_nftables_d_include()` idempotently provisions /etc/nftables.conf with `include "/etc/nftables.d/*.nft"` (creates fresh OR appends to existing with backup-first); (6) systemctl reload nftables; (7) systemctl enable wpa_supplicant@mgmt0.service (boot-up); (8) conditional systemctl start (skipped if placeholders unfilled to avoid auth-fail log spam). Verified: `nft -c -f $HOME/templates/nftables/management-wifi-outbound-only.nft` PASSES; dry-run on dev host (which has /etc/nftables.conf without include directive — Debian default) correctly shows "exists without include; would back up + append include line".
- [x] STUB: integrity sentinel registration — implemented (op_install_integrity_sentinel)
- [x] STUB: per-project install (`--profile project` + `op_install_tools` + `/install-agent-brain` slash command) — implemented 2026-05-06 per operator directive ("we can chose to install into project and not only the root... I should also be able to do it not only from the install scripts"). New `project` profile in `apply_profile()` deploys agent brain (settings + hooks + rules + commands + agents + modes + skills + tools) to `<dest-path>/.claude/` + `<dest-path>/tools/`, disables OS-level ops (bridge/wifi/integrity/ccstatusline/opencode bridge — all scope=root-only). New `op_install_tools` deploys `/tools/*.py` (skip-on-same-path so Path A is no-op; for non-Path-A, copies all 10 modules). New `/install-agent-brain <target-path> [--dry-run]` slash command at `$HOME/.claude/commands/install-agent-brain.md` provides operator-facing entry point that wraps install.sh project profile. **Live-verified**: `$HOME/install.sh --profile project --dest /tmp/proj-test` deployed 68 files (17 hooks + 10 rules + 22 commands + 3 agents + 3 modes + 2 skills + 10 tools + settings.json) with 10/10 op_verify PASS.

- [x] STUB: post-install verification — implemented 2026-05-06. `op_verify` runs 16+ comprehensive checks covering: settings.json parses; 3 hook scripts present + executable; integrity_check() runtime call; integrity baseline match (if --with-integrity); opencode bridge resolves (if --with-opencode); br0 UP (if --with-bridge); wpa_supplicant config + nftables ruleset deployed + ghp_mgmt_wifi table loaded in kernel + wpa_supplicant@mgmt0 enabled (if --with-wifi, with placeholder-aware service-status skip); rules/commands/agents/modes/skills deployed counts (if --with-hooks). `--check` mode now applies profile BEFORE running checks (was a bug — toggles were unset → all per-op checks skipped). Verified on dev host: 12/16 PASS (brain pieces all deployed), 4 expected FAIL (wifi+integrity not deployed on this dev host, confirms check correctly detects drift). Exit code 1 on any FAIL — caller integration with CI possible.
- [ ] Idempotency invariant: re-run = no-op when state matches (T016 covers; verifies install_file's "unchanged" path)
- [x] `bash -n install.sh` passes ✓ (verified 2026-05-06 after dep-check edit)
- [x] `shellcheck install.sh` passes — verified 2026-05-06 (shellcheck 0.10.0 installed via apt). Initial run found 17 issues (5 real bugs `SC2178/2128` array-vs-scalar collision in `run_check` between `synced/drifted/missing` scalars and `require_dependencies`'s `missing` array; 2 `SC2034` unused VERBOSE + ASSUME_YES; 3 `SC2155` readonly+command-sub; 7 `SC2015` `&&||` cosmetic). All fixed: scalars renamed `synced_count/drifted_count/missing_count`, narrow shellcheck disable directives added for documented-but-unwired flags + readonly safe patterns + set-euo-pipefail-protected op-chain. Final result: shellcheck exit 0, no warnings.

## Dependencies

- T011 (greenfield vs extend decision) — gates the authoring approach.
- T006 (prior debris reconciliation) — informs whether the prior `$HOME/install.sh` is touchable as a starting point.
- T008 (CLAUDE.md methodology section already references install.sh's planned invocations — per Adoption Guide) ✓

## Stage-gate (Implement)

Per CLAUDE.md methodology section: stage `implement` requires the code compiles + lint passes + ≥1 existing file imports new code. For shell scripts: `bash -n install.sh` parses cleanly; `shellcheck install.sh` passes (or operator-set baseline); CLAUDE.md routing references install.sh.

## Relationships

- PART OF: [[root-modules-m003-foundation-hardening|M003]]
- BLOCKED BY: T011
- RELATES TO: [[T006-prior-debris-reconciliation|T006]]
- BLOCKS: T015 (post-install verification), T017 (foundation gate verification)
