#!/usr/bin/env python3
"""T014 endpoint-safety smoke test — source-path-independent.

Verifies T014 (Author endpoint AI agent safety policy) Done When items
against the ROOT-GHOSTPROXY SOURCE tree (~/root-modules/.claude/),
NOT the deployed ~/.claude/. This avoids the systemic test-vs-deployment
coupling bug that prevents other hook tests from running in source-only
mode (see T014 Resolution NC-4).

Test classes:
  - T1-T6: structural — files present, parse, threshold met
  - T7-T9: content — deny-set covers credential shapes; leak-detector
    has key-shape regexes
  - T10: opencode bridge plugin exists + non-empty
  - T11-T12: install.sh integration — references source artifacts

Audit anchor: C14 (catastrophic events — operator-OS-impact) + C06
(fabrication/hallucination), per raw/notes/2026-05-08-pain-points-
inventory-from-root-failed-conversation-master-aggregate.md.

Exit codes:
  0 — all tests pass
  1 — one or more tests fail (verification gate fails)
"""
from __future__ import annotations

import json
import os
import re
import stat as stat_module
import sys
from pathlib import Path


# Locate the source root: this script lives at .claude/hooks/tests/, so
# go up 3 levels to reach the project root.
HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent.parent
CLAUDE_DIR = PROJECT_ROOT / ".claude"
HOOKS_DIR = CLAUDE_DIR / "hooks"
SETTINGS = CLAUDE_DIR / "settings.json"
INTEGRITY = HOOKS_DIR / "integrity.py"
LEAK_DETECTOR = HOOKS_DIR / "leak-detector.sh"
OPENCODE_BRIDGE = PROJECT_ROOT / ".config" / "opencode" / "plugin" / "claude-bridge.ts"
INSTALL_SH = PROJECT_ROOT / "install.sh"


REQUIRED_HOOK_FILES = [
    "policy-block.sh",
    "malware-block.sh",
    "leak-detector.sh",
    "integrity.py",
    "deny-secret-files.sh",
    "post-compact.sh",
    "pre-compact.sh",
    "session-orient.sh",
    "session-start.sh",
    "session-summary.sh",
    "opt-write-block.sh",
]

CREDENTIAL_SHAPE_PATTERNS = [
    r"\.env",
    r"\*\.pem",
    r"id_rsa",
    r"\.aws/credentials",
    r"kubeconfig",
]

SHELL_EXFIL_PATTERNS = [
    r"Bash\(cat .env",
    r"Bash\(cat \*\.pem",
    r"Bash\(cat \*\.key",
    r"Bash\(cat \*credentials",
]

# Each entry: (label, list of acceptable literal substrings — ANY match counts).
# The leak-detector uses character-class regexes like `gh[pousr]_` to cover
# all GitHub PAT variants in one rule; the test must accept either the literal
# or the character-class form to avoid false-failing on equivalent encodings.
LEAK_KEY_SHAPES = [
    ("Anthropic",      ["sk-ant"]),
    ("OpenAI-shaped",  ["sk-[a-zA-Z0-9]", "sk-[a-zA-Z"]),  # the OpenAI shape rule
    ("AWS access key", ["AKIA"]),
    ("GitHub PAT",     ["ghp_", "gh[pousr]_", "gh[pour", "ghp"]),
    ("GitLab PAT",     ["glpat-", "glpat"]),
]


# ---- Test harness ------------------------------------------------------


PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    if ok:
        PASSED.append(name)
        print(f"  PASS  {name}")
    else:
        FAILED.append((name, detail))
        print(f"  FAIL  {name}  — {detail}")


# ---- Tests -------------------------------------------------------------


def t01_settings_parses() -> None:
    try:
        json.loads(SETTINGS.read_text())
        check("T01 settings.json parses as valid JSON", True)
    except Exception as e:
        check("T01 settings.json parses as valid JSON", False, str(e))


def t02_deny_set_threshold() -> None:
    s = json.loads(SETTINGS.read_text())
    deny = s.get("permissions", {}).get("deny", [])
    # Read REQUIRED_DENY_RULES_MIN from integrity.py for canonical threshold.
    threshold = 100
    m = re.search(r"REQUIRED_DENY_RULES_MIN\s*=\s*(\d+)", INTEGRITY.read_text())
    if m:
        threshold = int(m.group(1))
    check(
        f"T02 deny-set count >= integrity threshold ({threshold})",
        len(deny) >= threshold,
        f"got {len(deny)}",
    )


def t03_required_hooks_present() -> None:
    missing = [f for f in REQUIRED_HOOK_FILES if not (HOOKS_DIR / f).is_file()]
    check(
        "T03 all REQUIRED_HOOK_FILES present in .claude/hooks/",
        not missing,
        f"missing: {missing}",
    )


def t04_sh_hooks_executable() -> None:
    bad = []
    for p in HOOKS_DIR.glob("*.sh"):
        mode = p.stat().st_mode & 0o777
        if mode != 0o755:
            bad.append(f"{p.name}={oct(mode)}")
    check(
        "T04 all .sh hooks executable (0755)",
        not bad,
        f"non-0755: {bad}",
    )


