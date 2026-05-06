Run integrity audits on $HOME project state.

> Slash-invoked. Operator types `/audit` literally. Read-only.

## On `/audit`

Run the deterministic checks below, in sequence. Report each pass/fail with context.

1. **Methodology engine yamls parse**:
   ```bash
   for f in $HOME/wiki/config/{methodology,sdlc-profile,domain-profile,methodology-profile}.yaml; do
     <second-brain>/.venv/bin/python -c "import yaml; yaml.safe_load(open('$f')); print('OK $f')"
   done
   ```

2. **Settings.json parses + has expected hooks**:
   ```bash
   <second-brain>/.venv/bin/python -c "
   import json
   cfg = json.load(open('$HOME/.claude/settings.json'))
   hooks = cfg.get('hooks', {})
   for evt in ['PreToolUse', 'PostToolUse', 'SessionStart', 'UserPromptSubmit', 'PreCompact', 'PostCompact', 'Stop', 'SessionEnd']:
       count = sum(len(e.get('hooks', [])) for e in hooks.get(evt, []))
       print(f'{evt}: {count} hooks')
   print(f'permissions.deny entries: {len(cfg.get(\"permissions\", {}).get(\"deny\", []))}')
   "
   ```

3. **All Python hooks compile**:
   ```bash
   for f in $HOME/.claude/hooks/*.sh $HOME/.claude/hooks/*.py; do
     python3 -m py_compile "$f" 2>/dev/null && echo "py-OK $(basename $f)" || echo "FAIL $(basename $f)"
   done
   ```

4. **Module + task frontmatter complete**:
   ```bash
   python3 -m tools.progress --json | python3 -c "
   import json, sys
   p = json.load(sys.stdin)
   print(f'modules: {p[\"modules\"][\"total\"]}, tasks: {p[\"tasks\"][\"total\"]}')
   "
   ```

5. **Blockers doc and live tasks in sync**:
   ```bash
   cd $HOME && python3 -m tools.blockers --check
   ```
   Exit code 0 = in sync; non-zero = drift.

6. **State sanity**:
   ```bash
   cd $HOME && python3 -m tools.state
   ```

7. **All `.gitignore` whitelist entries resolve to real files**:
   ```bash
   cd $HOME && for f in CLAUDE.md AGENTS.md BOOTSTRAP.md CONTEXT.md ARCHITECTURE.md DESIGN.md TOOLS.md SKILLS.md SECURITY.md README.md install.sh .claudeignore; do
     [ -e "$f" ] && echo "  OK $f" || echo "  MISSING $f"
   done
   ```

8. **All commands present**:
   ```bash
   ls $HOME/.claude/commands/ | wc -l
   ```
   Expected: 26 (orient, cycle, mode-{pm,architect,dual,status,clear}, blockers, progress, decisions, log, audit, sync-progress, help-root, handoff, stamp-{horizontal,vertical,on,off,auto,status}, install-agent-brain, mission, focus, impediment, priorities)

9. **All modes present**:
   ```bash
   ls $HOME/.claude/modes/
   ```
   Expected: pm-scrum-master.md, devops-architect.md, dual-expert.md

10. **Decisions logbook integrity**:
    ```bash
    python3 -m tools.decisions verify
    ```

11. **Objective + priorities state files** (SB-118 + SB-127 — files may exist or be absent; tools accept either):
    ```bash
    for f in active-mode active-mission active-focus active-impediment active-priorities; do
      if [ -e "$HOME/.claude/$f" ]; then echo "  present: $f ($(wc -c < "$HOME/.claude/$f") bytes)"
      else echo "  absent:  $f (tool defaults handle)"
      fi
    done
    ```
    Both states (present + absent) are valid. The tools `tools.objective` + `tools.priorities` handle absent gracefully. Audit just confirms current state visible.

12. **Compound + waterfall coverage** (SB-123 — every layer surfaces in at least 3 channels):
    ```bash
    grep -l "active-mission\|active-priorities" $HOME/.claude/hooks/*.sh $HOME/.claude/commands/*.md $HOME/tools/*.py 2>/dev/null | sort -u | wc -l
    ```
    Expected: ≥6 files (mode-enforcement.sh, pre-compact.sh, post-compact.sh, orient.md, handoff.md, cycle.py, mcp_server.py, objective.py, priorities.py, ...).

## Output

Aggregated pass/fail report; flag any FAILs with the corrective action; end with overall PASS/FAIL.

## When to invoke

- Before a fresh session test (so the operator knows the project is in expected state)
- After a substantive change (mode addition, hook update, settings.json modification)
- When debugging a "broken-and-idle" type symptom — first run /audit to rule out drift
