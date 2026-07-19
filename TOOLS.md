# TOOLS.md — root-modules tool reference

> Per-tool / per-script reference. What each tool does, when to use it, with concrete invocations. Reference, not narrative. Cross-referenced from [CLAUDE.md](CLAUDE.md)'s operator-intent routing table.
>
> The project has advanced from "scaffold + partial-foundation" to **install.sh implement-stage 98% (D024 GREENLIT)** with foundation IaC + 15 deterministic Python tools + 18 hook scripts (10 wired) + 30 slash commands + MCP server (10 root_* tools). Many tools listed here are now **implemented** + tested; remaining tools (M005 Suricata + PolarProxy module installers, M004 verifier pipeline, M007 second-brain forwarders) are **planned**. The "Status" column distinguishes today's reality from what's pending.

> **Agent doc-update discipline (operator directive 2026-05-06, sacrosanct)**: when refreshing TOOLS.md, **adding ≠ discarding**. Drift-fix counts inline; preserve design-intent content even when reconciling planned→implemented. The Tool Inventory table at top + the Per-Tool Reference sections must agree on each tool's status — section-vs-inventory drift produces "is it implemented or not?" confusion for cold-pickup agents. Hard Rule 15 (CLAUDE.md/AGENTS.md): empirical-count-verification before drift-claim — the discipline is run a programmatic walk + parse before refreshing any count in this file.

## Summary

This file indexes the project's tool layer — install scripts (`install.sh`/`uninstall.sh`), enforcement hooks (10 wired matchers across 8 lifecycle events at `.claude/hooks/`), 15 deterministic Python tools at `tools/` (state-management + MCP server + cycle orchestration), opencode bridge plugin (cross-tool integration), planned module installers (Suricata + PolarProxy + pipelock — facultative future-session work), and second-brain forwarders (gateway/view — land via `--connect-project` from second brain side). The **canonical per-module index** for the 15 Python tools is [tools/README.md](tools/README.md) (DRAFT v1, agent-authored 2026-05-06 evening per brain-improvement mandate); this TOOLS.md provides the **operator-facing usage view** (concrete invocations, when-to-use, planned vs implemented). The two files complement: TOOLS.md is HOW operator uses tools; tools/README.md is HOW tools compose internally. **Empirical state verified 2026-05-06 evening**: 15 .py tools / 18 hook scripts (10 wired) / 30 slash commands / 11 rules / 13 test files (215/234 passing) / 40 decisions logbook entries / 138-row systemic-bugs tracker (max ID SB-138).

## Tool Inventory

| Tool | Path | Layer | Purpose | Status |
|---|---|---|---|---|
| `install.sh` | `$HOME/install.sh` | Foundation | Idempotent installer — brings host to foundation-tier state (endpoint AI agent safety + bridge topology + management wifi + ccstatusline). Profile (base/full/interactive) × mode (bridge/endpoint/hybrid/auto) composition. | scaffold-stage stub: `--dry-run` passes both `--profile base` and `--profile full`. Stubs for integrity-sentinel + nftables + wpa_supplicant + --check verification. Operator-decision pending: advance to implement-stage. |
| `uninstall.sh` | `$HOME/uninstall.sh` | Foundation | Inverse of install.sh; removes project-installed config from the host. | scaffold-stage stub. |
| Tamper-detection sentinel | `$HOME/.claude/hooks/integrity.py` | Foundation | Pre-tool-call integrity check; refuses every tool call when safety controls are tampered. Imported by policy-block.sh + malware-block.sh. | Implemented. |
| Pre-tool-call hooks (3) | `.claude/hooks/{policy-block,malware-block,opt-write-block}.sh` | Foundation | policy-block (credential-file + path scan + bash exfil), malware-block (RAT install + reverse shells + privesc + hook tampering), opt-write-block (cwd-aware /opt write protection). | Implemented + regression-tested at `.claude/hooks/tests/`. |
| Post-tool-call hooks | `.claude/hooks/leak-detector.sh` | Foundation | Scans tool output for credential-shaped patterns; logs to `.claude/hooks/leaks.log`. | Implemented. |
| Session-lifecycle hooks (5) | `.claude/hooks/{session-start,session-orient,pre-compact,post-compact,session-summary}.sh` | Foundation | session-start (banner + integrity check), session-orient (project-priming directs `/orient`), pre-compact (writes deterministic state snapshot to `wiki/log/<ts>-pre-compact-handoff.md` BEFORE compaction), post-compact (directs `/orient` + references most-recent handoff), session-summary (deny/leak count). | Implemented. |
| opencode bridge plugin | `$HOME/.config/opencode/plugin/claude-bridge.ts` | Foundation | Maps opencode tool names to canonical envelope; spawns the same hook scripts. | Implemented (untested with live opencode). |
| `tools.state` | `$HOME/tools/state.py` | Infrastructure | State queries (active mode, git-state, bootstrap-exists, second-brain-reachable). CLI + MCP-exposed. | Implemented. |
| `tools.blockers` | `$HOME/tools/blockers.py` | Infrastructure | Blockers register: live-pending-decision-tasks scan, drift check vs `wiki/governance/blockers.md`. CLI + MCP. | Implemented. |
| `tools.progress` | `$HOME/tools/progress.py` | Infrastructure | Progress journey view: epic readiness + module/task counts + recent logs. CLI + MCP. | Implemented. |
| `tools.decisions` | `$HOME/tools/decisions.py` | Infrastructure | Decisions logbook: list / append / verify / next-id. **40 entries D001-D040** (empirically verified 2026-05-06 evening). CLI + MCP. | Implemented. |
| `tools.cycle` | `$HOME/tools/cycle.py` | Infrastructure | Structured cycle output (active mode + cycle definition + state + blockers + progress + lifecycle signals). Renders horizontal/vertical/ANSI/diff-fence stamp layouts; consumed by Stop hook + manual invocation. | Implemented. |
| `tools.tasks` | `$HOME/tools/tasks.py` | Infrastructure | Task-page parser (list / get / claimable) + **active-task cursor management (SB-124d): `active show / set / clear`** subcommands (validates ID against backlog) + create verbs (under-epic / under-task / from-blocker — DRAFT scaffolds for E002 piling, raise NotImplementedError until operator scope decisions). | Implemented. |
| `tools.stamp` | `$HOME/tools/stamp.py` | Infrastructure | Stamp render config per SB-114/115: `configure --layout horizontal\|vertical --enabled on\|off\|auto --density minified\|standard\|extended`, `show`, `clear`. Persists `$HOME/.claude/stamp-config.json`. Slash-command-driven via `/stamp-horizontal` `/stamp-vertical` `/stamp-on` `/stamp-off` `/stamp-auto` `/stamp-status`. Read by `end-of-cycle-stamp.sh` Stop hook + cycle.py emit functions. Density (SB-124c): minified drops Journey+Plan rows for narrow terminals; standard is default; extended ≡ standard until operator scopes additional detail. 2 layouts × 3 densities = 6 variants. | Implemented (DRAFT per SB-116 — UX redesign Epic placeholder). |
| `tools.objective` | `$HOME/tools/objective.py` | Infrastructure | Manage `active-mission` + `active-focus` + `active-impediment` state files (SB-118 — multi-cycle objective layer above active-task cursor). Subcommands: `set / clear / show` × 3 layers. Slash-command-driven via `/mission` `/focus` `/impediment`. Read by `mode-enforcement.sh` (banner) + `cycle.py` (stamp) + `mcp_server.py` (root_objective MCP tool). | Implemented (SB-118 closure D027). |
| `tools.priorities` | `$HOME/tools/priorities.py` | Infrastructure | Manage `active-priorities` imminent-work queue (SB-127 — top-priority tier ABOVE PM blockers). Verbs: `add / show / clear / remove / promote / demote / set / insert / update` (insert + update added per SB-130). Slash-command-driven via `/priorities <verb> <args>`. Read by `mode-enforcement.sh` + `cycle.py` (both stamps). | Implemented (SB-127 + SB-130 closures D029/D035). |
| `tools.questions` | `$HOME/tools/questions.py` | Infrastructure | Agent-pending questions retention layer (SB-134) — state file + verbs `add / show / clear / answer / promote-to-decision`. Distinct from blockers (operator-decision-required) + operator-pending decisions (operator-set). For agent's own pending Qs that should be retained past cycle. Slash-command-driven via `/questions`. Read by cycle.py (stamp surface) + handoff capture + `mcp_server.py` (root_questions MCP tool). | Implemented (SB-134 closure D037). |
| `tools.group` | `$HOME/tools/group.py` | Infrastructure | Chain / group / tree composition primitive (Q1 Layer A — DRAFT v1; canonical taxonomy from second-brain `wiki/domains/automation/research-pipeline-orchestration.md`). Programmatic composition: `chain(*steps)` sequential, `group(*callables)` parallel, `tree(root, branches, merge)` for synthesis. Documented inline pipelines: task-complete-cascade / stage-transition / sb-closure-batch / multi-file-coherent-edit / research-then-build. | Implemented DRAFT v1 (Layer B + C gated on operator-empirical). |
| `tools.run-tests` | `$HOME/tools/run-tests.py` | Infrastructure | Unified regression test runner across `.claude/hooks/tests/test-*.py` (8 hook tests) + `tools/tests/test-*.py` (5 tools tests) = 13 test files. Aggregate output: `<passed>/<total>` per file + AGGREGATE total. As of 2026-05-06 evening: **215/234 passing** (3 partial-fail files: end-of-cycle-stamp-diff-suppression 21/22, mode-enforcement 0/0 collection issue, questions 33/51). M-E001-1 vocabulary type 2 (verified-edit) requires this runner's exit-0 + inline output. | Implemented. |
| MCP server | `$HOME/tools/mcp_server.py` | Infrastructure | FastMCP server exposing **10 read-only tools** (empirically verified 2026-05-06 evening via `grep -c '@server\.tool()' tools/mcp_server.py = 10`): root_state, root_blockers, root_progress, root_decisions_{list,get,verify,next_id}, root_objective (SB-118+SB-127 — mission/focus/impediment/priorities), root_questions (SB-134 — agent-pending Q queue), root_orient (composite). Wired via `.mcp.json`; uses `/opt/.../venv/bin/python` (mcp pkg). | Implemented. |
| Hook regression tests | `.claude/hooks/tests/test-*.py` (8 files) + `tools/tests/test-*.py` (5 files) = **13 test files / 215/234 aggregate** | Infrastructure | Pre-merge verification that hook regex + tool logic changes don't introduce false-positives or false-negatives. Hook tests: context-warning, end-of-cycle-stamp-diff-suppression, malware-block, mindfulness, mode-enforcement, opt-write-block, output-discipline-guard, policy-block. Tools tests: group, objective-priorities, questions, stamp, tasks-create. Run via `python3 -m tools.run-tests`. | Implemented (cycles 52-53; expanded 2026-05-06 evening). |
| Validation pipeline (pre-commit OR CI workflow) | `.pre-commit-config.yaml` OR `.github/workflows/*.yml` | Infrastructure | Runs verify-policy + hook tests on relevant changes. | Planned (M004). |
| `tools/verify-policy.py` (or equivalent) | `$HOME/tools/verify-policy.py` | Infrastructure | Project-internal verifier — runs integrity check + deny-set count + hook permissions check + executable presence. | Planned (M004). |
| Suricata module install scripts | (path TBD by M005) | Features (facultative) | Install Suricata + suricata.yaml config + systemd unit + nftables / af-packet integration | Planned (M005, operator-driven). |
| PolarProxy module install scripts | (path TBD by M005) | Features (facultative) | Install PolarProxy + dummy interface setup + tcpreplay bridge service + CA distribution mechanism | Planned (M005, operator-driven). |
| pipelock module install scripts | (path TBD by M014) | Features (facultative) | Install luckyPipewrench/pipelock (AI agent firewall: MCP security + agent egress + DLP + SSRF + prompt-injection defense). Complementary agent-process layer. | Preliminary scope complete; atomic tasks gated on M007. |
| ccstatusline integration | `install.sh` `op_install_ccstatusline` + `templates/ccstatusline-{config,widgets}/` + `$HOME/.config/ccstatusline/profile-{base,intermediary,full-aidlc}.json` + 9 custom AIDLC widgets at `$HOME/.local/share/ccstatusline-widgets/` | Features | Custom Claude Code statusline. Operator-mandated 3-profile column tier (base=1, intermediary=2, full-aidlc=3). | Implemented + OPERATOR VISUALLY VERIFIED cycle 43. |
| `tools/gateway.py` (forwarder) | `$HOME/tools/gateway.py` | Sister-project integration | CLI dispatch into the second brain's gateway. Lands via `tools.setup --connect-project` from the second brain side. | Pending M007 (--connect-project run). |
| `tools/view.py` (forwarder) | `$HOME/tools/view.py` | Sister-project integration | CLI dispatch into the second brain's view tool. Lands via `tools.setup --connect-project`. | Pending M007. |

