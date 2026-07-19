---
description: Deploy the root-modules agent brain (settings + hooks + rules + commands + agents + modes + skills + tools) into a sister project, so it inherits the same hook envelope + slash commands + tooling. Opt-in per operator directive 2026-05-06.
argument-hint: <target-path> [--dry-run]
---

# /install-agent-brain — install agent brain into a sister project

Deploys the root-modules agent brain into `<target-path>/.claude/` + `<target-path>/tools/` so the target project inherits:

- All security hooks (policy-block, malware-block, leak-detector, etc.)
- All slash commands (/orient, /handoff, /cycle, /stamp-*, /mode-*, etc.)
- All rules (operator words sacrosanct, hook architecture, methodology, etc.)
- All brain-loaded subagents (root-explorer, root-architect, root-pm-scoper)
- All modes (PM Scrum Master, DevOps Architect, Dual Expert)
- All skills (surface-state, surface-blockers)
- All tools (cycle, blockers, progress, decisions, stamp, etc.)

Does NOT deploy OS-level infrastructure (network bridge, management wifi, integrity sentinel, ccstatusline, opencode bridge plugin) — those are scope=root and live only at `$HOME` level via the install.sh `base`/`full` profiles.

Operator directive 2026-05-06 verbatim: *"this should also probably be part of the things we can chose to install install into project and not only the root... not necessarily a by default since hooks are bit more intrusive but I will clearly use them everywhere so far... I should also be able to do it not only from the install scripts"*.

## Usage

When operator invokes this command with `$ARGUMENTS`:

1. Parse `$ARGUMENTS` as `<target-path> [--dry-run]`.
2. If `<target-path>` is missing → print usage + the `EXAMPLES` block below + stop.
3. If `<target-path>` does not exist as a directory → ask operator to confirm creating it OR abort. Don't auto-create silently — operator should know exactly where the brain lands.
4. If `--dry-run` is in `$ARGUMENTS`: invoke install.sh with `--dry-run --profile project --dest <target-path>` and report the deploy plan. NO state change.
5. If NOT `--dry-run`: invoke install.sh with `--profile project --dest <target-path>` for the real deploy. Capture output. On exit code 0 → confirm success + summarize files deployed. On non-zero → surface error.
6. After real install, recommend `/orient` from a fresh session in `<target-path>` to verify the brain loaded correctly.

## Underlying invocation

The command is a thin operator-facing wrapper over install.sh's project profile. Both this command and `bash $HOME/install.sh --profile project --dest <path>` produce identical results — operators can use either path.

## EXAMPLES

```
/install-agent-brain /opt/devops-solutions-information-hub
/install-agent-brain /home/jfortin/openarms --dry-run
/install-agent-brain ~/scratch/test-target --dry-run
```

## What changes on the target

- `<target>/.claude/settings.json` — Claude Code permissions + hook wiring (idempotent — backed up to `<path>.ghostproxy.bak.<ts>` if pre-existing + diverged)
- `<target>/.claude/hooks/*.{sh,py}` — security envelope hooks
- `<target>/.claude/rules/*.md` — on-demand topic rules
- `<target>/.claude/commands/*.md` — operator-invoked slash commands
- `<target>/.claude/agents/*.md` — brain-loaded subagent definitions
- `<target>/.claude/modes/*.md` — mode personae
- `<target>/.claude/skills/<name>/SKILL.md` — auto-trigger skills
- `<target>/tools/*.py` — autopilot Python modules (importable as `python3 -m tools.<name>` from target)

## What does NOT change

- Operator's existing `<target>/.claude/settings.local.json` (gitignored per-machine override) — preserved
- Operator's existing project files outside `<target>/.claude/` and `<target>/tools/`
- OS-level config (no `/etc/` writes; no systemd unit changes; no nftables rules)

## Pre-deploy checklist (operator-suggested before invoking)

- Confirm `<target-path>` is a sister project, not arbitrary directory
- If target already has its own `.claude/{hooks,commands}` — be aware install will deploy alongside (idempotent — backs up divergent files); consider `--dry-run` first
- If target uses different hook conventions (e.g., its own malware-block rules) — they will be replaced; review the dry-run output

## Cross-references

- install.sh project profile: `apply_profile()` at `$HOME/install.sh`
- Operator directive: 2026-05-06 (this session) on cross-project install capability
- Operating principle #9 refinement: knowledge-vs-operational-config distinction (this command writes operational config to a sister project — explicit operator-invoked, not auto)
- **Canonical command index**: [`.claude/commands/README.md`](README.md) (Tier 1 utility — `/install-agent-brain` is the cross-project deploy trigger; complement to install.sh `--profile project` invocation)
- Brain-inheritance pattern: [`.claude/rules/self-reference.md`](../rules/self-reference.md) "Bidirectional inheritance" — $HOME authors operational tooling; sister projects (incl. /opt second-brain) inherit/adapt
- Hooks deployed: 14-hook lifecycle per [`.claude/rules/hook-architecture.md`](../rules/hook-architecture.md)
- Commands deployed: 42 commands per [`.claude/commands/README.md`](README.md)
- Rules deployed: 11 active rules per [`.claude/rules/`](../rules/)
- Modes deployed: 3 personae per [`.claude/modes/`](../modes/)
- Tools deployed: 15 Python modules per [`tools/`](../../tools/)
- Idempotency invariant: install.sh's project profile must be re-runnable without breaking existing target state
- **M-E001-1 productive-cycle action vocabulary**: this command emits **`new-artifact`** action type (real install — files deployed) OR **`read-only-audit`** action type (`--dry-run`) per Hard Rule 14
- Brain-improvement mandate: [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md)
