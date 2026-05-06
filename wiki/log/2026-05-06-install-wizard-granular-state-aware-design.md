---
title: "2026-05-06 — Install wizard / granular / state-aware design (per operator directive)"
type: log
domain: cross-domain
status: design-stage
confidence: medium
maturity: seed
created: 2026-05-06
updated: 2026-05-06
sources:
  - id: operator-directive-2026-05-06-install-wizard-granular
    type: directive
tags: [log, design, install-sh, wizard, granular, state-aware, curl-bootstrap, project-install, sb-design, methodology-respected, design-stage]
---

# Install wizard + granular install + state-aware routes — design

> **Methodology stage**: design. ALLOWED: design-document, ADR, tech-spec. FORBIDDEN: code-file, test-file. Implementation pending operator review of this design.

## Operator directive (verbatim, sacrosanct)

> "I think we need to evolve even more the install. It should be posssible to do a --granular install so that the user can chose the hooks he wants to instant or gourps and ushc. and also do you think where I am coming from and the mesage you should say and also saying possibly what are my "options" / what I should do next possibly. like good Wizard and / or Asssitant. and also is this always considering I could be coming from the curl bash install ? and I might want to do the inner / project install after the repo downlown / base install. and such as chosing the level of options and the routes and branches and such."

## Decomposition

### Capability A — Granular install

User-controllable selection beyond profile-level. Two granularities:

**A.1 Group-level** (predefined sets):
| Group | Includes |
|---|---|
| `security` | policy-block, malware-block, opt-write-block, leak-detector |
| `session-lifecycle` | session-start, session-orient, pre-compact, post-compact, session-summary |
| `agent-discipline` | context-warning, output-discipline-guard |
| `stamp` | end-of-cycle-stamp, stamp-control |
| `brain-rules-core` | work-mode, words-are-sacrosanct, operating-principles |
| `brain-rules-all` | all 11 rules |
| `commands-core` | /orient, /handoff, /cycle, /audit, /help-root |
| `commands-mode` | /mode-* (5 commands) |
| `commands-stamp` | /stamp-* (6 commands) |
| `commands-objective` | /mission, /focus, /impediment (SB-118) |
| `commands-all` | all 26 commands |
| `tools-core` | state, blockers, progress, decisions |
| `tools-cycle` | cycle, tasks |
| `tools-stamp` | stamp |
| `tools-objective` | objective |
| `tools-all` | all 10 tools |

**A.2 Item-level** (individual selection):
- `--with-hook <name>` / `--no-hook <name>` per hook
- `--with-command <name>` / `--no-command <name>` per command
- `--with-rule <name>` / `--no-rule <name>` per rule
- `--with-tool <name>` / `--no-tool <name>` per tool

Composes with existing profile defaults (profile sets baseline, granular overrides specifics).

### Capability B — Wizard / Assistant mode

Interactive multi-step flow when run without flags (or via `--wizard`), with skippable prompts via flags. Wizard responsibilities:

1. **State detection** ("where you are"):
   - Detect current install state (none / partial / base / project / full)
   - Identify deployed components (which hooks / commands / brain pieces / tools)
   - Identify divergence (drift from canonical)
   - Identify ghostproxy mode (bridge / endpoint / hybrid auto-detect)
   - Identify host context (OS family, user, root vs non-root, multi-eth, wifi, etc.)

2. **Position framing** ("good wizard message"):
   - Brief 1-paragraph "you are here" — what's installed, what's missing, what's drifted
   - State of operator-pending decisions (T013 bridge policy, etc.)

3. **Options surfaced** ("what you can do next"):
   - Numbered/lettered choices with one-line descriptions
   - Per-choice preview of what would change (dry-run-style)
   - Recommended next-best-action highlighted

4. **Interactive choice** (with non-interactive bypass):
   - TTY input prompts when `stdin.isatty()`
   - Flag-based skip via `--yes` + explicit selections
   - Default per-prompt = the recommended next-action

### Capability C — Multi-route awareness

Operator may arrive from any of these entry points:

| Route | Entry | State at entry |
|---|---|---|
| **curl-bootstrap** | `curl <url>/scripts/install-from-curl.sh \| bash` | No repo, no install. Bootstrap script clones + invokes wizard. |
| **manual-clone** | `git clone <url> && cd && ./install.sh` | Repo present, no install. Wizard from repo root. |
| **post-clone-pre-install** | After clone, before any install action | Repo present, $HOME untouched. Wizard greenfield. |
| **post-base-install** | Base install ran, operator wants more | $HOME has settings + hooks. Wizard suggests project install / module install / customization. |
| **post-project-install** | Sister project has agent brain | Target dir has .claude/. Wizard suggests verification / customization. |
| **drift-detected** | `--check` reports divergence | Wizard offers reconcile / re-install / accept-drift options. |
| **partial-uninstall** | After some `--no-X` flags | Mixed state. Wizard offers complete-install / extend-current. |
| **maintenance** | Periodic re-run | Idempotent — wizard confirms in-sync, surfaces nothing actionable. |

