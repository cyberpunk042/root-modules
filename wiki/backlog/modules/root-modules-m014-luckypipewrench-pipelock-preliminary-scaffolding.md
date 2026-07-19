---
title: "root-modules M014 — luckyPipewrench/pipelock integration scaffolding"
aliases:
  - "M014 — pipelock integration"
type: module
domain: backlog
status: draft
priority: P1
task_type: module
parent_epic: "sfif-rollout-and-second-brain-integration"
current_stage: document
readiness: 30
progress: 0
sfif_stage: Features
sfif_ordering: "Stream 2, AFTER M011 ccstatusline, PARALLEL to M005 (facultative — pipelock is independent of Suricata/PolarProxy)"
decision_date: 2026-05-05
decision: "operator-approved cycle 19: SFIF=Features, ordering after M011 + parallel to M005, preliminary scope complete (module page authored), source-synthesis ingestion deferred until M007 connect"
stages_completed: []
artifacts: []
confidence: high
created: 2026-05-05
updated: 2026-05-05
sources:
  - id: operator-directive-first-real-epics
    type: directive
    file: $HOME/wiki/log/2026-05-05-first-real-epics-ccstatusline-and-pipelock-preliminary-only.md
  - id: pipelock-github-repo
    type: external
    url: https://github.com/luckyPipewrench/pipelock
    description: "luckyPipewrench/pipelock — open-source AI agent firewall (researched cycle 19)"
  - id: pipelock-homepage
    type: external
    url: https://pipelab.org
tags: [module, root-modules, m014, pipelock, ai-agent-firewall, mcp-security, agent-egress-control, dlp, ssrf, prompt-injection-defense, complementary-layer]
---

# M014 — luckyPipewrench/pipelock integration scaffolding

## What pipelock is (researched cycle 19 via gh api)

**pipelock** is an open-source AI agent firewall focused on MCP security, agent egress control, DLP, SSRF protection, and prompt-injection defense. Released under Apache 2.0 (core) + ELv2 (enterprise). 510 stars, last push 2026-05-05 (today), Go 1.25+, CNCF Landscape Security & Compliance.

**Architecture**: sits inline between AI agent and the network. Scans outbound + inbound traffic, blocks exfiltration + injection, sandboxes the agent process, generates Ed25519-signed action receipts.

**Key features** (from README):
- 11-layer URL scanner (scheme validation, CRLF injection, path traversal, DLP patterns × 48, SSRF protection, etc.)
- Process sandbox (Linux: Landlock LSM + seccomp + network namespaces; macOS: sandbox-exec)
- Response scanning with 6-pass normalization (zero-width chars, homoglyphs, leetspeak, base64)
- 25 prompt-injection patterns
- MCP proxy with bidirectional scanning (stdio / Streamable HTTP / HTTP reverse proxy)
- MCP Tool Policy: 17 built-in pre-execution rules
- Tool Call Chain Detection (10 patterns: recon / cred-theft / data-staging / persistence / exfiltration)
- Kill switch (4 independent activation sources)
- Scan API (programmatic eval endpoint)
- Filesystem sentinel (catches secrets written to disk)
- Event emission with MITRE ATT&CK technique IDs

**Works with**: Claude Code, Cursor, VS Code, JetBrains, OpenAI Agents SDK, Google ADK, AutoGen, CrewAI, LangGraph.

## Relationship to root-modules

**Complementary layers of AI agent safety**:

| Layer | Project | Boundary enforced |
|---|---|---|
| Agent process boundary | **pipelock** (M014, this module) | Outbound HTTP/WS/MCP from the agent process; sandboxes the process; signs receipts |
| Network L2 boundary | root-modules bridge + Suricata + PolarProxy (M005) | Transparent L2 inspection between OPNsense edge and LAN switch |
| OS-level safety envelope | root-modules foundation (M003) | Claude Code + opencode hardening at OS root level (settings.json deny + 7 hooks) |

The three layers cover different attack surfaces. pipelock adds the agent-process layer to root-modules's network + OS layers.

## Scope (preliminary — module page authoring complete cycle 19)

Per operator directive 2026-05-05 *"the skaffolding of the luckyPipewrench/pipelock on github... preliminary part... informed decision... proper integration"*:

**Done this cycle (preliminary scope)**:
- ✓ Project identity confirmed (luckyPipewrench/pipelock)
- ✓ Project purpose researched (MCP-security AI agent firewall)
- ✓ Relationship to $HOME identified (complementary agent-process layer)
- ✓ Module page authored with researched content
- ✓ Sources linked (github repo + homepage)

**Pending operator-decisions (3 items — see decision package below)**:
1. SFIF stage placement
2. Ordering relative to M011 + M005
3. Whether preliminary should also include source-synthesis ingestion via second-brain (gated on M007 connect)

## Done When (preliminary scope)

- [x] pipelock identity + purpose researched + documented
- [x] Relationship-to-$HOME mapped (complementary layers)
- [x] Module page authored with verifiable sources
- [x] Operator decides SFIF stage placement → **Features** (per decision_date 2026-05-05)
- [x] Operator decides ordering → **after M011, parallel to M005** (per decision_date 2026-05-05)
- [x] Operator decides whether to ingest pipelock as second-brain source-synthesis → **deferred until M007 connect** (per decision_date 2026-05-05)
- [ ] Atomic task pages T-M014-* authored — GATED ON M007 (source-synthesis ingestion is the first M014 atomic task; gated on second-brain reachability)

## Integration considerations (preliminary — for the design pass when this module activates)

- pipelock runs as a process-level proxy/sandbox. Installation typically: `brew install luckyPipewrench/tap/pipelock` OR `docker pull ghcr.io/luckypipewrench/pipelock:latest` OR Go install from source.
- Configuration via `pipelock.yaml`. `pipelock init` discovers IDE configs.
- Could be wrapped by root-modules's install.sh as a facultative module (similar to M005's Suricata/PolarProxy facultative pattern).
- License: Apache 2.0 core compatible; ELv2 enterprise tier available.
- Topics tagged: agent-security, ai-agent-security, mcp-security, prompt-injection, ssrf-protection — directly aligned with root-modules's safety-envelope mission.

## Tasks

(No atomic task pages T-M014-* yet — gated on operator decisions on the 3 pending items above.)

## Relationships

- PART OF: [[sfif-rollout-and-second-brain-integration|Epic — root-modules SFIF Rollout]]
- COMPLEMENTS: [[root-modules-m003-foundation-hardening|M003]] (OS-level safety envelope) + [[root-modules-m005-first-specialized-feature-module|M005]] (network IPS bridge layer)
- AWAITS: operator decisions on stage / ordering / synthesis-ingestion

## Backlinks

[[Epic — root-modules SFIF Rollout]]
