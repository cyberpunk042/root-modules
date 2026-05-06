# $HOME/.claude/rules/self-reference.md — What /root/ IS and how it relates to the second brain

> Loaded on demand when the agent needs to understand the project's identity + relationship to /opt. CLAUDE.md + README.md have the summary; this file has the operating framing.

## What this project IS

**`root-ghostproxy`** is a system-AI-safety-setup project at the OS-root level. Operator's verbatim framing (2026-05-04):

> "its a new type of project but its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network. its aiming to **secure an OS and configure claude code and opencode at the root with all the safety needed**. it will do this and it will also offer in the future to for instance we use this machine or another [new] one. So its not just an IPS its a system AI safety setup project and the IPS tools (suricata and [polarproxy]) as modules."

Two distinct capability halves:
1. **Endpoint AI agent safety (core).** Configure Claude Code + opencode at OS-root level with safety controls for AI agents on the host.
2. **Network inspection (modules).** Transparent L2 bridge between OPNsense edge and LAN switch, with Suricata (IDS/IPS) + PolarProxy (TLS termination) as facultative modules.

Identity: **type=root, group=operating-system-setup**. Scope, not path. The project remains type=root regardless of which user installs it (e.g., a future `jfortin` install). Canonical identity profile: `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md`.

## /root vs the second brain (don't conflate)