### Capability D — Inner / project install after base install

Specific flow operator named:

```
[curl-bootstrap OR manual-clone]
        ↓
[base install at $HOME]
        ↓
[wizard surfaces: "you can now install agent brain into a sister project"]
        ↓
[operator picks /opt/devops-solutions-information-hub OR /home/jfortin/openarms]
        ↓
[install.sh --profile project --dest <picked-target> ]
        ↓
[wizard verifies: target inherits hooks + commands + tools]
        ↓
[wizard suggests next: another project? OR module install? OR done?]
```

The wizard maintains continuity across these state transitions.

## Architecture proposal

### Layer 1 — State detection (`detect_install_state()` function)

Pure read-only inspection. Returns a structured state object:

```bash
# Returns env vars set + summary line via stdout
INSTALL_STATE_REPO_PRESENT=1                    # /install.sh exists at SRC
INSTALL_STATE_BASE_INSTALLED=1                  # ${DEST_CLAUDE}/settings.json exists
INSTALL_STATE_HOOKS_DEPLOYED=11                 # count of hooks at ${DEST_CLAUDE}/hooks/
INSTALL_STATE_HOOKS_DRIFTED=0                   # via SHA256 SRC vs DEST
INSTALL_STATE_BRAIN_DEPLOYED=46                 # count of {rules, commands, agents, modes, skills} files
INSTALL_STATE_TOOLS_DEPLOYED=10                 # count of /tools/*.py
INSTALL_STATE_BRIDGE_CONFIGURED=1               # br0 exists in /etc/systemd/network/
INSTALL_STATE_WIFI_CONFIGURED=0                 # /etc/wpa_supplicant/wpa_supplicant-mgmt0.conf exists
INSTALL_STATE_INTEGRITY_REGISTERED=0            # ${DEST_CLAUDE}/integrity.json exists
INSTALL_STATE_CCSTATUSLINE_INSTALLED=1          # ccstatusline binary present
INSTALL_STATE_OPENCODE_BRIDGE_DEPLOYED=1        # ${DEST_OPENCODE}/plugin/claude-bridge.ts exists
INSTALL_STATE_PROJECT_INSTALLS=("/opt/devops-solutions-information-hub")  # array of detected project deploys
```

### Layer 2 — Position frame (`frame_position()` function)

Reads state, prints human-readable "you are here":

```
═══════════════════════════════════════════════════════════════════════
INSTALL WIZARD · root-ghostproxy · type=root + group=operating-system-setup
═══════════════════════════════════════════════════════════════════════

Where you are:
  ✓ Repo present at /home/jfortin/root-ghostproxy
  ✓ Base install at /home/jfortin/.claude/ (11 hooks, 46 brain files, 10 tools)
  ✓ Network bridge config deployed (br0 UP, 2 ethernet members)
  ⚠ Management wifi NOT configured (--with-wifi disabled)
  ⊘ Integrity sentinel NOT registered (--with-integrity disabled)
  ⊘ ccstatusline NOT installed (Features tier; --with-ccstatusline disabled)
  ✓ Sister project deployed: /opt/devops-solutions-information-hub

OS detected: Debian 13 (debian-family) | Mode: bridge (auto-detected) | EUID: 1000

Pending operator decisions:
  - T013 bridge FORWARD/OUTPUT policy: default-accept vs default-drop (threat-model)
```

### Layer 3 — Options (`offer_options()` function)

Reads state + presents recommended-next-actions in priority order:

```
What you can do next:

  [1] Enable management wifi (recommended for type=root install)
      → install.sh --with-wifi  (deploys wpa_supplicant + nftables INPUT-drop)

  [2] Register integrity sentinel
      → install.sh --with-integrity  (SHA256 baselines for safety policy)

  [3] Install ccstatusline (Features tier)
      → install.sh --with-ccstatusline

  [4] Deploy agent brain into another sister project
      → install.sh --profile project --dest <path>
      OR /install-agent-brain <path>

  [5] Run drift-check on current install state
      → install.sh --check

  [6] Granular hook/command/rule selection
      → install.sh --granular  (or pick groups: --with-group security)

  [Q] Quit (no changes)

Choice [default: 1]: _
```

### Layer 4 — Granular selector (`granular_select()` function)

Triggered by `--granular` flag. Two sub-modes:

**Group-level** (default in granular interactive mode):
```
Pick groups to install/keep (toggle with number; ENTER to apply):

  [✓] security             (4 hooks: policy/malware/opt-write/leak)
  [✓] session-lifecycle    (5 hooks)
  [ ] agent-discipline     (2 hooks: context-warning, output-discipline-guard)
  [✓] stamp                (2 hooks: end-of-cycle, stamp-control)
  [✓] brain-rules-all      (11 rules)
  [✓] commands-core        (5: orient/handoff/cycle/audit/help-root)
  [ ] commands-mode        (5: /mode-*)
  [✓] commands-stamp       (6: /stamp-*)
  [ ] commands-objective   (3: /mission, /focus, /impediment)
  [✓] tools-core           (4: state, blockers, progress, decisions)
  [ ] tools-cycle          (2: cycle, tasks)
  [ ] tools-stamp          (1)
  [ ] tools-objective      (1)
```