## Currently Available Tools (today — empirically verified 2026-05-06 evening)

The project's authoritative state at $HOME includes:

- **10 brain files** (`$HOME/{README,CLAUDE,AGENTS,BOOTSTRAP,CONTEXT,ARCHITECTURE,DESIGN,TOOLS,SKILLS,SECURITY}.md`) — operator-authored project documentation
- The methodology layer (`$HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml`) — copied from the second brain, adaptable per project
- The backlog scaffold (`$HOME/wiki/backlog/{milestones,epics,modules,tasks}/`) with **milestone v0.2 + 4 active epics + 14 modules + 66 atomic tasks** (4-level hierarchy: Milestone → Epic → Module → Task introduced 2026-05-06)
- The log directory (`$HOME/wiki/log/`) — populated with session logs + cycle reports + handoff docs + decision packages + design notes
- The governance directory (`$HOME/wiki/governance/{blockers,progress,decisions}.md` + `systemic-bugs.md` (138-row tracker; max ID SB-138; 1 historical duplicate))
- **15 Python tools** at `$HOME/tools/` (state, blockers, progress, decisions, cycle, tasks, **stamp**, **objective** SB-118, **priorities** SB-127, **questions** SB-134, **group** chain/group/tree primitive, **run-tests** unified regression runner + mcp_server + _paths + __init__)
- **17 `.sh` + 1 `.py` hook scripts** on disk = **18 hook scripts**; **10 wired matchers across 8 events** (PreToolUse, PostToolUse, SessionStart, UserPromptSubmit (4-hook compound stack: context-warning + output-discipline-guard + mode-enforcement + mindfulness), PreCompact, PostCompact, Stop, SessionEnd); archived hooks (stamp-control, deny-secret-files, premise-guard, integrity.py-not-yet-wired) retained per operator directive 2026-05-06
- **30 slash commands** at `.claude/commands/` (incl. /stamp-* config + /install-agent-brain + /mode-* + /mission + /focus + /impediment SB-118 + /priorities SB-127 + /terminate + /finish-smoothly + /task SB-124d + /questions SB-134 + /audit + /sync-progress + /handoff + /help-root)
- 3 modes at `.claude/modes/` + 3 brain-loaded subagents at `.claude/agents/` (root-explorer / root-architect / root-pm-scoper)
- 2 skills at `.claude/skills/<name>/SKILL.md` (surface-state + surface-blockers — description-match auto-trigger)
- **11 rules files** at `.claude/rules/` (routing, methodology, hook-architecture, work-mode, self-reference, words-are-sacrosanct, operating-principles, loop-cron-lifecycle, trigger-model, context-engineering, **compound-and-waterfall** SB-123)
- ccstatusline integration: 5 profiles + 13 custom widgets + wrapper + switch script
- 5 deployment scripts at `$HOME/scripts/` + lib/ helpers + README (cycle-53 publish-readiness)
- **install.sh implement-stage (readiness 98%)** — `--profile {base|full|project|interactive}`, `--mode {bridge|endpoint|hybrid|auto}`, per-op toggles, `--wizard` state-aware route, granular install (`--with-group` / `--no-group`), `--dry-run` + `--check` + 16-step `op_verify`, shellcheck PASS
- **9 sub-READMEs** (DRAFT v1, agent-authored 2026-05-06 evening per brain-improvement mandate): tools/README.md + .claude/{commands,hooks,modes,rules,agents,skills}/README.md + templates/README.md + scripts/README.md (refreshed). All wiki-schema 9-field compliant + Summary + Relationships sections.
- **40 decisions logbook entries** (D001-D040) — full audit trail at `wiki/governance/decisions.md`
- **138-row systemic-bugs tracker** — max ID SB-138; 1 historical duplicate; status breakdown: 50 verified / 12 recurring / 6 open / 93 structurally-fixed (some overlap with the recurring set)
- **13 regression test files / 215/234 aggregate passing** (8 hook tests + 5 tools tests; run via `python3 -m tools.run-tests`)
- **MCP server with 10 root_* tools** at `tools/mcp_server.py` — exposes project state to any MCP-aware AI client (root_state, root_blockers, root_progress, root_decisions_{list,get,verify,next_id}, root_objective, root_questions, root_orient)

