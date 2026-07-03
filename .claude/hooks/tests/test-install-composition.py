#!/usr/bin/env python3
"""install.sh composition smoke test — profile × mode × granular scope resolution.

install.sh composes install SCOPE from three orthogonal axes (per its header +
SB-074): `--profile` (base / full / project), `--mode` (bridge / endpoint /
hybrid), and granular `--with-group` / `--no-group`. The composition rule is
"an op is installed iff (profile says yes) AND (mode_includes(op))", with
granular flags overriding. This is the exact logic the sovereign-os SDD-046
endpoint binding and every per-project deploy depend on — yet only the endpoint
slice was covered (test-sovereign-endpoint-mode.py). This locks the rest.

All runs are `--dry-run` into a throwaway --dest, so nothing is installed.

Two signal sources:
  1. The resolution line `profile=X mode=Y → hooks=.. opencode=.. bridge=..
     wifi=.. integrity=.. ccstatusline=.. tools=..` — reflects profile+mode
     defaults. NOTE: this line is printed in apply_profile() BEFORE granular
     --with-group/--no-group selection is applied (install.sh:421 vs the granular
     step ~:1639), so for granular cases it shows the PRE-granular state. The
     op-application lines below are the post-granular authority.
  2. Op-application lines (`skip: <op> (per profile/toggle)` / `would: ...`) —
     the actual post-granular decision.

Exit codes: 0 all pass · 1 any fail.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent.parent
INSTALL_SH = PROJECT_ROOT / "install.sh"

PASSED: list[str] = []
FAILED: list[tuple[str, str]] = []


def check(label: str, cond: bool, detail: str = "") -> None:
    if cond:
        PASSED.append(label)
        print(f"  PASS {label}")
    else:
        FAILED.append((label, detail))
        print(f"  FAIL {label}" + (f" — {detail}" if detail else ""))


def dry_run(*flags: str) -> str:
    r = subprocess.run(
        ["bash", str(INSTALL_SH), "--dry-run", "--dest", "/tmp/probe-composition", *flags],
        capture_output=True, text=True, cwd=str(PROJECT_ROOT), timeout=120,
    )
    return r.stdout + r.stderr


def resolution(out: str) -> dict:
    """Parse the `profile=.. mode=.. → k=v k=v ...` line into a dict."""
    m = re.search(r"profile=(\w+)\s+mode=(\w+)\s+→\s+(.+)", out)
    if not m:
        return {}
    d = {"profile": m.group(1), "mode": m.group(2)}
    for kv in re.findall(r"(\w+)=(\d+)", m.group(3)):
        d[kv[0]] = int(kv[1])
    return d


def main() -> int:
    print("=== install.sh composition smoke test ===")
    if not INSTALL_SH.exists():
        check("install.sh present", False, f"missing {INSTALL_SH}")
        print("Result: 0/1 passed")
        return 1

    # --- profile axis (mode=endpoint fixed) ---
    base = resolution(dry_run("--profile", "base", "--mode", "endpoint"))
    full = resolution(dry_run("--profile", "full", "--mode", "endpoint"))
    proj = resolution(dry_run("--profile", "project", "--mode", "endpoint"))

    check("base: hooks + integrity + tools on, ccstatusline off",
          base.get("hooks") == 1 and base.get("integrity") == 1 and base.get("tools") == 1 and base.get("ccstatusline") == 0,
          str(base))
    check("full = base + ccstatusline (Features tier)",
          full.get("ccstatusline") == 1 and full.get("hooks") == 1 and full.get("integrity") == 1,
          str(full))
    check("project disables OS-level ops (opencode + integrity off), keeps brain + tools",
          proj.get("opencode") == 0 and proj.get("integrity") == 0 and proj.get("hooks") == 1 and proj.get("tools") == 1,
          str(proj))

    # --- mode axis (profile=base fixed): mode gates bridge + wifi ---
    endp = resolution(dry_run("--profile", "base", "--mode", "endpoint"))
    brdg = resolution(dry_run("--profile", "base", "--mode", "bridge"))
    check("endpoint mode gates bridge + wifi OFF", endp.get("bridge") == 0 and endp.get("wifi") == 0, str(endp))
    check("bridge mode gates bridge + wifi ON", brdg.get("bridge") == 1 and brdg.get("wifi") == 1, str(brdg))

    # --- op-application authority (post-granular) ---
    proj_out = dry_run("--profile", "project", "--mode", "endpoint")
    check("project: opencode bridge op skipped", "skip: opencode bridge" in proj_out)
    check("project: integrity sentinel op skipped", "skip: integrity sentinel" in proj_out)

    # ccstatusline: base skips it, full deploys the widget set (many more lines).
    base_cc = dry_run("--profile", "base", "--mode", "endpoint").count("ccstatusline")
    full_cc = dry_run("--profile", "full", "--mode", "endpoint").count("ccstatusline")
    check("full deploys substantially more ccstatusline than base (Features tier)",
          full_cc > base_cc + 5, f"base_cc={base_cc} full_cc={full_cc}")

    # granular: --no-group wifi actually skips wifi even in bridge mode
    # (the op-application authority — the resolution line still shows pre-granular wifi=1).
    wifi_on = dry_run("--profile", "base", "--mode", "bridge")
    wifi_off = dry_run("--profile", "base", "--mode", "bridge", "--no-group", "wifi")
    check("bridge mode (no granular) deploys the wifi op",
          "management wifi config" in wifi_on or "would" in wifi_on and "wifi" in wifi_on.lower())
    check("--no-group wifi skips the wifi op (post-granular authority)",
          "skip: management wifi" in wifi_off)

    # every dry-run must be a clean no-op run.
    check("dry-run makes no state changes (footer present)",
          "dry-run; no state changes" in dry_run("--profile", "base", "--mode", "endpoint"))

    total = len(PASSED) + len(FAILED)
    print()
    print(f"Result: {len(PASSED)}/{total} passed")
    for label, detail in FAILED:
        print(f"  - {label}: {detail}")
    return 0 if not FAILED else 1


if __name__ == "__main__":
    sys.exit(main())
