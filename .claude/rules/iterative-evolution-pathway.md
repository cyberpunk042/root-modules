# $HOME/.claude/rules/iterative-evolution-pathway.md — Iterative continuous-evolution pathway across PM + Architect/SE synergy

> Loaded on demand when designing or evaluating a multi-step engineering pass: backlog evolution (when to create/update Epic/Task/Module/Milestone), stage-gate progression, multi-lens synergy, self-evaluation discipline, priority-driven action selection. Per operator directive 2026-05-06: *"we will need to create a pathway / way / tool to be able to evolve all this engineering iteratively continuously. the Architect + Soft Engineer and the PM side and all. lets try to create some synergy and make sure we do things right and make sure things are properly integrated by self evaluating and making sure like I said we keep evolving as we keep progressling like the normal behavior would be but the priorities would guide us to be aware of all this properly"*.
>
> **Strictness tier** (per `operating-principles.md`): **Advisory** — informs design judgment for backlog-evolution + multi-lens cycle work; per-case applied. Pairs with `compound-and-waterfall.md` (axes the pathway compounds along) + `methodology.md` (stage gates the pathway honors) + `trigger-model.md` (mechanism choice for each step).
>
> **DRAFT v1 — agent-authored 2026-05-06 evening per SB-095**. Operator may revise / promote / replace.

## Summary

The iterative-evolution pathway is the discipline by which root-modules advances from operator-directive → backlog artifact → spec/design → implementation → verification → governance-completion → forward-anchor naming, with PM + Architect/SE lenses synergizing per-fire and self-evaluation closing each cycle. The pathway is **continuous** (every fire produces real work per the productive-cycle taxonomy) and **priority-guided** (priorities determine WHICH work-item to advance, not just WHAT actions to take). It maps four orthogonal dimensions: **(1) backlog hierarchy** — when an item is Milestone vs Epic vs Module vs Task; **(2) stage gate** — when the artifact moves document → design → scaffold → implement → test; **(3) lens synergy** — when PM lens leads vs Architect/SE lens leads vs both compound; **(4) governance integration** — when decisions append, SBs close, brain docs drift-fix, session logs anchor. The pathway is the substrate; modes (`/mode-pm`, `/mode-architect`, `/mode-dual`) are configurations of which lens leads per fire.

## Key insights (5)

1. **Backlog hierarchy is determined by SCOPE, not by NAMING preference.** A new piece of work becomes a **Milestone** when it spans multiple Epics over weeks/months (e.g., v0.2 AI-Natural Task Management); an **Epic** when it spans multiple Modules over days/weeks (e.g., E001 auto-pilot rework); a **Module** when it's a coherent multi-task delivery within a Stream (e.g., M003 Foundation hardening); a **Task** when it's an atomic completion within a Module (e.g., T012 install.sh). The decision is mechanical: count the substantive steps + check the time-horizon. Operator-directive 2026-05-06: *"this is multiple Epics and tasks and you can even create a milestone and inside we will suggest this kind of evolution"*.

2. **Stage-gate + hierarchy co-determine when to author vs when to wait.** A Document-stage Task ALLOWED to author wiki page + raw notes; FORBIDDEN to ship code/tests. A Design-stage Task ALLOWED to author ADR + tech-spec; FORBIDDEN to ship code/tests. A Scaffold-stage Task ALLOWED to author type-definitions + schema + test-stubs; FORBIDDEN implementation. An Implement-stage Task ALLOWED implementation + integration-wiring; FORBIDDEN new tests. A Test-stage Task ALLOWED test-implementation + test-results; FORBIDDEN new features. Stage-gate VIOLATIONS carry security cost per methodology-profile=stage-gated (CLAUDE.md Hard Rule 6); the pathway honors the stage-gate when deciding what artifacts to author per work-item per fire.