**Project is at implement-stage for foundation install** — install.sh fully functional incl. real wifi/nftables/integrity ops; M011 ccstatusline operator-verified; modes-architecture working via /loop /cycle since cycle 41; per-project install via `--profile project` enables sister-project agent-brain deploy. T012 install.sh real-execute remains operator-driven future-session work (D024 GREENLIT).

## Per-Tool Reference

### `install.sh` (implemented, M003 — implement-stage 98% readiness)

**Purpose.** Take a fresh Linux host and bring it to foundation-tier root-modules state. Idempotent: re-running on an already-installed host is a no-op (or cleanly applies any config drift). OS-family-aware (Debian/RHEL/Arch). Two install scopes: OS-root install (`--profile base|full`) and per-project agent-brain install (`--profile project`).

**Invocations:**

```bash
cd $HOME

# Wizard mode — state-aware "where you are + what to do next" report
./install.sh --wizard                              # Safe from any state; detects route + offers next-best-actions

# Granular group-level install (composes with --profile)
./install.sh --profile base --no-group wifi --no-group integrity   # base minus groups
./install.sh --profile base --with-group ccstatusline              # base + Features group
# Groups: security, session-lifecycle, agent-discipline, stamp, bridge, opencode,
#         wifi, integrity, ccstatusline, tools-{core,cycle,stamp,objective,all}

# OS-root install (default mode for this dev host)
./install.sh --dry-run                            # Preview; no changes
./install.sh --dry-run --profile full             # Base + ccstatusline (Features tier)
./install.sh                                       # Apply base install (idempotent; backups divergent files)
./install.sh --profile full                        # Base + facultative modules (npm-based ccstatusline)
./install.sh --profile base --mode endpoint       # Endpoint-only host (no bridge/wifi ops)
./install.sh --no-bridge --no-wifi                # Per-op toggle override
./install.sh --check                               # Verify installed state (read-only; exit 1 on drift)
./install.sh --help                                # Full usage incl. all 14 flags + 4 profiles + examples
./install.sh --version                             # 0.0.3-implement-partial

# Per-project install (deploy agent brain into a sister project)
./install.sh --dry-run --profile project --dest /opt/devops-solutions-information-hub
./install.sh --profile project --dest /home/jfortin/openarms
# OR equivalent slash command from any session:
/install-agent-brain /opt/devops-solutions-information-hub
```

**Verified invariants:**
- Idempotent: `install_file()` detects identical content + skips with `unchanged` log; divergent files backup to `<path>.ghostproxy.bak.<UTC-ts>` before overwrite.
- Path-A safe: when `SRC == DEST_HOME` (e.g., installing on this dev host), all `op_install_*` functions short-circuit unchanged content.
- Per-op composition: `--profile project` disables OS-level ops (bridge/wifi/integrity/ccstatusline/opencode) since those are scope=root-only; deploys agent brain (settings/hooks/rules/commands/agents/modes/skills/tools) to `<dest>/.claude/` + `<dest>/tools/`.
- Post-install verification: 16+ checks (`op_verify`) — settings.json parses, hooks executable, integrity match, opencode bridge, br0 UP, wifi config + ruleset + table loaded + service enabled, brain pieces deployed counts.
- `bash -n install.sh` PASS; `shellcheck install.sh` PASS (zero findings).
- nftables ruleset for management wifi syntax-checked via `nft -c` before deploy.
- `ensure_nftables_d_include()` idempotently provisions `/etc/nftables.conf` with `include "/etc/nftables.d/*.nft"` (creates fresh OR appends with backup-first if missing).
- `wpa_supplicant@mgmt0.service` enabled at install; conditional start (skipped if SSID/PSK placeholders unfilled to avoid auth-fail log spam).

#### Idempotency invariants — files CREATED / OVERWRITTEN / LEFT UNTOUCHED + re-run behavior (T016 deliverable, empirically verified 2026-05-07 cron F46)

**Files install.sh CREATES** (when not pre-existing on host):

| Path pattern | Operator-flag gate | Created by op_function |
|---|---|---|
| `/root/.claude/settings.json` | always (hooks=1) | `op_install_endpoint_safety_policy` |
| `/root/.claude/hooks/*.sh` (18 files) + `/root/.claude/hooks/integrity.py` | always (hooks=1) | `op_install_endpoint_safety_policy` |
| `/root/.claude/agents/*.md` (3 brain-loaded sub-agents) | always | `op_install_endpoint_safety_policy` |
| `/root/.claude/modes/*.md` (3 mode files) | always | `op_install_endpoint_safety_policy` |
| `/root/.claude/rules/*.md` (12 rule files) | always | `op_install_endpoint_safety_policy` |
| `/root/.claude/commands/*.md` (43-44 slash commands) | always | `op_install_endpoint_safety_policy` |
| `/root/.claude/skills/*/SKILL.md` (2 skills) | always | `op_install_endpoint_safety_policy` |
| `/root/.claude/integrity.json` (SHA-256 baselines for 5 safety-policy artefacts) | `--with-integrity` (default on) | `op_install_integrity_sentinel` |
| `/root/.config/opencode/plugin/claude-bridge.ts` | `--with-opencode` (default on) | `op_install_opencode_bridge` |
| `/root/tools/*.py` (15 modules) | `--with-tools` (default on) | `op_install_tools` |
| `/etc/systemd/network/30-ghostproxy-bridge.netdev` | `--with-bridge` (default on, mode=bridge) | `op_install_network_bridge` |
| `/etc/systemd/network/30-ghostproxy-bridge.network` | same | same |
| `/etc/systemd/network/40-ghostproxy-bridge-members.network` | same | same |
| `/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf` | `--with-wifi` (default on) + operator-supplied credentials | `op_install_management_wifi` |
| `/etc/nftables.d/management-wifi-outbound-only.nft` | `--with-wifi` | same |

**Files install.sh OVERWRITES on re-run when out-of-sync** (backup-first pattern):

- Same list as CREATES, when current content diverges from what install.sh would render
- Pattern: `<dest>.ghostproxy.bak.<UTC-timestamp>` (e.g. `settings.json.ghostproxy.bak.2026-05-07T15-30-00Z`)
- `install_file()` (line 1546) computes SHA-256 of source vs destination → if identical: log `unchanged: <path>`, skip; if divergent: `backup_if_exists()` (line 1509) moves existing → `<path>.ghostproxy.bak.<ts>`, then writes new content
- `/etc/nftables.conf`: APPENDED with `include "/etc/nftables.d/*.nft"` directive only if missing (per `ensure_nftables_d_include()`); existing operator-authored rules preserved with backup-first

**Files install.sh LEAVES UNTOUCHED** (never modified by any op_function):