| Layer | This project (/root) | The second brain (/opt) |
|---|---|---|
| **What it is** | OS-setup IaC: install.sh, hooks, integrity scripts, network bridge config, IPS modules | Central knowledge hub: 16 named models, 25 standards, 477+ pages, methodology engine, source-syntheses |
| **What it knows** | How to harden a Debian 13 host for AI agent safety + transparent L2 inspection | How to run any project with consistent methodology + how to register/integrate sister projects |
| **Who consumes** | The operator's host(s) — runtime IaC | All 5 sister projects (this + OpenArms + OpenFleet + AICP + devops-control-plane) consume from it |
| **Brain location** | $HOME/CLAUDE.md + AGENTS.md + .claude/rules/*.md (this folder) | /opt/.../CLAUDE.md + AGENTS.md + .claude/rules/*.md |

**The two brains coincide for /root only when reading the second brain's authoritative knowledge.** This project's brain is its own (CLAUDE.md + AGENTS.md + the rules files in this folder). The second brain is a CONSUMED resource — for methodology engine, source-syntheses, identity profile, sister-projects.yaml registration.

## Behave FROM the project, not OVER it

Operator directive 2026-04-24 (from second brain raw notes):
> "A PROJECT IS THE EXTENSION OF A BRAIN AND YOU NEED TO BEHAVE FROM IT NOT OVER IT... THE PROJECT IS INTELLIGENT... THE INTELLIGENCE COMES FROM USING THE PROJECT"

For root-ghostproxy specifically:

| ❌ Behaving OVER the project | ✅ Behaving FROM the project |
|---|---|
| Read principles, then improvise IaC | Read CLAUDE.md + BOOTSTRAP.md, then act per their routing |
| Cite the methodology in prose | Use $HOME/wiki/config/methodology.yaml as the program — pick model by task_type, follow stages, hit gates |
| Generate a Suricata config from base-model knowledge | Read `/opt/.../wiki/sources/src-suricata*.md` (4 source-syntheses already in second brain) before authoring |
| INGEST a URL as a permanent wiki source-synthesis | Route to second brain (`wiki_fetch` MCP / `pipeline fetch`) — /root does NOT do source ingestion. RESEARCHING URLs via WebFetch / WebSearch / gh CLI for /root iteration context (e.g., looking up ccstatusline docs, verifying a vendor's release version) is allowed and expected per research-first principle. The distinction: ingestion = save to wiki/sources/; research = read for context. |
| Generate a status claim | Run BOOTSTRAP.md verification, inline output, then claim |
| Invent a foundation issue | Read CONTEXT.md (current SFIF stage) + _index.md (active modules) before asserting |

## The 5-project ecosystem (where /root fits)

| Project | Role | Relationship to /root |
|---|---|---|
| **Research wiki** (`<second-brain>/`) | Central intelligence hub (second brain) | Source of canonical identity profile, source-syntheses, methodology engine, models, standards. /root consumes from here. |
| **OpenArms** (`~/openarms/`) | Harness engineering; advanced agent runtime | Sister project — both consume the second brain. /root may share hook patterns with OpenArms. |
| **OpenFleet** (`~/openfleet/`) | Agent fleet orchestrator | Sister project — pattern source for solo-session work-mode. |
| **AICP** | Local-AI complexity-routed inference | Sister project — may eventually run AI workloads on /root-protected hosts. |
| **devops-control-plane** | Infrastructure governance | Sister project — pattern source for IaC discipline. |

When operator addresses you in /root, they're addressing root-ghostproxy's AI. Not the second brain's AI. Not a fleet agent.

## Bidirectional inheritance — /root and the second brain (and sisters)

The relationship between /root and /opt second-brain is NOT peer-to-peer. It is bidirectional with different layers flowing different directions. Operator correction 2026-05-06 (SB-115): *"second-brain take everything from you"*.

| Direction | Layer | Examples |
|---|---|---|
| /root **consumes** from second-brain | **Knowledge / authoritative resources** | source-syntheses (Suricata, PolarProxy), identity profile, methodology engine config, adoption guide, sister-projects.yaml, MCP tool catalog. (See "When to consume from the second brain" below.) |
| /root **authors**; second-brain (and other sisters) **inherit/adapt** | **Operational tooling at root/host level** | hook patterns (session-orient, end-of-cycle-stamp, pre-compact, post-compact), slash-command patterns (/orient, /cycle, /handoff, /stamp-*), tool patterns (tools.cycle, tools.stamp, tools.state), settings.json hook-wiring conventions, ANSI-fence + diff-fence rendering patterns. /root is type=root + group=operating-system-setup — root-level tooling lives here as canonical. |

**Anti-pattern (SB-115 instance)**: when investigating an inconsistency between /root's and /opt's hooks, agent framed them as independent peers ("/opt has its own hook, separate from /root's"). That obscured the fact that /opt's hook is a copy/adaptation of /root's pattern (per /opt's hook header comment: "Adapted from the parallel root-ghostproxy hook pattern"). When /root's hook evolves (e.g., SB-115 redesign of stamp config from prompt-marker to slash-command + persistent JSON), /opt should track the improvement, not maintain a divergent copy.

**Operationally**: when /root authors a new operational pattern (hook, command, tool), the agent should note "candidate for sister-project inheritance" so the second-brain side can adapt or be informed. Cross-project propagation is NOT automatic; it's a deliberate sync the operator coordinates.

## When to consume from the second brain

| /root agent needs | Where to look in /opt |
|---|---|
| Suricata source-syntheses | `wiki/sources/src-suricata*.md` (4 pages) |
| PolarProxy source-syntheses | `wiki/sources/src-polarproxy.md`, `wiki/sources/src-hanke-honeypot-polarproxy-suricata-integration.md` |
| Identity profile (canonical) | `wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` |
| Adoption Guide (how to roll a methodology layer) | `wiki/spine/references/adoption-guide.md` |
| Methodology engine config (master) | `.claude/rules/methodology.md` + `wiki/config/methodology.yaml` |
| Sister-projects.yaml entry | `wiki/config/sister-projects.yaml` |
| MCP tool catalog (28 tools) | `.claude/rules/routing.md` |
| Operator verbatim directives (PRIOR sessions) | `/opt/.../raw/notes/2026-05-04-*.md`, `/opt/.../raw/notes/2026-05-05-*.md` (read-only — historical reference) |
| Operator verbatim directives (CURRENT /root iteration) | `$HOME/wiki/log/<date>-<slug>.md` (this is where /log slash command writes; /root iteration directives stay in /root) |

## Cross-references

- Universal self-reference (canonical, second brain): `<second-brain>/.claude/rules/self-reference.md` (BUT note: that file frames the second brain as the second brain. This file frames /root as the OS-setup project.)
- README.md — full project description.
- BOOTSTRAP.md — cold-pickup guide.
- CONTEXT.md — current SFIF stage + active epic + 13 modules + verbatim directives + pending decisions.
