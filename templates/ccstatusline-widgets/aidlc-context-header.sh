#!/usr/bin/env bash
# aidlc-context-header.sh — context-aware header for line 1.
#
# When the calling session is root-modules → exit empty (let the existing
# /root-specific widgets fill line 1: Mode / Task / SFIF / Stage / Bugs / etc).
#
# When the calling session is a sister project (e.g. /opt second-brain) →
# render a short identifier so line 1 isn't collapsed empty. SB-103 fix gated
# the /root-specific widgets out of sister sessions; this widget fills the gap
# with context-correct info.
#
# Output examples:
#   $HOME context       → ""  (empty; other widgets fill line 1)
#   /opt second-brain   → "[ devops-solutions-information-hub · second-brain ]"
#   other sister        → "[ <basename of CLAUDE_PROJECT_DIR> ]"

set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/_lib.sh"

# In $HOME context: do nothing. The existing line-1 AIDLC widgets render here.
if rgp_is_in_root_context; then
    exit 0
fi

# Sister-project context: render a short identifier from CLAUDE_PROJECT_DIR.
proj="${CLAUDE_PROJECT_DIR:-}"
proj="${proj%/}"
if [[ -z "${proj}" ]]; then
    # No CLAUDE_PROJECT_DIR — render minimal "(unknown context)" rather than
    # collapse silently, so operator sees something rather than blank line.
    printf '[ unknown-context ]'
    exit 0
fi

basename="${proj##*/}"

# Special-case the second-brain (canonical sister) for clearer identification.
if [[ "${basename}" == "devops-solutions-information-hub" ]]; then
    printf '[ %s · second-brain ]' "${basename}"
else
    printf '[ %s ]' "${basename}"
fi
