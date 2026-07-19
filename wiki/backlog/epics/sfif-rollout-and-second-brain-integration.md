---
title: "Epic — root-modules SFIF Rollout + Second-Brain Integration (2026-05)"
aliases:
  - "Epic — root-modules SFIF Rollout + Second-Brain Integration (2026-05)"
type: epic
domain: cross-domain
status: draft
confidence: high
maturity: seed
priority: P0
task_type: epic
current_stage: document
readiness: 10
stages_completed: []
artifacts: []
created: 2026-05-04
updated: 2026-05-04
sources:
  - id: operator-directive-2026-05-04-root-prep
    type: directive
    file: raw/notes/2026-05-04-prepare-root-ghostproxy-as-sister-type-root-group-operating-system-setup.md
  - id: root-modules-identity-profile
    type: wiki
    file: wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md
  - id: root-modules-readme
    type: file
    file: $HOME/README.md
    description: "Read in full 2026-05-04 — architecture, install steps, v1 limitations"
  - id: model-sfif-architecture
    type: wiki
    file: wiki/spine/models/quality/model-sfif-architecture.md
    description: "Build framework: Scaffold → Foundation → Infrastructure → Features (recursive, applies at project / feature / component levels)"
  - id: sister-projects-registry
    type: file
    file: wiki/config/sister-projects.yaml
    description: "root-modules entry added 2026-05-04 with type=root, group=operating-system-setup, auto_connect=false"
tags: [epic, root-modules, sfif, second-brain-integration, sister-project, type-root, group-operating-system-setup, pre-milestone, future-session-work]
---

# Epic — root-modules SFIF Rollout + Second-Brain Integration (2026-05)

## Summary

Build root-modules from its current SFIF Foundation tier (install.sh + base hooks operable) to full Infrastructure + Features tier, in parallel with hooking it into the second-brain ecosystem as a sister project of `type=root, group=operating-system-setup`. The work is split into two independent-but-interlocking streams: **Stream 2** (pure SFIF project base — author CLAUDE.md, AGENTS.md, methodology layer, infrastructure tooling, and OS-setup features beyond AI-safety hooks) and **Stream 1** (second-brain integration — gated on Stream 2 Scaffold output, specifically AGENTS.md existing in root-modules first). All work happens inside `$HOME` (or wherever root-modules is installed) — therefore in a future session, NOT this preparation session. This epic captures the future-session work plan so a fresh agent in the root-modules context can pick up cold.

## Goals

> [!info] Outcomes — what done means for this epic
>
> - root-modules reaches SFIF Infrastructure tier (methodology-aware tooling, validation pipeline, agent harness layer in place)
> - root-modules reaches SFIF Features tier on at least one specialized OS-setup feature beyond AI-safety hooks (suricata module OR polarproxy module — operator picks which first)
> - root-modules is connected as a second-brain sister: research-wiki MCP entry installed in its `.mcp.json`, gateway/view forwarders installed in its `tools/`, AGENTS.md has the `## Second Brain Connection` block
> - From a fresh Claude Code session opened in root-modules, the agent has full operating environment: project-specific CLAUDE.md, universal AGENTS.md, methodology pointer (or local methodology), backlog, log/, hooks, second-brain MCP available
> - Type=root and Group=operating-system-setup are operator-confirmed (or revised) once the rollout has shaken out edge cases
> - sister-projects.yaml `auto_connect` for root-modules is operator-decided based on the integration outcome

## Done When

