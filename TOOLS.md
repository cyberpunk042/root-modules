# TOOLS.md — root-ghostproxy tool reference

> Per-tool / per-script reference. What each tool does, when to use it, with concrete invocations. Reference, not narrative. Cross-referenced from [CLAUDE.md](CLAUDE.md)'s operator-intent routing table.
>
> The project is at SFIF scaffold + partial-foundation tier. Most tools listed here are **planned** — they land at Foundation stage (M003) or Infrastructure stage (M004) or Features stage (M005). The "Status" column tells you what exists today vs what's pending.

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
| `tools.decisions` | `$HOME/tools/decisions.py` | Infrastructure | Decisions logbook: list / append / verify / next-id. 25 entries D001-D025. CLI + MCP. | Implemented. |
| `tools.cycle` | `$HOME/tools/cycle.py` | Infrastructure | Structured cycle output (active mode + cycle definition + state + blockers + progress + lifecycle signals). | Implemented. |
| `tools.tasks` | `$HOME/tools/tasks.py` | Infrastructure | Task-page parser. | Implemented. |
| `tools.stamp` | `$HOME/tools/stamp.py` | Infrastructure | Stamp render config per SB-114/115: `configure --layout horizontal\|vertical --enabled on\|off\|auto`, `show`, `clear`. Persists `$HOME/.claude/stamp-config.json`. Slash-command-driven via `/stamp-horizontal` `/stamp-vertical` `/stamp-on` `/stamp-off` `/stamp-auto` `/stamp-status`. Read by `end-of-cycle-stamp.sh` Stop hook to control render. | Implemented (DRAFT per SB-116 — UX redesign Epic placeholder). |
| MCP server | `$HOME/tools/mcp_server.py` | Infrastructure | FastMCP server exposing 6 read-only tools (root_orient, root_state, root_blockers, root_progress, root_decisions_*). Wired via `.mcp.json`. | Implemented. |
| Hook regression tests | `.claude/hooks/tests/{test-policy-block,test-malware-block}.py` | Infrastructure | Pre-merge verification that hook regex changes don't introduce false-positives or false-negatives. | Implemented (cycles 52-53). |
| Validation pipeline (pre-commit OR CI workflow) | `.pre-commit-config.yaml` OR `.github/workflows/*.yml` | Infrastructure | Runs verify-policy + hook tests on relevant changes. | Planned (M004). |
| `tools/verify-policy.py` (or equivalent) | `$HOME/tools/verify-policy.py` | Infrastructure | Project-internal verifier — runs integrity check + deny-set count + hook permissions check + executable presence. | Planned (M004). |
| Suricata module install scripts | (path TBD by M005) | Features (facultative) | Install Suricata + suricata.yaml config + systemd unit + nftables / af-packet integration | Planned (M005, operator-driven). |
| PolarProxy module install scripts | (path TBD by M005) | Features (facultative) | Install PolarProxy + dummy interface setup + tcpreplay bridge service + CA distribution mechanism | Planned (M005, operator-driven). |
| pipelock module install scripts | (path TBD by M014) | Features (facultative) | Install luckyPipewrench/pipelock (AI agent firewall: MCP security + agent egress + DLP + SSRF + prompt-injection defense). Complementary agent-process layer. | Preliminary scope complete; atomic tasks gated on M007. |
| ccstatusline integration | `install.sh` `op_install_ccstatusline` + `templates/ccstatusline-{config,widgets}/` + `$HOME/.config/ccstatusline/profile-{base,intermediary,full-aidlc}.json` + 9 custom AIDLC widgets at `$HOME/.local/share/ccstatusline-widgets/` | Features | Custom Claude Code statusline. Operator-mandated 3-profile column tier (base=1, intermediary=2, full-aidlc=3). | Implemented + OPERATOR VISUALLY VERIFIED cycle 43. |
| `tools/gateway.py` (forwarder) | `$HOME/tools/gateway.py` | Sister-project integration | CLI dispatch into the second brain's gateway. Lands via `tools.setup --connect-project` from the second brain side. | Pending M007 (--connect-project run). |
| `tools/view.py` (forwarder) | `$HOME/tools/view.py` | Sister-project integration | CLI dispatch into the second brain's view tool. Lands via `tools.setup --connect-project`. | Pending M007. |

## Currently Available Tools (today)

