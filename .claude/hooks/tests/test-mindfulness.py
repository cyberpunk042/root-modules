#!/usr/bin/env python3
# Regression tests for $HOME/.claude/hooks/mindfulness.sh
#
# Per SB-126 (mindfulness baseline hook). Verifies: 4-clause reminder
# (one-notch / confirm-don't-construct / artifacts-flagged / forward-not-freeze),
# silence when no active-mode, cross-fire prevention.
#
# Run: python3 $HOME/.claude/hooks/tests/test-mindfulness.py

import json
import os
import subprocess
from pathlib import Path

HOOK = str(Path.home() / ".claude" / "hooks" / "mindfulness.sh")
HOME = Path.home()

passed = 0
failed = 0
results: list = []


def run_hook(env_overrides: dict | None = None, cwd: str | None = None) -> tuple[int, str]:
    env = os.environ.copy()
    env["CLAUDE_PROJECT_DIR"] = str(HOME)
    if env_overrides:
        env.update(env_overrides)
    r = subprocess.run(
        [HOOK],
        input="",
        env=env,
        capture_output=True, text=True,
        cwd=cwd or str(HOME),
    )
    return r.returncode, r.stdout


def expect(label: str, condition: bool, evidence: str = "") -> None:
    global passed, failed
    if condition:
        passed += 1
        results.append(f"✓ {label}")
    else:
        failed += 1
        results.append(f"✗ {label}{(' — ' + evidence) if evidence else ''}")


# Ensure executable bit
HOOK_PATH = Path(HOOK)
if not os.access(HOOK, os.X_OK):
    HOOK_PATH.chmod(0o755)

# Test 1: hook fires when active-mode set
rc, out = run_hook()
expect("compiles + executes (rc=0)", rc == 0, f"rc={rc}")
expect("emits non-empty stdout (active-mode set)", bool(out.strip()), "empty")

if out.strip():
    try:
        parsed = json.loads(out)
        expect("valid JSON", "hookSpecificOutput" in parsed)
        ctx = parsed.get("hookSpecificOutput", {}).get("additionalContext", "")
        # 6-clause baseline reminder per DRAFT v2 (SB-129 quality compile, MUST/MUST NOT binary format)
        expect("MINDFULNESS prefix", ctx.startswith("MINDFULNESS"))
        expect("clause 1 — one-notch", "one-notch" in ctx)
        expect("clause 2 — premise (confirm before constructing)", "premise" in ctx and "confirm" in ctx)
        expect("clause 3 — artifacts agent-draft", "artifacts" in ctx and "agent-draft" in ctx)
        expect("clause 4 — forward (fix-and-continue)", "forward" in ctx and "fix-and-continue" in ctx)
        expect("clause 5 — priority (P1-first)", "priority" in ctx.lower() and "FIRST" in ctx)
        expect("clause 6 — substance-per-cycle", "substance" in ctx)
        expect("clause 7 — not-blocked-when-unblocked + chain-operations (SB-131)",
               "not-blocked-when-unblocked" in ctx and "chain" in ctx)
        # MUST/MUST NOT binary format per second-brain context-engineering standard
        expect("uses MUST format (≥6 occurrences)", ctx.count("MUST ") >= 6)
        expect("uses MUST NOT format (≥3 occurrences)", ctx.count("MUST NOT") >= 3)
        # SB cross-references
        expect("references SB-082/093 (pendulum)", "SB-082" in ctx or "SB-093" in ctx)
        expect("references SB-090 (premise)", "SB-090" in ctx)
        expect("references SB-095 (artifacts)", "SB-095" in ctx)
        expect("references SB-099 (freeze)", "SB-099" in ctx)
        expect("references SB-128 (priority/substance)", "SB-128" in ctx)
    except json.JSONDecodeError as e:
        expect("valid JSON parse", False, repr(e))

# Test 2: silence when no active-mode (fires only when mode bound)
mode_file = HOME / ".claude" / "active-mode"
mode_backup = mode_file.read_text() if mode_file.exists() else None
try:
    if mode_file.exists():
        mode_file.unlink()
    rc, out = run_hook()
    expect("silent when no active-mode", out.strip() == "", f"out={out[:80]}")
finally:
    if mode_backup is not None:
        mode_file.write_text(mode_backup)

# Test 3: silence when not in project context
rc, out = run_hook(env_overrides={"CLAUDE_PROJECT_DIR": "/tmp"})
expect("silent when not in project context", out.strip() == "", f"out={out[:80]}")

# Test 4: cwd-independent
rc, out = run_hook(cwd="/tmp")
expect("cwd-independent (runs from /tmp)", rc == 0, f"rc={rc}")
if out.strip():
    expect("cwd-independent stdout has MINDFULNESS",
           "MINDFULNESS" in out, f"out_head={out[:80]}")

print()
for line in results:
    print(line)

print()
print(f"Result: {passed}/{passed + failed}")
exit(0 if failed == 0 else 1)
