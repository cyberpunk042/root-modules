# SKILLS.md — root-ghostproxy skills directory

> Skills directory context for this project. Where skills will live, conventions for authoring, when skills are appropriate vs other extension mechanisms (commands, hooks). **Future-tense** for this project — at scaffold + partial-foundation tier, no project-authored skills exist yet.

## Skills, Commands, and Hooks (the three extension mechanisms)

Per the second brain's `model-skills-commands-hooks.md`, AI tools (Claude Code in particular) support three extension mechanisms with different determinism levels and trigger semantics:

| Mechanism | Determinism | Trigger | Use when |
|---|---|---|---|
| **Hook** | Logical (block + reason + remediation) | Tool-call lifecycle event (PreToolUse / PostToolUse / SessionStart / PreCompact / PostCompact / SessionEnd) | Structural enforcement: rule MUST hold at this point. 9 wired in this project. |
| **Command** | **100% deterministic** | Operator types `/<name>` literally | Workflow with predictable steps, operator-driven, no auto-trigger needed. 15 in this project. |
| **Skill** | **~70-95% deterministic** | Auto-triggered by description-match on operator prose | Workflow where auto-trigger is desirable. 2 local + user-level skills (cycle / orient / etc) in this project. |
| **Sub-agent** | Cold-context | Parent agent invokes via Agent tool with `subagent_type` | Delegated research with own brain-load + tool subset. 3 brain-loaded subagents in this project (root-explorer / root-architect / root-pm-scoper). |

For root-ghostproxy:
- **Hooks** are the foundation's safety envelope + project-priming + compaction lifecycle. 13 fires across 8 events (PreToolUse + PostToolUse + SessionStart + UserPromptSubmit + PreCompact + PostCompact + Stop + SessionEnd). Regression tests at `.claude/hooks/tests/`.
- **Commands** are operator-typed slash commands for project workflows. 25 commands at `.claude/commands/*.md` (`/orient`, `/cycle`, `/mode-{pm,architect,dual,status,clear}`, `/blockers`, `/progress`, `/decisions`, `/log`, `/audit`, `/sync-progress`, `/help-root`, `/handoff`, `/stamp-{horizontal,vertical,on,off,auto,status}` (SB-115), `/install-agent-brain`, `/mission`, `/focus`, `/impediment` (SB-118)).
- **Skills** are auto-triggered workflows. `surface-state` (auto-fires on "where are we" prose → `/orient`) + `surface-blockers` (auto-fires on "what's blocking" prose → `/blockers`) live at `.claude/skills/`. Plus user-level skills (audit, cycle, modes, etc).
- **Sub-agents** are project-aware delegated workers. 3 at `.claude/agents/*.md` — each starts COLD without parent context, so each has explicit "load brain first" prompts naming CLAUDE.md / rules / state files.

## Currently Available Skills

| Skill | Path | Trigger | What it does |
|---|---|---|---|
| `surface-state` | `.claude/skills/surface-state/` | "where are we" / "what's the state" / etc. natural prose | Routes to `/orient` deterministic chain |
| `surface-blockers` | `.claude/skills/surface-blockers/` | "what's blocking us" / "what needs my input" / etc. | Routes to `/blockers` register surface |

Plus user-level / harness-provided skills (loop, schedule, claude-api, audit, cycle, mode-*, blockers, progress, decisions, log, handoff, help-root, etc.) — see `/help-root` for the full project surface.

## Skills Directory (planned)

When skills are added, they will live at:

```
$HOME/.claude/skills/
  <skill-name>/
    skill.md      # SKILL.md format (frontmatter + instructions + trigger)
    (other files)
```

Each skill is a directory under `$HOME/.claude/skills/` containing a `skill.md` file with:

- Frontmatter: `name`, `description` (used for auto-trigger matching), `tools` (which AI tools the skill is available to)
- Body: instructions for the AI tool when the skill is auto-triggered

## When a Skill Is Appropriate (vs Command, vs Hook)

Decision matrix:

| Question | If yes → | If no → |
|---|---|---|
| Does the workflow need auto-trigger from operator prose? | Skill or hook | Command |
| Is the workflow a tool-call-time decision (allow/deny/ask)? | Hook | Skill or command |
| Is the workflow an operator-typed explicit invocation? | Command | Skill or hook |
| Does the workflow have predictable scripted steps the operator wants on-demand? | Command | Skill |
| Does the workflow have variable shape that the agent should reason about? | Skill | Command |
| Does the rule MUST hold at this point (not "should remember")? | Hook | Skill or command |

For root-ghostproxy specifically:

| Workflow | Mechanism | Why |
|---|---|---|
| Tamper detection on every tool call | **Hook** (PreToolUse) | Must run before every call; rule must hold at this point |
| Deny-set check on credential paths | **Hook** (PreToolUse) | Must run before tool executes; rule must hold |
| Leak detection on tool output | **Hook** (PostToolUse) | Must run after every tool output; rule must hold |
| Session-start integrity self-check | **Hook** (SessionStart) | Must run at session start; rule must hold |
| Operator typing `/verify-foundation` to run M003 gate | **Command** (planned) | Operator-typed; deterministic scripted steps |
| Operator typing `/audit-deny-set` to inspect policy state | **Command** (planned) | Same |
| Auto-triggered "ingest a Suricata-related URL" workflow when operator says "ingest <url>" | **Skill** (none planned for this project — ingestion is a second-brain concern, not this project's) | (n/a here — would route through second brain after M007) |
| Auto-triggered "audit deny-set" when operator says "audit" or "is the policy intact" | **Skill** (potentially, M004+) | Auto-trigger gives low-friction operator UX; description-match is reliable for these terms |

The current verdict: most useful workflows for root-ghostproxy at its current SFIF tier are **hooks** (foundation safety envelope) and **commands** (operator-driven Infrastructure tooling). Skills are a Phase-2+ addition where auto-trigger from operator prose adds value — for example, methodology-routing skills that auto-trigger when operator references a specific workflow shape.

## Skill Authoring Conventions (when skills are added)

When a skill is authored for this project, it follows these conventions:

### File layout

```
$HOME/.claude/skills/<skill-name>/skill.md
```

One directory per skill. The `skill.md` file is the canonical form. Additional files (templates, scripts referenced by the skill) live alongside `skill.md` in the same directory.

### Frontmatter

```yaml
---
name: <skill-name>
description: <one-sentence description used for auto-trigger matching>
tools:
  - Read
  - Bash
  - Edit
  # ... only the tools the skill actually needs
---
```

The `description` field is the auto-trigger signal. Quality matters — the description must be specific enough to fire on the right operator prose AND general enough to fire on operator prose that varies in phrasing.

### Body

```markdown
# <Skill name>

<one-paragraph context: when this skill applies, why it exists>

## When to use

<bulleted list of operator prose patterns that should trigger this skill>

## Steps

<numbered list of steps the agent follows when the skill auto-triggers>

## Done When

<checklist of completion criteria>
```

### Naming

- Skill names use kebab-case: `audit-deny-set`, `verify-foundation-gate`.
- Skills do NOT shadow commands. If a slash command exists with the same intent, the skill name should be different (e.g. command `/verify-foundation` + skill `audit-policy-state` for prose-triggered variant).

### Determinism caveat

Skills are ~70% deterministic. The auto-trigger fires based on description-match against operator prose, which is non-deterministic. **Don't use a skill when the workflow MUST run** — use a hook for that.

## Skill vs Slash Command (the conflation pattern to avoid)

Per `<second-brain>/raw/notes/2026-05-04-rename-continue-conflation-bug-and-similar-conflations.md`, prose-vs-slash conflation is a documented failure mode in the second brain ecosystem. The lesson:

- **Slash commands** (`/checkin`, `/distill`, `/healthcheck`, etc.) are operator-invoked LITERALLY. They fire only when the operator types the slash + name verbatim.
- **Bare prose** ("continue", "evolve", "review") is **trajectory language** for the agent's current track, NOT a workflow trigger. Don't conflate these.
- **Skills** auto-trigger on description-match. Their descriptions should NOT match prose words that have established trajectory-language meaning. A skill description like "trigger on 'continue'" would conflate with the operator's bare "continue" trajectory-language.

For root-ghostproxy: if + when skills are added, their descriptions are written carefully to avoid matching trajectory-language phrases. The second brain has renamed three slash commands (`/continue` → `/checkin`, `/review` → `/healthcheck`, `/evolve` → `/distill`) precisely to break this conflation. Future root-ghostproxy slash commands + skills should follow the same discipline.

## Planned Skills (none committed, illustrative only)

If skills are added later, candidates include:

| Candidate skill | Auto-trigger description | Steps |
|---|---|---|
| `audit-policy-state` | "Operator wants to know whether the safety policy is intact + audit deny-set count + verify hooks" | 1. Run integrity check; 2. Run deny-set count audit; 3. Run hook executable audit; 4. Report findings |
| `prepare-module-design` | "Operator is starting design work for a new inspection module" | 1. Read M005 module page; 2. Pull source-synthesis pages from second brain; 3. Capture sample test pcap; 4. Outline design doc structure |
| `verify-foundation-gate` | "Operator wants to verify the M003 Foundation gate" | 1. `./install.sh --dry-run`; 2. Integrity check; 3. git audit; 4. Report green/red |
| `verify-bridge-topology` | "Operator wants to confirm bridge is up + L3-invisible" | 1. `brctl show`; 2. `ip link`; 3. nftables INPUT chain check; 4. Report state |

**None of these are committed.** They are examples to anchor the skills concept in concrete project workflows. Skill addition is operator-decided Phase-2+ work.

## Cross-References

| For… | Read |
|---|---|
| Project description + identity + modules + status | [README.md](README.md) |
| Tools (per-script reference) | [TOOLS.md](TOOLS.md) |
| Hook architecture (the safety envelope hooks) | [ARCHITECTURE.md § Hook Architecture (Two-Layer)](ARCHITECTURE.md#hook-architecture-two-layer) |
| Cross-tool agent contract | [AGENTS.md](AGENTS.md) |
| Claude Code-specific routing | [CLAUDE.md](CLAUDE.md) |
| Current operational state | [CONTEXT.md](CONTEXT.md) |
| Design pattern rationale (incl. why hooks vs commands vs skills) | [DESIGN.md](DESIGN.md) |
| Security policy (threat model + fail-closed enforcement) | [SECURITY.md](SECURITY.md) |
| Skills/Commands/Hooks model (canonical, in second brain) | `<second-brain>/wiki/spine/models/agent-config/model-skills-commands-hooks.md` |
| Three-Layer Agent Context Architecture (canonical, in second brain) | `<second-brain>/wiki/patterns/01_drafts/three-layer-agent-context-architecture.md` |
| Prose-vs-slash conflation lesson (canonical, in second brain) | `<second-brain>/raw/notes/2026-05-04-rename-continue-conflation-bug-and-similar-conflations.md` |
