#!/usr/bin/env bash
# scripts/lib/json-merge.sh — JSON validation + atomic stage-then-swap +
# additive merge primitives.
#
# All merges follow the SURGICAL pattern:
#   1. Stage proposed result to <target>.merged
#   2. Validate JSON (refuse to swap if invalid)
#   3. Atomic swap with <target>.pre-merge.bak preservation of prior version
#
# Requires: lib/common.sh sourced first (uses ok/warn/info/fail).
#
# Re-source guard:
[ -n "${RM_LIB_JSON_MERGE_SOURCED:-}" ] && return 0
RM_LIB_JSON_MERGE_SOURCED=1

# validate_json <file>
#   Returns 0 if valid JSON, non-zero otherwise.
validate_json() {
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$1" 2>/dev/null
}

# stage_swap <staged-file> <target-file>
#   Validates staged (if .json), preserves target as <target>.pre-merge.bak,
#   then mv staged → target. Refuses to swap if validation fails.
#   Returns: 0 on success, 1 on validation failure.
stage_swap() {
  local staged="$1" target="$2"

  case "$target" in
    *.json)
      if ! validate_json "$staged"; then
        warn "VALIDATION FAILED: staged $staged is not valid JSON. Refusing to swap."
        return 1
      fi
      ;;
  esac

  local pre_merge="$target.pre-merge.bak"
  if [ -f "$target" ]; then
    cp -a "$target" "$pre_merge"
  fi
  mv "$staged" "$target"
  ok "swapped: $target (prior version preserved at $pre_merge)"
  return 0
}

# permissions_union_settings <backup-settings.json> <repo-settings.json> <output-staged.json>
#   Produces a merged settings.json with permissions.allow/deny/ask UNIONS
#   from backup + repo (additive only). Hooks block + other keys: repo wins.
#   Use stage_swap afterward to atomically place + validate.
permissions_union_settings() {
  local bak="$1" cur="$2" out="$3"
  python3 - "$bak" "$cur" "$out" <<'PYEOF'
import json, sys
bak = json.load(open(sys.argv[1]))
cur = json.load(open(sys.argv[2]))
out = json.loads(json.dumps(cur))  # start from repo's
out_perms = out.setdefault("permissions", {})
bak_perms = bak.get("permissions", {}) or {}
for sub in ("allow", "deny", "ask"):
    bl = bak_perms.get(sub, []) or []
    cl = out_perms.get(sub, []) or []
    union = list(cl)
    for item in bl:
        if item not in union:
            union.append(item)
    if union:
        out_perms[sub] = union
json.dump(out, open(sys.argv[3], "w"), indent=2)
PYEOF
}

# operator_unique_keys_opencode <backup-opencode.json> <repo-opencode.json> <output-staged.json>
#   Produces a merged opencode.json: starts from repo's, copies any top-level
#   keys present in backup but not in repo (operator's customizations the repo
#   doesn't manage). Repo-managed keys (mcp, plugin) are NEVER overridden.
operator_unique_keys_opencode() {
  local bak="$1" cur="$2" out="$3"
  python3 - "$bak" "$cur" "$out" <<'PYEOF'
import json, sys
bak = json.load(open(sys.argv[1]))
cur = json.load(open(sys.argv[2]))
out = json.loads(json.dumps(cur))
for k, v in bak.items():
    if k not in out:
        out[k] = v
json.dump(out, open(sys.argv[3], "w"), indent=2)
PYEOF
}

# diff_settings <backup-settings.json> <repo-settings.json>
#   Prints per-key analysis (no mutation). Used by --diff mode.
diff_settings() {
  local bak="$1" cur="$2"
  python3 - "$bak" "$cur" <<'PYEOF'
import json, sys
bak = json.load(open(sys.argv[1]))
cur = json.load(open(sys.argv[2]))

def keys(d): return set(d.keys()) if isinstance(d, dict) else set()
b_keys, c_keys = keys(bak), keys(cur)

print("    backup keys:", sorted(b_keys))
print("    repo   keys:", sorted(c_keys))
print("    only in backup:", sorted(b_keys - c_keys), "  ← would merge into $HOME if applied")
print("    only in repo  :", sorted(c_keys - b_keys), "  ← came from repo (additive, no conflict)")
print("    in both       :", sorted(b_keys & c_keys), "  ← per-key review below")

for key in sorted(b_keys & c_keys):
    b, c = bak[key], cur[key]
    if b == c:
        print(f"    [{key}] identical in both — no action needed")
    elif key == "permissions" and isinstance(b, dict) and isinstance(c, dict):
        for sub in ("allow", "deny", "ask"):
            bl = b.get(sub, []) or []
            cl = c.get(sub, []) or []
            unique_to_bak = [x for x in bl if x not in cl]
            unique_to_cur = [x for x in cl if x not in bl]
            if unique_to_bak:
                print(f"    [{key}.{sub}] {len(unique_to_bak)} item(s) ONLY in backup (would be added if applied):")
                for item in unique_to_bak[:5]:
                    print(f"        + {item}")
                if len(unique_to_bak) > 5:
                    print(f"        ... and {len(unique_to_bak) - 5} more")
            if unique_to_cur:
                print(f"    [{key}.{sub}] {len(unique_to_cur)} item(s) only in repo (already present, no action)")
    elif key == "hooks":
        print(f"    [{key}] DIFFERS. Repo's hooks are source of truth. Manual review required if you customized hooks.")
        print(f"        backup hooks structure: {sorted(b.keys()) if isinstance(b, dict) else type(b).__name__}")
        print(f"        repo   hooks structure: {sorted(c.keys()) if isinstance(c, dict) else type(c).__name__}")
    else:
        print(f"    [{key}] DIFFERS — operator decision (no auto-merge for this key)")
        bs = json.dumps(b)[:80]
        cs = json.dumps(c)[:80]
        print(f"        backup: {bs}{'...' if len(json.dumps(b)) > 80 else ''}")
        print(f"        repo  : {cs}{'...' if len(json.dumps(c)) > 80 else ''}")
PYEOF
}

# diff_opencode <backup-opencode.json> <repo-opencode.json>
diff_opencode() {
  local bak="$1" cur="$2"
  python3 - "$bak" "$cur" <<'PYEOF'
import json, sys
bak = json.load(open(sys.argv[1]))
cur = json.load(open(sys.argv[2]))

b_keys = set(bak.keys()) if isinstance(bak, dict) else set()
c_keys = set(cur.keys()) if isinstance(cur, dict) else set()
print("    backup keys:", sorted(b_keys))
print("    repo   keys:", sorted(c_keys))

unique_to_bak = sorted(b_keys - c_keys)
if unique_to_bak:
    print(f"    {len(unique_to_bak)} key(s) ONLY in backup (operator customizations):")
    for k in unique_to_bak:
        v = bak[k]
        preview = json.dumps(v)[:80]
        print(f"        {k}: {preview}{'...' if len(json.dumps(v)) > 80 else ''}")
PYEOF
}