The project's authoritative state at $HOME includes:

- The 9 brain files (`$HOME/{README,CLAUDE,AGENTS,CONTEXT,ARCHITECTURE,DESIGN,TOOLS,SKILLS,SECURITY}.md`) — operator-authored project documentation
- The methodology layer (`$HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml`) — copied from the second brain, adaptable per project
- The backlog scaffold (`$HOME/wiki/backlog/{epics,modules,tasks}/`) with active epic + 14 modules + 66 atomic tasks
- The log directory (`$HOME/wiki/log/`) — populated with session logs + cycle reports + handoff docs
- The governance directory (`$HOME/wiki/governance/{blockers,progress,decisions}.md` + `systemic-bugs.md`)
- 11 Python tools at `$HOME/tools/` (state, blockers, progress, decisions, cycle, tasks, **stamp**, **objective**, **priorities** + mcp_server + _paths)
- 16 hooks at `.claude/hooks/` (incl. context-warning, end-of-cycle-stamp, stamp-control, integrity.py + test fixtures)
- 26 slash commands at `.claude/commands/` (incl. /stamp-* config + /install-agent-brain + /mode-* + /mission + /focus + /impediment SB-118 + /priorities SB-127)
- 3 modes at `.claude/modes/` + 3 brain-loaded subagents at `.claude/agents/`
- 2 skills at `.claude/skills/<name>/SKILL.md` (surface-state + surface-blockers)
- 10 rules files at `.claude/rules/`
- ccstatusline integration: 5 profiles + 13 custom widgets + wrapper + switch script
- 5 deployment scripts at `$HOME/scripts/` + lib/ helpers + README (cycle-53 publish-readiness)
- install.sh implement-stage (readiness 98%) — `--profile {base|full|project|interactive}`, `--mode {bridge|endpoint|hybrid|auto}`, per-op toggles, `--dry-run` + `--check` + 16-step `op_verify`, shellcheck PASS

**Project is at implement-stage for foundation install** — install.sh fully functional incl. real wifi/nftables/integrity ops; M011 ccstatusline operator-verified; modes-architecture working via /loop /cycle since cycle 41; per-project install via `--profile project` enables sister-project agent-brain deploy.

## Per-Tool Reference

### `install.sh` (implemented, M003 — implement-stage 98% readiness)

**Purpose.** Take a fresh Linux host and bring it to foundation-tier root-ghostproxy state. Idempotent: re-running on an already-installed host is a no-op (or cleanly applies any config drift). OS-family-aware (Debian/RHEL/Arch). Two install scopes: OS-root install (`--profile base|full`) and per-project agent-brain install (`--profile project`).

**Invocations:**

```bash
cd $HOME

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

### Tamper-detection sentinel (planned, M003)

**Purpose.** Pre-tool-call hook that refuses every tool call when safety controls are tampered. Fail-CLOSED.

**Planned invocations** (when authored, the exact command depends on operator's authoring choices):

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

**Planned invariants:**
- Returns OK when all sub-checks pass; specific failure reason otherwise.
- Failure cases enumerated explicitly (not "something failed" — operator can resolve the specific issue).
- Sentinel is itself integrity-protected (size + checksum verification of the sentinel script).

### Pre-tool-call hooks: deny-set + behavior-pattern + leak-detector (planned, M003)

**Purpose.** Inspect every AI tool call against the safety policy. Refuse / ask-for-confirmation / allow.

**Planned hook events** (per Claude Code's hook protocol):
- `PreToolUse` — runs before tool executes; can decide allow/deny/ask
- `PostToolUse` — runs after tool output is captured; can scan output for sensitive values

**Planned invocations** (hooks fire automatically on tool calls; manual invocation for testing):

```bash
# Test pre-tool-call hook on a sample envelope:
echo '{"session_id":"test","tool_name":"Bash","tool_input":{"command":"cat ~/.env"},"hook_event_name":"PreToolUse"}' | <hook-path>

