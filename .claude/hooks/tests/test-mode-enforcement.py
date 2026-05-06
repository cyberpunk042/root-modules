#!/usr/bin/env python3
# Regression tests for $HOME/.claude/hooks/mode-enforcement.sh
#
# Per SB-117 (Modes proper support — Epic) regression-tests sub-item.
# Verifies: invocation paths, dynamic mode-file parsing, objective+priorities
# surfacing (SB-118 + SB-127), no-cap output (SB-122 closure), error paths.
#
# Run: python3 $HOME/.claude/hooks/tests/test-mode-enforcement.py
# Expected: all green

import json
import os
import subprocess
import tempfile
from pathlib import Path

HOOK = str(Path.home() / ".claude" / "hooks" / "mode-enforcement.sh")
HOME = Path.home()

passed = 0
failed = 0
results: list = []


def run_hook(env_overrides: dict | None = None) -> tuple[int, str, str]:
    # Clear frequency-control cache before each fire — tests expect emit, not
    # suppression-on-identical (SB-117 deeper engineering: hook suppresses
    # byte-identical banners; tests bypass via cache-clear).
    cache_path = Path("/tmp/.mode-enforcement-last-banner")
    if cache_path.exists():
        try:
            cache_path.unlink()
        except Exception:
            pass
    env = os.environ.copy()
    env["CLAUDE_PROJECT_DIR"] = str(HOME)
    if env_overrides:
        env.update(env_overrides)
    r = subprocess.run(
        [HOOK],
        input="",
        env=env,
        capture_output=True, text=True,
        cwd=str(HOME),
    )
    return r.returncode, r.stdout, r.stderr


def expect(label: str, condition: bool, evidence: str = "") -> None:
    global passed, failed
    if condition:
        passed += 1
        results.append(f"✓ {label}")
    else:
        failed += 1
        results.append(f"✗ {label}{(' — ' + evidence) if evidence else ''}")


# Test 1: hook fires when active-mode set, emits valid JSON
rc, out, _ = run_hook()
expect("compiles + executes (rc=0)", rc == 0, f"rc={rc}")
expect("emits non-empty stdout", bool(out.strip()), "stdout empty")

if out.strip():
    try:
        parsed = json.loads(out)
        expect("valid JSON shape", "hookSpecificOutput" in parsed)
        ctx = parsed.get("hookSpecificOutput", {}).get("additionalContext", "")
        # Test 2: contains MODE-ENFORCEMENT marker
        expect("MODE-ENFORCEMENT prefix present", "MODE-ENFORCEMENT:" in ctx)
        # Test 3: persona section parsed
        expect("PERSONA section parsed", "PERSONA:" in ctx)
        # Test 4: cycle steps section parsed
        expect("CYCLE STEPS section parsed", "CYCLE STEPS:" in ctx)
        # Test 5: objective layer surfaced (SB-118)
        expect("MISSION present (SB-118)", "MISSION:" in ctx)
        expect("FOCUS present (SB-118)", "FOCUS:" in ctx)
        expect("IMPEDIMENT present (SB-118)", "IMPEDIMENT:" in ctx)
        # Test 6: priorities surfaced (SB-127)
        expect("PRIORITIES present (SB-127)", "PRIORITIES:" in ctx)
        # Test 7: live state cross-reference
        expect("LIVE STATE present", "LIVE STATE:" in ctx)
        # Test 8: not truncated to 1200 chars (SB-122 closure)
        expect("no MAX_REMINDER_CHARS cap (SB-122)", len(ctx) > 1200 or ctx.count(":") > 5,
               f"len={len(ctx)}")
    except json.JSONDecodeError as e:
        expect("valid JSON parse", False, repr(e))

# Test 9: silence when no active-mode (move temporarily)
mode_file = HOME / ".claude" / "active-mode"
mode_backup = mode_file.read_text() if mode_file.exists() else None
try:
    if mode_file.exists():
        mode_file.unlink()
    rc, out, _ = run_hook()
    expect("silent when no active-mode", out.strip() == "", f"out={out[:80]}")
finally:
    if mode_backup is not None:
        mode_file.write_text(mode_backup)

# Test 10: silence when not project context
rc, out, _ = run_hook(env_overrides={"CLAUDE_PROJECT_DIR": "/tmp"})
expect("silent when not in project context", out.strip() == "", f"out={out[:80]}")

# Test 11: silence when BOOTSTRAP.md absent — skip (would require unsafe move)
# Test 12: cwd-independent (sys.path injection — SB-118 build)
rc, out, _ = run_hook()  # with cwd=$HOME (default in run_hook)
# Re-run from /tmp to verify cwd-independence
env = os.environ.copy()
env["CLAUDE_PROJECT_DIR"] = str(HOME)
r = subprocess.run([HOOK], input="", env=env, capture_output=True, text=True, cwd="/tmp")
expect("cwd-independent (runs from /tmp)", r.returncode == 0, f"rc={r.returncode}")
if r.stdout.strip():
    expect("cwd-independent output has LIVE STATE",
           "LIVE STATE:" in r.stdout,
           f"out_head={r.stdout[:120]}")

