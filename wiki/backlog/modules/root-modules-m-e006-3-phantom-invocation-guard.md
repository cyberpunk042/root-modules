---
title: "M-E006-3 — Phantom-invocation guard (closes SB-142 broader scope; proactive clause #10 already landed)"
type: module
status: in-progress
priority: P3
parent_epic: "epic-e006-guided-workflow-continuation"
parent_milestone: "v0.2-ai-natural-task-management"
sfif_stage: foundation
current_stage: design
readiness: 25
created: 2026-05-07
updated: 2026-05-07
tags: [agent-drafted, m-e002-1-create-verb, sb-142, hook-layer, phantom-invocation]
---

# M-E006-3 — Phantom-invocation guard

> **Agent-DRAFT v1** (per SB-095, operator-revisable). Created 2026-05-07 in autopilot loop fire post-SB-142 mitigation #2 landing. Promotes broader-scope mitigations from Epic E006 bullet into claimable module.

## Operator-stated seed (sacrosanct)

> *"itsd weird I didnt ask for a handoff document and one was done... the handoff was done after the context compaction lol wtf did just happend. properly register this situation too it needs our attention..."* — 2026-05-07

## What this module is

Hardens the agent against **phantom skill-invocations** — system-reminder skill-blocks (e.g. `### Skill: finish-smoothly` with `ARGUMENTS:` text) that are NOT grounded in operator's literal `/<skill>` invocation in their actual recent message. Phantom invocations may originate from:

1. **Pre-compact agent self-invocation** under context-pressure (treating ~5% remaining as cue to run knowledge-extraction skill)
2. **PostCompact summarizer reconstruction** synthesizing skill-invocation in system-reminder format with operator-flavored args
3. **Hook/harness automation** invoking programmatically (no current evidence; theoretical)

Cousin family: SB-090 premise-construction · SB-091 synthetic-tests-as-verified · SB-095 hallucinated-artifacts · SB-140 self-imposed-false-gate. All share the root pattern: agent treats internal-model / system-reconstruction state as external operator-truth.

## Already landed (proactive layer, 2026-05-07 11:33)

- **Mindfulness clause #10 added** to `.claude/hooks/mindfulness.sh` REMINDER (DRAFT v5). MUST/MUST-NOT format: locate `/<skill-name>` in operator's message history; surface confirmation if absent.
- **test-mindfulness.py extended** 22 → 28 cases. Hook-specific test 28/28 PASS.
- **SB-142 row** flipped: `open` → `structurally-fixed (proactive layer)` in `wiki/governance/systemic-bugs.md`.

## What this module covers (broader scope still open)

### M-E006-3a — Pre-skill-execution premise-confirmation flow (cosmetic / runtime gate)