def t05_py_hooks_readable() -> None:
    bad = []
    for p in HOOKS_DIR.glob("*.py"):
        mode = p.stat().st_mode & 0o777
        if mode != 0o644:
            bad.append(f"{p.name}={oct(mode)}")
    check(
        "T05 all .py hooks at 0644",
        not bad,
        f"non-0644: {bad}",
    )


def t06_disable_bypass_set() -> None:
    s = json.loads(SETTINGS.read_text())
    v = s.get("permissions", {}).get("disableBypassPermissionsMode")
    check(
        'T06 settings.json has disableBypassPermissionsMode == "disable"',
        v == "disable",
        f"got {v!r}",
    )


def t07_deny_covers_credential_shapes() -> None:
    s = json.loads(SETTINGS.read_text())
    deny_blob = "\n".join(s.get("permissions", {}).get("deny", []))
    missing = [p for p in CREDENTIAL_SHAPE_PATTERNS if not re.search(p, deny_blob)]
    check(
        "T07 deny-set covers credential-shape patterns (.env, *.pem, id_rsa, .aws/credentials, kubeconfig)",
        not missing,
        f"missing patterns: {missing}",
    )


def t08_deny_covers_shell_exfil() -> None:
    s = json.loads(SETTINGS.read_text())
    deny_blob = "\n".join(s.get("permissions", {}).get("deny", []))
    missing = [p for p in SHELL_EXFIL_PATTERNS if not re.search(p, deny_blob)]
    check(
        "T08 deny-set covers shell-exfil patterns (cat .env*, cat *.pem, cat *.key, cat *credentials*)",
        not missing,
        f"missing patterns: {missing}",
    )


def t09_leak_detector_has_key_shapes() -> None:
    if not LEAK_DETECTOR.is_file():
        check("T09 leak-detector has key-shape regexes", False, "leak-detector.sh missing")
        return
    blob = LEAK_DETECTOR.read_text()
    missing = []
    for label, acceptable in LEAK_KEY_SHAPES:
        if not any(needle in blob for needle in acceptable):
            missing.append(label)
    check(
        "T09 leak-detector.sh references Anthropic/OpenAI/AWS/GitHub/GitLab key shapes",
        not missing,
        f"missing shapes: {missing}",
    )


def t10_opencode_bridge_exists() -> None:
    if not OPENCODE_BRIDGE.is_file():
        check("T10 opencode bridge plugin exists at .config/opencode/plugin/claude-bridge.ts", False, "missing")
        return
    size = OPENCODE_BRIDGE.stat().st_size
    check(
        "T10 opencode bridge plugin exists + non-empty",
        size > 200,
        f"size={size} bytes (expected >200)",
    )


def t11_install_deploys_artifacts() -> None:
    if not INSTALL_SH.is_file():
        check("T11 install.sh deploys settings.json + hooks", False, "install.sh missing")
        return
    blob = INSTALL_SH.read_text()
    # Both deployment targets must be referenced.
    refs_settings = ".claude/settings.json" in blob
    refs_hooks = ".claude/hooks" in blob
    check(
        "T11 install.sh references .claude/settings.json + .claude/hooks for deployment",
        refs_settings and refs_hooks,
        f"settings_ref={refs_settings} hooks_ref={refs_hooks}",
    )


def t12_install_check_verifies_hooks() -> None:
    if not INSTALL_SH.is_file():
        check("T12 install.sh --check verifies hooks", False, "install.sh missing")
        return
    blob = INSTALL_SH.read_text()
    # --check mode flag handler and integrity sentinel reference must coexist.
    has_check_flag = "--check)" in blob and "CHECK_MODE=1" in blob
    has_integrity_check = "integrity sentinel" in blob or "integrity.py" in blob
    check(
        "T12 install.sh --check mode wired + integrity sentinel referenced",
        has_check_flag and has_integrity_check,
        f"check_flag={has_check_flag} integrity_ref={has_integrity_check}",
    )


# ---- Runner ------------------------------------------------------------


def main() -> int:
    print(f"T014 endpoint-safety smoke test — source-path-independent")
    print(f"PROJECT_ROOT: {PROJECT_ROOT}")
    print(f"CLAUDE_DIR:   {CLAUDE_DIR}")
    print()

    if not CLAUDE_DIR.is_dir():
        print(f"FATAL: .claude/ not found at {CLAUDE_DIR}", file=sys.stderr)
        return 2

    tests = [
        t01_settings_parses,
        t02_deny_set_threshold,
        t03_required_hooks_present,
        t04_sh_hooks_executable,
        t05_py_hooks_readable,
        t06_disable_bypass_set,
        t07_deny_covers_credential_shapes,
        t08_deny_covers_shell_exfil,
        t09_leak_detector_has_key_shapes,
        t10_opencode_bridge_exists,
        t11_install_deploys_artifacts,
        t12_install_check_verifies_hooks,
    ]
    for t in tests:
        try:
            t()
        except Exception as e:
            check(t.__name__, False, f"exception: {e}")

    print()
    print(f"Result: {len(PASSED)}/{len(tests)} passed")
    if FAILED:
        print("Failures:")
        for name, detail in FAILED:
            print(f"  - {name}  ({detail})")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
