# CONTEXT.md — root-ghostproxy operational state

> Current operational state of the project. Distinct from [README.md](README.md) (project description — what root-ghostproxy IS) and [CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) (operating rules — how AI tools behave here). CONTEXT.md = "what's currently true, what's active, what's next." Updates turn-to-turn as state evolves.

## Quick Identity

| Dimension | Value | Layer |
|---|---|---|
| Type | `root` | Stable |
| Group | `operating-system-setup` | Stable |
| Domain | Infrastructure | Stable |
| Phase | scaffold + partial-foundation | State |
| Scale | micro (single host) | State |
| Execution mode | solo (default) | Consumer/Task |
| SDLC profile | simplified (default) | Consumer/Task |
| PM Level | L1 (default) | Consumer/Task |
| Trust tier | operator-supervised (default) | Consumer/Task |

Stable rows are project-level invariants. State rows track SFIF stage. Consumer/Task rows are session-overridable defaults.

Full identity profile (canonical): `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md`.

## Current SFIF Stage

**Stage: scaffold + partial-foundation.**

| SFIF Stage | Status |
|---|---|
| **Scaffold** | In progress (effective ~majority done). Identity registered with second brain ✓, methodology layer adopted ✓, backlog scaffolded with active epic + 14 modules + 66 atomic tasks (T001-T066) ✓, all 8 agent-context MD files authored + iterating ✓, install.sh authored with dry-run passing both base and full profiles ✓. Cycles 41-58 added: PreCompact hook + handoff-doc loop, 3 brain-loaded subagents at .claude/agents/, trigger-model.md unified rule, /handoff slash command, hook regression-test infrastructure at .claude/hooks/tests/. **2026-05-06 audit + Phase A/B/C** added: 12 hooks across 8 events (added UserPromptSubmit context-warning + agent-discipline-gate, Stop end-of-cycle-stamp), 22 slash commands (added /stamp-* + /install-agent-brain), 7 Python tools (added cycle, tasks, stamp), 118-row systemic-bugs tracker post-audit (17 verified, 13 recurring, 4 open, 76 structurally-fixed including 8 DRAFT, 5 partial, 3 in-progress; D026 captures deliverables), bidirectional $HOME↔/opt inheritance documented in self-reference.md. |
| **Foundation** | install.sh scaffold-gate met (`./install.sh --dry-run` runs cleanly without performing changes; backlog page+module+task structure exists). Operator-decision pending: advance to implement-stage (real integrity-sentinel + nftables + wpa_supplicant + check-mode implementation). The transparent-bridge install path is wired in install.sh as `op_install_network_bridge` (systemd-networkd templates installed in dry-run mode). |
| **Infrastructure** | Not started. Project-internal verifier tooling (M004 work) deferred. |
| **Features** | Not started. Modules (Suricata, PolarProxy) deferred — operator-driven future-session work. |

## Active Epic

[**SFIF Rollout + Second-Brain Integration (2026-05)**](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md)

Status: draft. Readiness: 10. Two work streams.

### Stream 2 — Pure SFIF Project Base (M001–M005, M011)