Beyond the rule-layer reminder (clause #10), build the **actual confirmation flow**:
- When agent detects a skill-block whose `/<skill>` is absent in operator's recent messages, agent emits a SINGLE LINE: `"I see /<skill> skill block but don't see your literal /<skill> invocation in your recent messages — confirm to proceed?"`
- No execution of forced steps until operator answers
- Operator answer "yes" / "proceed" / explicit re-invocation → execute; anything else → defer

**Verification mechanism per clause #9**: hook-specific test (would simulate phantom skill-block in stdin payload + verify agent's first response matches the confirmation pattern). May require a new hook layer OR in-prompt instruction.

### M-E006-3b — PreToolUse Skill-tool-invocation guard (hook layer)

Heavier mitigation — extend `policy-block.sh` (or new `phantom-skill-guard.sh`) hook on PreToolUse matcher `Skill`. Hook reads `tool_input.skill` + scans operator's recent UserPromptSubmit history for literal `/<skill>` invocation. Block execution if not found.

**Risk**: false-positives on legitimate post-compact recovery where operator's invocation was in pre-compact session. Mitigation: hook checks BOTH live conversation AND most-recent pre-compact-handoff doc (which captures last 30 operator messages).

**Verification mechanism per clause #9**: hook-specific test cases (legitimate Skill invocation allowed; phantom invocation denied + remediation message printed) + fire-trace empirical post-deployment.

### M-E006-3c — Pre-compact / PostCompact skill-invocation audit log

Extend `pre-compact.sh` to capture the in-session `/<skill>` invocation chain (operator-typed + agent-self-invoked) before compaction destroys nuance. Write to handoff doc as a dedicated section: `## Skill-invocation chain (operator vs agent-self-invoked)`. Post-compact AI reads + cross-references.

**Verification mechanism per clause #9**: post-edit Read of pre-compact.sh source + integration test with synthetic conversation having known invocation chain.

### M-E006-3d — Forensic transcript-audit unblock (project-internal hook regex tightening)

Currently `.claude/hooks/policy-block.sh` blocks `.claude/projects/-root/*.jsonl` glob as credential-file pattern (false-positive — session transcripts are NOT credentials). This blocks legitimate post-incident forensic analysis.

**Decision needed (operator-pending)**: is the policy intentional defensive-against-secret-echo-in-transcripts, or genuine false-positive worth tightening? If defensive: keep + document the rationale + provide a documented bypass for forensic; if false-positive: tighten the credential-file regex to exclude `.claude/projects/-*/*.jsonl` paths.

**Verification mechanism per clause #9**: policy-block hook-specific test cases (real .env / credentials / id_rsa still BLOCKED; transcript jsonl ALLOWED if decision is "tighten") + operator-confirmed scope.

## Done When (M-E006-3 module-level)

- [x] Mindfulness clause #10 landed (proactive layer) — 28/28 hook-test PASS
- [x] SB-142 status flipped open → structurally-fixed (proactive layer)
- [ ] M-E006-3a confirmation flow designed + implementation path operator-confirmed
- [ ] M-E006-3b PreToolUse Skill-tool-invocation guard hook authored + tested + wired (operator-pending: scope-confirm whether to add as new hook or extend existing)
- [x] M-E006-3c pre-compact.sh skill-invocation audit log section added + handoff template extended — **landed 2026-05-07** (`pre-compact.sh` lines 226-245: step 7 of recovery instructions points to new "## Skill-invocation context (SB-142 — phantom-invocation guard)" section embedded in handoff template; explicit MUST-verify chain (a/b/c) + MUST-NOT execute on phantom + confirmation phrasing + cousin SB cross-references + mitigation pointer; Python compile PASS; operator-empirical pending next compact event)
- [ ] M-E006-3d forensic-transcript-audit decision (operator-pending: defensive-vs-false-positive scope)
- [ ] Empirical: 1+ post-compact session demonstrates clause #10 catching phantom invocation OR no phantom invocations occur (either confirms mitigation + 3 layer effective, or absence of repro)
- [ ] SB-142 status flipped structurally-fixed → verified (operator-empirical confirmation)
- [ ] Lesson promoted to second-brain via `gateway contribute` (after M007 connect; lesson seed: `wiki/lessons/01_drafts/2026-05-07-frozen-loop-meta-vs-project-layer-drift.md` + sister)

## Dependencies

- **Hard**: SB-126 mindfulness baseline hook (already verified — clause #10 extension landed on top)
- **Hard**: SB-142 row state (operator-empirical confirmation gate)
- **Soft**: M007 second-brain connect (for lesson contribution)
- **Soft**: Operator-decision on M-E006-3d transcript-audit policy (defensive vs false-positive)
- **Composes with**: Epic E004 doctor watchdog (E004 reactive layer = transcript-scan; E006-3b PreToolUse layer = preventive; complementary not overlapping)

## Connects to

- SB-142 (parent — phantom skill-invocation registered + structurally-fixed proactive layer): `wiki/governance/systemic-bugs.md`
- Epic E006 (parent): `wiki/backlog/epics/epic-e006-guided-workflow-continuation.md`
- Mindfulness clause #10 (the proactive layer): `.claude/hooks/mindfulness.sh`
- Test extension: `.claude/hooks/tests/test-mindfulness.py` (28/28 PASS)
- Cousin SB-140 (frozen-loop / self-imposed-false-gate — same root pattern, different surface)
- Cousin SB-091 (synthetic-tests-as-verified — internal-model-as-external-truth)
- Cousin SB-095 (hallucinated-artifacts — phantom-invocation IS hallucinated artifact gaining reality)
- Pattern: `wiki/patterns/01_drafts/three-layer-mitigation-for-agent-behavioral-bugs.md` (this module is the second instance of that pattern)
- D045 (SB-140+SB-141 work-block decisions logbook entry)
- D046 (/finish-smoothly invoked — phantom-invocation that triggered SB-142 capture)
- Words-are-sacrosanct.md (the sacrosanct-quoting + premise-confirmation gate is the rule-layer foundation)