3. **PM + Architect/SE lens synergy is SEQUENTIAL within a work-item lifecycle, PARALLEL within a single fire.** PM identifies importance (does this become a Milestone? what priority?) + decides hierarchy + sets gating (which Tasks block which). Architect designs structure (what modules? what stage? what gates?) + identifies design questions. SE implements within stage-gates + maintains code-quality + tests + verifies idempotency. A given Task progresses sequentially through PM-decide → Architect-design → SE-implement, but a given fire processes ALL active work-items via BOTH lenses (PM checks all blockers; Architect/SE checks all in-flight implementations). Dual-expert mode is the lens-switching configuration.

4. **Self-evaluation per fire closes the loop and prevents drift.** Per mindfulness clause 6 + SB-128 productive-cycle taxonomy: every fire MUST produce one of 9 named action types (`sb-closure / verified-edit / drift-fix-with-empirical / explicit-standby-with-named-reason / new-artifact / doc-refresh / blocker-surface / operator-directive-register / read-only-audit`). The cycle's last line MUST end with `Productive output: <type> — <one-line specific>`. Self-evaluation also checks: did the fire respect priorities (top-first, no short-circuit per clause 5)? Did agent-drafts get flagged (clause 3)? Did premise-confirmation gate hold (clause 2)? Did 4-gate Q-self-elevation pre-check apply before any `/questions add` (SB-138)? The mindfulness hook fires per-prompt to keep these salient.

5. **Continuous evolution is the NORMAL behavior; priorities are the GUIDE not the gate.** Operator directive 2026-05-06: *"we keep evolving as we keep progressing like the normal behavior would be but the priorities would guide us to be aware of all this properly"*. The pathway is NOT "wait for operator scope direction on each step"; it's "always-iterating, priorities tell us WHICH dimension to iterate on this fire". P1 active = anti-standby + substance-per-cycle. P2 active = surface immense work in existing priorities. P3-P5 active = the named substantive work areas. Priorities re-prioritize as work lands; operator can re-set anytime via `/priorities`.

## Deep analysis

### Dimension 1 — Backlog hierarchy decision logic

When a new piece of work surfaces (operator-directive / blocker-need / spec-gap / SB-pattern / etc.), apply this decision:

| Scope check | Outcome |
|---|---|
| Spans multiple Epics + multi-week horizon + needs operator-named theme | **Milestone** — author at `wiki/backlog/milestones/v<N>-<slug>.md`, declare 2-5 Epic links + mission + verification gate |
| Spans multiple Modules + days/weeks horizon + has clear cross-cutting theme | **Epic** — author at `wiki/backlog/epics/epic-<id>-<slug>.md`, declare parent_milestone + 2-5 Module links + mission + readiness 0% |
| Coherent multi-task delivery within a Stream + days horizon + 3-10 tasks | **Module** — author at `wiki/backlog/modules/<project>-m<NNN>-<slug>.md`, declare parent_epic + initial Task list + dependencies + done-when |
| Atomic completion within a Module + hours horizon + single done-when checklist | **Task** — author via `tools.tasks create under-epic/under-task/from-blocker` (M-E002-1 verbs); declare parent_module + status + priority + current_stage + readiness + done-when checklist |
| Less than atomic / a fragment / a piece of information | **Artifact-segment** — append to existing Task/Module page OR draft as `wiki/log/<ts>-<slug>.md` for later promotion |

When in doubt, default to one level **finer-grained** than instinct (start with Task; promote to Module if scope expands; promote to Epic if it becomes multi-Module). Demoting is harder than promoting per Hard Rule 11 (adding ≠ discarding).

### Dimension 2 — Stage-gate progression triggers

Per methodology engine `wiki/config/methodology.yaml` — 5 universal stages with ALLOWED/FORBIDDEN per stage. Stage transitions trigger:

| Transition | Trigger | Required gate |
|---|---|---|
| → document (0-25%) | New work-item appears; concept not yet captured | Page exists with Summary + gaps identified |
| document → design (25-50%) | Concept clear; trade-offs need exploration | Spec reviewed; trade-offs documented; ADR if architectural |
| design → scaffold (50-80%) | Spec accepted; implementation skeleton needed | install.sh `--dry-run` passes (for IaC) OR test-stubs exist (for code) OR config files exist (for ops) |
| scaffold → implement (80-95%) | Skeleton works; real-execute can begin | Operator-greenlit (decision-logbook entry per D024 pattern); install.sh real-run readiness |
| implement → test (95-100%) | Implementation complete; regression confirms | Test suite passes; idempotent re-run is no-op; integration smoke passes |

The pathway HONORS these gates — it does NOT skip stages. Per Hard Rule 6 stage boundaries are HARD; violations carry security cost. The pathway also recognizes that **multi-stage work items decompose into per-stage Tasks** (one Task in document, one in design, etc.) rather than one Task crossing stages.

### Dimension 3 — Lens synergy per fire

Each fire in dual-expert mode (PM + Architect/SE simultaneously) processes BOTH lenses:

| Lens | Per-fire scan | Synergy point |
|---|---|---|
| **PM** | Blocker decumulate sweep · pending-decision filter · priority-order check · backlog-hierarchy-decision needs · governance drift (SBs, decisions, progress) | PM hands Architect/SE: "T012 is at scaffold-stage 98%; design is settled; implementation is operator-driven future-session" |
| **Architect** | Top-down design-staleness scan · open ADR gaps · architectural risk-flagging · cross-cutting design questions | Architect hands SE: "install.sh --dry-run passes both base and full profiles; the implementation gate is the real-execute decision" |
| **SE (Software Engineer)** | Bottom-up code/script/config next-action · regression-test discipline · idempotency verification · drift-fix-with-empirical · technical-debt awareness | SE hands PM: "274/274 tests pass; no regression from any of this fire's edits; ready to advance the work-item if PM clears the gate" |

Synergy is achieved when each fire's output INCLUDES findings from each lens. Pure-PM output (just blockers) or pure-SE output (just code edits) is partial; dual-expert mode requires the compound.

### Dimension 4 — Governance integration triggers

Per the just-completed Statusline UX-Design Pass (D043) as exemplar: a multi-fire work block landed widget+profile+command artifacts AND closed governance loops:

| Governance step | Trigger | Mechanism |
|---|---|---|
| Append decision logbook entry | Substantive choice made (architectural pick / scope change / Epic-level commitment) | `tools.decisions append` with operator-verbatim quote in --verbatim |
| Update SB tracker row | An open SB became structurally-fixed by the work | Edit `wiki/governance/systemic-bugs.md` row status column |
| Drift-fix brain docs | Empirical counts changed (commands / widgets / profiles / tests) | Edit per Hard Rule 15 — empirically verify before refresh |
| Author session-arc log | Multi-fire work block wraps + needs cold-pickup memory | Author at `wiki/log/<ts>-<slug>.md` per Concept-Page-Standards |
| Refresh progress callout | Active work-item state advanced | `tools.progress --callout` OR `/sync-progress` |
| Forward-anchor naming | Some work-item NOT advanced this work block but should be remembered | Mention in session log + active-priorities + handoff doc |

Governance integration is NOT optional. Every multi-fire work block ends with at least decisions append + brain-doc drift-fix + session log. Single-fire work blocks may skip session log.

### Dimension 5 — Self-evaluation discipline per fire

The cycle's substance-gate (per dual-expert.md /cycle step 6): verify ONE of 9 action types fired this fire. Plus check:

| Self-eval | Per cycle |
|---|---|
| Substance-per-cycle (clause 6) | Did this fire produce real work or thin standby? Name the action type. |
| Top priority first (clause 5) | Did P1/P2 advance before P3-P5? No short-circuit. |
| One-notch (clause 1) | Did corrections produce one-notch adjustments, not extreme swings? |
| Premise-confirmation (clause 2) | Did premises trace to operator-literal-words, not agent-construction? |
| Artifacts flagged (clause 3) | Are agent-DRAFTs labeled as such (SB-095)? |
| Forward-not-freeze (clause 4) | If operator-corrected, did the next fire fix-and-continue? |
| Chain ops (clause 7) | When multiple files reflect ONE coherent change, were they chained? |
| 4-gate Q pre-check (SB-138) | Before any `/questions add`, did the 4 gates filter out parallel-pattern + meta-answered + agent-already-acted + low-stake Qs? |

