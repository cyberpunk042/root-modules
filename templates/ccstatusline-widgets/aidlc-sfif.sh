#!/usr/bin/env bash
# aidlc-sfif.sh — active SFIF tier (Scaffold/Foundation/Infrastructure/Features) at project level.
# Output: "SFIF:Foundation" / "SFIF:Scaffold" / "SFIF:?"
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

readonly TOOLS_PYTHON="$(rm_resolve_python)"
readonly TOOLS_DIR="$(rm_resolve_project)"

# Path 1: tools.progress with module-derived SFIF tier (works for $HOME)
if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/progress.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    stage=$("${TOOLS_PYTHON}" -c "
import json, subprocess, sys
try:
    out = subprocess.check_output([sys.executable, '-m', 'tools.progress', '--json'], stderr=subprocess.DEVNULL)
    p = json.loads(out)
    mods = p.get('modules', {}).get('list', [])
    tiers = ['Scaffold', 'Scaffold-Design', 'Foundation', 'Infrastructure', 'Features']
    seen = set()
    for m in mods:
        sf = m.get('sfif', '')
        if m.get('status') in ('in-progress', 'done'):
            seen.add(sf)
    if seen:
        for t in reversed(tiers):
            if t in seen: print(t); break
        else:
            print(next(iter(seen)))
    elif mods:
        print(mods[0].get('sfif', ''))
except Exception:
    pass" 2>/dev/null || true)
    if [[ -n "${stage:-}" ]]; then printf 'SFIF: %s' "${stage}"; exit 0; fi
fi

# Path 2: parse <project>/CONTEXT.md Phase row (col 2 of the markdown table).
# Works for /opt second-brain which has `| **Phase** | production | ... |`.
CTX_FILE="${TOOLS_DIR}/CONTEXT.md"
if [[ -f "${CTX_FILE}" ]]; then
    phase=$(awk -F'|' '/\*\*Phase\*\*/ {
        # col 3 (0-indexed: $3) is the value (col 1=before-first-pipe is empty, $2="**Phase**", $3=value)
        gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $3);
        print $3; exit
    }' "${CTX_FILE}" 2>/dev/null)
    if [[ -n "${phase:-}" ]]; then printf 'SFIF: %s' "${phase}"; exit 0; fi
fi

printf 'SFIF: ?'