# Expected output: a JSON decision
# {"permissionDecision":"deny","permissionDecisionReason":"credential file pattern matched: ~/.env"}
```

**Planned invariants:**
- Hooks return JSON decisions (allow/deny/ask) per the canonical envelope contract documented in [AGENTS.md](AGENTS.md).
- Hooks are deterministic — same input → same decision.
- Hook decisions are logged with reason + timestamp (audit-log-ready).

### opencode bridge plugin (planned, M003)

**Purpose.** Map opencode's plugin SDK to the canonical envelope; opencode obeys the same policy as Claude Code without policy duplication.

**Planned invariants:**
- opencode's tool name `bash` maps to canonical `Bash`; `read` → `Read`; etc.
- Bridge spawns the same hook scripts Claude Code calls; same scripts, same envelope, different runtime.
- Bridge plugin is type-only-deps on `@opencode-ai/plugin` (no runtime deps that drift).
- Verification command: `opencode debug config 2>/dev/null | grep claude-bridge` returns non-empty when bridge is resolved; silent when not.

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

**Purpose.** Install Suricata + configure it for root-ghostproxy's bridge topology.

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
python3 -m tools.gateway timeline --scope root-ghostproxy   # This project's events

python3 -m tools.gateway contribute --type lesson --title "..." --content "..."
python3 -m tools.gateway contribute --type correction --title "..." --content "..."
python3 -m tools.gateway contribute --type remark --title "..." --content "..."

python3 -m tools.gateway flow [--step N]              # Goldilocks step-by-step
```

**Invariants:**
- Forwarder is auto-generated (do NOT hand-edit; re-run `--connect-project` to regenerate).
- `cwd=<second-brain>/` for the dispatched call.
- `--wiki-root` is set to root-ghostproxy's path so the gateway knows which project called.
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
- `WIKI_VIEW_CALLER_DIR` env var set to root-ghostproxy's CWD for the dispatched call.

## Operator-Intent → Tool (summary)

For the full operator-intent → tool routing table, see [CLAUDE.md § Operator-Intent Routing Table](CLAUDE.md#operator-intent-routing-table-claude-code-specific). Summary mapping:

| Operator says... | Tool / command |
|---|---|
| `"verify install"` | `./install.sh --dry-run` |
| `"reinstall"` | `./install.sh` |
| `"check integrity"` | (sentinel command per Foundation authoring) |
| `"audit deny-set"` | (project-internal verifier check) |
| `"git audit"` | `cd $HOME && git status` + `git ls-files` |
| `"orient to second brain"` | `python3 -m tools.gateway orient` (after M007) |
| `"browse second brain"` | `python3 -m tools.view spine` (after M007) |
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
# Integrity check (when sentinel exists):
<sentinel-command> --check

# git audit (always available):
cd $HOME && git status
cd $HOME && git ls-files

# Project-internal verifier (when M004 lands):
python3 -m tools.verify_policy

# Methodology gate (when applicable to the change):
# - For Document-stage changes: verify the wiki page has Summary + gaps
# - For Design-stage: verify a design doc exists, trade-offs documented
# - For Scaffold-stage: verify ./install.sh --dry-run runs cleanly
# - For Implement-stage: verify ./install.sh + integrity check both pass
# - For Test-stage: verify all gates green + idempotent re-run is no-op

# Backlog state (always):
ls -la $HOME/wiki/backlog/{epics,modules,tasks}/
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

## Cross-References

| For… | Read |
|---|---|
| Project description + identity + modules + status | [README.md](README.md) |
| System topology + components + data flow | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Design pattern rationale (why these tool choices) | [DESIGN.md](DESIGN.md) |
| Threat model + protections + escalation | [SECURITY.md](SECURITY.md) |
| Cross-tool agent contract | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing (full operator-intent table) | [CLAUDE.md](CLAUDE.md) |
| Current operational state | [CONTEXT.md](CONTEXT.md) |
| Methodology engine | [wiki/config/methodology.yaml](wiki/config/methodology.yaml) |
| Active epic | [wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md](wiki/backlog/epics/sfif-rollout-and-second-brain-integration.md) |
| Module M005 (first specialized feature module) | [wiki/backlog/modules/root-ghostproxy-m005-first-specialized-feature-module.md](wiki/backlog/modules/root-ghostproxy-m005-first-specialized-feature-module.md) |
| Suricata source-syntheses (in second brain) | `<second-brain>/wiki/sources/src-suricata*.md` |
| PolarProxy source-syntheses (in second brain) | `<second-brain>/wiki/sources/src-polarproxy.md`, `src-hanke-honeypot-polarproxy-suricata-integration.md` |
