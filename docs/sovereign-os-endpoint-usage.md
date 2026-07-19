# Sovereign-OS usage — root-modules in endpoint mode (proxy disabled)

> **Status: DRAFT v1 — agent-authored 2026-07-03** per operator directive (verbatim, sacrosanct):
> *"Lets prepare root-ghostproxy for sovereign-os usage, we will use use the repo without the proxy mode enabled."*
> Primary source: [`wiki/log/2026-07-03-sovereign-os-endpoint-prep-directive.md`](../wiki/log/2026-07-03-sovereign-os-endpoint-prep-directive.md).
> Operator may revise / promote / replace.

## Summary

This document is the canonical guide for consuming root-modules from the **sovereign-os arc**
(the SAIN-01 sovereign node that `cyberpunk042/sovereign-os` builds). The consumption posture is
**endpoint mode**: the proxy/IPS half of root-modules — the transparent L2 bridge, the
outbound-only management wifi, and the facultative inspection modules (Suricata, PolarProxy) —
stays **disabled**. What sovereign-os consumes is the other half: the **endpoint AI agent safety
foundation** (machine-level Claude Code + opencode safety envelope, agent brain, tools, integrity
sentinel). Nothing is removed from the repo to achieve this — the mode axis (`--mode endpoint`)
is a runtime selection built into `install.sh` since SB-074/D023; the bridge half remains intact
and facultative for other hosts.

## What "proxy mode disabled" maps to

root-modules has two capability halves (per README.md + `.claude/rules/self-reference.md`):

| Half | Contents | On a sovereign-os node |
|---|---|---|
| **Endpoint AI agent safety (core)** | `settings.json` + machine-level hooks (policy-block, malware-block, leak-detector, session lifecycle, discipline stack) + rules + commands + agents + modes + skills + `tools/*.py` + integrity sentinel + opencode bridge plugin | **INSTALLED** — this is what sovereign-os uses |
| **Network inspection (proxy/IPS)** | Transparent L2 bridge (systemd-networkd + nftables), management wifi (wpa_supplicant, outbound-only), Suricata + PolarProxy modules | **DISABLED** — excluded by `--mode endpoint`; `mode_includes()` gates the `bridge` and `wifi` ops off |

The two axes are orthogonal (per D023): `--profile` decides install SCOPE (foundation vs
foundation+modules), `--mode` decides which foundation ops are APPLICABLE on the host. An op is
installed iff *(profile says yes) AND (mode_includes(op))*.

## Canonical invocation

```bash
# On the sovereign-os node (Debian-family; SAIN-01 target):
git clone <root-modules-url> /tmp/root-modules
cd /tmp/root-modules

# 1. Preview — endpoint mode, base profile (foundation only, no Features modules)
./install.sh --dry-run --profile base --mode endpoint

# 2. Execute (idempotent; re-runs are no-ops where state matches)
sudo ./install.sh --profile base --mode endpoint

# 3. Verify (read-only drift check; same op_verify as post-install verification)
./install.sh --check --profile base --mode endpoint
```

Notes:

- **`--mode endpoint` should be explicit**, not left to `auto`. Auto-detection promotes to
  `bridge` when the host has ≥2 ethernet interfaces + bridge tools (`detect_ghostproxy_mode()`).
  A sovereign node may well have multiple NICs; the operator's stated posture is proxy-off, so
  pin the mode.
- `--profile base` in endpoint mode installs: agent brain (op 1) + tools (op 1b) + opencode
  bridge plugin (op 2) + integrity sentinel baselines (op 5) + post-install verification (op 7).
  Bridge (op 3) and wifi (op 4) are skipped by the mode gate; ccstatusline (op 6) is
  Features-tier and off in `base` (add with `--with-group ccstatusline` if wanted).
- Per-op toggles still compose: e.g. `--no-opencode` if the node runs Claude Code only.
- `--dest <path>` supports non-`$HOME` prefixes if sovereign-os composes the install into an
  image-build stage rather than a live host.

## What lands on the node (endpoint mode, base profile)

Empirically verified 2026-07-03 via `./install.sh --dry-run --profile base --mode endpoint`
(output excerpt — bridge + wifi confirmed skipped):

