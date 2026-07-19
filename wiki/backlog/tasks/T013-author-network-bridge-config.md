---
title: "T013 — Author network bridge configuration (br0 + ethernet members + management wifi outbound-only)"
type: task
status: in-progress
priority: P0
parent_module: "root-modules-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: scaffold
readiness: 78
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-07
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m003-foundation-hardening.md
  - id: architecture-md
    type: wiki
    file: ARCHITECTURE.md
    description: "Network position + interface roles + bridge configuration"
tags: [task, p0, t013, foundation, network, bridge, design, m003]
---

# T013 — Author network bridge configuration

## Description

Configure the host's network as the transparent L2 bridge: two ethernet interfaces as members of `br0`, no IPs on the inspected segment, management wifi as outbound-only client.

## Subtasks (decision points)

| Decision | Options | Notes |
|---|---|---|
| Network configuration tool | `ifupdown` (Debian classic) / `netplan` / `systemd-networkd` | Operator-decision; each has trade-offs in declarativeness vs operational maturity |
| Bridge MTU | 1500 (default) / jumbo if upstream supports | If modules will inspect: must match across both members |
| Hardware offloads | Disabled (GRO, LRO, TSO) | Required for inline inspection; keep disabled even before modules install |
| Wifi client mechanism | `wpa_supplicant` direct / NetworkManager | If host runs NetworkManager elsewhere, integrate; if not, wpa_supplicant is simpler |
| Bridge default policy | nftables FORWARD default-accept / default-drop | Operator's threat model decides |

## Done When

- [x] Network config tool chosen (operator decision); files authored per tool's syntax — **D024 GREENLIT 2026-05-05** (`tool=systemd-networkd`); 3 files deployed: `/etc/systemd/network/30-ghostproxy-bridge.netdev` (NetDev gpbr0 with STP=no, ForwardDelaySec=0, Priority=32768) + `/etc/systemd/network/30-ghostproxy-bridge.network` (no IP, LinkLocalAddressing=no, DHCP=no, IPv6AcceptRA=no, ConfigureWithoutCarrier=yes) + `/etc/systemd/network/40-ghostproxy-bridge-members.network` (Bridge=gpbr0, default Match Name=en* customizable via `--bridge-member1`/`--bridge-member2` flags).
- [ ] Bridge `gpbr0` config: two ethernet members, no IP, hardware offloads disabled. **PARTIAL 2026-05-07 cron F47**: ✅ gpbr0 deployed + L2-only (no IP empirically verified per `.network` content) + member assignment via Bridge=gpbr0 directive · ⚠️ **GAP**: hardware offloads (GRO/LRO/TSO) NOT explicitly disabled in deployed configs (no `[Link]` section / ethtool directive). Operator-pending: extend templates with offload-disable directives OR document acceptance of default offload behavior on this Debian 13 host (operator-decision since changing security-envelope-adjacent network config requires review per CLAUDE.md Hard Rule 3-style framing).
- [ ] Management wifi config: client to operator's existing SSID, INPUT chain drops everything except established/related, no inbound services bind. **PARTIAL 2026-05-07 cron F47**: ✅ Templates authored at `templates/wpa_supplicant/` + `templates/nftables/management-wifi-outbound-only.nft` · ⚠️ **GAP**: deployment is operator-credentials-gated per CONTEXT.md (`/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf: missing` + `/etc/nftables.d/management-wifi-outbound-only.nft: missing` per F35+F46 install-check).
- [x] systemd unit (or equivalent) brings bridge UP at boot — empirically confirmed `br0 UP: PASS` (more accurately gpbr0 UP) per F35+F46 install-check; systemd-networkd manages via `.netdev` + `.network` files.
- [x] Recovery: console-only fallback documented — **landed 2026-05-07 cron F48** in `TOOLS.md` install.sh per-tool reference, "Recovery / console-only fallback" subsection. Covers 5 scenarios: A (wifi-mgmt0 fails to associate) · B (bridge gpbr0 no-carrier) · C (bridge breaks SSH — emergency disable systemd-networkd + move configs) · D (safety envelope tampered — re-run install.sh OR restore from `.ghostproxy.bak.*` backup) · E (emergency revert all ghostproxy changes). Each scenario: console login → diagnose commands → hot-fix or fallback steps → verification. Recovery-doc-maintenance footnote: cross-references Idempotency invariants subsection so future install.sh touchpoints get scenario coverage added in lockstep.
- [ ] Verification: `brctl show br0` lists both members; `ip addr` shows only management-wifi IP; nftables INPUT chain confirmed outbound-only on wifi. **OPERATOR-EMPIRICAL PENDING**: full verification recipe requires real Debian 13 host execution (T012 last-2% per D024 operator-driven future-session); `gpbr0 UP` empirical fragment confirmed.

## Dependencies

- T011 (foundation-IaC approach) — gates authoring style
- T012 (install.sh) — install.sh deploys this config

## Stage-gate

Per methodology stage `scaffold`: type-definitions / schema / config-files allowed; no implementation. The network config FILES are scaffold-stage outputs; the actual bringing-up of the bridge is implement-stage (T012's install.sh apply).

## Relationships

- PART OF: [[root-modules-m003-foundation-hardening|M003]]
- BLOCKED BY: T011
- RELATES TO: [[T012-author-install-sh|T012]] (install.sh deploys this config)
- BLOCKS: T015 (post-install verification of bridge state)
