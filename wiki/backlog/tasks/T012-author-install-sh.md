---
title: "T012 — Author /root/install.sh (idempotent, --dry-run, --check, --dest)"
type: task
status: in-progress
priority: P0
parent_module: "root-ghostproxy-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: implement
readiness: 91
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-06
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-ghostproxy-m003-foundation-hardening.md
  - id: tools-md
    type: wiki
    file: TOOLS.md
    description: "Planned install.sh invocations + invariants (idempotency, --dry-run support, exit codes, backups)"
tags: [task, p0, t012, foundation, install-sh, scaffold, m003]
---

# T012 — Author /root/install.sh

## Description

Author the foundation's idempotent installer. Takes a fresh Linux host (target: Debian 13) and brings it to foundation-tier root-ghostproxy state: endpoint AI agent safety policy installed at `~/.claude/`, bridge topology configured, management wifi configured, opencode bridge plugin installed.

## Done When

**Scaffold-stage (cycle 23 — partial):**
- [x] `/root/install.sh` exists, executable (`chmod 0755`) — greenfield authored cycle 23
- [x] `./install.sh --dry-run` previews; no state changes — STUBS list operations
- [x] `./install.sh --help` prints usage + all flags
- [x] `./install.sh --version` prints version
- [x] `./install.sh --check` mode wired (read-only stub)
- [x] `./install.sh --dest <path>` flag wired
- [x] Out-of-sync backup helper `backup_if_exists()` defined
- [x] Exit codes documented in --help (0/1/2/3/4 with semantics)
- [x] Prior `/root/install.sh` debris backed up to `install.sh.prior-debris.bak.<UTC-ts>` before greenfield overwrite (per T011 + T006 decisions)
- [x] Greenfield framing in file header explicitly cites T011 + T006 decisions

**Implement-stage (in-progress — partial completion):**
- [x] STUB: dependency check (python3, jq, nft, ip, wpa_supplicant) — implemented 2026-05-06; OS-family-aware install hint (debian/rhel/arch); conditional optional-deps per WITH_BRIDGE/WITH_WIFI; `--dry-run` warns on missing, real-install exits 2. Verified: 3 toggle scenarios produce correct required-set (`base mode=bridge` requires nft+ip+wpa_supplicant; `--no-wifi` drops wpa_supplicant; `--mode endpoint` drops bridge+wifi deps). brctl replaced by `ip` (iproute2) — modern alternative.
- [x] STUB: OS-family detection (Debian/RHEL/Arch) — implemented earlier (cycle ~22-24); detect_os_family parses /etc/os-release. Note: original Done When said "Debian 13 verification" — superseded per SB-073 to be OS-family-aware (operator: "this project is not limited to being on debian 13").
- [x] STUB: deploy `~/.claude/settings.json` + hook scripts — implemented (op_install_endpoint_safety_policy at install.sh:415)
- [x] STUB: deploy opencode bridge plugin (`~/.config/opencode/`) — implemented (op_install_opencode_bridge at install.sh:446)
- [x] STUB: configure network bridge (systemd-networkd per T013) — implemented (op_install_network_bridge at install.sh:467)
- [ ] STUB: configure nftables rules (BRIDGE FORWARD/OUTPUT) — bridge-side rules pending T013 operator-decision (default-accept vs default-drop FORWARD policy, threat-model question). Wifi-side INPUT/FORWARD chain DONE (see wifi STUB below).
- [x] STUB: configure management wifi (outbound-only) — implemented 2026-05-06. Authored: `/root/templates/wpa_supplicant/wpa_supplicant-mgmt0.conf.template` (operator-fill placeholders for SSID/PSK/country); `/root/templates/nftables/management-wifi-outbound-only.nft` (deterministic per operator's outbound-only invariant: INPUT drops all except established/related + ICMP echo-reply, OUTPUT accept, FORWARD drops anything touching wifi ifaces). install.sh `op_install_management_wifi` deploys both, runs `nft -c` syntax check, reloads nftables if /etc/nftables.conf includes /etc/nftables.d/*. Verified: `nft -c -f /root/templates/nftables/management-wifi-outbound-only.nft` PASSES; dry-run shows correct deploy sequence with operator-config-required reminder.
- [x] STUB: integrity sentinel registration — implemented (op_install_integrity_sentinel)
- [ ] STUB: post-install verification — partial (op_verify dry-run preview only; real verification logic pending)
- [ ] Idempotency invariant: re-run = no-op when state matches (T016 covers; verifies install_file's "unchanged" path)
- [x] `bash -n install.sh` passes ✓ (verified 2026-05-06 after dep-check edit)
- [ ] `shellcheck install.sh` passes (TBD; not yet run)

## Dependencies

- T011 (greenfield vs extend decision) — gates the authoring approach.
- T006 (prior debris reconciliation) — informs whether the prior `/root/install.sh` is touchable as a starting point.
- T008 (CLAUDE.md methodology section already references install.sh's planned invocations — per Adoption Guide) ✓

## Stage-gate (Implement)

Per CLAUDE.md methodology section: stage `implement` requires the code compiles + lint passes + ≥1 existing file imports new code. For shell scripts: `bash -n install.sh` parses cleanly; `shellcheck install.sh` passes (or operator-set baseline); CLAUDE.md routing references install.sh.

## Relationships

- PART OF: [[root-ghostproxy-m003-foundation-hardening|M003]]
- BLOCKED BY: T011
- RELATES TO: [[T006-prior-debris-reconciliation|T006]]
- BLOCKS: T015 (post-install verification), T017 (foundation gate verification)
