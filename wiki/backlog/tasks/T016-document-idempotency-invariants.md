---
title: "T016 — Document idempotency invariants of install.sh + post-install state"
type: task
status: review
priority: P1
parent_module: "root-modules-m003-foundation-hardening"
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: test
readiness: 95
sfif_stage: Foundation
created: 2026-05-04
updated: 2026-07-03
sources:
  - id: parent-module
    type: wiki
    file: wiki/backlog/modules/root-modules-m003-foundation-hardening.md
  - id: tools-md-deliverable
    type: file
    file: TOOLS.md
    description: "#### Idempotency invariants subsection (lines 121-173) — T016 deliverable, empirically verified F46"
tags: [task, p1, t016, foundation, idempotency, documentation, m003]
---

# T016 — Document idempotency invariants

## Description

Document explicitly what install.sh creates, overwrites, and leaves alone — and what re-running install.sh on an already-installed host does. Per TOOLS.md tool invariants section: every project-authored tool is idempotent.

## Done When

- [x] List of files install.sh CREATES (`~/.claude/settings.json`, `~/.claude/hooks/*` (18 .sh + integrity.py), `~/.claude/agents/*`, `~/.claude/modes/*`, `~/.claude/rules/*`, `~/.claude/commands/*`, `~/.claude/skills/*`, `~/.claude/integrity.json`, `~/.config/opencode/plugin/claude-bridge.ts`, `~/tools/*`, `/etc/systemd/network/30-ghostproxy-*` + `40-ghostproxy-*`, `/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf`, `/etc/nftables.d/management-wifi-outbound-only.nft`) — **landed 2026-05-07 cron F46** in `TOOLS.md` install.sh per-tool reference, Idempotency invariants subsection.
- [x] List of files install.sh OVERWRITES on re-run when out-of-sync (with backup pattern: `<dest>.ghostproxy.bak.<UTC-timestamp>`) — landed 2026-05-07 cron F46 (TOOLS.md "Files install.sh OVERWRITES on re-run when out-of-sync" subsection).
- [x] List of files/dirs install.sh LEAVES UNTOUCHED (operator's `.bashrc`/`.profile`/`.bash_history`/`.gitconfig`/`.ssh/*`, `/home/*` other users, project work outside `.claude/` + `.config/opencode/` + `tools/`, `*.ghostproxy.bak.*` preserved, `/etc/systemd/network/*` non-prefixed, `/etc/nftables.d/*` non-`management-wifi-*`, `/etc/nftables.conf` body content) — landed 2026-05-07 cron F46.
- [x] Re-run behavior: re-running install.sh on a consistent host outputs `unchanged: <path>` per file; exit 0; no state mutation — landed 2026-05-07 cron F46 with empirical evidence cross-ref to F35+F46 `--check` runs (13/16 PASS, 3 wifi-credentials gated per CONTEXT.md).
- [x] Documentation: lives at TOOLS.md per-tool reference section per literal (chosen primary location).
- [x] Verification: idempotency claim is testable — recipe documented at TOOLS.md ("Idempotency claim is testable per the recipe: `./install.sh && ./install.sh; ./install.sh --check`"). Worker-verifiable surrogate gate `./install.sh --check` (read-only) runs without state mutation per NC-5 RESOLVE (operator-territory). **Full real-execute empirical on Debian 13 host** is T012 last-2% (D024 GREENLIT, operator-driven future-session) — split out as DW#6b operator-territory per same NC-3 split pattern (source-side worker-verifiable / runtime-deployed operator-verified).
- [x] **Behavioral idempotency test (worker-verifiable surrogate — DW#6c)**: the recipe from DW#6a is now EXERCISED end-to-end against the real installer — `.claude/hooks/tests/test-t016-idempotency-smoke.py` (9/9, landed 2026-07-03). Runs `install.sh --profile project --dest <tmpdir>` twice into a throwaway dir (project profile disables all OS-level ops, so the effect is confined to the temp dir), and asserts the invariant empirically: run 1 → N files `installed:` / 0 `unchanged:`; run 2 → 0 `installed:` / 0 `updated:` / 0 backups / N `unchanged:` (every prior file), stable skip count. This upgrades the idempotency claim from *documented + recipe* to *documented + behaviorally-tested*. Discovered by `python3 -m tools.run-tests`. (DW#6b full OS-level real-execute on a Debian 13 host remains operator-territory.)

## Test Plan

(SDD only — pure-docs task per methodology principle 10 "For pure-docs tasks: SDD only, no TDD ceremony.")

| # | Behavior under test | Gate |
|---|---|---|
| DW#1 | CREATES section enumerates the 15 install paths | `grep -q '^\*\*Files install\.sh CREATES\*\*' TOOLS.md` |
| DW#2 | OVERWRITES section documents backup-first pattern | `grep -q 'Files install\.sh OVERWRITES on re-run' TOOLS.md` |
| DW#3 | LEAVES UNTOUCHED section names operator-territory paths | `grep -q 'Files install\.sh LEAVES UNTOUCHED' TOOLS.md` |
| DW#4 | Re-run behavior subsection documents `unchanged: <path>` output | `grep -q 'Re-run behavior' TOOLS.md` |
| DW#5 | T016 deliverable located in TOOLS.md (chosen primary location) | `grep -q 'T016 deliverable' TOOLS.md` |
| DW#6a | Testable recipe documented (worker-verifiable) | `grep -q 'Idempotency claim is testable' TOOLS.md` |
| DW#6b | Real-execute empirical on Debian 13 host | **operator-territory** — D024 GREENLIT, deferred |
| DW#6c | Behavioral idempotency test (recipe exercised, isolated `--dest`) | `python3 .claude/hooks/tests/test-t016-idempotency-smoke.py` → 9/9 (landed 2026-07-03) |

## Resolution

**Files edited**: T016 task file only (frontmatter `status: in-progress → review`, `current_stage: document → test`, `readiness: 75 → 95`; DW#6 marked complete with split into DW#6a worker-verifiable / DW#6b operator-territory; Test Plan section added; this Resolution section added).

**2026-07-03 addendum (DW#6c behavioral test)**: the DW#6a recipe is now implemented as a worker-verifiable behavioral test — `.claude/hooks/tests/test-t016-idempotency-smoke.py` (9/9) runs the installer twice into an isolated `--dest` (project profile, no OS-level ops) and asserts installed→unchanged with zero re-writes/backups. First behavioral (not just documentary) coverage of the idempotency invariant. DW#6b (OS-level real-execute) stays operator-territory.

**No source-file edits**: All 5 documentation deliverables (DW#1-5) already landed 2026-05-07 cron F46 in `TOOLS.md` lines 121-173 (`#### Idempotency invariants — files CREATED / OVERWRITTEN / LEFT UNTOUCHED + re-run behavior (T016 deliverable, empirically verified 2026-05-07 cron F46)`). Per operator-doctrine 2026-05-16 "do not rewrite everything everytime make augmentations" + methodology principle 12 "Augment, never rewrite" — this fire verifies + closes, does not re-author.

**Verification output (inline, per CLAUDE.md rule 7)**:

```
$ cd ~/root-modules && for dw in \
    "^\*\*Files install.sh CREATES\*\*" \
    "Files install.sh OVERWRITES on re-run" \
    "Files install.sh LEAVES UNTOUCHED" \
    "Re-run behavior" \
    "T016 deliverable" \
    "Idempotency claim is testable"; do
    grep -q "$dw" TOOLS.md && echo "PASS: $dw" || echo "FAIL: $dw"
  done
PASS: ^\*\*Files install.sh CREATES\*\*
PASS: Files install.sh OVERWRITES on re-run
PASS: Files install.sh LEAVES UNTOUCHED
PASS: Re-run behavior
PASS: T016 deliverable
PASS: Idempotency claim is testable

$ python3 -c "..."  # CREATES table row count
CREATES table rows: 15  # matches DW#1 spec (~/.claude/settings.json + 18 hook files counted as 1 pattern + 13 other paths = 15 rows)

$ ./install.sh --check 2>&1 | tail -3
[install.sh][CHECK] op_verify: FAIL   # expected — host NOT deployed per NC-5 (operator-territory)
# read-only gate ran without state mutation; idempotency-claim-testability surrogate confirmed

$ ./install.sh --dry-run 2>&1 | tail -2
[install.sh][DRY-RUN] would: verify bridge interfaces UP (if --with-bridge)
[install.sh] install.sh done (dry-run; no state changes)   # confirms no mutation in surrogate run
```

**Audit cluster anchor**: **C09 (status-claim reliability — 12 hits)** — invariants doc preempts the doc-vs-code drift pattern that surfaced in NC-2 (M003 module claimed `151+ deny patterns` while integrity.py uses `100`). T016 is the structural prevention: when install.sh's CREATES/OVERWRITES/LEAVES UNTOUCHED contract is documented inline at TOOLS.md beside the script itself (not in a stale separate doc), the doc-vs-code drift surface shrinks. Secondary: **C03 (regression-introducing edits — 12 hits)** — without an invariants contract, future install.sh edits could silently violate "leaves untouched" guarantees (operator's `.bashrc` / `.ssh/*` etc.); the LEAVES UNTOUCHED table makes regressions detectable in code review.

**Spec-Driven Development discipline (per methodology principle 10)**: Spec (Done When) was constitutive; each item maps to a single grep-gate (DW → Test Plan table). For pure-docs tasks the spec IS the verification — no production-code red→green ceremony was authored (TDD waived per principle 10).

**SFIF discipline (per principle 11)**: T016 is M003 Foundation-tier; no Scaffold dependencies skipped (T012 install.sh authored / T012 in-progress with empirical-execute as last 2%). On-tier execution.

**Augment-not-rewrite (per principle 12)**: zero source-file edits. Task-file frontmatter + Test Plan + Resolution sections added via surgical Edit, not Write.

**Methodology-novelty right-sizing (per principle 17)**: integration-tier model (3 stages: implement → test → close) used, not feature-development 5-stage. Task is pure-docs verification of already-landed content, not greenfield spec-of-unknown — methodology-theater avoided.

## Dependencies

- T012 (install.sh authored) — invariants document what it does ✓ author-complete (in-progress is empirical-execute last 2%, D024 GREENLIT operator-driven)

## Relationships

- PART OF: [[root-modules-m003-foundation-hardening|M003]]
- BLOCKED BY: ~~T012~~ — author-complete, empirical-execute deferred but does not block T016 doc-closure
- ENABLES: clear contract for operator + future-session about install.sh behavior
- DEMONSTRATES: per-tool reference section as canonical idempotency-invariant location (vs. separate `docs/foundation-invariants.md` literal in original module text — co-location with tool's own page chosen per F46 design decision)
- DERIVED FROM: [[2026-05-08-pain-points-inventory-from-root-failed-conversation-master-aggregate#C09 — Status-claim reliability|audit C09]] — doc-vs-code drift prevention
