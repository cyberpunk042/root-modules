#!/usr/bin/env bash
# $HOME/templates/ccstatusline-widgets/stage.sh
# ccstatusline Custom Text widget data source — root-modules "SFIF stage" field.
#
# Output: the active SFIF stage name (e.g., "Foundation") or "?".
# Source: tools.state --field active-sfif-stage OR derived from progress.json.
#
# Per M011 T064. Stage: scaffold (preliminary).

set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"


readonly TOOLS_PYTHON="$(rgp_resolve_python)"
readonly TOOLS_DIR="$(rgp_resolve_project)"

if [[ -x "${TOOLS_PYTHON}" ]] && [[ -f "${TOOLS_DIR}/tools/progress.py" ]]; then
    cd "${TOOLS_DIR}" || exit 0
    stage=$("${TOOLS_PYTHON}" -c "
import json, sys, subprocess
try:
    out = subprocess.check_output([sys.executable, '-m', 'tools.progress', '--json'], stderr=subprocess.DEVNULL)
    p = json.loads(out)
    mods = p.get('modules', {}).get('list', [])
    if mods:
        for m in mods:
            if m.get('status') in ('in-progress', 'done'):
                print(m.get('sfif', ''))
                break
        else:
            print(mods[0].get('sfif', ''))
except Exception:
    pass" 2>/dev/null || true)
    if [[ -n "${stage:-}" ]]; then
        printf 'Stage: %s' "${stage}"
        exit 0
    fi
fi

# Fallback: parse <project>/CONTEXT.md Phase row (col 3 of markdown table)
CTX_FILE="${TOOLS_DIR}/CONTEXT.md"
if [[ -f "${CTX_FILE}" ]]; then
    phase=$(awk -F'|' '/\*\*Phase\*\*/ {
        gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", $3);
        print $3; exit
    }' "${CTX_FILE}" 2>/dev/null)
    if [[ -n "${phase:-}" ]]; then printf 'Stage: %s' "${phase}"; exit 0; fi
fi

printf 'Stage: ?'