| Order | Module | Stage | Status | Notes |
|---|---|---|---|---|
| 1 | **[M001 — CLAUDE.md + AGENTS.md authoring](wiki/backlog/modules/root-ghostproxy-m001-author-claude-md-and-agents-md.md)** | Scaffold | Done (effective) | All 8 brain files authored + iterating; cycle 41-58 substantive evolutions captured in those files. |
| 2 | **[M002 — Methodology layer decision](wiki/backlog/modules/root-ghostproxy-m002-methodology-layer-decision.md)** | Scaffold/Design | Decided (local copy chosen — methodology.yaml + 3 profiles in `$HOME/wiki/config/`) | Operator's directive to copy the second brain's methodology + profiles confirmed this choice. |
| 3 | **[M003 — Foundation hardening](wiki/backlog/modules/root-ghostproxy-m003-foundation-hardening.md)** | Foundation | In progress (scaffold-gate met; advance pending) | install.sh authored + dry-run passes both `--profile base` and `--profile full`; STUBS for integrity-sentinel + nftables + wpa_supplicant + --check verification — operator decides scaffold→implement advance. |
| 4 | **[M004 — Infrastructure tooling](wiki/backlog/modules/root-ghostproxy-m004-infrastructure-tooling.md)** | Infrastructure | Not started | Project-internal verifier (`tools/verify-policy.py` or similar) — gated on M003. |
| 5 | **[M011 — ccstatusline custom widget](wiki/backlog/modules/root-ghostproxy-m011-ccstatusline-statusline-widget.md)** | Features | In progress (~80% effective) | 3 profiles deployed (base/intermediary/full-aidlc); 9 custom AIDLC widgets at $HOME/.local/share/ccstatusline-widgets/; install.sh op_install_ccstatusline functional; OPERATOR VISUALLY VERIFIED cycle 43 ("looking much better"). 4 atomic tasks T062-T065 in-progress 60-80%. |
| 6 | **[M005 — First specialized feature module](wiki/backlog/modules/root-ghostproxy-m005-first-specialized-feature-module.md)** | Features | Not started | Operator picks Suricata-first OR PolarProxy-first. Operator-driven future-session work. |
| 7 | **[M013 — Agent modes (PM / Architect / Dual)](wiki/backlog/modules/root-ghostproxy-m013-agent-modes-and-mode-aware-loops.md)** | Features | Implemented (effective) | 3 modes at `.claude/modes/*.md`, /cycle skill for autopilot, /loop /cycle composition — used continuously cycles 41-58. |
| 8 | **[M014 — luckyPipewrench/pipelock preliminary](wiki/backlog/modules/root-ghostproxy-m014-luckypipewrench-pipelock-preliminary-scaffolding.md)** | Features | Preliminary scope complete | Module page authored cycle 19; SFIF + ordering decisions resolved; atomic task pages gated on M007 connect. |

### Stream 1 — Second-Brain Integration (M006–M010)

| Module | Status | Notes |
|---|---|---|
| **[M006 — Pre-connect verification](wiki/backlog/modules/root-ghostproxy-m006-pre-connect-verification.md)** | Not started | Verify AGENTS.md present, $HOME state captured, dry-run reviewed. |
| **[M007 — Connect to second brain](wiki/backlog/modules/root-ghostproxy-m007-connect-second-brain.md)** | Not started | Run `python3 -m tools.setup --connect-project $HOME` from second brain. |
| **[M008 — Smoke test from inside](wiki/backlog/modules/root-ghostproxy-m008-smoke-test-from-inside.md)** | Not started | Fresh Claude Code session in $HOME, gateway orient + view spine + research-wiki MCP. |
| **[M009 — Worked example](wiki/backlog/modules/root-ghostproxy-m009-worked-example-readme-ingest.md)** | Not started | Bidirectional flow proof. |
| **[M010 — sister-projects.yaml auto_connect decision](wiki/backlog/modules/root-ghostproxy-m010-sister-projects-yaml-flip.md)** | Not started | Operator decision after M009 stability. Currently `auto_connect: false`. |

## Recent Operator Directives (This Work Block)

These are the operator's verbatim directives that shaped this work block. Captured chronologically. Sacrosanct — quoted, not paraphrased. Full archive: [wiki/log/](wiki/log/) and `<second-brain>/raw/notes/2026-05-04-*.md`.