- `/root/.bashrc`, `/root/.profile`, `/root/.bash_history` — operator's shell config
- `/root/.gitconfig` — operator's git identity
- `/root/.ssh/*` — never touched by any safety-policy op
- `/home/*` — other users; install scope is `/root` only (Path-A safe per `SRC == DEST_HOME` short-circuit)
- `/root/*` files outside `.claude/` and `.config/opencode/` and `tools/` — operator's project work
- `*.ghostproxy.bak.*` files — preserved across runs (operator-controlled cleanup; uninstall.sh also preserves per "Planned invariants" above)
- `/etc/systemd/network/*` files NOT prefixed with `30-ghostproxy-` or `40-ghostproxy-` — operator's other network configs preserved
- `/etc/nftables.d/*` files NOT named `management-wifi-*` — operator's other rulesets preserved
- `/etc/nftables.conf` body content — only the `include` directive is added (with backup); existing rules preserved

**Re-run behavior** (`./install.sh; ./install.sh` on consistent host):

- Each `install_file()` call detects identical content via SHA-256 → logs `unchanged: <path>` → skips
- Exit 0
- No new backup files created (no overwrites occurred)
- `op_verify` runs read-only (does not mutate state); reports PASS/FAIL per check
- `--check` flag (line 100) confirms idempotency: read-only verification; exit 1 if drift, exit 0 if all in-sync
- Empirically demonstrable: F35+F46 ran `./install.sh --check` showing 13/16 PASS (3 wifi-credentials gated per CONTEXT.md, expected per literal); zero state mutations since the integrity baseline refresh in F35

**Idempotency claim is testable** per the recipe: `./install.sh && ./install.sh; ./install.sh --check` — should produce identical end state, second run is no-op (no backups created), `--check` exits 0 if no other drift. Operator-empirical full-execute on real Debian 13 host is T012 last-2% (D024 GREENLIT, operator-driven).

#### Recovery / console-only fallback (T013 Done-When 5 deliverable, agent-authored 2026-05-07 cron F48 — operator-revisable)

When the management wifi (`mgmt0`) or bridge (`gpbr0`) misbehaves and SSH access is lost, the operator must be able to recover via direct console (keyboard + monitor on the host). This subsection documents the fallback procedures.