**Item-level** (advanced, via flags):
```
install.sh --granular \
  --with-hook policy-block --with-hook malware-block \
  --no-hook opt-write-block \
  --with-command orient --with-command handoff \
  --no-rule trigger-model
```

### Layer 5 — Route awareness (`detect_route()` function)

Identifies entry point from environmental signals:

```
if [[ -n "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" == "/dev/stdin" ]]; then
    ROUTE="curl-bootstrap"
elif [[ ! -d "${SRC}/.claude" ]]; then
    ROUTE="repo-incomplete"  # cloned but missing parts
elif [[ ! -f "${DEST_CLAUDE}/settings.json" ]]; then
    ROUTE="post-clone-pre-install"
elif install_state_drifted; then
    ROUTE="drift-detected"
elif install_state_partial; then
    ROUTE="partial-install"
else
    ROUTE="post-install-maintenance"
fi
```

Each route has its own opening-frame + recommended-actions.

## Implementation phases (proposal)

| Phase | Scope | Effort | Dependency |
|---|---|---|---|
| **P1** | `detect_install_state()` + `frame_position()` — read-only state report | Small | None — pure inspection |
| **P2** | `offer_options()` + `--wizard` flag | Medium | P1 |
| **P3** | `detect_route()` + route-specific opening messages | Medium | P1 |
| **P4** | `granular_select()` interactive group-picker | Medium | P2 |
| **P5** | `--with-group <name>` / `--no-group <name>` flags | Small | None |
| **P6** | `--with-hook <name>` / `--with-command <name>` / etc. (item-level) | Medium | P5 |
| **P7** | curl-bootstrap script integration (chains into wizard post-clone) | Small | scripts/install-from-curl.sh + P3 |
| **P8** | install.sh --help update with wizard examples | Small | All above |
| **P9** | Documentation refresh (README + BOOTSTRAP + TOOLS) | Small | All above |

Total: 9 phases. P1+P2 are MVP wizard. P4+P5 are granular MVP. P7 is the curl-bootstrap closure.

## Open design questions (operator review)

| # | Question | Options |
|---|---|---|
| Q1 | TTY behavior — wizard auto-runs when `stdin.isatty()` AND no flags? | (a) Yes, opt-out via `--no-wizard` (b) Opt-in via `--wizard` flag only |
| Q2 | Group definitions — match the table above OR different groupings? | (a) Use proposed (b) Operator-redefined per host needs |
| Q3 | curl-bootstrap → wizard handoff | (a) install-from-curl.sh always invokes wizard after clone (b) optional via flag passed through curl URL |
| Q4 | Granular item-level — by individual hook/command/rule/tool name OR predefined groups only? | (a) Both (proposed) (b) Groups only (simpler) |
| Q5 | "Where you are" message scope — terse (5 lines) or comprehensive (15+ lines)? | (a) Terse default + `--verbose` for full (b) Always comprehensive |
| Q6 | Pending operator decisions surface — wizard mentions T013 bridge policy etc.? | (a) Yes, recommend reading decision doc (b) Out of scope; only install-state |
| Q7 | Route detection sensitivity — robust to PATH variations + symlinks? | (a) Conservative heuristic + ROUTE override flag (b) Strict detection |
| Q8 | Sister-project install — wizard remembers previously-deployed targets? | (a) State file at `.claude/installed-projects.json` (b) Re-detect each invocation |

## Stage gate (per `/wiki/config/methodology.yaml` design stage)

Per methodology: design stage 25–50% readiness. Gate: trade-offs documented; spec reviewed.

This synthesis is **trade-offs documented** ✓. **Spec reviewed = pending operator review** ⏳.

After operator-review, the next stage is scaffold (50–80%) — type-definitions + helper-stub functions in install.sh + state-detection skeleton without business logic.

After scaffold, implement-stage P1–P9 produce the working wizard.

## Cross-references

- Operator directive (sacrosanct primary): this section above
- install.sh current state: `$HOME/install.sh` (implement-stage 98%, readiness)
- Existing `--profile` mechanism: `apply_profile()` at install.sh
- Curl-bootstrap entry: `$HOME/scripts/install-from-curl.sh`
- Per-project install (already implemented): `--profile project --dest <path>` + `/install-agent-brain` slash command
- Methodology engine: `$HOME/wiki/config/methodology.yaml` design stage row

## Operator action

Review Q1–Q8 + indicate go/no-go on the proposal. Then I'll start P1+P2 (MVP wizard skeleton).
