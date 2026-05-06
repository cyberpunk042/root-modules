---
title: "T016 — Document idempotency invariants of install.sh + post-install state"
type: task
status: not-started
priority: P1
parent_module: "root-ghostproxy-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 25
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-05-05
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-ghostproxy-m003-foundation-hardening.md
tags: [task, p1, t016, foundation, idempotency, documentation, m003]
---

# T016 — Document idempotency invariants

## Description

Document explicitly what install.sh creates, overwrites, and leaves alone — and what re-running install.sh on an already-installed host does. Per TOOLS.md tool invariants section: every project-authored tool is idempotent.

## Done When

- [ ] List of files install.sh CREATES (e.g. `~/.claude/settings.json`, `~/.claude/hooks/*`, `~/.config/opencode/*`, network config files).
- [ ] List of files install.sh OVERWRITES on re-run when out-of-sync (with backup pattern: `<dest>.ghostproxy.bak.<UTC-timestamp>`).
- [ ] List of files/dirs install.sh LEAVES UNTOUCHED (e.g. operator's other dotfiles, project files outside `~/.claude/` and `~/.config/opencode/`).
- [ ] Re-run behavior: re-running install.sh on a consistent host outputs `unchanged: <path>` per file; exit 0; no state mutation.
- [ ] Documentation: lives at TOOLS.md per-tool reference section (or a new `$HOME/docs/foundation-invariants.md` if operator prefers separate doc).
- [ ] Verification: idempotency claim is testable — `./install.sh; ./install.sh` produces the same end state and the second run is a no-op.

## Dependencies

- T012 (install.sh authored) — invariants document what it does

## Relationships

- PART OF: [[root-ghostproxy-m003-foundation-hardening|M003]]
- BLOCKED BY: T012
- ENABLES: clear contract for operator + future-session about install.sh behavior