```
[install.sh] skip: network bridge (per profile/toggle)
[install.sh] skip: management wifi (per profile/toggle)
[install.sh][DRY-RUN] would: compute SHA256 baselines for 5 safety-policy artefacts
[install.sh][DRY-RUN] would: register sentinel state at <dest>/.claude/integrity.json
[install.sh] skip: ccstatusline (per profile/toggle — Features tier)
```

| Surface | Destination | Purpose on the sovereign node |
|---|---|---|
| `settings.json` + hooks | `<dest>/.claude/` | Machine-level safety envelope: deny secret reads, block dangerous bash, leak detection, session lifecycle + discipline stack. Fires for ALL Claude Code sessions on the host (two-layer hook architecture, Hard Rule 5). |
| Rules / commands / agents / modes / skills | `<dest>/.claude/{rules,commands,agents,modes,skills}/` | Agent brain — /orient, /cycle, governance commands, 3 modes, auto-trigger skills. |
| `tools/*.py` | `<dest>/tools/` | Deterministic non-LLM autopilot modules (state, blockers, progress, decisions, cycle, run-tests, …). |
| opencode bridge | `<dest>/.config/opencode/` | opencode plugin sharing the same safety policy. |
| Integrity sentinel | `<dest>/.claude/integrity.json` | SHA256 baselines over the 5 safety-policy artefacts; tamper detection is fail-closed. |

NOT landed (proxy half, excluded by the mode gate): systemd-networkd bridge units, nftables
bridge/wifi rulesets, wpa_supplicant config, Suricata/PolarProxy module hooks.

## Verification gate

Two layers, both runnable on the node and in CI:

1. **Install-state**: `./install.sh --check --profile base --mode endpoint` — read-only op_verify;
   in endpoint mode the bridge-interface check reports as not-applicable/skip rather than FAIL
   (Hard Rule 4: don't fail a foundation gate because a facultative module isn't installed).
2. **Repo-side regression**: `python3 .claude/hooks/tests/test-sovereign-endpoint-mode.py`
   (also aggregated by `python3 -m tools.run-tests`) — asserts the endpoint-mode dry-run plan
   excludes bridge + wifi ops and includes the endpoint safety foundation, for both `base` and
   `full` profiles.

## Cross-repo boundary (per sovereign-os SDD-001)

- sovereign-os **CONSUMES FROM** root-modules only through this repo's install surface
  (`install.sh` + this doc). It does not re-derive or fork the safety envelope.
- root-modules stays authoritative for the endpoint safety policy content (hooks, deny-sets,
  integrity mechanism). sovereign-os stays authoritative for the OS image pipeline + profile
  schema; where in the image lifecycle (pre-install / during-install / post-install) the
  root-modules install step runs is a sovereign-os decision.
- runtime security policy on the node beyond the AI-agent envelope (Tetragon daemon, notifier
  channels, escalation engine) is **selfdef**'s surface — not this repo's. The two compose:
  root-modules governs the AI-agent tool-call surface; selfdef governs the OS runtime-defense
  surface.
- sovereign-os-side doc updates (its SDD-001 "dormant" row, ARCHITECTURE/README tables) are that
  repo's own artifacts to evolve — deliberately not edited from this repo (reverse flows are
  forbidden by default per the boundary contract).

## Re-enabling the proxy half later (nothing was discarded)

Endpoint mode is a selection, not an amputation. If a future sovereign node should ALSO act as the
inspection bridge, the same checkout supports it: `sudo ./install.sh --profile base --mode hybrid`
(endpoint + bridge on one host) or `--mode bridge` (bridge-only posture). Module work
(Suricata/PolarProxy) remains operator-driven future-session work per M005.

## Cross-references

- Operator directive (primary source): [`wiki/log/2026-07-03-sovereign-os-endpoint-prep-directive.md`](../wiki/log/2026-07-03-sovereign-os-endpoint-prep-directive.md)
- Mode axis design: install.sh header comments (SB-074) + D023 in [`wiki/governance/decisions.md`](../wiki/governance/decisions.md)
- Setup path (general): [`README.md`](../README.md) § Setup Path
- Endpoint safety policy content: [`SECURITY.md`](../SECURITY.md) + T014 smoke test
- Regression test: [`.claude/hooks/tests/test-sovereign-endpoint-mode.py`](../.claude/hooks/tests/test-sovereign-endpoint-mode.py)
- sovereign-os boundary contract: `cyberpunk042/sovereign-os docs/sdd/001-cross-repo-boundaries.md`