> [!info] Verifiable completion criteria
>
> ### Stream 2 — Pure SFIF project base (root-modules itself)
>
> - [ ] AGENTS.md exists at root-modules repo root (universal cross-tool context — < 100 lines per three-layer architecture)
> - [ ] CLAUDE.md exists at root-modules repo root (Claude Code-specific routing — < 200 lines per CLAUDE.md structural patterns standards)
> - [ ] root-modules README.md updated to document its position as sister project (type=root, group=operating-system-setup, second-brain-connected)
> - [ ] Methodology layer present — either local `wiki/config/methodology.yaml` OR a documented pointer to second-brain's methodology
> - [ ] At least one specialized feature module SFIF-Foundation reached (suricata module OR polarproxy module) with: design doc + install integration into install.sh + tests
> - [ ] `./install.sh --dry-run` and `./install.sh --check` both succeed cleanly (Foundation gate verified explicitly)
> - [ ] `integrity.py integrity_check()` continues to return None (OK) after the rollout — fail-closed properties preserved
> - [ ] Project's own backlog populated with the work decomposition (epic-of-modules-of-tasks per backlog hierarchy rules)
>
> ### Stream 1 — Second-brain integration (sister hookup)
>
> - [ ] `python3 -m tools.setup --connect-project <root-modules-path>` runs from second brain and succeeds
> - [ ] root-modules/.mcp.json has a `research-wiki` MCP server entry pointing at the second brain's venv + cwd
> - [ ] root-modules/tools/gateway.py forwarder exists and `python3 -m tools.gateway orient` runs from inside root-modules
> - [ ] root-modules/tools/view.py forwarder exists and `python3 -m tools.view spine` runs from inside root-modules
> - [ ] root-modules/AGENTS.md contains the `## Second Brain Connection` auto-generated block (see `_install_view_forwarder` + AGENTS.md updater in `tools/setup.py`)
> - [ ] sister-projects.yaml entry's `auto_connect` field flipped to `true` IF operator authorizes (operator-decision)
>
> ### Cross-cutting verification
>
> - [ ] A fresh Claude Code session opened with `claude` in the root-modules repo orients itself within 60 seconds via CLAUDE.md + gateway orient — no manual intervention
> - [ ] Two-layer hook architecture preserved: machine-level `~/.claude/settings.json` hooks fire BEFORE project-level `<root-modules>/.claude/` hooks (project may not have a project-level layer initially — that's fine, machine layer suffices)
> - [ ] A worked example: ingest the root-modules README into the second brain as a source-synthesis page (proves bidirectional knowledge flow works)

## Streams and Module Decomposition

### Stream 2 modules (SFIF project base — execute in SFIF order)

| Module | SFIF stage | Focus |
|---|---|---|
| **M1 — Author CLAUDE.md + AGENTS.md** | Scaffold | Three-layer agent context for the project. AGENTS.md cross-tool universal; CLAUDE.md Claude-Code-specific routing table. |
| **M2 — Methodology layer decision** | Scaffold/Design | Decision: local methodology.yaml OR pointer to second brain. Per Goldilocks (this project at simplified profile right-sized for SFIF Foundation phase), pointer is likely. Decide and document. |
| **M3 — Foundation hardening** | Foundation | Verify `./install.sh --dry-run` + `./install.sh --check`; expand README install + verify steps; document idempotency invariants explicitly |
| **M4 — Infrastructure tooling** | Infrastructure | Project-internal tooling: `tools/` dir with at minimum a verifier (`tools/verify-policy.py` runs integrity_check + deny-list count + hook permissions check); validation pipeline (CI or local pre-commit) |
| **M5 — First specialized feature module** | Features | Operator picks: suricata IPS module OR polarproxy TLS inspection module. Design + integration + tests. Single-module first; second module is its own epic. |

### Stream 1 modules (Second-brain integration)

| Module | Focus |
|---|---|
| **M6 — Pre-connect verification** | Verify Stream 2 M1 (AGENTS.md) is complete; verify root-modules is at a clean git state; verify operator authorizes the connection |
| **M7 — Connect** | Run `python3 -m tools.setup --connect-project <path>` from second brain. Verify all 3 outputs (`.mcp.json` entry, `tools/gateway.py` forwarder, `tools/view.py` forwarder, AGENTS.md `## Second Brain Connection` block) |
| **M8 — Smoke test from inside** | Open fresh Claude Code session in root-modules. Run `gateway orient` (should resolve to the connected second brain). Run `view spine` (should print the second brain's spine). |
| **M9 — Worked example** | Ingest root-modules README as a source-synthesis page in the second brain. Proves the bidirectional flow. |
| **M10 — sister-projects.yaml flip** | Operator-decision: flip `auto_connect: false` → `true` if integration is stable, OR keep `false` and document why. |

## Dependencies

- **Hardware/host:** Any Linux host with bash + python3 + git. The two-layer hook architecture (machine-level `~/.claude/settings.json`) requires Claude Code installed on the host. Multi-host install (`./install.sh --dest PATH`) is supported.
- **Operator authorization for Stream 1:** explicit. `auto_connect: false` in sister-projects.yaml is the gate.
- **Stream 2 M1 (AGENTS.md) blocks Stream 1 M7 (--connect-project):** the connect script writes the `## Second Brain Connection` block INTO an existing AGENTS.md or CLAUDE.md.
- **Operator decision M5:** which module first (suricata or polarproxy). Affects M5 scope.
- **Operator decision M2:** local methodology vs pointer. Affects M2 + downstream Infrastructure layer.
- **No dependency on `$HOME` access from the second brain side** — Stream 1 connect runs from inside the second brain pointing AT root-modules via `--connect-project <path>`. The second brain pushes config; the project receives.

## Open Questions

> [!question] Should root-modules carry its own methodology.yaml or just point to the second brain?
> Per Goldilocks (simplified profile, micro scale), pointing to the second brain is likely the right call — root-modules doesn't need a full methodology engine on day one. But the project may grow and want its own. Decide in M2. (Requires: operator confirmation)

> [!question] Which feature module first — suricata or polarproxy?
> Both are operator-named. Suricata is a more mature OSS project with simpler integration. Polarproxy is more specialized (TLS inspection). Operator picks. (Requires: operator decision in M5)

> [!question] Will root-modules ever auto-connect from `python3 -m tools.setup`?
> `auto_connect: true` means `tools.setup` (no args) will hook it up automatically when the path resolves locally. Given root-modules is *operating-system-setup* and gates the security envelope, operator may want auto-connect to stay false even after the integration is stable — manual `--connect-project` keeps the operator in the loop. (Requires: operator decision in M10)

> [!question] Should other type=root projects share infrastructure with root-modules?
> If future projects of type=root + group=operating-system-setup appear (container-runtime-setup, network-edge-setup, etc.), do they share modules / hook patterns / install conventions with root-modules? Or are they independent? (Requires: when the second project of this group exists)

## Pickup-cold runbook (for the future session)

```bash
# 1. Open Claude Code in root-modules
cd $HOME  # or wherever root-modules is on the host
claude

# 2. Read this epic for context
cat /opt/devops-solutions-information-hub/wiki/backlog/epics/pre-milestone/root-modules-sfif-rollout-and-second-brain-integration-2026-05.md

# 3. Read the operator directive verbatim
cat /opt/devops-solutions-information-hub/raw/notes/2026-05-04-prepare-root-ghostproxy-as-sister-type-root-group-operating-system-setup.md

# 4. Read the identity profile (the brain's understanding of root-modules)
cat /opt/devops-solutions-information-hub/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md

# 5. Read the SFIF model
cat /opt/devops-solutions-information-hub/wiki/spine/models/quality/model-sfif-architecture.md

# 6. Start with Stream 2 M1: author AGENTS.md + CLAUDE.md for root-modules
# 7. Then M2 — methodology decision
# 8. Then M3 — Foundation hardening
# 9. Branch into M4 (infrastructure) and prepare for M7 (connect from second brain)
```

## Relationships

- BUILDS ON: [[model-sfif-architecture|Model — SFIF and Architecture]]
- BUILDS ON: [[project-self-identification-protocol|Project Self-Identification Protocol — The Goldilocks Framework]]
- BUILDS ON: [[model-claude-code|Model — Claude Code]]
- BUILDS ON: [[model-skills-commands-hooks|Model — Skills, Commands, and Hooks]]
- IMPLEMENTS: [[infrastructure-as-code-patterns|Infrastructure as Code Patterns]]
- RELATES TO: [[four-project-ecosystem|Four-Project Ecosystem]]
- RELATES TO: [[ecosystem-feedback-loop-wiki-as-source-of-truth|Ecosystem Feedback Loop — Wiki as Source of Truth]]
- FEEDS INTO: [[model-ecosystem|Model — Ecosystem Architecture]]

## Backlinks

[[model-sfif-architecture|Model — SFIF and Architecture]]
[[project-self-identification-protocol|Project Self-Identification Protocol — The Goldilocks Framework]]
[[model-claude-code|Model — Claude Code]]
[[model-skills-commands-hooks|Model — Skills, Commands, and Hooks]]
[[infrastructure-as-code-patterns|Infrastructure as Code Patterns]]
[[four-project-ecosystem|Four-Project Ecosystem]]
[[ecosystem-feedback-loop-wiki-as-source-of-truth|Ecosystem Feedback Loop — Wiki as Source of Truth]]
[[model-ecosystem|Model — Ecosystem Architecture]]
