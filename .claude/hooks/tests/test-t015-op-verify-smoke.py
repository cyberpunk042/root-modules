#!/usr/bin/env python3
"""T015 post-install verification (op_verify) smoke test — source-path-independent.

Verifies T015 (Author post-install verification — integrity + bridge + opencode
bridge + git audit) Done When items against the ROOT-GHOSTPROXY SOURCE tree
(~/root-ghostproxy/install.sh), NOT a deployed state. Mirrors the T014 smoke
test pattern (source-path-independent; locates PROJECT_ROOT from __file__).

T015 Done When mapping (8 items):
  DW#1: Verification script exists — `install.sh --check` mode invoking op_verify
  DW#2: Integrity check sub-step (calls integrity_check from integrity.py)
  DW#3: Bridge state sub-step (`ip link show br0` UP when --with-bridge)
  DW#4: opencode bridge sub-step (`opencode debug config | grep claude-bridge`
        when --with-opencode)
  DW#5: Git audit sub-step (`git status --porcelain | wc -l` at SRC; INFO not FAIL)
  DW#6: Exit code reflects sub-step pass/fail; fail_reasons[] printed at summary
  DW#7: Wifi sub-steps (wpa_supplicant config + nftables ruleset + ghp_mgmt_wifi
        table loaded + service enabled with placeholder-aware skip)
  DW#8: Brain pieces sub-steps (rules/commands/agents/modes/skills counts)

Test classes (one per DW item plus structural sanity):
  T1: install.sh exists + parseable as bash (bash -n exit 0)
  T2: --check flag declared + dispatches to op_verify path
  T3: op_verify() function defined
  T4: DW#2 — integrity_check sub-step present (calls integrity.py)
  T5: DW#3 — bridge state sub-step present (br0 UP gated by --with-bridge)
  T6: DW#4 — opencode bridge sub-step present (gated by --with-opencode)
  T7: DW#5 — git audit sub-step present at SRC (INFO level not FAIL)
  T8: DW#6 — exit code structure (fail_reasons array printed; return non-zero
      on failure)
  T9: DW#7 — wifi sub-steps present (wpa_supplicant + nftables + ghp_mgmt_wifi
      + service status)
  T10: DW#8 — brain pieces sub-steps present (rules/commands/agents/modes/skills)
  T11: --check mode actually runs to completion + exits with structured code
      (live execution; non-zero on this dev host is EXPECTED per NC-5 — project
      not deployed; we verify exit code is 0/1/3, not crash, AND verify summary
      line `verify: N/M passed` is emitted on stdout)
  T12: Hook script presence sub-step (policy-block.sh, malware-block.sh,
      leak-detector.sh checked for executable)

Audit anchor: C09 (status-claim reliability — verification must be
trustworthy) + C02 (verification gates) + C12 (foundation gate completeness),
per raw/notes/2026-05-08-pain-points-inventory-from-root-failed-conversation-
master-aggregate.md.

Exit codes:
  0 — all tests pass
  1 — one or more tests fail
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


# Locate source root: script lives at .claude/hooks/tests/, go up 3 levels.
HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent.parent
INSTALL_SH = PROJECT_ROOT / "install.sh"


# Test result tracking
PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, condition: bool, detail: str = "") -> None:
    """Record a test result."""
    if condition:
        PASSED.append(label)
        print(f"[T015-smoke] PASS  {label}")
    else:
        FAILED.append((label, detail))
        print(f"[T015-smoke] FAIL  {label}: {detail}", file=sys.stderr)


def read_install_sh() -> str:
    """Load install.sh content."""
    return INSTALL_SH.read_text(encoding="utf-8")


# ---------- Tests ----------

def t1_install_sh_exists_and_parses() -> None:
    """T1: install.sh exists + parseable as bash (bash -n exits 0)."""
    if not INSTALL_SH.is_file():
        check("T1 install.sh exists", False, f"missing at {INSTALL_SH}")
        return
    check("T1 install.sh exists", True)
    # Bash syntax check
    r = subprocess.run(
        ["bash", "-n", str(INSTALL_SH)],
        capture_output=True,
        text=True,
    )
    check(
        "T1 install.sh parses (bash -n)",
        r.returncode == 0,
        f"bash -n stderr: {r.stderr.strip()[:200]}",
    )


def t2_check_flag_declared() -> None:
    """T2: --check flag declared + CHECK_MODE dispatch path exists."""
    content = read_install_sh()
    check(
        "T2 --check flag declared",
        "--check)" in content and "CHECK_MODE" in content,
        "no --check) case or CHECK_MODE token in install.sh",
    )
    # --check mode block must invoke op_verify
    check(
        "T2 --check mode dispatches to op_verify",
        re.search(r"CHECK_MODE.*op_verify|op_verify.*CHECK_MODE", content, re.DOTALL)
        is not None
        or "if op_verify" in content,
        "op_verify not invoked from --check dispatch path",
    )


def t3_op_verify_function_defined() -> None:
    """T3: op_verify() function defined as bash function."""
    content = read_install_sh()
    check(
        "T3 op_verify() function defined",
        re.search(r"^op_verify\s*\(\s*\)\s*\{", content, re.MULTILINE) is not None,
        "no `op_verify()` function header found",
    )


def t4_integrity_substep() -> None:
    """T4 (DW#2): integrity_check sub-step calls integrity.py."""
    content = read_install_sh()
    has_call = "integrity_check" in content and "integrity.py" in content
    check(
        "T4 DW#2 integrity_check sub-step present",
        has_call,
        "no integrity_check + integrity.py wiring",
    )


def t5_bridge_substep() -> None:
    """T5 (DW#3): bridge state sub-step (`ip link show br0` UP, --with-bridge)."""
    content = read_install_sh()
    has_bridge = (
        "WITH_BRIDGE" in content
        and "br0" in content
        and "ip link show" in content
        and "state UP" in content
    )
    check(
        "T5 DW#3 bridge state sub-step present",
        has_bridge,
        "missing one of: WITH_BRIDGE / br0 / ip link show / state UP",
    )


def t6_opencode_substep() -> None:
    """T6 (DW#4): opencode bridge sub-step (gated by --with-opencode)."""
    content = read_install_sh()
    has_opencode = (
        "WITH_OPENCODE" in content
        and "opencode debug config" in content
        and "claude-bridge" in content
    )
    check(
        "T6 DW#4 opencode bridge sub-step present",
        has_opencode,
        "missing one of: WITH_OPENCODE / opencode debug config / claude-bridge",
    )


def t7_git_audit_substep() -> None:
    """T7 (DW#5): git audit sub-step at SRC; INFO not FAIL."""
    content = read_install_sh()
    has_git = (
        '"${SRC}/.git"' in content or "SRC}/.git" in content
    ) and "git status --porcelain" in content
    check(
        "T7 DW#5 git audit sub-step present at SRC",
        has_git,
        "no SRC/.git check + git status --porcelain",
    )
    # Must be INFO not FAIL when changes exist (per DW#5 spec)
    # We look for the INFO label near the git block
    has_info = re.search(
        r"git tree.*INFO.*modified.*active work", content, re.DOTALL
    ) is not None or 'log_check "git tree" "INFO' in content
    check(
        "T7 DW#5 git audit reports INFO (not FAIL) on dirty tree",
        has_info,
        "no INFO-level reporting for dirty git tree",
    )


def t8_exit_code_structure() -> None:
    """T8 (DW#6): exit code structure — fail_reasons array; non-zero on failure."""
    content = read_install_sh()
    check(
        "T8 DW#6 fail_reasons array used",
        "fail_reasons" in content and "fail_reasons+=(" in content,
        "no fail_reasons+=( accumulation",
    )
    # op_verify returns 1 when failed > 0
    check(
        "T8 DW#6 op_verify returns non-zero on failure",
        re.search(r'if \[\[ "\$\{failed\}" -gt 0 \]\]', content) is not None
        and "return 1" in content,
        "no `if [[ ${failed} -gt 0 ]]` + return 1 pattern",
    )


def t9_wifi_substeps() -> None:
    """T9 (DW#7): wifi sub-steps — wpa_supplicant + nftables + ghp_mgmt_wifi + svc."""
    content = read_install_sh()
    has_all = (
        "WITH_WIFI" in content
        and "wpa_supplicant" in content
        and "nftables" in content
        and "ghp_mgmt_wifi" in content
        and "wpa_supplicant@mgmt0" in content
    )
    check(
        "T9 DW#7 wifi sub-steps present",
        has_all,
        "missing one of: WITH_WIFI / wpa_supplicant / nftables / ghp_mgmt_wifi / wpa_supplicant@mgmt0",
    )
    # Placeholder-aware skip
    has_placeholder = "__OPERATOR_SSID__" in content or "__OPERATOR_PSK" in content
    check(
        "T9 DW#7 wifi placeholder-aware skip present",
        has_placeholder,
        "no __OPERATOR_SSID__ / __OPERATOR_PSK placeholder gate",
    )


def t10_brain_pieces_substeps() -> None:
    """T10 (DW#8): brain-pieces sub-steps (rules/commands/agents/modes/skills)."""
    content = read_install_sh()
    # All five brain-piece dirs must appear in op_verify context
    # Look for the for-loop iterating over brain dirs
    has_loop = re.search(
        r"for brain_dir in rules commands agents modes", content
    ) is not None
    has_skills = "SKILL.md" in content and "skills" in content
    check(
        "T10 DW#8 brain-pieces loop covers rules/commands/agents/modes",
        has_loop,
        "no `for brain_dir in rules commands agents modes` loop in op_verify",
    )
    check(
        "T10 DW#8 brain-pieces includes skills/ (SKILL.md count)",
        has_skills,
        "no skills/ SKILL.md count sub-step",
    )


def t11_check_mode_runs_and_exits_structured() -> None:
    """T11: --check mode runs to completion; exit code is structured (0/1/3, not crash).

    On this dev host the project is NOT deployed to ~/.claude/, so we expect
    non-zero exit per NC-5 (RESOLVED). What we verify here:
      - Exit code is one of {0, 1, 3} (defined codes per install.sh USAGE)
      - stdout contains `verify: N/M passed` summary line (DW#6 evidence)
      - No bash crash (return code < 128, i.e., not a signal kill)
    """
    r = subprocess.run(
        [str(INSTALL_SH), "--check", "--profile", "base"],
        capture_output=True,
        text=True,
        cwd=str(PROJECT_ROOT),
        timeout=60,
    )
    rc = r.returncode
    check(
        "T11 --check exit code in defined set {0,1,3}",
        rc in (0, 1, 3),
        f"got exit code {rc} (expected 0, 1, or 3 per install.sh USAGE)",
    )
    combined = (r.stdout or "") + (r.stderr or "")
    check(
        "T11 --check emits `verify: N/M passed` summary line",
        re.search(r"verify:\s+\d+/\d+\s+passed", combined) is not None,
        "no `verify: N/M passed` line in --check output",
    )
    check(
        "T11 --check did not crash (rc < 128)",
        rc < 128,
        f"got exit code {rc} (>= 128 suggests signal kill)",
    )


def t12_hook_script_presence_substep() -> None:
    """T12: hook-script presence sub-step (policy-block / malware-block / leak-detector)."""
    content = read_install_sh()
    has_loop = (
        "policy-block.sh" in content
        and "malware-block.sh" in content
        and "leak-detector.sh" in content
    )
    check(
        "T12 hook-script presence sub-step covers all 3 critical hooks",
        has_loop,
        "missing one of policy-block.sh / malware-block.sh / leak-detector.sh",
    )


# ---------- Main ----------

def main() -> int:
    print(f"[T015-smoke] PROJECT_ROOT: {PROJECT_ROOT}")
    print(f"[T015-smoke] INSTALL_SH:   {INSTALL_SH}")
    print()

    t1_install_sh_exists_and_parses()
    t2_check_flag_declared()
    t3_op_verify_function_defined()
    t4_integrity_substep()
    t5_bridge_substep()
    t6_opencode_substep()
    t7_git_audit_substep()
    t8_exit_code_structure()
    t9_wifi_substeps()
    t10_brain_pieces_substeps()
    t11_check_mode_runs_and_exits_structured()
    t12_hook_script_presence_substep()

    print()
    total = len(PASSED) + len(FAILED)
    print(f"[T015-smoke] {len(PASSED)}/{total} tests passed")
    # Canonical summary line consumed by tools.run-tests' RESULT_RE
    # (^Result:\s*(\d+)/(\d+)). Without it the aggregate runner counts this
    # suite as 0/0 and silently drops its assertions from the total.
    print(f"Result: {len(PASSED)}/{total} passed")
    if FAILED:
        print(f"[T015-smoke] {len(FAILED)} failure(s):")
        for label, detail in FAILED:
            print(f"  - {label}: {detail}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