| Date | Directive (verbatim) | Implication for this work |
|---|---|---|
| 2026-05-04 | *"this is a new machine with a new root project $HOME but first we need to load into context this project knowledge"* | Fresh machine; load second-brain context before acting. |
| 2026-05-04 | *"its IAC and its basically a IPS sitting in between the Edge firewall (OPNSense) and the first switch / the local network. its aiming to secure an OS and configure claude code and opencode at the root with all the safety needed."* | Project's two-capability scope: endpoint AI agent safety + network IPS bridge. Both halves. |
| 2026-05-04 | *"first there is no modules then 1 then 2 and later more but they are all facultative as much as if I do a full install they would all be installed"* | Modules facultative. Foundation runs without them. |
| 2026-05-04 | *"WHy root ? since it could have been jfortin install too.. since its an operating system IaC project, even in a user such as jfortin it would remain a root-type project"* | type=root is scope, not install path. |
| 2026-05-04 | *"the project is barely started... we will need to build everything inside of it so that a future session in its context can work properly. not only the full second-brain integration but just pure sfif project base."* | Build everything inside $HOME for the future session. SFIF base + second-brain integration. |
| 2026-05-04 | *"all this and the wiki LLM and methodology goes before the modules since the modules you are not going to do, I am going to do In a session in a the root project when its ready and will not drop/crash in my hands"* | Order: methodology + integration FIRST. Modules SECOND, operator-driven. |
| 2026-05-05 | *"I DIDNT WRITE ANYTHING.. JUST FORGFET EVERYTHING FUCING EXIST"* | Prior $HOME files (README, install.sh, hooks, integrity.py, opencode bridge, memory folder) are AI-debris from a prior session. Not authoritative. |
| 2026-05-05 | *"imagine there is no fucking root-GHOSTPROXY project righT NOW.. this whole system is virgIN"* | Treat the system as virgin from operator's perspective. Build the project from scratch from the operator's verbatim definitions. |
| 2026-05-05 | *"WE NEED TO BUILD IT FROM THE BOTTOM-UP"* | Bottom-up: foundation first, then layers. Not top-down comprehensive vision before grounding. |
| 2026-05-05 | *"STOP FUCKING WORKING IN REVERSE"* | Don't reverse-engineer the project from existing artefacts. Build forward from definition. |
| 2026-05-05 | *"THE MAIN FUCKING TASK OF THIS WHOLE CONVERSTAION IS TO CREATE THE FUCKING 3 main MD files and then the 3-7+ secondary MD files"* | Deliverable: README + CLAUDE.md + AGENTS.md (3 main) + CONTEXT.md + ARCHITECTURE.md + TOOLS.md + DESIGN.md + SKILLS.md + SECURITY.md (5-7+ secondary). |
| 2026-05-05 | *"we are going to need to create at least two new templates list for a new project and for a new second-brain preparation to integration"* | Two template lists in second brain — sister-project-preparation manifest + second-brain-integration overlay manifest. (Authored at `<second-brain>/wiki/config/templates/sister-project-preparation/` and `<second-brain>/wiki/config/templates/second-brain-integration/`.) |
| 2026-05-05 | *"having compacted is not an excuse you have to go get the information I gave you"* | Future sessions: pull operator-verbatim from raw notes + identity profile + this work block's session log when context is incomplete. |
| 2026-05-05 | *"JUST FUCKING COPY AND PASTE EVERYTHING FROM THE FUCKING SECOND-BRAIN"* | Initial copy of $HOME MD files from second brain's root-level MD files (README, CLAUDE.md, AGENTS.md, CONTEXT.md, ARCHITECTURE.md, DESIGN.md, TOOLS.md, SKILLS.md) — done. Re-authoring per project specifics is the iteration that follows. |
| 2026-05-05 | *"work on doing good and relevant and appropriate and high standard brain file files (md). Claude & Agents, & etc."* | Iterate the agent-context MD files (CLAUDE.md, AGENTS.md, others) on quality. |
| 2026-05-05 | *"have we done the rules files too ? normally its part of the process. what is there is propably only scafold files in $HOME. and the hooks an the cross project vision."* | Rules files at `$HOME/.claude/rules/` were a gap (only `words-are-sacrosanct.md` existed). Closed by porting routing/methodology/hook-architecture/work-mode/self-reference as project-specific files (not verbatim copies of second brain's). |
| 2026-05-05 | *"we are also going to have a simpler module for ccstatusline custom widget so my claude code interface is better and we can even load different profile such as one that allow to see the selected-task, progress, stage and etc... + the obvious normal stuff  I need such as context and context usage and billing usage, 5h windows, 7d + tokens and etc... I am not saying do it now. I am saying this is one of the modules and it will be before suricata and polarproxy."* | New module M011 (ccstatusline custom widget) added to backlog, ordered BEFORE M005 (Suricata/PolarProxy first feature) in the SFIF Features stream. Module slug preserved at M011 (no renumbering churn); ordering documented in modules `_index.md` Order column. Atomic tasks NOT yet authored — operator gives go-ahead first. |
| 2026-05-05 | *"what happend if I do a git checkout in the root project. is there something that can detect and add the folder to .gitignore ? I will also want to check that we didn't miss any file and folder in the git ignore and that we have a solution for the gitignored ones that need to have mapping that are not gitignored and are able to be installed normally on a new machine with a fresh checkout that we explain to the user how to put into the $home context and how to install and possibly have the auto features like the detect of a large file download or a new vender that could maybe be registered as vendor but clearly not added as complete source into my own root project source."* | M012 (Vendor mapping + fresh-machine install + auto-detect) added to backlog, co-located with M004 in Infrastructure tier. Phase A (gitignore audit), Phase B (fresh-machine install path), Phase C (vendor manifest), Phase D (auto-detect, optional). Operator approves whitelist additions before .gitignore is modified. |
| 2026-05-05 | *"Its imporant to denote too if you had not already realized that we prone spec driven development and a strong methodology and standards. this make a huge difference in the executions and the outputs and the quality and reliability and tracability and operability and observability and project management and progress tracking and LLM Wiki enforment and compatibility exploitation."* | Spec-Driven Development DENOTED as the operating doctrine in: README.md ("Spec-Driven Development (Operating Doctrine)" section, before Three Principles); AGENTS.md ("Operating Doctrine — Spec-Driven Development" section, after What This Project Is); BOOTSTRAP.md ("Operating doctrine" first-read block at top). All 11 operator-named impact areas verbatim-listed in README. SDD frames every action: spec lives in repo, state regenerates per host. |
| 2026-05-05 | *"I just tested.... it started like crap somehow... hard to explain..."* + *"maybe its missing a hook... in the brain we have a start hook and an after compact hook I think right ?... its as if It was just broken and idle..."* | Diagnosed via $HOME session transcript inspection (471cef22-...). Confirmed: existing SessionStart hook printed only security-envelope; agent defaulted to "Hi. What would you like to work on?" with no project orientation. Authored two new hooks: `$HOME/.claude/hooks/session-orient.sh` (project priming, self-gates via BOOTSTRAP.md presence) + `$HOME/.claude/hooks/post-compact.sh` (warns about behavioral-state degradation, chains to session-orient). Wired both into `$HOME/.claude/settings.json` per operator approval ("apply"): SessionStart now fires session-start.sh THEN session-orient.sh; new PostCompact entry fires post-compact.sh. Pattern adapted from second brain's `/opt/.../session-start.sh` + `post-compact.sh`. |
| 2026-05-05 | *"its okay to view the hooks as unfinished and unperfect yet... after all, all this project is just a draft right now"* | Hook false positives (policy-block matching `.env` substring in regex args; malware-block matching `install.sh` + `.claude/hooks/` co-occurrence; "script-capture" matching multi-`.sh` ls commands; `.jsonl` extension matching credential-pattern) registered as draft-tier expected behavior. Refinement queued as M003 task **T-M003-7** + log entry `wiki/log/2026-05-05-hook-pattern-false-positives-for-m003-refinement.md`. Not reactively fixed; deferred to M003 Foundation work. |
| 2026-05-05 | *"well its not correct lol... how fucking useless is the session without all the minimal context for the brain loaded and the base project awareness and the branches and leaves followed and ingested and processed properly... I need intelligence to start working or even having a conversation... any session would..."* + *"the AI should realize Oh this is a new conversation I neeed to gather the intel..."* + *"I need to see the picture..."* | Session-start hook upgraded: was printing pointers (agent didn't load); rewritten to inject full BOOTSTRAP.md content via stdout, then later via JSON `additionalContext` for stronger imperative framing. Default behavior: agent autonomously gathers intel before responding even to "Hi"; opt-out is explicit-precise opposite. |
| 2026-05-05 | *"its why I was talking about commands too. when you force a command its 100% deterministic... its not a generative choice at the root"* + *"chaining commands and its like we do in methodologies depending on the cases"* | Hook directives are ~70-85% generative compliance; commands are 100% deterministic when invoked. Authored `$HOME/.claude/commands/orient.md` as the deterministic 18-step intel-gathering chain. Hook directs agent to invoke `/orient`; harness then deterministically runs the chain. Per-case methodology chaining flagged as the higher pattern. |
| 2026-05-05 | *"i was talking about the .claudeignore file... it serves another purpose..."* + *"wwe will also invent modes and we will have the PM Scrum Master Mode and the DevOps Software Engineer & Architect expert mode and the Dual Expert mode and we will when those mode are enabled allow be to trigger with a /loop a desired sequence or group of sequence."* | (a) Corrected understanding of `.claudeignore`: it's a context-window auto-load filter (soft, GitHub issue #29455), distinct from `permissions.deny` (hard tool-access block) and `.gitignore` (git tracking). Authored `$HOME/.claudeignore` with runtime-artifact patterns. (b) Three modes captured as backlog M013 — PM Scrum Master, DevOps Architect, Dual Expert; modes enable mode-aware `/loop` sequences via sub-agent profiles + brain pieces composition. Modes implementation deferred per *"we will... invent"* future framing. |
| 2026-05-05 | *"its the user choice to enter a mode or not. but the agent can tell him about it, about the feature and loop compatibility and the possibility to drive the wiki LLM pm in autopilot. lets make sure we already register the knowledge we commulated in the second-brain too. we possibly have a long to make sure we do not forget and pass through all over again from scratch."* | Modes Phase 1 implemented: 3 mode brain pieces, 6 mode-related slash commands, state file `$HOME/.claude/active-mode`, SessionStart hook informs about feature without auto-enabling, pattern registered in second brain (`/opt/.../wiki/patterns/01_drafts/agent-modes-three-mode-pattern-with-mode-aware-loop-cycles.md`), comprehensive session log at `$HOME/wiki/log/2026-05-05-session-architecture-modes-and-determinism-ladder.md` to prevent rebuilding from scratch. |
| 2026-05-05 | *"there should be a clear channel of the blockers that cummulate that require my inputs and the tracking of the progress and the view of journey and current position and planning... I really need a way to have the blockers surfacing and with enough context and explanation so I can answer and so I dont receive dumb questions too. There can also be a tracking of the decisions like a logbook that I can look at, similar to a kind of progress trackin but with its own SRP..."* | Governance layer authored at `$HOME/wiki/governance/`: `blockers.md` (operator-facing pending-input register with full per-blocker context + options), `progress.md` (journey view with current-position callout + milestone planning + path traveled), `decisions.md` (chronological audit trail with rationale + reversibility + downstream effects). Three docs SRP-separated. New slash commands `/blockers`, `/progress`, `/decisions` to surface each. Mode `/cycle` chains updated to compose these per active mode. Addresses operator's perspective-gap concern + agent-regression failure mode. |
| 2026-05-05 | *"did you know we can also split / group Epics and such into milestones ? it help with the archiving and and views and filtering"* | Acknowledged; built into `progress.md` planning view (active milestone v0.1 — Foundation Scaffolding; sketched future milestones v0.2-v1.0). Directory restructure of $HOME/wiki/backlog/epics/ into milestone subfolders (matching second brain's pre-milestone/ + milestone-v2/ pattern) deferred as F005 future-decision (~73 references to update; not blocking). |
| 2026-05-05 | *"(when needed a bit like with in the second-brain we can do tool for the things that have no need to be done by a model but mostly empower or interact or exploit it.) a bit like commands but obviously thats the deeper level... but MCP we must not overflow especially with things that are useless or confusing or useless or we dont even refer to anywhere so will never be used..."* | Tools layer (analogous to second brain's tools.gateway / tools.pipeline) captured as F007 future-decision in `blockers.md`. "When needed" qualifier respected — not built pre-emptively. MCP discipline noted: don't add MCP tools that aren't referenced or used. |

## Operator-Pending Decisions

Decisions the operator has not yet made + the work blocks they unblock when made:

| Decision | Blocks | Notes |
|---|---|---|
| Foundation IaC authoring approach | M003 (Foundation hardening) | Author `install.sh` from scratch (operator-driven), or extend the prior `$HOME/install.sh` as a starting point with explicit "this was prior debris" reframing. Operator preference matters: starting fresh aligns with the "forget everything fucking exist" framing; extending prior keeps known-working pieces. |
| Network bridge configuration approach | M003 | `ifupdown` (Debian classic) vs `netplan` vs `systemd-networkd`. Each is a foundation-tier choice. |
| Stream 2 first vs Stream 1 first | M006-M010 vs M003-M005 | Stream 2 (SFIF base) and Stream 1 (second-brain integration) can progress mostly in parallel; Stream 1 M007 has a Stream 2 M001 dependency (AGENTS.md must exist before --connect-project runs, which is satisfied). |
| Suricata-first vs PolarProxy-first | M005 (first feature module) | Per `<second-brain>/wiki/sources/src-suricata-ips-mode-linux.md`: Suricata-first is "passive before active" default; PolarProxy-first is preferred when cert-distribution risk is the higher-uncertainty risk to de-risk first. |
| Suricata IPS mode failopen | M005 (Suricata path) | NFQUEUE+nftables `bypass` (fail-OPEN; network keeps working) vs AF_PACKET copy-mode (fail-CLOSED at L2). |
| PolarProxy license tier | M005 (PolarProxy path) | Free-tier 10 GB / 10 000 sessions/day; paid tiers L1/L2/L3 for higher volume. Operator decision based on traffic estimate. |
| auto_connect flip | M010 | Flip `auto_connect: false` → `true` after M009 stability proven (typical: ≥1 week stable). Or keep `false` permanently as security-tier signal. |
| Foundation install verification approach | M003 gate | Trust `--dry-run` + `--check` output (option a per M003 page) vs full clean-host VM verification (option b). Operator decides per threat model. |
| Cleanup of prior $HOME debris | (orthogonal) | Delete the prior `install.sh` / `~/.claude/settings.json` / hooks / `integrity.py` / opencode bridge plugin / `~/.claude/projects/-root/memory/` files? Or leave in place pending re-author? Operator decision — affects whether project-authored implementation can extend or must replace. |

## Next-Best Moves (per SFIF)

In priority order:

1. **Finish CLAUDE.md / AGENTS.md / CONTEXT.md / ARCHITECTURE.md / DESIGN.md / TOOLS.md / SECURITY.md / SKILLS.md** — agent-context files, currently being iterated. M001 work block.
2. **Operator selects Stream 2 next module after M001 completes** — likely M002 (methodology layer decision — already mostly decided by copying) → M003 (Foundation hardening).
3. **Stream 1 M006 (pre-connect verification)** — can progress in parallel with M003 once M001's AGENTS.md exists. AGENTS.md exists (this iteration); M006 is unblocked.
4. **Operator authorizes M007 connect** — runs `python3 -m tools.setup --connect-project $HOME --dry-run` first (preview), then for real. The connection adds the four artefacts (research-wiki MCP entry, gateway/view forwarders, brain-pointer block in AGENTS.md).
5. **Operator-driven M005 module work** — Suricata or PolarProxy first; module design + integration.
6. **M008 smoke test from inside $HOME** — fresh Claude Code session in $HOME, gateway orient + view spine + MCP tool invocation.
7. **M009 worked example** — proves bidirectional flow (second brain has root-ghostproxy queryable, root-ghostproxy contributes back).
8. **M010 auto_connect decision** — operator decision after M009 stability.

## Recent Work Completed (this conversation block)

| Date | Artefact | Status |
|---|---|---|
| 2026-05-04 | Sister-projects.yaml entry + identity profile in second brain | Complete |
| 2026-05-04 | Goldilocks 9-dimension protocol extension (Type + Group dimensions added) | Complete |
| 2026-05-04 | 6 source-syntheses for Suricata + PolarProxy + Hanke integration | Complete (in second brain) |
| 2026-05-04 | Active rollout epic + 10 module pages | Complete (in second brain backlog) |
| 2026-05-04 | `tools.setup --dry-run` flag + type/group-aware brain-pointer block | Patched in `tools/setup.py` |
| 2026-05-04 | Two template lists in second brain (sister-project-preparation + second-brain-integration) | Complete |
| 2026-05-05 | $HOME/wiki/ structure scaffolded (config/, backlog/, log/) | Complete |
| 2026-05-05 | $HOME/wiki/config/ populated (methodology.yaml + 3 profiles copied) | Complete |
| 2026-05-05 | Epic + 10 module pages ported to $HOME/wiki/backlog/ | Complete |
| 2026-05-05 | $HOME/README.md authored project-specifically | Complete (925 lines, multiple iterations) |
| 2026-05-05 | $HOME/SECURITY.md authored fresh | Complete (207 lines) |
| 2026-05-05 | $HOME/CLAUDE.md re-authored project-specifically (replaces second-brain copy) | Complete (175 lines) |
| 2026-05-05 | $HOME/AGENTS.md re-authored project-specifically (replaces second-brain copy) | Complete (168 lines) |
| 2026-05-05 | $HOME/ARCHITECTURE.md, DESIGN.md, TOOLS.md, SKILLS.md authored project-specifically | Complete |
| 2026-05-05 | 61 atomic task pages T001-T061 across 10 modules at $HOME/wiki/backlog/tasks/ — extended to T066 across 14 modules by 2026-05-06 (M011 ccstatusline + M012 vendor mapping + M014 pipelock preliminary added) | Complete (66 tasks across M001-M014) |
| 2026-05-05 | Session log $HOME/wiki/log/2026-05-05-preparation-session-foundation-scaffolding.md | Complete (241 lines) |
| 2026-05-05 | Methodology engine validation (4 yamls parse cleanly) | Complete |
| 2026-05-05 | Broken-reference audit: 10 module pages had stale long-slug epic refs + bogus pre-milestone path → fixed | Complete |
| 2026-05-05 | $HOME/BOOTSTRAP.md authored — one-page cold-pickup guide; pointer added to CLAUDE.md + README.md | Complete (7.3KB) |
| 2026-05-05 | $HOME/.claude/rules/ files authored (routing.md, methodology.md, hook-architecture.md, work-mode.md, self-reference.md) — project-specific, not verbatim copies of second brain | Complete (5 files, ~30KB total) |
| 2026-05-05 | M011 — ccstatusline custom widget module page added (ordered before M005) per operator directive | Complete (module page + index updates; atomic tasks pending operator go-ahead) |
| 2026-05-05 | M012 — Vendor mapping + fresh-machine install + auto-detect module page added (Infrastructure tier, co-located with M004) | Complete (module page + index updates; 4 phases scoped) |
| 2026-05-05 | `.gitignore` whitelist patch applied per operator approval — brain files + rules files + wiki/ tree + open-interfaces.template + docs/ now tracked | Complete; `$HOME` git-init'd 2026-05-05; spec uncommitted; verified 19 spec files track + 8 runtime files denied + section 6 hard-deny intact |
| 2026-05-05 | SessionStart orient hook + PostCompact hook authored + wired in settings.json per operator approval | Complete; agent now actively oriented on session start + post-compact (was the cause of "broken and idle" test session) |
| 2026-05-05 | Hooks upgraded to Python + JSON `additionalContext` output (~85% determinism vs ~70% plain stdout) | Complete; both session-orient.sh + post-compact.sh validate as proper Claude Code hook JSON |
| 2026-05-05 | `$HOME/.claude/commands/orient.md` authored — deterministic 18-step intel-gathering chain (Read brain + verify state + structured ORIENT REPORT) | Complete; hook directs agent to invoke `/orient`; chain is 100% deterministic once invoked |
| 2026-05-05 | `$HOME/.claudeignore` created — context-window auto-load filter for runtime artifacts (.claude/projects/, sessions/, caches, etc.); whitelisted in .gitignore for tracking | Complete; soft filter (explicit Reads bypass per known bug #36163); complementary to .gitignore + permissions.deny |
| 2026-05-05 | `$HOME/.claude/settings.json` permissions.deny extended with 18 runtime-artifact entries (sessions, file-history, shell-snapshots, caches, .opencode storage, **/*.log, etc.) | Complete; JSON parses; hard tool-access block layer |
| 2026-05-05 | M013 — Agent modes (PM Scrum Master / DevOps Architect / Dual Expert) + mode-aware /loop sequences module page added | Complete (module page); 4 phases scoped, 5 open questions for operator. Atomic tasks deferred per "we will invent" framing |
| 2026-05-05 | M013 Phase 1 implemented — 3 mode brain pieces + 6 mode-related slash commands + state file mechanism + /cycle dispatch + /orient mode-aware update + SessionStart hook surfaces feature without auto-enable | Complete; pattern registered in second brain at `/opt/.../wiki/patterns/01_drafts/agent-modes-three-mode-pattern-with-mode-aware-loop-cycles.md` |
| 2026-05-05 | Governance layer authored — `$HOME/wiki/governance/{blockers,progress,decisions}.md` (594 lines total, SRP-separated) + 3 slash commands (`/blockers`, `/progress`, `/decisions`) | Complete; addresses operator's perspective-gap concern; /cycle sequences updated to compose governance commands per mode |
| 2026-05-05 | Comprehensive session log written | `$HOME/wiki/log/2026-05-05-session-architecture-modes-and-determinism-ladder.md` covering 6 phases of this session's arc + 5 high-leverage knowledge insights for future sessions |
| 2026-05-05 | Tools layer authored at `$HOME/tools/` — 4 deterministic non-LLM Python scripts (state, blockers, progress, decisions) | Complete; all 4 functional + tested empirically; commands compose tools per operator's "commands can use tools" framing |
| 2026-05-05 | 3 additional commands authored: `/log` (raw-note + decision logging), `/audit` (10-step integrity check), `/sync-progress` (re-derive progress.md callout from live state) | Complete; total commands now 13 (orient + cycle + 5 mode-* + 3 governance + 3 utility) |
| 2026-05-05 | MCP + skills intentionally deferred | (Superseded by next entry — operator clarified they want both implemented in the same /loop iteration.) |
| 2026-05-05 | MCP server authored at `$HOME/tools/mcp_server.py` — 6 tools (root_state, root_blockers, root_progress, root_decisions_list/get/verify/next_id, root_orient composite) | Complete; FastMCP-based; mirrors second brain's pattern; read-only surface; defensible per "no overflow" — every MCP tool here has a downstream caller. **Wiring pending operator action**: add to `$HOME/.mcp.json` or `~/.claude.json` with stdio transport pointing at `python3 -m tools.mcp_server` (cwd=$HOME). Requires `mcp` Python package. |
| 2026-05-05 | 2 skills authored at `$HOME/.claude/skills/` — `surface-state` (auto-triggers on "where are we" type prose; runs `/orient`) + `surface-blockers` (auto-triggers on "what's blocking" type prose; runs `/blockers`) | Complete; both have precise descriptions to avoid over-firing; both compose existing slash commands rather than duplicating logic |
| 2026-05-05 | BOOTSTRAP.md updated for new architecture | Added "Architecture surfaces" table covering all 7 surfaces (commands, modes, hooks, tools, skills, governance, rules); updated read-order to include governance docs + new session log; added pointer to invoke `/orient` for deterministic load |

## Brain file status (post-2026-05-06 audit)

All 8 top-level brain files are project-specific authoring (no longer verbatim copies); each iterates independently. State tracked at `wiki/governance/progress.md`.

| File | Status |
|---|---|
| README.md | Substantive. Refreshed 2026-05-06 (13 hooks / 25 commands / 10 tools / 124-row tracker counts post SB-118 build). |
| CLAUDE.md | Substantive. Refreshed 2026-05-06 (hook + command + tool counts). |
| AGENTS.md | Substantive. Refreshed 2026-05-06 (lifecycle hooks list: added UserPromptSubmit + Stop). |
| BOOTSTRAP.md | Substantive. Refreshed 2026-05-06 (hook + command + tool tables). |
| CONTEXT.md | This file. Refreshed 2026-05-06. |
| ARCHITECTURE.md | Substantive. Refreshed 2026-05-06 (hook lifecycle table: UserPromptSubmit + Stop entries). |
| DESIGN.md | Substantive. Extended 2026-05-06 (stamp design + agent-discipline-gate design rationale sections). |
| SECURITY.md | Substantive. No changes 2026-05-06 (fail-closed invariants intact; deny-set 169 entries above threshold 100). |
| TOOLS.md | Substantive. Refreshed 2026-05-06 (added `tools.stamp` row). |
| SKILLS.md | Substantive. |

## Cross-References

- [README.md](README.md) — project description, architecture vision, identity, modules, current state, build order, methodology, sister-project status, backlog, SFIF stages, principles, setup path, verification, status, glossary, operator directives, ecosystem relationship
- [CLAUDE.md](CLAUDE.md) — Claude Code-specific routing + methodology pointer + Claude-specific hard rules
- [AGENTS.md](AGENTS.md) — universal cross-tool agent contract + canonical envelope + no-policy-duplication invariant
- [SECURITY.md](SECURITY.md) — threat model + protections + fail-closed invariants + escalation + audit + limitations
- [wiki/backlog/](wiki/backlog/) — active epic + 14 modules + 66 atomic tasks
- [wiki/log/](wiki/log/) — operator directives + session logs
- `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` — full identity profile (canonical)
- `<second-brain>/raw/notes/2026-05-04-*.md` — operator-verbatim directive logs (sacrosanct, primary source for project intent)