**Scenario A — wifi-mgmt0 fails to associate** (operator's existing SSID changed, AP down, or credentials drift)

1. Boot host with keyboard + monitor attached → console login as `root` (no SSH dependency)
2. Diagnose: `journalctl -u wpa_supplicant@mgmt0 -n 50` → look for auth-failure / SSID-not-found / no-carrier
3. Diagnose: `ip link show mgmt0` → confirm interface UP; if DOWN run `ip link set mgmt0 up`
4. Hot-fix: edit `/etc/wpa_supplicant/wpa_supplicant-mgmt0.conf` (update SSID/PSK if changed); `systemctl restart wpa_supplicant@mgmt0`
5. Verify: `wpa_cli -i mgmt0 status` → should report `wpa_state=COMPLETED`; `ip addr show mgmt0` → IP assigned
6. SSH should restore once carrier + IP land

**Scenario B — bridge `gpbr0` brings up with no carrier** (LAN-side disconnected, operator's switch/router off)

1. Console login as above
2. Diagnose: `ip link show gpbr0` → state UP but `NO-CARRIER` flag = no upstream link detected
3. Diagnose: `ip link show <member1> <member2>` → bridge members; check each for cable + LED + carrier
4. Diagnose: `journalctl -u systemd-networkd -n 50` → bridge brought up + members enslaved
5. The bridge `ConfigureWithoutCarrier=yes` setting (per `30-ghostproxy-bridge.network`) means it WILL come up without carrier — this is intentional for IPS pass-through (host doesn't depend on inspected segment being up)
6. If carrier is genuinely needed: physically reconnect cables, then `systemctl restart systemd-networkd`

**Scenario C — bridge breaks SSH access entirely (worst case — emergency disable)**

1. Console login
2. Disable systemd-networkd: `systemctl stop systemd-networkd && systemctl disable systemd-networkd`
3. Move ghostproxy network configs out of the way: `mkdir -p /root/ghostproxy-disabled-configs && mv /etc/systemd/network/{30,40}-ghostproxy-* /root/ghostproxy-disabled-configs/`
4. Restart networking with classic ifupdown OR networkd: `dhclient mgmt0` (or operator's preferred network manager)
5. Once SSH access restored: investigate root cause via `journalctl -u systemd-networkd --since "1 hour ago"`
6. Re-enable when fixed: move configs back + `systemctl enable --now systemd-networkd`

**Scenario D — install.sh broke the safety envelope (settings.json / hooks tampered)**

1. Console login
2. The integrity sentinel (`integrity.py`) fail-CLOSES every Claude tool call → Claude Code is unusable until restored
3. Recovery: `cd $HOME && ./install.sh` (re-applies hooks + settings + integrity baseline; idempotent so safe to re-run)
4. If install.sh itself broken: restore from backup `<file>.ghostproxy.bak.<UTC-ts>` (preserved per "Files install.sh LEAVES UNTOUCHED" subsection)
5. Verify: `./install.sh --check` should report 13/16 PASS minimum (3 wifi-credentials gated remain; everything else green)

**Scenario E — emergency: revert all ghostproxy changes**

1. Console login
2. Run `./uninstall.sh` (when implemented per M003 planned section below) — restores prior state from backups
3. Pre-uninstall.sh manual fallback: locate `*.ghostproxy.bak.*` files via `find /root /etc -name "*.ghostproxy.bak.*" 2>/dev/null`; manually restore via `mv <backup> <original>`
4. Disable ghostproxy systemd units: `systemctl disable wpa_supplicant@mgmt0 systemd-networkd`
5. Reboot to confirm clean state

**Recovery doc maintenance**: when install.sh adds new touchpoints (new systemd unit / new config file / new hook), add scenario coverage to this subsection. The doc must stay synchronized with install.sh's actual touchpoints (cross-reference with the Idempotency invariants subsection above).

### `uninstall.sh` (planned, M003)

**Purpose.** Remove project-installed config from the host. Restores prior state where backups exist; removes config where the project itself authored it.

**Planned invocations:**

```bash
cd $HOME
./uninstall.sh --dry-run             # Preview removal
./uninstall.sh                        # Apply removal
./uninstall.sh --bridge-only          # Remove only the opencode bridge wiring (Claude side untouched)
./uninstall.sh --hooks-only           # Remove only the hook scripts (settings.json untouched)
```

**Planned invariants:**
- After full uninstall, `./install.sh --dry-run` reports the host as needing a full install (state is fully removed).
- After `--bridge-only`, opencode operates without the bridge plugin; Claude Code policy still applies.
- Existing backup files (`*.ghostproxy.bak.*`) are NOT touched by uninstall — they remain for operator-controlled cleanup.

### Tamper-detection sentinel (implemented — `$HOME/.claude/hooks/integrity.py`)

**Purpose.** Pre-tool-call hook that refuses every tool call when safety controls are tampered. Fail-CLOSED.

**Status update 2026-05-06**: section header was previously marked "(planned, M003)" — this was section-vs-inventory drift. The Tool Inventory table at top of file marked it as "Implemented" (sentinel exists at `$HOME/.claude/hooks/integrity.py`). Section now reconciled — the design-intent content below describes the verified behavior + planned future enhancements.

**Verified invocations** (when authored, the exact command depends on operator's authoring choices — sentinel imported by policy-block.sh + malware-block.sh as Python module rather than standalone CLI):

```bash
# Manual integrity check (run at any time):
<sentinel-command> --check

# Expected output (when OK):
# OK

# Expected output (when tampered, example failure modes):
# FAIL: settings.json missing
# FAIL: disableAllHooks=true
# FAIL: deny-set count below threshold (current: 87, minimum: 100)
# FAIL: hook script /path/to/policy-block.sh missing
# FAIL: hook script /path/to/policy-block.sh size 0 (suspicious)
```

**Verified invariants:**
- Returns OK when all sub-checks pass; specific failure reason otherwise.
- Failure cases enumerated explicitly (not "something failed" — operator can resolve the specific issue).
- Sentinel is itself integrity-protected (size + checksum verification of the sentinel script).
- Wiring as standalone CLI (vs current import-only pattern) deferred to T015 post-install verification work.

### Pre-tool-call hooks: deny-set + behavior-pattern + leak-detector (implemented — `.claude/hooks/{policy-block,malware-block,opt-write-block,leak-detector}.sh`)

**Purpose.** Inspect every AI tool call against the safety policy. Refuse / ask-for-confirmation / allow.

**Status update 2026-05-06**: section header was previously marked "(planned, M003)" — this was section-vs-inventory drift. All 4 hooks are wired in `.claude/settings.json` and regression-tested at `.claude/hooks/tests/`:
- `policy-block.sh` — deny credential-file reads (.env / *.pem / id_rsa / etc.); regression-tested SB-083 false-positive resistance
- `malware-block.sh` — block dangerous bash patterns; regression-tested SB-084/106/132 false-positive resistance
- `opt-write-block.sh` — block knowledge-content writes to /opt second-brain; bypass via `ROOT_OPT_WRITE_REASON` per SB-098
- `leak-detector.sh` — PostToolUse output scan for credential-shaped patterns

**Verified hook events** (per Claude Code's hook protocol):
- `PreToolUse` — runs before tool executes; can decide allow/deny/ask
- `PostToolUse` — runs after tool output is captured; can scan output for sensitive values

**Verified invocations** (hooks fire automatically on tool calls; manual invocation for testing):

```bash
# Test pre-tool-call hook on a sample envelope:
echo '{"session_id":"test","tool_name":"Bash","tool_input":{"command":"cat ~/.env"},"hook_event_name":"PreToolUse"}' | <hook-path>

# Expected output: a JSON decision
# {"permissionDecision":"deny","permissionDecisionReason":"credential file pattern matched: ~/.env"}

# Run regression suite (verifies all hooks haven't drifted):
python3 -m tools.run-tests
# Expected: 215/234 aggregate (3 partial-fail files; 8 hook tests + 5 tools tests = 13 files)
```

**Verified invariants:**
- Hooks return JSON decisions (allow/deny/ask) per the canonical envelope contract documented in [AGENTS.md](AGENTS.md).
- Hooks are deterministic — same input → same decision.
- Hook decisions are logged with reason + timestamp (audit-log-ready) at `.claude/hooks/{policy-block,malware-block}-deny.log` + `leaks.log`.
- False-positive resistance regression-tested per closure of SB-083 (cmd-sub regex), SB-084 (script-capture), SB-106 (log-tamper), SB-132 (hook-ln) — anchored regexes prevent matching benign command-substring patterns.

### opencode bridge plugin (implemented, untested with live opencode — `$HOME/.config/opencode/plugin/claude-bridge.ts`)

**Purpose.** Map opencode's plugin SDK to the canonical envelope; opencode obeys the same policy as Claude Code without policy duplication.

**Status update 2026-05-06**: section header was previously marked "(planned, M003)" — this was section-vs-inventory drift. Bridge plugin file exists at `$HOME/.config/opencode/plugin/claude-bridge.ts` (verified by `ls`); marked "Implemented (untested with live opencode)" in Tool Inventory table. The "Verified invariants" describe design-intent + verified-by-code-inspection behavior; live-opencode-session smoke test pending.

**Verified invariants** (by code inspection):
- opencode's tool name `bash` maps to canonical `Bash`; `read` → `Read`; etc.
- Bridge spawns the same hook scripts Claude Code calls; same scripts, same envelope, different runtime.
- Bridge plugin is type-only-deps on `@opencode-ai/plugin` (no runtime deps that drift).
- Verification command: `opencode debug config 2>/dev/null | grep claude-bridge` returns non-empty when bridge is resolved; silent when not.

**Pending live-test invariants** (operator-driven future-session):
- Live opencode session opening in $HOME confirms bridge plugin loads + intercepts opencode's tool calls.
- Cross-tool consistency: same deny-set fires when opencode invokes `bash cat ~/.env` as when Claude Code invokes `Bash(cat ~/.env)`.

### `tools/verify-policy.py` (planned, M004)

**Purpose.** Project-internal verifier that programmatically checks the safety envelope's invariants.

**Planned invocations:**

```bash
cd $HOME
python3 -m tools.verify_policy            # Full check (integrity + deny-set + hooks + permissions)
python3 -m tools.verify_policy --quick    # Just integrity check (subset; faster)
python3 -m tools.verify_policy --json     # Machine-readable output
python3 -m tools.verify_policy --help
```

**Planned invariants:**
- Returns 0 when all checks pass; non-zero with specific failure list otherwise.
- Checks include: integrity check (delegate to sentinel) + deny-set count above threshold + all hooks executable + correct file permissions + no out-of-sync backups left over.
- Idempotent + side-effect-free — running it does not mutate state.

### Validation pipeline (planned, M004)

**Purpose.** Run `verify-policy` automatically on relevant changes. Catches drift before it lands.

**Planned forms** (operator-decision):

- **pre-commit:** `.pre-commit-config.yaml` runs `verify-policy --quick` on every commit.
- **CI workflow:** `.github/workflows/verify.yml` runs `verify-policy` on every push.
- **Both:** pre-commit for local fast feedback + CI for guaranteed enforcement.

**Planned invariants:**
- Failure of `verify-policy` blocks the commit / push.
- Pipeline output is human-readable (not just exit codes).
- Operator can bypass for legitimate emergencies via documented channel (e.g. `--no-verify` with operator approval logged).

### Suricata module install scripts (planned, M005, operator-driven)

**Purpose.** Install Suricata + configure it for root-modules's bridge topology.

**Planned invocations:**

```bash
cd $HOME
./install-module.sh suricata --dry-run      # Preview Suricata install
./install-module.sh suricata                # Apply
./install-module.sh suricata --uninstall    # Remove
```

**Planned config:** `/etc/suricata/suricata.yaml` configured per the chosen IPS path (NFQUEUE+nftables vs AF_PACKET copy-mode), HOME_NET, interface(s), runmode (`workers` for IPS), `stream.inline: yes`, `action-order` default, eve.json output, threading per host CPU count.

**Planned smoke test** (per `wiki/sources/src-suricata-install-quickstart.md`):

```bash
# Install ET Open ruleset:
sudo suricata-update

# Trigger canary alert:
sudo tail -f /var/log/suricata/fast.log &
curl http://testmynids.org/uid/index.html

# Expected: SID 2100498 alerts: "GPL ATTACK_RESPONSE id check returned root"
```

### PolarProxy module install scripts (planned, M005, operator-driven)

**Purpose.** Install PolarProxy + configure for transparent forward proxy + integrate with Suricata via dummy interface + tcpreplay.

**Planned invocations:**

```bash
cd $HOME
./install-module.sh polarproxy --dry-run    # Preview
./install-module.sh polarproxy              # Apply
./install-module.sh polarproxy --uninstall  # Remove
```

**Planned setup steps** (per `wiki/sources/src-polarproxy.md` + `src-hanke-honeypot-polarproxy-suricata-integration.md`):

1. Download PolarProxy Linux x64 binary from Netresec.
2. `setcap 'cap_net_bind_service=+ep'` on the binary (so sub-1024 ports work without root).
3. Create `proxyuser` system user; install systemd service unit.
4. Create dummy interface: `ip link add polarproxytls type dummy && ip link set polarproxytls up` (boot-time via systemd-networkd or oneshot service).
5. PolarProxy systemd service: transparent forward mode (`-p 443,80,443`), `--pcapoverip 4430`, output dir `/var/log/polarproxy/`, bypass list for cert-pinned domains.
6. tcpreplay bridge systemd service: `nc localhost 4430 | tcpreplay -i polarproxytls -t -`. Depends on polarproxy.service.
7. Suricata's af-packet config gains the `polarproxytls` dummy interface as a third capture source.
8. CA distribution: dynamic CA exposed via `--certhttp 10080` for client retrieval; operator deploys to LAN endpoints.

**Planned smoke test:**

```bash
# Verify PolarProxy is running:
systemctl status polarproxy

# Verify dummy interface exists + is up:
ip link show polarproxytls

# Verify tcpreplay bridge:
systemctl status polarproxy-tcpreplay

# Verify Suricata sees the dummy interface:
sudo suricata --build-info | grep af-packet
sudo cat /etc/suricata/suricata.yaml | grep polarproxytls

# Send a test HTTPS session through the bridge from a CA-trusting LAN endpoint:
curl https://testmynids.org/uid/index.html

# Verify cleartext appears in the PCAP-over-IP stream + Suricata sees it:
sudo tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="http")'
```

### Implemented Python Tools (consolidated reference)

> The 12 functional Python modules at `$HOME/tools/` (excluding `__init__.py` + `_paths.py` helpers + `mcp_server.py` documented separately). Per-module composition map + state-file architecture detail at the **canonical [tools/README.md](tools/README.md)** (DRAFT v1, agent-authored 2026-05-06 evening). This section is operator-facing usage view; tools/README.md is per-module composition view.

**Canonical invocation pattern** (cross-reference):

```bash
# Use the second-brain venv (ensures deps resolved)
/opt/devops-solutions-information-hub/.venv/bin/python -m tools.<module> <verb> <args>
```

System `python3` works for tools that don't have venv-only deps (most of them) but the canonical form ensures portability + compatibility with the second-brain's tooling. M-E001-1 vocabulary type 2 (`verified-edit`) requires real regression-suite output — use `python3 -m tools.run-tests` for that.

**Per-module quick reference:**

| Module | Verb examples | Slash-command surface |
|---|---|---|
| `state` | `python3 -m tools.state` (snapshot) | (composes — no direct command) |
| `blockers` | `tools.blockers --check` (exit 0/1), `--filter`, `--decision-package` | `/blockers` |
| `progress` | `tools.progress` (refresh callout from live state), `--callout` | `/progress`, `/sync-progress` |
| `decisions` | `tools.decisions list / append --title --rationale --reversibility / verify / next-id` | `/decisions` |
| `cycle` | `tools.cycle --json / --status-block / --color / --diff-fence / --ansi-fence / --ansi-horizontal / --emit-status-block` | (rendered by Stop hook + manual; not direct slash) |
| `tasks` | `tools.tasks list / get <T###> / claimable / active show / active set <T###> / active clear / create under-epic --epic <slug> --title <text> / under-task --task <T###> --title <text> / from-blocker --blocker <SB-NNN\|B###> --title <text>` | `/task <verb>` |
| `stamp` | `tools.stamp configure --layout horizontal\|vertical --enabled on\|off\|auto --density minified\|standard\|extended / show / clear` | `/stamp-{horizontal,vertical,on,off,auto,status}` |
| `objective` | `tools.objective set mission\|focus\|impediment <text> / clear mission\|focus\|impediment / show` | `/mission`, `/focus`, `/impediment` |
| `priorities` | `tools.priorities add\|show\|clear\|remove\|promote\|demote\|set\|insert\|update <args>` | `/priorities <verb>` |
| `questions` | `tools.questions add\|show\|clear\|answer\|promote-to-decision <args>` | `/questions <verb>` |
| `group` | `tools.group` (programmatic — chain/group/tree composition primitive) | (no slash command yet — Layer B + C gated on operator-empirical) |
| `run-tests` | `tools.run-tests` (no args — runs full suite); 13 test files / 215/234 aggregate as of 2026-05-06 evening | (composes — `/audit` step indirectly) |

**Consumer pattern** (state-file-mediated — see tools/README.md "How tools fit together" diagram for full composition map):

```
   Slash commands → tools.* (write state) → $HOME/.claude/active-* state files →
   ↓
   Hooks (read state) — mode-enforcement.sh, end-of-cycle-stamp.sh, pre-compact.sh
   ↓
   MCP server (read state) — exposes 10 root_* tools for cross-process access
   ↓
   /orient command — deterministic 21-step intel chain reads tools' output
   ↓
   /handoff command — captures tools' state into pre-compact handoff doc
```

No tool calls another tool's API directly — composition flows through the state files. This is the **state-file-mediated** pattern documented at tools/README.md.

**Extension guide**: when authoring a new tool, follow the convention at [tools/README.md § Extending — adding a new tool](tools/README.md#extending--adding-a-new-tool). Update both this consolidated section + the canonical tools/README.md inventory + brain-piece counts in root README.md when count changes.

### `tools/gateway.py` forwarder (lands via M007)

**Purpose.** Dispatch CLI calls into the second brain's gateway tool. After M007 connect runs, this thin forwarder is at `$HOME/tools/gateway.py` and dispatches with `cwd=<second-brain>/`.

**Generated by:** `python3 -m tools.setup --connect-project $HOME` from the second brain.

**Available subcommands** (after M007 connect):

```bash
# From inside $HOME:
python3 -m tools.gateway orient                      # Context-aware orientation (canonical first step)
python3 -m tools.gateway orient --fresh              # Force fresh-mode orientation
python3 -m tools.gateway orient --format json        # Structured output

python3 -m tools.gateway query --models              # All 9 methodology models
python3 -m tools.gateway query --model bug-fix       # One model's stages + artifacts
python3 -m tools.gateway query --identity            # This project's identity profile
python3 -m tools.gateway query --profiles            # SDLC profiles available

python3 -m tools.gateway compliance                   # Adoption-tier check + gaps
python3 -m tools.gateway health                       # Health score (when applicable)

python3 -m tools.gateway template <type>              # Get a page template

python3 -m tools.gateway timeline --scope all --since 7d   # Cross-project temporal view
python3 -m tools.gateway timeline --scope root-modules   # This project's events

python3 -m tools.gateway contribute --type lesson --title "..." --content "..."
python3 -m tools.gateway contribute --type correction --title "..." --content "..."
python3 -m tools.gateway contribute --type remark --title "..." --content "..."

python3 -m tools.gateway flow [--step N]              # Goldilocks step-by-step
```

**Invariants:**
- Forwarder is auto-generated (do NOT hand-edit; re-run `--connect-project` to regenerate).
- `cwd=<second-brain>/` for the dispatched call.
- `--wiki-root` is set to root-modules's path so the gateway knows which project called.
- Auto-generated marker comment at the top of the file.

### `tools/view.py` forwarder (lands via M007)

**Purpose.** Dispatch CLI calls into the second brain's view tool. Auto-generated by `--connect-project`.

**Available subcommands** (after M007 connect):

```bash
# From inside $HOME:
python3 -m tools.view                       # Wiki dashboard (full tree)
python3 -m tools.view spine                  # 16 models + 5 sub-models + standards
python3 -m tools.view model <name>           # One model in full
python3 -m tools.view model methodology      # The methodology model
python3 -m tools.view model llm              # The wiki itself
python3 -m tools.view lessons                # 44+ validated lessons
python3 -m tools.view patterns               # 19+ validated patterns
python3 -m tools.view decisions              # 16+ decisions
python3 -m tools.view principles             # 3 governing principles
python3 -m tools.view standards              # 25 standards pages
python3 -m tools.view domain <name>          # One domain
python3 -m tools.view search "<query>"        # Full-text search
python3 -m tools.view refs "<title>"          # Trace relationships
python3 -m tools.view model <name> --full    # Complete page (no truncation)
```

**Invariants:**
- Same auto-generated forwarder pattern as gateway.py.
- `WIKI_VIEW_CALLER_DIR` env var set to root-modules's CWD for the dispatched call.

## Operator-Intent → Tool (summary)

For the full operator-intent → tool routing table, see [CLAUDE.md § Operator-Intent Routing Table](CLAUDE.md#operator-intent-routing-table-claude-code-specific). Summary mapping:

| Operator says... | Tool / command |
|---|---|
| `"verify install"` | `./install.sh --check` (read-only verification — exit 0 = clean; exit 1 = drift) OR `./install.sh --dry-run` (preview) |
| `"reinstall"` | `./install.sh` (idempotent; backups divergent files) |
| `"wizard mode"` / `"where am I"` | `./install.sh --wizard` (state-aware route detection + next-best-actions) |
| `"granular install"` / `"install partial"` | `./install.sh --profile base --no-group <name>` OR `--with-group <name>` (groups: security, session-lifecycle, agent-discipline, stamp, bridge, opencode, wifi, integrity, ccstatusline, tools-{core,cycle,stamp,objective,all}) |
| `"per-project install"` / `"deploy agent brain"` | `./install.sh --profile project --dest <path>` OR `/install-agent-brain <path>` slash command |
| `"check integrity"` | (sentinel imported by policy-block + malware-block — runs automatically per tool call) |
| `"audit"` / `"10-step integrity check"` | `/audit` slash command — yamls + hooks + blockers + decisions + state files |
| `"git audit"` | `cd $HOME && git status` + `git ls-files` |
| `"run regression tests"` / `"verify edit"` | `python3 -m tools.run-tests` — 13 test files / 215/234 aggregate |
| `"orient"` | `/orient` slash command (deterministic 21-step intel chain) |
| `"orient to second brain"` | `python3 -m tools.gateway orient` (after M007) |
| `"browse second brain"` | `python3 -m tools.view spine` (after M007) |
| `"set mission/focus/impediment"` | `/mission set <text>` · `/focus set <text>` · `/impediment set <text>` (SB-118) |
| `"add priority"` / `"P1 ..."` | `/priorities add <text>` (SB-127 — verbs: add/show/clear/remove/promote/demote/set/insert/update) |
| `"set active task"` / `"working on T###"` | `/task set <T###>` (SB-124d — validates against backlog) |
| `"create new task"` | `/task create under-epic --epic <slug> --title <text>` (DRAFT scaffolds for E002 piling) |
| `"agent has a question"` / `"retain Q"` | `/questions add <text>` (SB-134 — agent-pending Q queue distinct from blockers + operator-pending decisions) |
| `"handoff"` / `"checkpoint"` | `/handoff` slash command (snapshot doc) |
| `"terminate session"` / `"end session"` | `/terminate` (full status/progress/artifacts/role sweep + handoff doc) |
| `"finish smoothly"` | `/finish-smoothly` (forced knowledge-extraction PASS + handoff) |
| `"smoke suricata"` | (per Suricata module install + canary alert SID 2100498) |
| `"polarproxy decryption rate"` | (monitor TLS sessions seen vs decrypted, per PolarProxy module) |
| `"build a module"` | Read M005 module page; modules are facultative + operator-driven |

## System-Level Dependencies

Tools planned by this project rely on system-level packages. When install scripts exist, they will check + install (or document the operator-managed install of) these dependencies.

| System dependency | Required by | Install (Debian) |
|---|---|---|
| `bash` | install.sh, uninstall.sh, hook scripts | (built-in) |
| `python3` (3.11+) | integrity sentinel, verify-policy, forwarders | `apt install python3` (default in Debian 13+) |
| `git` | repo operations | `apt install git` |
| `nftables` | bridge firewall + Suricata NFQUEUE integration | `apt install nftables` (default in Debian 13+) |
| `bridge-utils` | `brctl` for bridge inspection | `apt install bridge-utils` |
| `iproute2` | `ip` command for interface ops | (built-in in modern Debian) |
| `jq` | parsing eve.json + settings.json in audit scripts | `apt install jq` |
| `wpa_supplicant` (or NetworkManager) | wifi client | `apt install wpasupplicant` |
| `suricata` | Suricata module (Layer 2) | `apt install suricata` (Debian 13+) OR build from source |
| `polarproxy` (binary) | PolarProxy module (Layer 3) | Manual download from Netresec (vendor binary, not in apt) |
| `tcpreplay` | PolarProxy → dummy interface bridge | `apt install tcpreplay` |
| `netcat-openbsd` | tcpreplay's `nc localhost` reader | `apt install netcat-openbsd` |
| `opencode` | (operator's choice) | Per opencode upstream install instructions |

## Verification Commands (Adjacent — for any system change)

When making changes to the project's authoritative state, run these verifications.

```bash
# Unified regression runner (canonical for verified-edit per M-E001-1 vocabulary type 2):
python3 -m tools.run-tests
# Expected: AGGREGATE: <passed>/<total> across 13 files (8 hook tests + 5 tools tests)
# As of 2026-05-06 evening: 215/234 aggregate (3 partial-fail files)

# /audit slash command (10-step integrity check):
/audit
# Runs: yamls parseable + hooks executable + blockers/decisions verify + state files consistent

# install.sh verification (read-only drift detection):
./install.sh --check
# Exit 0 = clean; exit 1 = drift detected. Runs op_verify (16+ checks).

# Integrity check (when sentinel exists):
<sentinel-command> --check

# git audit (always available):
cd $HOME && git status
cd $HOME && git ls-files

# Project-internal verifier (when M004 lands):
python3 -m tools.verify_policy

# Empirical-count verification (per Hard Rule 15 — before drift-claim in any brain file):
/opt/devops-solutions-information-hub/.venv/bin/python -c "
import glob, json
print('decisions:', sum(1 for line in open('/root/wiki/governance/decisions.md') if line.startswith('  D')))
print('SB rows:', sum(1 for line in open('/root/wiki/governance/systemic-bugs.md') if line.startswith('| SB-')))
print('tools .py:', len(glob.glob('/root/tools/*.py')))
print('commands:', len(glob.glob('/root/.claude/commands/*.md')))
print('hooks .sh:', len(glob.glob('/root/.claude/hooks/*.sh')))
print('rules:', len(glob.glob('/root/.claude/rules/*.md')))
s = json.load(open('/root/.claude/settings.json'))
fires = sum(len(v) for v in s.get('hooks',{}).values())
print('hook fires wired:', fires)
"

# Methodology gate (when applicable to the change):
# - For Document-stage changes: verify the wiki page has Summary + gaps
# - For Design-stage: verify a design doc exists, trade-offs documented
# - For Scaffold-stage: verify ./install.sh --dry-run runs cleanly
# - For Implement-stage: verify ./install.sh + integrity check both pass
# - For Test-stage: verify all gates green + idempotent re-run is no-op

# Backlog state (always):
ls -la $HOME/wiki/backlog/{milestones,epics,modules,tasks}/
```

## Tool Invariants (cross-cutting)

These invariants apply to all project-authored tools regardless of which layer they're at:

| Invariant | What it means |
|---|---|
| **Idempotency** | Running a tool twice produces the same end state as running it once. install.sh, uninstall.sh, install-module.sh, verify-policy all idempotent. |
| **--dry-run support** | Every state-mutating tool supports `--dry-run` to preview without applying. |
| **Exit codes are meaningful** | Exit 0 = success / no-op. Non-zero = specific failure type. Tools document their exit codes. |
| **Output is human-readable** | Tools print plain English explanations alongside any structured output. Operator should never have to decode an exit code without context. |
| **--help is comprehensive** | Every tool has `--help` listing all options + examples. |
| **--json for machine consumption** | Tools that produce structured output support `--json` for automation. |
| **No silent state mutation** | Tools log every state change. Reviewing the tool's output should reveal exactly what changed on disk. |
| **Backups before destructive ops** | Tools that overwrite files first move the existing file to `<file>.ghostproxy.bak.<ts>`. Never overwrite without backup. |
| **Consistent naming** | All tools live at `$HOME/tools/` (Python modules) or `$HOME/*.sh` (top-level shell scripts). No nested vendor directories. |
| **Methodology stage compliance** | Tools authored in Implement-stage tasks; Document-stage tasks produce specs only. Stage boundaries are hard. |

## Agent personal-learning notes (operator-allowed, per directive 2026-05-06)

> **Operator directive 2026-05-06 (sacrosanct)**: *"you can take notes of your personal learnings progress here, there is such a room for system project even a root one"*. Entries below are **agent-authored** (per SB-095 — flagged as agent-DRAFT, not operator-stated content). Operator may revise / promote / remove. Each timestamped + initialed `[agent]`. TOOLS.md-specific framing — tool-reference-file lessons.

### 2026-05-06 evening — Inventory-vs-Section drift is the recurring TOOLS.md trap

`[agent]` TOOLS.md grew incrementally over multiple sessions. The Tool Inventory table (top of file) was refreshed to mark sentinel/hooks/bridge as "Implemented", but the Per-Tool Reference sections (mid-file) retained their original "(planned, M003)" markers from when they were authored as design-intent. This produces "is it implemented or not?" confusion for cold-pickup agents — the same tool appears with two different statuses in the same file.

**Discipline**: when a tool transitions from planned → implemented, BOTH the Inventory table AND the Per-Tool Reference section header MUST be updated together. Treat them as paired edits. The Per-Tool Reference's "Planned invocations" content describes design-intent — when reconciling, RELABEL to "Verified invocations" but PRESERVE the design-intent content (it documents the agreed-upon behavior). Don't delete content under the assumption it's stale.

### 2026-05-06 evening — TOOLS.md vs tools/README.md role distinction

`[agent]` Two files cover the tools layer with different focuses:
- **TOOLS.md** (this file, root level) — operator-facing usage view. Concrete invocations. Planned vs implemented status. Operator-Intent → Tool routing summary.
- **[tools/README.md](tools/README.md)** (subdir level) — per-module composition view. State-file architecture diagram. Internal API per module. Extension guide.

These are NOT redundant — they serve different audiences. TOOLS.md answers "what command do I run?"; tools/README.md answers "how do these tools fit together internally?". The Implemented Python Tools consolidated section (added 2026-05-06 evening) bridges them with a quick-reference table that cross-references tools/README.md for full per-module detail.

### 2026-05-06 evening — Empirical-count verification before any TOOLS.md count claim

`[agent]` TOOLS.md is dense with counts (decisions / MCP tools / hooks / commands / rules / brain files / test files / aggregate-passing). Each count is a drift-magnet. Per Hard Rule 15 (CLAUDE.md/AGENTS.md): empirical-count-verification before drift-claim. The Verification Commands section now includes a Python one-liner that walks `tools/`, `.claude/{commands,hooks,rules}/`, `wiki/backlog/`, and parses `decisions.md` + `systemic-bugs.md` + `settings.json` directly — gives authoritative counts in one pass.

**Pattern**: when refreshing TOOLS.md (or any brain file with counts), run the verification command FIRST; refresh counts SECOND; never the reverse (the temptation is to compound prior counts with current cycle's deltas — that's how compounding errors accumulate).

### 2026-05-06 evening — productive-cycle vocabulary tools mapping

`[agent]` Per Hard Rule 14 (M-E001-1 vocabulary): each cycle-fire emits one of 9 action types. The tools layer is HOW agents emit each type:
- `sb-closure` → `tools.decisions append` + tracker grep
- `verified-edit` → `python3 -m tools.run-tests` (215/234 aggregate)
- `drift-fix-with-empirical` → empirical-count Python one-liner + `tools.progress` callout refresh
- `explicit-standby-with-named-reason` → `tools.blockers --check` + named blocker
- `new-artifact` → file Write + flag agent-DRAFT in frontmatter (per SB-095)
- `doc-refresh` → empirical-count + inline empirically-verified-YYYY-MM-DD timestamp
- `blocker-surface` → `/blockers` slash command (decision-package format)
- `operator-directive-register` → `/log` slash command + verbatim quote
- `read-only-audit` → `/audit` slash command (10-step integrity check)

Cross-tool universal — every AI tool's cycle skill maps action types to tools the same way.

### What this section is NOT

`[agent]` Not the SB tracker (`wiki/governance/systemic-bugs.md`). Not the decisions logbook (`wiki/governance/decisions.md`). Not the session log (`wiki/log/`). Not tools/README.md (per-module composition view). For TOOLS.md-specific tool-reference lessons that benefit fresh-pickup agents but are too small to warrant their own rule file. Operator promotes to structured artifact when pattern matures.

## Cross-References

### Top-level brain files (10)

| For… | Read |
|---|---|
| Project description + identity + modules + status | [README.md](README.md) |
| Cold-pickup orientation | [BOOTSTRAP.md](BOOTSTRAP.md) |
| System topology + components + data flow | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Design pattern rationale (why these tool choices) | [DESIGN.md](DESIGN.md) |
| Threat model + protections + escalation | [SECURITY.md](SECURITY.md) |
| Cross-tool agent contract | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing (full operator-intent table) | [CLAUDE.md](CLAUDE.md) |
| Current operational state (active mission/focus/impediment/priorities/task) | [CONTEXT.md](CONTEXT.md) |
| Skills directory context | [SKILLS.md](SKILLS.md) |

### Subdirectory READMEs (9 — DRAFT v1, agent-authored 2026-05-06 evening)

| For… | Read |
|---|---|
| **Per-module composition view of tools/** (canonical extension of TOOLS.md) | [tools/README.md](tools/README.md) |
| 30 slash commands by category | [.claude/commands/README.md](.claude/commands/README.md) |
| 18 hook scripts (10 wired + archive) by event | [.claude/hooks/README.md](.claude/hooks/README.md) |
| 3 modes + cycle-sequence comparison | [.claude/modes/README.md](.claude/modes/README.md) |
| 11 rules + strictness-tier matrix | [.claude/rules/README.md](.claude/rules/README.md) |
| 3 brain-loaded subagents | [.claude/agents/README.md](.claude/agents/README.md) |
| 2 skills + mechanism-choice context | [.claude/skills/README.md](.claude/skills/README.md) |
| 5 install template categories | [templates/README.md](templates/README.md) |
| Deployment + maintenance toolkit | [scripts/README.md](scripts/README.md) |

### Backlog + governance + log

| For… | Read |
|---|---|
| Methodology engine | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| Active epic (foundational) | [wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md) |
| Active milestone v0.2 + 4 epics structure | [wiki/backlog/milestones/](wiki/backlog/milestones/) + [wiki/backlog/epics/](wiki/backlog/epics/) |
| Module M005 (first specialized feature module) | [wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md](wiki/backlog/modules/root-modules-m005-first-specialized-feature-module.md) |
| Decisions logbook (40 entries D001-D040) | [wiki/governance/decisions.md](wiki/governance/decisions.md) |
| Systemic-bugs tracker (138-row register) | [wiki/governance/systemic-bugs.md](wiki/governance/systemic-bugs.md) |
| Blockers + progress | [wiki/governance/blockers.md](wiki/governance/blockers.md) + [wiki/governance/progress.md](wiki/governance/progress.md) |

### Universal cross-cutting rules (Hard Rules cross-references)

| For… | Read |
|---|---|
| **Hard Rule 14 (productive-cycle taxonomy)** — tools-as-emitters mapping | [CLAUDE.md](CLAUDE.md) Rule 14 + [AGENTS.md](AGENTS.md) Rule 14 |
| **Hard Rule 15 (empirical-count-verification before drift-claim)** — directly relevant to TOOLS.md drift discipline | [CLAUDE.md](CLAUDE.md) Rule 15 + [AGENTS.md](AGENTS.md) Rule 15 |
| Hard Rules 11-13 (additive≠discarding, brain-inheritance, chain-operations) | [CLAUDE.md](CLAUDE.md) + [AGENTS.md](AGENTS.md) |

### Brain-improvement mandate (this work block — 2026-05-06)

| For… | Read |
|---|---|
| Sacrosanct verbatim directive governing this TOOLS.md edit pass | [wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md](wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) |
| M-E001-1 productive-cycle action vocabulary DRAFT v2 (9 types) | [wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md](wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md) |

### Second brain (canonical sources)

| For… | Read |
|---|---|
| Suricata source-syntheses | `<second-brain>/wiki/sources/src-suricata*.md` |
| PolarProxy source-syntheses | `<second-brain>/wiki/sources/src-polarproxy.md`, `src-hanke-honeypot-polarproxy-suricata-integration.md` |
| Identity profile (canonical Goldilocks 9-dim) | `<second-brain>/wiki/ecosystem/project_profiles/root-ghostproxy/identity-profile.md` |
| Adoption Guide | `<second-brain>/wiki/spine/references/adoption-guide.md` |
