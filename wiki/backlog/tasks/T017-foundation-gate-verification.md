---
title: "T017 — Verify Foundation gate (install + integrity + bridge + opencode bridge + git audit all green)"
type: task
status: not-started
priority: P0
parent_module: "root-modules-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 0
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m003-foundation-hardening.md
tags: [task, p0, t017, foundation, gate-verification, test, m003]
---

# T017 — Foundation gate verification

## Description

Per the methodology engine's stage `test` gate: 0 test failures, health check clean. For Foundation tier in root-modules: install.sh + integrity check + bridge state + opencode bridge + git audit all green. This task is M003's terminal verification — when it passes, M003 is complete.

## Done When

- [ ] `./install.sh --dry-run` on a clean host: succeeds, prints what would be installed.
- [ ] `./install.sh --dry-run` on an already-installed host: succeeds, prints `unchanged` per file (idempotency confirmation).
- [ ] `./install.sh --check` (or equivalent): all checks pass; exit 0.
- [ ] Integrity sentinel: returns OK; output captured.
- [ ] Bridge state: `brctl show br0` lists both ethernet members; bridge UP; no IP on inspected segment.
- [ ] Management wifi: `ip addr show <wifi-iface>` shows the host's management IP; nftables INPUT chain confirmed outbound-only.
- [ ] opencode bridge: `opencode debug config | grep claude-bridge` non-empty.
- [ ] Git audit: `cd $HOME && git status` clean; `git ls-files` matches whitelist (deny-all + whitelist `.gitignore` invariant intact).
- [ ] Smoke test of safety policy: a tool call to `cat ~/.env` is denied; a tool call to a non-credential path is allowed; tamper detection on settings.json edit refuses subsequent calls.
- [ ] Idempotency confirmation: re-run install.sh produces no state mutation.
- [ ] Foundation gate report (markdown summary) authored at `$HOME/wiki/log/<date>-foundation-gate-report.md`.

## Stage-gate (Test stage exit)

Passing this task marks M003 module complete. M003's stage transitions document → design → scaffold → implement → test all green. Module readiness reaches 100. Module status flows up to active epic.

## Dependencies

- T012 (install.sh) ✓ when authored
- T013 (network bridge config) ✓ when authored
- T014 (endpoint AI safety policy) ✓ when authored
- T015 (post-install verification) ✓ when authored
- T016 (idempotency invariants doc) ✓ when authored

## Relationships

- PART OF: [[root-modules-m003-foundation-hardening|M003]]
- BLOCKED BY: T012, T013, T014, T015, T016
- ENABLES: M004 (Infrastructure tooling — gated on Foundation green)
- ENABLES: Stream 1 M006-M010 (second-brain integration on a stable foundation)
