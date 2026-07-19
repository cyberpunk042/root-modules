root-modules intel-gathering chain — deterministic load + structured state report.

> **CRITICAL — disambiguation.** This command runs ONLY when the operator (or the agent following the SessionStart hook directive) types `/orient` LITERALLY. Bare prose like "where are we", "what's the state", "give me an overview" are conversation moves, NOT triggers — handle those by responding from already-loaded context, don't auto-invoke this command.
>
> Run this once per fresh session (post-SessionStart hook), once after `/compact` (post-PostCompact hook), or when the operator explicitly invokes it.

## On `/orient`

Execute the chain below in order. Each step is a deterministic Read / Bash invocation. The chain produces a single structured intel report at the end. Don't skip steps; don't reorder. Don't substitute summaries for actual file reads — load the content into context.

### Step 1 — Load brain (essential, always)

1. Read `$HOME/BOOTSTRAP.md` — cold-pickup map
2. Read `$HOME/CONTEXT.md` — SFIF stage, active modules, 6 pending decisions, verbatim operator directives
3. Read `$HOME/.claude/rules/words-are-sacrosanct.md` — verbatim-quoting meta-rule (load BEFORE any operator-quoting work)
4. Read `$HOME/.claude/rules/work-mode.md` — solo session, PO approval boundary, status-claim discipline
5. Read `$HOME/.claude/rules/routing.md` — operator-intent → tool routing
6. Read `$HOME/.claude/rules/self-reference.md` — $HOME vs /opt second brain
7. Read `$HOME/.claude/rules/methodology.md` — 5 stages with project-specific gates
8. Read `$HOME/.claude/rules/hook-architecture.md` — 2-layer hook design + draft-tier false-positive notes

### Step 2 — Load backlog + state

9. Read `$HOME/wiki/backlog/tasks/_index.md` — task status snapshot
10. Bash: `ls -t $HOME/wiki/log/ | head -5` — find most-recent $HOME logs (PRIMARY source for $HOME iteration directives — sacrosanct)
11. Read the 3 most-recent `$HOME/wiki/log/*.md` (per step 10) — verbatim operator directives + iteration logs live HERE for $HOME work
12. Bash: `ls -t <second-brain>/raw/notes/2026-*.md | head -5` — find historical operator directives from PRIOR sessions (read-only citation source for project-history context)
13. Read the 2 most-recent `/opt/.../raw/notes/2026-*.md` (per step 12) — historical context only; do NOT write back here

### Step 3 — Verify state empirically

14. Bash: `for f in $HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml; do <second-brain>/.venv/bin/python -c "import yaml; yaml.safe_load(open('$f')); print('OK $f')"; done` — confirm methodology engine parses
15. Bash: `ls <second-brain>/wiki/spine/references/adoption-guide.md` — confirm second-brain reachable
16. Bash: `grep -A2 "^  root-modules:" <second-brain>/wiki/config/sister-projects.yaml` — confirm registered with second brain
17. Bash: `cd $HOME && git status --short` — git state (commit/uncommit summary)
18. (Optional, costly) Bash: `cd <second-brain>/ && <second-brain>/.venv/bin/python -m tools.gateway orient --orient-as sister` — second-brain agent's orient view of $HOME as sister project

### Step 3.5 — Detect active mode + objective + priorities (compound layer)

19. Bash: `cat $HOME/.claude/active-mode 2>/dev/null || echo "(none)"` — read the active mode (or report none)
20. If a mode is active: Read `$HOME/.claude/modes/<mode-name>.md` — load persona, primary brain pieces, scope, /cycle sequence
21. If no mode active: don't auto-enable; surface the option in the report (per operator directive 2026-05-05: mode-entry is operator-choice)
22. Bash: `cat $HOME/.claude/active-mission $HOME/.claude/active-focus $HOME/.claude/active-impediment 2>/dev/null` — read objective layer (SB-118)
23. Bash: `cat $HOME/.claude/active-priorities 2>/dev/null` — read priorities queue (SB-127)

### Step 4 — Compose intel report

After all 23 steps complete, emit a structured report (terse — operator reads diff, not novel):

