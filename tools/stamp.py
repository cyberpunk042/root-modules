"""tools.stamp — persistent stamp config (SB-115 redesign of SB-114 marker approach).

Replaces the failed `!stamp=...` prompt-marker mechanism with deterministic
slash-command-driven config. Slash commands invoke this tool; tool writes to
`$HOME/.claude/stamp-config.json`; end-of-cycle-stamp.sh reads it on Stop event.

Schema of stamp-config.json:
    {
      "layout":  "horizontal" | "vertical",            # default: vertical
      "enabled": "on" | "off" | "auto",                # default: auto (mode-conditional)
      "density": "minified" | "standard" | "extended"  # default: standard (SB-124c)
    }

Semantics of `enabled`:
    "on"   — stamp always renders (even with no active-mode)
    "off"  — stamp never renders
    "auto" — stamp renders ONLY when $HOME/.claude/active-mode is non-empty
             (per SB-114 sub-req c: default-hide-when-no-mode)

Layout `horizontal` selects --ansi-horizontal output; `vertical` selects --ansi-fence.

Semantics of `density` (SB-124c profile-variants per operator directive 2026-05-06:
    *"we can also create configuration of profiles too ? like one that is more
    minified ? or less minified ? for different resolution and such"*):
    "minified" — drop Journey + Plan rows; keep Status + Tracker + Cursor +
                 Mission/Focus/Impediment + (top 2) Priorities. Suits narrow terminals.
    "standard" — current default; all rows visible.
    "extended" — adds extra detail (full priority list, recent commits inline, more SBs).

Slash commands in $HOME/.claude/commands/ (thin wrappers):
    /stamp-horizontal → set layout=horizontal
    /stamp-vertical   → set layout=vertical
    /stamp-on         → set enabled=on
    /stamp-off        → set enabled=off
    /stamp-auto       → set enabled=auto (default mode-conditional)
    /stamp-status     → show current config

Composes-with:
- Slash commands: 6 /stamp-* (this tool's primary consumers; thin wrappers above)
- Hooks: end-of-cycle-stamp.sh (Stop event) reads stamp-config.json each fire to decide
  layout + enabled; this is the runtime consumer
- MCP: not wired (config-mutation surface; operator-only)

Config-file: $HOME/.claude/stamp-config.json (JSON; written by configure subcommand;
read by end-of-cycle-stamp.sh). Operator-editable directly with same schema.

Idempotency invariant: configure writes whole-file JSON (one key change at a time);
re-run with same args = same content. No incremental state to corrupt.

Action vocabulary (Hard Rule 14): emits `operator-directive-register` (configure path)
OR `read-only-audit` (show path) per Hard Rule 14 + the M-E001-1 vocabulary at
wiki/log/2026-05-06-181500-auto-pilot-action-vocabulary-draft.md.

Test file: implicit (stamp config + render exercised in real-session render).

Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".claude" / "stamp-config.json"

DEFAULT_CONFIG: dict = {
    "layout": "vertical",
    "enabled": "auto",
    "density": "standard",
    "highlight_deltas": False,
}

VALID_LAYOUTS = {"horizontal", "vertical"}
VALID_ENABLED = {"on", "off", "auto"}
VALID_DENSITY = {"minified", "standard", "extended"}
VALID_HIGHLIGHT_DELTAS = {"true", "false"}  # CLI string form; coerced to bool in cmd_set


def load_config() -> dict:
    if CONFIG_PATH.exists():
        try:
            data = json.loads(CONFIG_PATH.read_text())
            if isinstance(data, dict):
                merged = {**DEFAULT_CONFIG, **data}
                # Validate
                if merged.get("layout") not in VALID_LAYOUTS:
                    merged["layout"] = DEFAULT_CONFIG["layout"]
                if merged.get("enabled") not in VALID_ENABLED:
                    merged["enabled"] = DEFAULT_CONFIG["enabled"]
                if merged.get("density") not in VALID_DENSITY:
                    merged["density"] = DEFAULT_CONFIG["density"]
                return merged
        except Exception:
            pass
    return dict(DEFAULT_CONFIG)


def save_config(cfg: dict) -> None:
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(cfg, indent=2) + "\n")


def cmd_set(args: argparse.Namespace) -> int:
    cfg = load_config()
    changed = []
    if args.layout:
        if args.layout not in VALID_LAYOUTS:
            print(f"ERROR: --layout must be one of {sorted(VALID_LAYOUTS)}", file=sys.stderr)
            return 2
        if cfg.get("layout") != args.layout:
            cfg["layout"] = args.layout
            changed.append(f"layout → {args.layout}")
    if args.enabled:
        if args.enabled not in VALID_ENABLED:
            print(f"ERROR: --enabled must be one of {sorted(VALID_ENABLED)}", file=sys.stderr)
            return 2
        if cfg.get("enabled") != args.enabled:
            cfg["enabled"] = args.enabled
            changed.append(f"enabled → {args.enabled}")
    if getattr(args, "density", None):
        if args.density not in VALID_DENSITY:
            print(f"ERROR: --density must be one of {sorted(VALID_DENSITY)}", file=sys.stderr)
            return 2
        if cfg.get("density") != args.density:
            cfg["density"] = args.density
            changed.append(f"density → {args.density}")
    if getattr(args, "highlight_deltas", None) is not None:
        if args.highlight_deltas not in VALID_HIGHLIGHT_DELTAS:
            print(f"ERROR: --highlight-deltas must be one of {sorted(VALID_HIGHLIGHT_DELTAS)}", file=sys.stderr)
            return 2
        new_val = args.highlight_deltas == "true"
        if cfg.get("highlight_deltas") != new_val:
            cfg["highlight_deltas"] = new_val
            changed.append(f"highlight_deltas → {new_val}")
    save_config(cfg)
    if changed:
        print(f"OK: stamp config updated ({', '.join(changed)}) at {CONFIG_PATH}")
    else:
        print(f"OK: stamp config unchanged (already at requested values) at {CONFIG_PATH}")
    print(f"Current: {json.dumps(cfg)}")
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    cfg = load_config()
    if args.json:
        print(json.dumps(cfg, indent=2))
    else:
        print(f"Stamp config ({CONFIG_PATH}):")
        print(f"  layout:  {cfg['layout']}  (horizontal=compact 6-line | vertical=stacked sections)")
        print(f"  enabled: {cfg['enabled']}  (on=always | off=never | auto=mode-conditional)")
        print(f"  density: {cfg.get('density', 'standard')}  (minified=narrow-terminal | standard=full | extended=detail-heavy) [SB-124c]")
    return 0


def cmd_clear(args: argparse.Namespace) -> int:
    if CONFIG_PATH.exists():
        CONFIG_PATH.unlink()
        print(f"OK: stamp config cleared (defaults will apply): {CONFIG_PATH}")
    else:
        print(f"OK: stamp config already absent: {CONFIG_PATH}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage root-modules stamp render config")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_set = sub.add_parser("configure", help="configure layout and/or enabled fields")
    p_set.add_argument("--layout", choices=sorted(VALID_LAYOUTS))
    p_set.add_argument("--enabled", choices=sorted(VALID_ENABLED))
    p_set.add_argument("--density", choices=sorted(VALID_DENSITY))
    p_set.add_argument("--highlight-deltas", choices=sorted(VALID_HIGHLIGHT_DELTAS), help="enable per-row delta highlighting (T067)")
    p_set.set_defaults(func=cmd_set)

    p_show = sub.add_parser("show", help="show current config")
    p_show.add_argument("--json", action="store_true", help="emit JSON")
    p_show.set_defaults(func=cmd_show)

    p_clear = sub.add_parser("clear", help="reset to defaults (delete config file)")
    p_clear.set_defaults(func=cmd_clear)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
