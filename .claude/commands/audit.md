Run integrity audits on /root project state.

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
   for evt in ['PreToolUse', 'PostToolUse', 'SessionStart', 'PreCompact', 'PostCompact', 'SessionEnd']:
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
   cd /root && python3 -m tools.blockers --check
   ```
   Exit code 0 = in sync; non-zero = drift.

6. **State sanity**:
   ```bash
   cd /root && python3 -m tools.state
   ```

7. **All `.gitignore` whitelist entries resolve to real files**:
   ```bash
   cd /root && for f in CLAUDE.md AGENTS.md BOOTSTRAP.md CONTEXT.md ARCHITECTURE.md DESIGN.md TOOLS.md SKILLS.md SECURITY.md README.md install.sh .claudeignore; do
     [ -e "$f" ] && echo "  OK $f" || echo "  MISSING $f"
   done
   ```

8. **All commands present**:
   ```bash
   ls $HOME/.claude/commands/ | wc -l
   ```
   Expected: 15 (orient, cycle, mode-pm, mode-architect, mode-dual, mode-status, mode-clear, blockers, progress, decisions, log, audit, sync-progress, help-root, handoff)

9. **All modes present**:
   ```bash
   ls $HOME/.claude/modes/
   ```
   Expected: pm-scrum-master.md, devops-architect.md, dual-expert.md

10. **Decisions logbook integrity**:
    ```bash
    python3 -m tools.decisions verify
    ```

## Output

Aggregated pass/fail report; flag any FAILs with the corrective action; end with overall PASS/FAIL.

## When to invoke

- Before a fresh session test (so the operator knows the project is in expected state)
- After a substantive change (mode addition, hook update, settings.json modification)
- When debugging a "broken-and-idle" type symptom — first run /audit to rule out drift
