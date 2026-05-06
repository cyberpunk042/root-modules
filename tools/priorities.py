"""tools.priorities — top-priorities imminent-work list (operator directive 2026-05-06).

Operator directive: *"my new STP file which would contain a list with
task-and/or-focus combo with priotities that should be identified as the
imminent work, even before the PM work.. again with commands and tools and
hook update and stuff"*.

Semantics:
    The priorities list captures the IMMINENT-work queue — items that take
    precedence over PM-decision-tier work (real blockers / Epic-pending /
    behavioral). It is the "what to drive RIGHT NOW" list. Surfaces in
    mode-enforcement banner + stamp + handoff doc.

    Each priority is free-form text: typically a task ID, focus phrase, or
    combo. Operator-authored. The agent surfaces; doesn't auto-promote.

State file: `$HOME/.claude/active-priorities`
    One priority per line. No JSON. Operator-editable directly.
    Order = priority (line 1 = highest priority).
    Empty file or missing = no priorities set.

Slash command: `/priorities <verb> [args]`
    add <text>      — append at lowest priority
    show            — display numbered list
    clear           — empty the list
    remove <N>      — drop priority N (1-based)
    promote <N>     — move priority N up one rank
    demote <N>      — move priority N down one rank
    set <text>      — replace entire list with single-line text (semicolon-separated for multi)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

PRIORITIES_PATH = Path.home() / ".claude" / "active-priorities"


def read_priorities() -> list[str]:
    if not PRIORITIES_PATH.exists():
        return []
    try:
        return [ln.strip() for ln in PRIORITIES_PATH.read_text().splitlines() if ln.strip()]
    except Exception:
        return []


def write_priorities(items: list[str]) -> None:
    PRIORITIES_PATH.parent.mkdir(parents=True, exist_ok=True)
    PRIORITIES_PATH.write_text("\n".join(items) + ("\n" if items else ""))


def cmd_add(args: argparse.Namespace) -> int:
    text = " ".join(args.text).strip()
    if not text:
        print("ERROR: text required for add", file=sys.stderr)
        return 2
    items = read_priorities()
    items.append(text)
    write_priorities(items)
    print(f"OK: priority P{len(items)} added: {text}")
    return 0


def cmd_show(args: argparse.Namespace) -> int:
    items = read_priorities()
    if not items:
        print("priorities: (none — no imminent work set)")
        return 0
    for i, item in enumerate(items, start=1):
        print(f"P{i}: {item}")
    return 0


def cmd_clear(args: argparse.Namespace) -> int:
    if PRIORITIES_PATH.exists():
        PRIORITIES_PATH.unlink()
        print(f"OK: priorities cleared ({PRIORITIES_PATH})")
    else:
        print(f"OK: priorities already empty ({PRIORITIES_PATH})")
    return 0


def cmd_remove(args: argparse.Namespace) -> int:
    items = read_priorities()
    n = args.n
    if n < 1 or n > len(items):
        print(f"ERROR: priority P{n} out of range (have {len(items)})", file=sys.stderr)
        return 2
    removed = items.pop(n - 1)
    write_priorities(items)
    print(f"OK: removed P{n}: {removed}")
    return 0


def cmd_promote(args: argparse.Namespace) -> int:
    items = read_priorities()
    n = args.n
    if n < 2 or n > len(items):
        print(f"ERROR: P{n} cannot be promoted (have {len(items)}, must be ≥2)", file=sys.stderr)
        return 2
    items[n - 2], items[n - 1] = items[n - 1], items[n - 2]
    write_priorities(items)
    print(f"OK: promoted P{n} → P{n-1}: {items[n - 2]}")
    return 0


def cmd_demote(args: argparse.Namespace) -> int:
    items = read_priorities()
    n = args.n
    if n < 1 or n >= len(items):
        print(f"ERROR: P{n} cannot be demoted (have {len(items)}, must be <{len(items)})", file=sys.stderr)
        return 2
    items[n - 1], items[n] = items[n], items[n - 1]
    write_priorities(items)
    print(f"OK: demoted P{n} → P{n+1}: {items[n]}")
    return 0


def cmd_set(args: argparse.Namespace) -> int:
    text = " ".join(args.text).strip()
    if not text:
        print("ERROR: text required for set", file=sys.stderr)
        return 2
    # Split on semicolon for multi-priority single-shot
    items = [p.strip() for p in text.split(";") if p.strip()]
    write_priorities(items)
    print(f"OK: priorities set ({len(items)} items)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Manage active-priorities imminent-work queue")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_add = sub.add_parser("add", help="append a priority")
    p_add.add_argument("text", nargs="+")
    p_add.set_defaults(func=cmd_add)

    p_show = sub.add_parser("show", help="display priorities list")
    p_show.set_defaults(func=cmd_show)

    p_clear = sub.add_parser("clear", help="empty priorities list")
    p_clear.set_defaults(func=cmd_clear)

    p_remove = sub.add_parser("remove", help="drop priority N")
    p_remove.add_argument("n", type=int)
    p_remove.set_defaults(func=cmd_remove)

    p_promote = sub.add_parser("promote", help="move priority N up one rank")
    p_promote.add_argument("n", type=int)
    p_promote.set_defaults(func=cmd_promote)

    p_demote = sub.add_parser("demote", help="move priority N down one rank")
    p_demote.add_argument("n", type=int)
    p_demote.set_defaults(func=cmd_demote)

    p_set = sub.add_parser("set", help="replace list (semicolon-separated for multi)")
    p_set.add_argument("text", nargs="+")
    p_set.set_defaults(func=cmd_set)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
