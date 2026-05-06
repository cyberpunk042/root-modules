#!/usr/bin/env python3
# Regression tests for $HOME/.claude/hooks/output-discipline-guard.sh
#
# Covers:
#   SB-090: PREMISE-RISK detector (enumerative observation, observational
#           adjective, short reaction, unclear-reference start)
#   SB-094: ESCALATION detector (caps + frustration + repeated punctuation,
#           ≥2 markers required)
#   SB-120: CONDITIONAL-CLAUSE detector (future-conditional alongside imperative)
#
# Run: <second-brain>/.venv/bin/python $HOME/.claude/hooks/tests/test-output-discipline-guard.py
# Expected: all PASS

import json
import os
import subprocess
from pathlib import Path

HOOK = str(Path.home() / ".claude" / "hooks" / "output-discipline-guard.sh")


def run_hook(prompt: str):
    """Invoke hook with given prompt; return parsed additionalContext or None."""
    payload = {
        "session_id": "test-sid",
        "prompt": prompt,
        "hook_event_name": "UserPromptSubmit",
        "cwd": str(Path.home()),
    }
    env = {**os.environ, "CLAUDE_PROJECT_DIR": str(Path.home())}
    proc = subprocess.run(
        ["python3", HOOK],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        timeout=8,
        env=env,
    )
    if not proc.stdout.strip():
        return None  # silent
    try:
        return json.loads(proc.stdout)["hookSpecificOutput"]["additionalContext"]
    except Exception:
        return proc.stdout


tests = []
def t(name, fn):
    tests.append((name, fn))


# --- SILENT (routine) cases ---

@lambda fn: t("silent on routine imperative prompt", fn)
def _():
    return run_hook("fix the regression in tools/cycle.py") is None

@lambda fn: t("silent on slash command", fn)
def _():
    return run_hook("/cycle") is None

@lambda fn: t("silent on pure information question", fn)
def _():
    return run_hook("what does the SB-119 hook do?") is None

@lambda fn: t("silent on bare empty prompt", fn)
def _():
    return run_hook("") is None


# --- PREMISE-RISK (SB-090) ---

@lambda fn: t("premise: enumerative observation without imperative", fn)
def _():
    r = run_hook("everything else doesn't seem to be in the right context")
    return r is not None and "PREMISE-RISK" in r and "enumerative" in r

@lambda fn: t("premise: observational adjective", fn)
def _():
    r = run_hook("this is weird")
    return r is not None and "PREMISE-RISK" in r

@lambda fn: t("premise: short reaction word", fn)
def _():
    r = run_hook("wtf")
    return r is not None and "PREMISE-RISK" in r

@lambda fn: t("premise: unclear-reference + state", fn)
def _():
    # 'missing' is in unclear-reference state list but NOT in observational
    # adjective list, so this exercises the unclear-reference branch cleanly.
    r = run_hook("it's missing")
    return r is not None and "PREMISE-RISK" in r and "unclear-reference" in r

@lambda fn: t("premise: imperative present → silent", fn)
def _():
    # 'remove' is imperative → premise-risk should NOT fire
    return run_hook("remove that weird thing") is None


# --- ESCALATION (SB-094) ---

@lambda fn: t("escalation: 2 caps + frustration", fn)
def _():
    r = run_hook("WHY IS THIS BROKEN fucking trash")
    return r is not None and "ESCALATION" in r

@lambda fn: t("escalation: caps alone (1 marker) → silent", fn)
def _():
    # 1 frustration word + benign caps doesn't reach score 2
    return run_hook("fucking thing") is None

@lambda fn: t("escalation: benign acronyms not flagged", fn)
def _():
    # AIDLC + JSON + URL are benign caps; no frustration → silent
    return run_hook("the AIDLC JSON URL config is fine") is None


# --- CONDITIONAL-CLAUSE (SB-120) ---

@lambda fn: t("conditional: 'after we will' + imperative", fn)
def _():
    # 'fix' is in _IMPERATIVE_VERBS; 'iterate' is not. Use 'fix' to satisfy
    # the imperative-required gate. (Could expand verb list later if needed.)
    r = run_hook("fix the hooks; after we will review every action")
    return r is not None and "CONDITIONAL" in r and "after we will" in r.lower()

@lambda fn: t("conditional: 'later we'll' + imperative", fn)
def _():
    r = run_hook("fix this now; later we'll do the bigger refactor")
    return r is not None and "CONDITIONAL" in r

@lambda fn: t("conditional: 'in the future' + imperative", fn)
def _():
    r = run_hook("update the config; in the future we may want a profile system")
    return r is not None and "CONDITIONAL" in r

@lambda fn: t("conditional: 'next iteration' + imperative", fn)
def _():
    r = run_hook("verify this works; next iteration we add tests")
    return r is not None and "CONDITIONAL" in r

@lambda fn: t("conditional: future-only without imperative → silent", fn)
def _():
    # Pure future-statement, no imperative to confuse → silent
    return run_hook("later we'll think about it") is None

@lambda fn: t("conditional: imperative-only without future → silent", fn)
def _():
    # No conditional clause → silent
    return run_hook("fix the bug now") is None


# --- COMPOUND (multiple detectors fire) ---

@lambda fn: t("compound: escalation + conditional fires both", fn)
def _():
    r = run_hook("FIX THIS BROKEN trash; LATER we will rewrite EVERYTHING")
    return r is not None and "ESCALATION" in r and "CONDITIONAL" in r


# Run tests
passed = 0
failed = 0
for name, fn in tests:
    try:
        ok = fn()
        if ok:
            print(f"✓ {name}")
            passed += 1
        else:
            print(f"✗ {name}")
            failed += 1
    except Exception as e:
        print(f"✗ {name}  (exception: {e!r})")
        failed += 1

total = passed + failed
print()
print(f"Result: {passed}/{total}")
exit(0 if failed == 0 else 1)