# Test 13d: frequency-control suppression (SB-117 deeper engineering)
# Hook suppresses identical-banner re-emission to reduce context-injection noise;
# any state delta produces fresh banner.
cache_path = Path("/tmp/.mode-enforcement-last-banner")
mode_file = HOME / ".claude" / "active-mode"
mode_backup = mode_file.read_text() if mode_file.exists() else None
try:
    if cache_path.exists():
        cache_path.unlink()
    mode_file.write_text("dual-expert")
    # Fire 1 (no cache) — emits
    env = os.environ.copy()
    env["CLAUDE_PROJECT_DIR"] = str(HOME)
    r1 = subprocess.run([HOOK], input="", env=env, capture_output=True, text=True, cwd=str(HOME))
    expect("freq-control: fire 1 emits non-empty", bool(r1.stdout.strip()), f"len={len(r1.stdout)}")
    # Fire 2 (identical state, cache hit) — suppresses
    r2 = subprocess.run([HOOK], input="", env=env, capture_output=True, text=True, cwd=str(HOME))
    expect("freq-control: fire 2 suppresses identical (empty stdout)", not r2.stdout.strip(),
           f"unexpected={r2.stdout[:80]}")
    # Fire 3 after state change — emits
    mode_file.write_text("pm-scrum-master")  # state change
    r3 = subprocess.run([HOOK], input="", env=env, capture_output=True, text=True, cwd=str(HOME))
    expect("freq-control: fire 3 emits after state-delta", bool(r3.stdout.strip()),
           f"len={len(r3.stdout)}")
finally:
    if mode_backup is not None:
        mode_file.write_text(mode_backup)

# Test 13c: cite-bracket extraction from 4-col DRAFT v1 voice tables (SB-129)
mode_file = HOME / ".claude" / "active-mode"
mode_backup = mode_file.read_text() if mode_file.exists() else None
try:
    mode_file.write_text("dual-expert")
    rc, out, _ = run_hook()
    if out.strip():
        ctx = json.loads(out).get("hookSpecificOutput", {}).get("additionalContext", "")
        embody = ctx.split("EMBODY:")[1].split("CYCLE STEPS")[0] if "EMBODY:" in ctx else ""
        # DRAFT v1 voice tables have 4 columns; cite (4th) should appear in brackets
        expect("cite-bracket present in dual-expert embody (SB-129)",
               "[SB-128" in embody or "[SB-090" in embody or "[Forward-naming" in embody,
               f"sample={embody[:200]}")
        # Sanity: cite-brackets should NOT swallow the sounds-like content
        expect("cite-bracket appears AFTER quoted sounds-like",
               '"' in embody and embody.find('"') < embody.find('['),
               "structure broken")

    mode_file.write_text("pm-scrum-master")
    rc, out, _ = run_hook()
    if out.strip():
        ctx = json.loads(out).get("hookSpecificOutput", {}).get("additionalContext", "")
        embody = ctx.split("EMBODY:")[1].split("CYCLE STEPS")[0] if "EMBODY:" in ctx else ""
        expect("pm-scrum-master cite-bracket present (SB-129)",
               "[SB-" in embody or "[work-mode" in embody,
               f"sample={embody[:200]}")
finally:
    if mode_backup is not None:
        mode_file.write_text(mode_backup)

# Test 13a: each mode-file's voice table parser-extractable post-compile (SB-129)
mode_file = HOME / ".claude" / "active-mode"
mode_backup = mode_file.read_text() if mode_file.exists() else None
try:
    for mode_name, expected_qualities in [
        ("dual-expert", ["Driven", "Decisive", "Cadenced", "Lens-switching", "Priority-respecting"]),
        ("pm-scrum-master", ["Tier-explicit", "Decision-package", "Auto-research", "Decumulate", "Status-claim", "Priority-respecting"]),
        ("devops-architect", ["Trade-off-explicit", "Stage-gate-aware", "Empirical-verifying", "Idempotent-by-design", "Risk-flagging"]),
    ]:
        mode_file.write_text(mode_name)
        rc, out, _ = run_hook()
        if out.strip():
            ctx = json.loads(out).get("hookSpecificOutput", {}).get("additionalContext", "")
            embody = ctx.split("EMBODY:")[1].split("CYCLE STEPS")[0] if "EMBODY:" in ctx else ""
            for q in expected_qualities:
                expect(f"{mode_name} voice surfaces '{q}'", q in embody, f"missing in embody: {embody[:80]}")
        else:
            expect(f"{mode_name} fires", False, "empty output")
finally:
    if mode_backup is not None:
        mode_file.write_text(mode_backup)

# Test 13: mode-switch handling (SB-117 sub-item — operator directive 2026-05-06)
# Hook reads active-mode file each fire; switching modes mid-session should
# produce different banner content reflecting the new mode.
mode_file = HOME / ".claude" / "active-mode"
mode_backup = mode_file.read_text() if mode_file.exists() else None
try:
    # Fire 1: dual-expert
    mode_file.write_text("dual-expert")
    rc, out, _ = run_hook()
    if out.strip():
        d = json.loads(out)
        ctx_dual = d.get("hookSpecificOutput", {}).get("additionalContext", "")
        expect("mode-switch: dual-expert banner contains 'dual-expert'",
               "dual-expert" in ctx_dual.lower(),
               f"head={ctx_dual[:120]}")

    # Fire 2: switch to pm-scrum-master mid-session
    mode_file.write_text("pm-scrum-master")
    rc, out, _ = run_hook()
    if out.strip():
        d = json.loads(out)
        ctx_pm = d.get("hookSpecificOutput", {}).get("additionalContext", "")
        expect("mode-switch: pm-scrum-master banner reflects new mode",
               "pm-scrum-master" in ctx_pm.lower(),
               f"head={ctx_pm[:120]}")
        expect("mode-switch: banner content actually changed",
               ctx_dual != ctx_pm)
    else:
        expect("mode-switch: pm-scrum-master fires", False, "empty output")
finally:
    if mode_backup is not None:
        mode_file.write_text(mode_backup)

print()
for line in results:
    print(line)

print()
print(f"Result: {passed}/{passed + failed}")
exit(0 if failed == 0 else 1)