```
ROOT-GHOSTPROXY ORIENT REPORT
═════════════════════════════
Identity:        type=root, group=operating-system-setup, scale=micro, solo
SFIF stage:      <stage> (<readiness>%)
Modules:         <count> total, <done> done, <pending> pending-op-decision, <not-started> not-started
git state:       <init/uncommitted/clean>
Active mode:     <mode-name | none — feature available; /mode-pm, /mode-architect, or /mode-dual to enable>
Mission:         <active-mission text | (unset)>     # SB-118 objective layer
Focus:           <active-focus text | (unset)>
Impediment:      <active-impediment text | (none — focus unblocked)>
Priorities:      <P1: ... · P2: ... · P3: ... | (none set)>     # SB-127 imminent-work queue
Last log:        <path> (<date>)
Last operator
directive:       <verbatim quote from most-recent raw note, ≤100 chars>

Pending operator decisions (the bottleneck):
  T006  prior-debris reconciliation                       <P1>
  T011  Foundation IaC approach (greenfield vs extend)    <P0>
  T018  verifier scope                                    <P0>
  T024  Suricata-first vs PolarProxy-first                <P0>
  T051  M009 reframe                                      <P1>
  T058  auto_connect flip                                 <P2>

Verify state:
  4 methodology yamls:    <pass/fail>
  Second-brain reachable: <pass/fail>
  Registration in /opt:   <pass/fail>
  Gateway orient:         <pass/fail/skipped>

Modes (if no mode active, mention briefly):
  /mode-pm        — backlog grooming + decision surfacing + status reports
  /mode-architect — design + IaC implementation + hooks + vendor manifests
  /mode-dual      — both lenses; switches per question
  Combine with /loop <interval> /cycle to enable autopilot in the chosen mode.

Next-best-actions (operator-facing):
  - Walk through pending decision: <best-fit decision per current state>
  - OR commit $HOME spec to git (requires operator decision: scope + message)
  - OR work specific task (operator names which)
  - OR enable a mode + autopilot (operator-choice; not auto-enabled)

Intel-gathering complete. <X> Read tool calls, <Y> Bash calls. Brain loaded.
═════════════════════════════
```

### Step 5 — Wait for operator

Do NOT proceed past the report. Wait for operator direction. The 6 pending decisions are P0/P1 blockers; surfacing them honestly + standing by is the correct response. No unilateral task-claiming.

## Why this command exists

Per operator directive 2026-05-05: hook output is a directive (~70% deterministic compliance); commands are 100% deterministic when the harness executes them. The SessionStart hook (`$HOME/.claude/hooks/session-orient.sh`) frames the conversation + tells the agent to invoke `/orient`. This command IS that deterministic chain. Combined: hook fires → agent sees "invoke /orient now" → invokes → harness runs this chain → 21-step deterministic load → structured report.

If a Claude Code mechanism exists for hook-direct-invokes-command, this same chain should fire automatically without the agent's generative compliance step. (Pending claude-code-guide research.)

## Cross-references

- **Canonical command index**: [`.claude/commands/README.md`](README.md) (DRAFT v1, agent-authored 2026-05-06 evening — categorizes 42 commands by tier)
- SessionStart hook: `$HOME/.claude/hooks/session-orient.sh` (this command's invocation directive — see [`.claude/hooks/README.md`](../hooks/README.md))
- PostCompact hook: `$HOME/.claude/hooks/post-compact.sh` (post-compact orientation)
- Hook architecture rule: [`.claude/rules/hook-architecture.md`](../rules/hook-architecture.md)
- Second-brain command pattern: `<second-brain>/.claude/commands/checkin.md`
- M003 T-M003-7: queued refinement of policy-block + malware-block hook false-positives
- **M-E001-1 productive-cycle action vocabulary**: this command emits **`read-only-audit`** action type (per Hard Rule 14 in CLAUDE.md/AGENTS.md). Mandatory cycle-report last-line `Productive output: read-only-audit — orient report emitted; <N> Read calls + <M> Bash calls`.
- **Brain-improvement mandate**: [`wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md`](../../wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md) — sacrosanct verbatim directive governing the brain-quality passes that surface in /orient's intel chain.
