---
title: "T014 — Author endpoint AI agent safety policy (deny-set + hooks + integrity sentinel + opencode bridge)"
type: task
status: not-started
priority: P0
parent_module: "root-ghostproxy-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: design
readiness: 25
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-ghostproxy-m003-foundation-hardening.md
  - id: agents-md
    type: wiki
    file: AGENTS.md
    description: "Cross-tool agent contract: canonical envelope shape, hook firing order, two-layer architecture"
  - id: security-md
    type: wiki
    file: SECURITY.md
    description: "Layer-by-layer protections + fail-closed invariants"
tags: [task, p0, t014, foundation, endpoint-safety, deny-set, hooks, integrity-sentinel, m003]
---

# T014 — Author endpoint AI agent safety policy

## Description

Author the endpoint half of the system AI safety setup per operator's verbatim: *"secure an OS and configure claude code and opencode at the root with all the safety needed."* This is the OS-level shared policy that every AI tool on the host obeys via its own extension mechanism.

## Subtasks (per AGENTS.md cross-tool agent contract + SECURITY.md layer-by-layer protections)

| Component | Spec |
|---|---|
| `~/.claude/settings.json` | Canonical policy: deny-set patterns + hooks config (PreToolUse, PostToolUse, SessionStart, SessionEnd) |
| Deny-set | Credential-shaped paths: `.env*`, `*.pem`, `*.key`, `id_rsa*`, `.aws/credentials`, `kubeconfig`, `.netrc`, `.git-credentials`, `**/secret*` + shell-exfil-readers (`cat .env*`, `base64 *.pem`, `grep * *credentials*`, etc.). Operator-curated count above the integrity-sentinel's threshold. |
| Pre-tool-call hooks | Credential-file blocker (defense-in-depth on top of deny-set) + behavior-pattern blocker (shell-exfil idioms, malicious-shape inputs) |
| Post-tool-call hooks | Leak-detector — scans output for credential-shaped values (Anthropic / OpenAI / GitHub / GitLab / AWS / Stripe / SendGrid / npm / Telegram / JWT / private keys / DB connection strings / Authorization headers) |
| Session-lifecycle hooks | Banner + integrity check at SessionStart; per-session deny/leak count at SessionEnd |
| Integrity sentinel | Fail-closed pre-tool-call check: settings.json present, hooks not disabled, deny-set above threshold, all required hook scripts present + executable + non-suspicious size |
| opencode bridge plugin | Maps opencode's tool names to canonical envelope; spawns the same hook scripts. Type-only-deps on `@opencode-ai/plugin`. |

## Done When

- [ ] All policy files exist + are integrated into install.sh's deployment.
- [ ] Hooks are executable (0755 for .sh; 0644 for .py).
- [ ] Deny-set count above integrity-sentinel's threshold.
- [ ] opencode bridge resolves: `opencode debug config | grep claude-bridge` non-empty.
- [ ] Smoke test: tool call to a credential path is denied; tool call to allowed path is permitted; tamper detection on settings.json edit refuses subsequent calls.
- [ ] No reference to prior $HOME debris in the new authored files (greenfield) OR explicit reframing if extending prior (per T011 decision).

## Dependencies

- T011 (foundation-IaC approach) — greenfield vs extend gates the authoring style
- T006 (prior debris reconciliation) — informs whether prior hooks are reusable

## Stage-gate

Multiple stages — per ALLOWED/FORBIDDEN per stage:
- Document stage: hook design specs (what each hook does, in prose)
- Design stage: hook ADRs (why deny-by-default, why fail-closed-tamper, why two-layer)
- Scaffold stage: hook script SKELETONS with type-stubs (no business logic yet)
- Implement stage: full hook implementation
- Test stage: hooks tested against canary inputs (legitimate tool calls allowed; credential-shaped paths denied; tamper detection refuses)

## Relationships

- PART OF: [[root-ghostproxy-m003-foundation-hardening|M003]]
- BLOCKED BY: T011
- RELATES TO: [[T006-prior-debris-reconciliation|T006]]
- BLOCKS: T015 (post-install verification: integrity check OK), T017 (foundation gate)