Self-evaluation surfaces in cycle reports as a passable critique; it is NOT operator-shown unless explicitly asked OR a failure detected. The hooks (mindfulness.sh + mode-enforcement.sh + output-discipline-guard.sh) externalize parts of this baseline; the agent's self-evaluation is the in-prompt check.

### Dimension 6 — Priorities-as-guide pattern

Operator directive 2026-05-06: *"the priorities would guide us to be aware of all this properly"*. Priorities are NOT a strict gate (work doesn't STOP on lower priorities); they are the GUIDE for which dimension to iterate on each fire:

- P1 active = stop-pattern (anti-standby per SB-099/SB-128 family) — substance-per-cycle is the real-time check
- P2 active = "see immense work" — recognize agent-actionable items deferred as operator-domain-that-arent
- P3-P5 active = the named substantive work areas

When operator sets P3 = "statusline draft + profile-variants design within authority", the fire should be drafting/designing statusline+profiles. Not P5 unless P3 is genuinely complete OR operator explicitly redirects.

Priority order is dynamic — operator may re-set via `/priorities` (insert/promote/demote/update verbs per SB-130). Agent self-prioritizes WITHIN a work block when operator delegates ("you can even make priority"); operator-explicit re-set always takes precedence.

### Dimension 7 — Artifact-preparation triggers (specs / requirements / designs / plans)

Per operator directive 2026-05-06: *"where and when we need to create Epic Task or Module or even Milestones we do or do update things or to prepare, specs requirements draft designs or plan and etc or pieces of information or segment of artifact"*. The pathway recognizes preparation triggers:

| Artifact type | Trigger | Where |
|---|---|---|
| **Spec** (operator-named requirement) | New behavior named by operator + needs definition | `wiki/backlog/<level>/<slug>.md` description field OR `wiki/log/<ts>-spec-<slug>.md` |
| **Requirement** (functional/non-functional) | Operator names quality bar OR non-functional dimension (security, performance, UX) | Inline in spec OR separate `requirements.md` per module |
| **Design draft** (architectural choice) | Spec clear but multiple implementation paths exist | `wiki/log/<ts>-design-<slug>.md` (DRAFT) OR ADR if architectural |
| **Plan** (multi-step execution sequence) | Work-item decomposes into sequenced steps | Per-task done-when checklist OR multi-task module page |
| **Information segment** (brief insight / observation) | Worth capturing but not yet structured | `wiki/log/<ts>-<slug>.md` brief entry (DRAFT, agent-flagged per SB-095) |
| **Artifact segment** (template, snippet, reference) | Reusable piece for future work | `templates/<category>/<file>` OR appendix on existing module |

The pathway preserves operator-originated content sacrosanct (per `words-are-sacrosanct.md`) and flags agent-drafted content (per SB-095). Operator promotes drafts to canonical via per-file yes (per brain-improvement mandate protocol).

### Dimension 8 — SDD doctrine + SFIF + methodology engine + wiki-LLM integration awareness

Per operator directive 2026-05-06 evening: *"sfif, gates, configs, wiki llm, stages and progresses and integations and evolutions, do not forget that also... what the full aidlc / sdlc and methodology considerate and what it can bring to to embrace it such as Spec Driven Development. and make sure artifacts and documentation and designs and architectures and such and all markdown documents for the needs"*. The pathway honors:

| Layer | What | Where | Pathway integration |
|---|---|---|---|
| **Spec-Driven Development (SDD)** | Operating doctrine — repo carries spec, runtime regenerates per host (per AGENTS.md "Operating Doctrine" + BOOTSTRAP.md frame) | brain files + `wiki/config/` + `wiki/backlog/` + `install.sh` realizer | D1 hierarchy decisions ALWAYS author spec-as-artifact (not realized state); D7 spec/requirement/design preparation triggers honor SDD |
| **SFIF stages** (Scaffold → Foundation → Infrastructure → Features) | Project-lifecycle macro distinct from per-task methodology stages | CONTEXT.md "SFIF Stage" section + module frontmatter `sfif:` field | Each work-item declares parent SFIF stage; cycle skill respects SFIF-aware action selection (e.g., M005 Features-stage modules don't claim before M003 Foundation closes) |
| **Methodology engine** (5 stage gates + 9 models) | Per-task discipline (document → design → scaffold → implement → test) | `wiki/config/methodology.yaml` + 3 profiles | D2 stage-gate progression triggers consult engine before authoring; ALLOWED/FORBIDDEN per stage HARD per Hard Rule 6 |
| **Configs** (4 yaml profiles + 3 supplementary) | Methodology-stage-gated · sdlc-simplified · domain-infrastructure · stage-gated profile + artifact-types · quality-standards · wiki-schema (Tier 3 adoption per D041) | `wiki/config/*.yaml` (7 yamls total) | Pathway respects yaml-driven gate-commands + path-patterns; D7 artifact-preparation per artifact-types.yaml taxonomy |
| **Wiki-LLM integration** (second-brain consume + contribute) | Knowledge consumer (source-syntheses / patterns / lessons) + contribute channel (gateway after M007) | `<second-brain>/` + `tools/gateway.py` (after M007 connect) | D7 artifact-segment of cross-project relevance flagged for `gateway contribute`; D4 governance integration tracks pending contributions |
| **AIDLC / SDLC progressions** (project-lifecycle iterations) | Continuous evolution — operator's "we keep evolving as we keep progressling like the normal behavior" | progress.md callout · CONTEXT.md SFIF row · backlog hierarchy state | Per fire's `read-only-audit` action checks SFIF + progress states; pathway D6 priorities-as-guide consumes these |
| **Artifact + doc + design + architecture** (markdown documents for needs) | Engineer-quality compile per Concept-Page-Standards (Summary + Key Insights + Deep Analysis subsectioned) | `wiki/log/` · `wiki/lessons/` · `wiki/patterns/` · `.claude/rules/` · brain files · backlog frontmatter | D4 governance integration triggers session-arc log per multi-fire work block; D7 artifact-preparation per Concept-Page-Standards quality bar |

**Bridges/highways/channels** the pathway recognizes (per operator's *"find a way to create bridge / highway and channels for such things as tools and such and / or commands and options"*):

- **Tools layer** (`tools/*.py`) — programmatic CLI that pathway-aware fires consume (`tools.tasks create` per M-E002-1 verbs · `tools.decisions append` per D044 governance · `tools.cycle --json` per pathway D5 self-eval)
- **Commands layer** (`.claude/commands/`) — operator-invoked deterministic chains (`/cycle` consumes pathway D1+D2 via step 10 · `/task` per D1 task creation · `/statusline-*` per D7 artifact-preparation)
- **Skills layer** (`.claude/skills/`) — auto-trigger workflows (surface-state · surface-blockers — pathway D5 awareness signals)
- **Hooks layer** (`.claude/hooks/`) — runtime injection (mode-enforcement consumes pathway D6 priorities-as-guide · mindfulness consumes pathway D5 self-eval clauses)
- **MCP layer** (`tools/mcp_server.py`) — structured returns for AI consumers (root_state / root_blockers / root_progress / root_decisions / root_objective / root_questions — all pathway-aware state surfaces)

The pathway names these as the integration substrate; each fire's `productive output` taxonomy (M-E001-1 9 types) MAY route through any of these channels.

### Dimension 9 — Mode-alternance + hybrid + repeat patterns (operator-wondering 2026-05-06 evening)

Per operator: *"I wounder also what is our mentally about the loop and possible alternance between a one ot the other mode and then hybrid and on repeat and such especially depanding on the cases and situations"*.

The pathway recognizes 3 mode-cadence patterns (DRAFT v1, agent-flagged per SB-095, operator-revisable):

| Pattern | When | How |
|---|---|---|
| **Single-mode sustained** | Deep PM-only OR deep Architect/SE-only work for a session | `/mode-pm` OR `/mode-architect` · `/loop <interval> /cycle` until work concludes · `/mode-clear` to disable |
| **Hybrid sustained (dual-expert)** | Cross-cutting work needing BOTH lenses per fire (current default) | `/mode-dual` · `/loop <interval> /cycle` · cycle output compounds both lenses per fire |
| **Alternance** (mode-switching mid-loop) | Work-item stage transitions across PM-heavy (decisions/blockers) → Architect-heavy (design/implement) phases | `/mode-pm` for PM-heavy phase → operator decision-package resolved → `/mode-architect` for implement-heavy phase → operator stage-gate-passed → `/mode-clear` OR `/mode-dual` for cross-cutting follow-on |

**Decision logic** (when to switch modes):
- Single-mode: when the work-item's lifecycle stage is one-lens-dominant (PM stage = blocker decumulate; Architect/SE stage = implement + verify)
- Hybrid: when work is genuinely cross-cutting (e.g., authoring this very rule — PM-decides-hierarchy + Architect-designs-structure + SE-implements both)
- Alternance: when the SAME work-item progresses through mode-distinct phases (rare; alternance is operator-coordinated, not auto-pilot)

**Repeat cadence**: `/loop <interval> /cycle` is the autopilot mechanism. Per loop-cron-lifecycle.md: 90s-1800s wakeup; cron-deterministic OR self-paced via ScheduleWakeup; L1-L7 scenarios for autonomous cancel/update.

**On repeat behavior**: each cron-fire produces ONE atomic coherent edit (the substance-per-cycle gate per D5). Multiple fires compound the substrate per D6 priorities-as-guide. The pattern observed in this work block (statusline UX-design 7-phase pass + pathway rule + autopilot loop kickoff) demonstrates the cadence: each fire ~1 atomic delta; multi-fire cumulates substantial outcome.

**Operator-pending evolution**: this Dimension 9 is OPERATOR-WONDERING (per literal verbatim), not OPERATOR-DIRECTIVE. The 3-pattern proposal above is agent-DRAFT v1; operator-empirical across upcoming work-blocks may surface additional patterns (e.g., cron-rate-shift-on-stage-transition; mode-shift-on-priority-shift; etc.). Promotion to canonical requires operator explicit confirmation.

**Empirical evidence — autopilot loop run 2026-05-06 evening (10 fires, dual-expert hybrid sustained)**: cron `538ffec4` armed at `1-59/2 * * * *` (~2 min cadence). 10 consecutive fires produced atomic deltas exercising 8 of 9 M-E001-1 action types — blocker-surface ×2 / verified-edit ×3 / drift-fix-with-empirical ×2 / tracker-reconciliation / explicit-standby-with-named-reason / read-only-audit ×2 (type 8 `operator-directive-register` only unexercised — would need NEW operator directive in cycle prompt). Substantive-burst pattern observed: fires 1-6 produced major deltas (rule + cycle.md extension + tracker updates + journey row); fires 7-10 reached steady-state verification cadence. Cross-project parallel-work observed at fire 5 (second-brain enriched 9 statusline-* command files concurrently — per self-reference.md bidirectional-inheritance pattern operating in real-time, no race-collision thanks to Edit's "modified since read" guard). Loop healthy across all 10 fires; 274/274 regression unchanged. **Pattern hypothesis**: substantive-burst (deltas-per-fire ≥ 1 atomic edit) → steady-state (verification + surface, no new edits) is the natural cadence when major substantive work-block closes; cron remains armed but cycle.md cat-5 explicit-standby-with-named-reason becomes the typical action type until new operator directive OR new SB pattern emerges. Per Hard Rule 11 — this empirical evidence is APPENDED, not replacing the 3-pattern proposal above.

## Composition with other rules

- `compound-and-waterfall.md` — the two axes the pathway populates (compound = lenses+findings stack at-a-moment in cycle output; waterfall = work-item evolves stage-by-stage event-to-event)
- `methodology.md` — the 5 stage gates the pathway honors per work-item; stage-transition triggers per Dimension 2
- `trigger-model.md` — mechanism choice for each pathway step (rule informs / hook auto-fires / command operator-invokes / skill auto-triggers / tool computes)
- `operating-principles.md` — strictness graduation per pathway step (some steps Strict like sacrosanct quoting; others Advisory like multi-lens synergy)
- `loop-cron-lifecycle.md` — when self-paced loops cancel/update; pathway respects L1-L7 scenarios
- `work-mode.md` — PO approval boundary per pathway step (which steps unilateral, which need operator approval)
- `words-are-sacrosanct.md` — operator-verbatim preservation throughout the pathway
- `hook-architecture.md` — runtime injection of mindfulness + mode-enforcement to keep self-evaluation salient

## Anti-patterns the pathway closes

| Anti-pattern | Failure | Closes |
|---|---|---|
| Skip stage-gates | Implementation in Document-stage Task; tests in Implement-stage Task | Hard Rule 6 + Dimension 2 |
| One Task crossing multiple stages | Stage transition mid-Task; readiness becomes meaningless | Dimension 2 (decompose per-stage) |
| Author Epic when Module would suffice | Hierarchy bloat; readiness signals diluted | Dimension 1 (start finer-grained) |
| Single-lens output in dual-expert mode | PM-only or SE-only finding; the OTHER lens's findings ignored | Dimension 3 (require both lenses' findings) |
| No governance close after multi-fire block | Decisions not appended; SBs not updated; drift accumulates | Dimension 4 (require closure steps) |
| Thin standby mid-pathway | Cycle produces no real work; agent freezes | Dimension 5 (substance-per-cycle gate) |
| Priority short-circuit | Jumping to easier P3 because P1 feels meta | Dimension 6 (priorities-as-guide; top-first) |
| Agent-drafts not flagged | Agent content treated as operator-known | SB-095 + Dimension 7 |
| Operator-words paraphrased | Sacrosanct words altered; alignment lost | `words-are-sacrosanct.md` + Dimension 7 |

## When the pathway changes

The pathway is **DRAFT v1**. Operator-empirical evaluation across multiple work-blocks may surface gaps (e.g., a 6th lens needed; a hierarchy level missing; a stage-gate too rigid). Per continuous-evolution stance, the pathway itself iterates — append revisions to this rule with version bump (DRAFT v2, v3...) per per-iteration operator yes. Promotion to canonical (`status: active` + `maturity: growing/mature/canonical`) requires operator explicit confirmation.

## Cross-references

- Operator directive (this rule's seed): 2026-05-06 evening verbatim — *"we will need to create a pathway / way / tool to be able to evolve all this engineering iteratively continuously..."* (sources frontmatter quote)
- Active milestone: `wiki/backlog/milestones/v0.2-ai-natural-task-management.md`
- Active epics: E001 auto-pilot rework · E002 piling-tasks · E003 compound-retention-and-multi-group
- M-E001-1 productive-cycle action vocabulary: `wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md`
- 4-gate Q pre-check (SB-138 closure): `wiki/lessons/01_drafts/2026-05-06-q-self-elevation-4-gate-pre-check.md`
- Statusline UX-design pass exemplar (D043 governance-completion): `wiki/log/2026-05-06-222748-statusline-ux-design-pass-7-phases-landed.md`
- `compound-and-waterfall.md` · `methodology.md` · `trigger-model.md` · `operating-principles.md` · `loop-cron-lifecycle.md` · `work-mode.md` · `words-are-sacrosanct.md`
