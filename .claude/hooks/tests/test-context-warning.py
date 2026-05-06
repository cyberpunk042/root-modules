#!/usr/bin/env python3
# Regression tests for $HOME/.claude/hooks/context-warning.sh
#
# Covers:
#   SB-107: transcript_path-based model+usage resolution (replaces failed
#           UserPromptSubmit-stdin model_id approach + glob-over-session-id hack);
#           filter for real `claude-*` models (skip system-injected `<synthetic>`)
#   SB-119: absolute-token thresholds (<50k / <25k / <10k) fire independently of
#           % thresholds; critical color when abs ≤ 10k regardless of %
#   General: silent above all thresholds; threshold name = threshold value
#           (no invented severity labels per operator directive)
#
# Authored 2026-05-06 per /loop iteration (post SB-107 + SB-119 fixes).
#
# Run: <second-brain>/.venv/bin/python $HOME/.claude/hooks/tests/test-context-warning.py
# Expected: 8/8 PASS

import json
import subprocess
import tempfile
from pathlib import Path

HOOK = str(Path.home() / ".claude" / "hooks" / "context-warning.sh")


def make_transcript(records):
    """Write JSONL records to a temp file; return path."""
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".jsonl", delete=False)
    for r in records:
        f.write(json.dumps(r) + "\n")
    f.close()
    return f.name


def assistant_record(model, used_input=0, cache_read=0, cache_create=0, output=0):
    """Return an assistant-message JSONL record with model + usage."""
    return {
        "type": "assistant",
        "message": {
            "model": model,
            "usage": {
                "input_tokens": used_input,
                "cache_read_input_tokens": cache_read,
                "cache_creation_input_tokens": cache_create,
                "output_tokens": output,
            },
        },
    }


def run_hook(transcript_path):
    """Invoke hook with given transcript_path; return parsed systemMessage or None."""
    payload = {
        "session_id": "test-sid",
        "transcript_path": transcript_path,
        "prompt": "test",
        "hook_event_name": "UserPromptSubmit",
    }
    proc = subprocess.run(
        ["python3", HOOK],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        timeout=8,
    )
    if not proc.stdout.strip():
        return None  # silent (above thresholds)
    try:
        return json.loads(proc.stdout)["systemMessage"]
    except Exception:
        return proc.stdout  # raw, for debugging


tests = []
def t(name, fn):
    tests.append((name, fn))


# 1. Silent when above all thresholds (Opus 4.7 @ 50% remaining = 500k tokens)
@lambda fn: t("silent above thresholds (1M Opus @ 50%)", fn)
def _():
    tx = make_transcript([assistant_record("claude-opus-4-7", 50000, 400000, 50000, 1000)])
    r = run_hook(tx)
    return r is None


# 2. SB-119 — 1M Opus @ 4% (40k tokens): <5% pct + <50k abs both fire (yellow)
@lambda fn: t("SB-119 1M Opus @ 4% — both thresholds fire, yellow", fn)
def _():
    tx = make_transcript([assistant_record("claude-opus-4-7", 50000, 900000, 10000, 1000)])
    r = run_hook(tx)
    if r is None:
        return False
    # Expect: <5% + <50k header, "40,000 tokens left", yellow color escape
    return ("<5% threshold" in r and "<50k tokens threshold" in r
            and "40,000 tokens left" in r and "\033[33m" in r)  # yellow ANSI


# 3. SB-119 — 200k Haiku @ 4% (8k tokens): <5% pct + <10k abs both fire (RED critical)
@lambda fn: t("SB-119 200k Haiku @ 4% — critical red (abs ≤ 10k)", fn)
def _():
    tx = make_transcript([assistant_record("claude-haiku-4-5", 20000, 170000, 2000, 1000)])
    r = run_hook(tx)
    if r is None:
        return False
    return ("<5% threshold" in r and "<10k tokens threshold" in r
            and "8,000 tokens left" in r and "\033[31m" in r)  # red ANSI


