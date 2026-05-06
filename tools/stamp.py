"""tools.stamp — persistent stamp config (SB-115 redesign of SB-114 marker approach).

Replaces the failed `!stamp=...` prompt-marker mechanism with deterministic
slash-command-driven config. Slash commands invoke this tool; tool writes to
`/root/.claude/stamp-config.json`; end-of-cycle-stamp.sh reads it on Stop event.

Schema of stamp-config.json:
    {
      "layout": "horizontal" | "vertical",     # default: vertical
      "enabled": "on" | "off" | "auto"         # default: auto (mode-conditional)
    }

Semantics of `enabled`:
    "on"   — stamp always renders (even with no active-mode)
    "off"  — stamp never renders
    "auto" — stamp renders ONLY when /root/.claude/active-mode is non-empty
             (per SB-114 sub-req c: default-hide-when-no-mode)

Layout `horizontal` selects --ansi-horizontal output; `vertical` selects --ansi-fence.

Slash commands in /root/.claude/commands/ (thin wrappers):
    /stamp-horizontal → set layout=horizontal
    /stamp-vertical   → set layout=vertical
    /stamp-on         → set enabled=on
    /stamp-off        → set enabled=off
    /stamp-auto       → set enabled=auto (default mode-conditional)
    /stamp-status     → show current config
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
}

VALID_LAYOUTS = {"horizontal", "vertical"}
VALID_ENABLED = {"on", "off", "auto"}


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
    return 0


def cmd_clear(args: argparse.Namespace) -> int:
    if CONFIG_PATH.exists():
        CONFIG_PATH.unlink()
        print(f"OK: stamp config cleared (defaults will apply): {CONFIG_PATH}")
    else:
        print(f"OK: stamp config already absent: {CONFIG_PATH}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage root-ghostproxy stamp render config")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_set = sub.add_parser("configure", help="configure layout and/or enabled fields")
    p_set.add_argument("--layout", choices=sorted(VALID_LAYOUTS))
    p_set.add_argument("--enabled", choices=sorted(VALID_ENABLED))
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
