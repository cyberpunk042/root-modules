#!/usr/bin/env bash
# scripts/lib/security-scan.sh — security flag detection for merge inputs.
#
# Scans candidate-merge content (permission entries, custom hooks, opencode
# keys, .gitignore lines) for patterns that warrant operator review before
# being merged into the working tree.
#
# Functions return non-zero if flags are found; output flags to stdout (one
# per line, format: "<severity>\t<category>\t<detail>").
#
# Severities: HIGH (blocks apply unless --accept-security-flags) | MED (warns) | LOW (informational)
#
# Requires: lib/common.sh sourced first.
#
# Re-source guard:
[ -n "${RM_LIB_SECURITY_SCAN_SOURCED:-}" ] && return 0
RM_LIB_SECURITY_SCAN_SOURCED=1

# scan_permission_entries <permission-list-as-jsonl-or-text>
#   Reads from stdin: one permission entry per line.
#   Outputs flags to stdout, one per line. Returns 0 if clean, 1 if flags found.
scan_permission_entries() {
  local found=0
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    # Strip leading/trailing whitespace + JSON quotes if present
    entry=$(echo "$entry" | sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//; s/,$//')
    [ -z "$entry" ] && continue

    # HIGH: unbounded wildcards on dangerous tools
    if echo "$entry" | grep -qE '^(Bash|Write|Edit|NotebookEdit)\(\*\)$'; then
      printf "HIGH\tperm-unbounded-wildcard\t%s\n" "$entry"; found=1; continue
    fi
    if echo "$entry" | grep -qE '^Bash\(rm[[:space:]]+-[a-zA-Z]*r'; then
      printf "HIGH\tperm-rm-recursive\t%s\n" "$entry"; found=1; continue
    fi
    if echo "$entry" | grep -qE '^Bash\((sudo|su)[[:space:]]'; then
      printf "HIGH\tperm-privilege-elevation\t%s\n" "$entry"; found=1; continue
    fi
    if echo "$entry" | grep -qE '^Bash\(curl[^|;]*\|.*sh\)'; then
      printf "HIGH\tperm-curl-pipe-shell\t%s\n" "$entry"; found=1; continue
    fi

    # MED: paths to system directories
    if echo "$entry" | grep -qE '^Write\((/(etc|usr|boot|lib|sbin|var)/'; then
      printf "MED\tperm-system-path-write\t%s\n" "$entry"; found=1; continue
    fi
    if echo "$entry" | grep -qE '^Edit\((/(etc|usr|boot|lib|sbin|var)/'; then
      printf "MED\tperm-system-path-edit\t%s\n" "$entry"; found=1; continue
    fi

    # MED: broad WebFetch domains (e.g., *.com)
    if echo "$entry" | grep -qE '^WebFetch\(domain:\*'; then
      printf "MED\tperm-broad-webfetch\t%s\n" "$entry"; found=1; continue
    fi

    # LOW: unrecognized but plausible patterns
    # (no flag — informational only; could log but skip for now)
  done
  [ "$found" = "1" ] && return 1 || return 0
}

# scan_opencode_unique_keys <backup-opencode.json> <repo-opencode.json>
#   Detects unique-keys whose values look like credentials.
#   Outputs flags. Returns 0 if clean, 1 if flags found.
scan_opencode_unique_keys() {
  local bak="$1" cur="$2"
  python3 - "$bak" "$cur" <<'PYEOF'
import json, re, sys
bak = json.load(open(sys.argv[1]))
cur = json.load(open(sys.argv[2]))
b_keys = set(bak.keys()) if isinstance(bak, dict) else set()
c_keys = set(cur.keys()) if isinstance(cur, dict) else set()

# Patterns suggestive of credentials in values
CRED_VALUE_RE = re.compile(
    r'^(sk_|sk-|gh_|ghp_|gho_|ghs_|xox[abprs]-|AKIA[0-9A-Z]{16}|AIzaSy|hf_|nvapi-|Bearer\s)|'
    r'^[A-Za-z0-9+/]{40,}={0,2}$|'  # base64-ish long string
    r'^[a-fA-F0-9]{32,}$'           # hex token
)

flags = []
for k in sorted(b_keys - c_keys):
    v = bak[k]
    s = json.dumps(v) if not isinstance(v, str) else v
    if CRED_VALUE_RE.search(s):
        flags.append(f"HIGH\tope-cred-shape\t{k}: <{len(s)} char value matching credential pattern>")
    elif isinstance(v, str) and any(t in k.lower() for t in ("token", "key", "secret", "password", "credential", "apikey", "api_key")):
        flags.append(f"HIGH\tope-cred-keyname\t{k}: {len(v)} char string in credential-named key")

for f in flags:
    print(f)

sys.exit(1 if flags else 0)
PYEOF
}

# scan_gitignore_additions <unique-lines>
#   Reads unique non-comment lines from stdin.
#   Detects entries that would un-deny patterns repo's deny-all is calibrated to catch.
#   Outputs flags. Returns 0 if clean, 1 if flags found.
scan_gitignore_additions() {
  local found=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue

    # HIGH: explicit un-deny of secret patterns that the repo's hard-deny section blocks
    if echo "$line" | grep -qE '^!.*\.(env|pem|key|crt|p12|pfx)$'; then
      printf "HIGH\tgi-undeny-secrets\t%s\n" "$line"; found=1; continue
    fi
    if echo "$line" | grep -qE '^!.*credentials'; then
      printf "HIGH\tgi-undeny-credentials\t%s\n" "$line"; found=1; continue
    fi
    if echo "$line" | grep -qE '^!.*\.ssh|^!\.ssh'; then
      printf "HIGH\tgi-undeny-ssh\t%s\n" "$line"; found=1; continue
    fi

    # MED: broad allows that might pull in unintended content
    if echo "$line" | grep -qE '^!.*\*$'; then
      printf "MED\tgi-broad-allow\t%s\n" "$line"; found=1; continue
    fi

    # LOW: anything else — informational
  done
  [ "$found" = "1" ] && return 1 || return 0
}

# scan_custom_hook_file <path>
#   Reads file content, looks for patterns suggestive of unsafe behavior.
#   Outputs flags. Returns 0 if clean, 1 if flags found.
scan_custom_hook_file() {
  local f="$1"
  [ -f "$f" ] || return 0
  local found=0
  local base
  base=$(basename "$f")

  # HIGH: curl|sh in hook
  if grep -qE '(curl|wget|fetch)[^|;]*\|[[:space:]]*(bash|sh|python3?|perl|ruby)' "$f" 2>/dev/null; then
    printf "HIGH\thook-curl-pipe-shell\t%s\n" "$base"; found=1
  fi
  # HIGH: reverse shell shapes
  if grep -qE '/dev/(tcp|udp)/' "$f" 2>/dev/null; then
    printf "HIGH\thook-rev-shell\t%s\n" "$base"; found=1
  fi
  # HIGH: history wipe
  if grep -qE 'history[[:space:]]+-c|HISTFILE=/dev/null' "$f" 2>/dev/null; then
    printf "HIGH\thook-history-wipe\t%s\n" "$base"; found=1
  fi
  # MED: writes to system paths
  if grep -qE '>[[:space:]]*/(etc|usr|boot|lib|sbin)' "$f" 2>/dev/null; then
    printf "MED\thook-system-write\t%s\n" "$base"; found=1
  fi
  # MED: PATH manipulation
  if grep -qE 'export[[:space:]]+PATH=' "$f" 2>/dev/null; then
    printf "MED\thook-path-mutation\t%s\n" "$base"; found=1
  fi

  [ "$found" = "1" ] && return 1 || return 0
}

# format_flags_summary
#   Reads flags from stdin (severity\tcategory\tdetail per line).
#   Counts + prints a summary.
format_flags_summary() {
  local high=0 med=0 low=0
  local flags_out
  flags_out=$(cat)
  if [ -z "$flags_out" ]; then
    return 0
  fi
  while IFS=$'\t' read -r sev cat detail; do
    case "$sev" in
      HIGH) high=$((high+1)) ;;
      MED)  med=$((med+1)) ;;
      LOW)  low=$((low+1)) ;;
    esac
    say "  [$sev] [$cat] $detail"
  done <<< "$flags_out"
  say ""
  say "  Flag summary: $high HIGH, $med MED, $low LOW"
  if [ "$high" -gt 0 ]; then
    return 2  # caller blocks apply
  elif [ "$med" -gt 0 ]; then
    return 1  # caller warns + asks confirmation
  else
    return 0
  fi
}