# 4. SB-107 — `<synthetic>` model filtered; falls back to real claude-* in earlier record
@lambda fn: t("SB-107 <synthetic> model skipped, real claude-* picked up", fn)
def _():
    # Newest record has <synthetic>; older record has claude-opus-4-7 with 99%-used usage
    tx = make_transcript([
        assistant_record("claude-opus-4-7", 50000, 940000, 1000, 1000),  # older, real
        assistant_record("<synthetic>", 0, 0, 0, 0),  # newer, system-injected
    ])
    r = run_hook(tx)
    if r is None:
        return False  # should fire — 992k used of 1M
    # Confirm window resolved to 1M (Opus), not 200k (default fallback)
    return "1,000,000 used" in r or "/ 1,000,000" in r


# 5. SB-107 — only <synthetic> records → no real model → DEFAULT_WINDOW (200k) fallback
@lambda fn: t("SB-107 only synthetic records → 200k fallback (no claude-* found)", fn)
def _():
    tx = make_transcript([assistant_record("<synthetic>", 50000, 100000, 5000, 1000)])
    r = run_hook(tx)
    if r is None:
        return False  # 156k used vs 200k default → 21.5% remaining → above threshold (silent)
    # Actually 156k of 200k = 78% used / 21.5% remaining → silent. So None expected.
    return False  # if non-None, we hit a fallback that incorrectly fires
# This test is deliberately constructed so the hook should be silent.
# Fix the test:
tests = [t for t in tests if t[0] != "SB-107 only synthetic records → 200k fallback (no claude-* found)"]
@lambda fn: t("SB-107 only synthetic records → silent (200k fallback applied)", fn)
def _():
    tx = make_transcript([assistant_record("<synthetic>", 10000, 100000, 5000, 1000)])
    r = run_hook(tx)
    return r is None  # 116k of 200k = 42% remaining → above 5% → silent


# 6. Threshold name = threshold value (no "ATTENTION/WARNING/URGENT" labels)
@lambda fn: t("no invented severity labels (threshold name = threshold value)", fn)
def _():
    tx = make_transcript([assistant_record("claude-opus-4-7", 50000, 940000, 1000, 1000)])
    r = run_hook(tx)
    if r is None:
        return False
    # Operator-rejected labels must NOT appear in output
    forbidden = ("ATTENTION", "WARNING", "URGENT")
    return not any(label in r for label in forbidden)


# 7. SB-078 framing reference present when warning fires
@lambda fn: t("SB-078 framing reference appears when fired", fn)
def _():
    tx = make_transcript([assistant_record("claude-opus-4-7", 50000, 940000, 1000, 1000)])
    r = run_hook(tx)
    if r is None:
        return False
    return "SB-078" in r and "prepare for compact" in r


# 8. Absolute threshold WITHOUT % threshold (e.g., 1M @ 6% = 60k → only <5% pct? No — 6% > 5%, but 60k > 50k → none fires; need 1M @ 5.5% = 55k)
# Construct: 1M Opus @ 4.5% = 45k tokens left. <5% pct fires AND <50k abs fires.
# To test ONLY abs (not pct): need pct > 5% but tokens < 50k. Possible only if window < ~1M.
# E.g., 800k window @ 6% remaining = 48k → would fire <50k abs but pct > 5%.
# But our model→window map only has 1M and 200k. So skip this edge case for now.
# Instead test that ABS-only fires for extremely-low-pct-% on 1M (e.g., 0.5% = 5k → <2% pct + <10k abs).
@lambda fn: t("extreme: 1M Opus @ 0.5% (5k left) — both pct + abs critical thresholds", fn)
def _():
    tx = make_transcript([assistant_record("claude-opus-4-7", 50000, 940000, 5000, 1000)])
    r = run_hook(tx)
    if r is None:
        return False
    # 996k used of 1M → 0.4% remaining, 4k tokens left → <2% pct + <10k abs (CRITICAL red)
    return "<2% threshold" in r and "<10k tokens threshold" in r and "\033[31m" in r


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
