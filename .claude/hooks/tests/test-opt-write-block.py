#!/usr/bin/env python3
# Regression tests for <project>/.claude/hooks/opt-write-block.sh
#
# Verifies SB-009/SB-010 fix: $HOME agent cannot write into <second-brain>/
# directly (must use <project>/wiki/log/ for iteration directives, or `tools.gateway contribute`
# after M007 connect). Hook is cwd-aware: only blocks when calling agent operates from $HOME
# (second-brain's own agent at /opt cwd legitimately writes its own dir).
#
# Run: <second-brain>/.venv/bin/python <project>/.claude/hooks/tests/test-opt-write-block.py
# Expected: 5/5 PASS

import json
import os
import subprocess
from pathlib import Path

# Portable resolution: project root = $HOME for type=root install.
HOOK = str(Path.home() / ".claude" / "hooks" / "opt-write-block.sh")
PROJECT = str(Path.home())
# OPT is the second-brain path. The hook resolves the second-brain root
# dynamically (RGP_SECOND_BRAIN_ROOT env → $HOME/devops-solutions-information-hub
# → /opt legacy). To keep this test deterministic regardless of the ambient
# filesystem, we PIN the root via RGP_SECOND_BRAIN_ROOT (set into every
# subprocess env below) and derive OPT from the SAME value — so the path the
# test asserts against and the prefix the hook protects can never diverge.
# (Without pinning, a host where neither /opt/... nor $HOME/...-info-hub exists
# resolves the hook to a different prefix than this hardcoded default, and the
# DENY case silently passes — an environment-coupling false-green.)
SECOND_BRAIN_ROOT = os.environ.get(
    "RGP_SECOND_BRAIN_ROOT", "/opt/devops-solutions-information-hub"
).rstrip("/")
OPT = SECOND_BRAIN_ROOT + "/"

# Each test: label, env-vars-to-set, payload, expected ("allow" or "block")
tests = [
    ("write to project path (always allow)",
     {"CLAUDE_PROJECT_DIR": PROJECT},
     {"tool_name": "Write", "tool_input": {"file_path": f"{PROJECT}/wiki/log/test.md"}},
     "allow"),
    ("write to /opt path from project cwd (DENY)",
     {"CLAUDE_PROJECT_DIR": PROJECT},
     {"tool_name": "Write", "tool_input": {"file_path": OPT + "raw/notes/foo.md"}},
     "block"),
    ("write to /opt path from /opt cwd (legitimate second-brain — ALLOW)",
     {"CLAUDE_PROJECT_DIR": OPT.rstrip("/")},
     {"tool_name": "Write", "tool_input": {"file_path": OPT + "wiki/page.md"}},
     "allow"),
    ("write to /opt with ROOT_OPT_WRITE_REASON bypass (allow + log)",
     {"CLAUDE_PROJECT_DIR": PROJECT, "ROOT_OPT_WRITE_REASON": "operator-explicit-one-time"},
     {"tool_name": "Write", "tool_input": {"file_path": OPT + "test.md"}},
     "allow"),
    ("non-write tool (not in matcher; pass-through)",
     {"CLAUDE_PROJECT_DIR": PROJECT},
     {"tool_name": "Read", "tool_input": {"file_path": OPT + "wiki/page.md"}},
     "allow"),
]

passed = 0
total = len(tests)

for label, envvars, tool_input, expected in tests:
    payload = {"session_id": "test", **tool_input}
    env = os.environ.copy()
    # Pin the second-brain root so the hook protects exactly the prefix this
    # test builds its OPT paths from (see SECOND_BRAIN_ROOT note above).
    env["RGP_SECOND_BRAIN_ROOT"] = SECOND_BRAIN_ROOT
    env.update(envvars)
    r = subprocess.run(
        [HOOK],
        input=json.dumps(payload),
        capture_output=True, text=True, env=env,
    )
    out = r.stdout.strip() or "(no output → allow)"
    actually_blocked = '"block"' in out
    ok = (expected == "block") == actually_blocked
    if ok:
        passed += 1
    marker = "✓" if ok else "✗"
    short = out[:120].replace("\n", " ")
    print(f"{marker} {label:60s} -> {short}")

print()
print(f"Result: {passed}/{total}")
exit(0 if passed == total else 1)
