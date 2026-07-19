"""tools.group — chain / group / tree composition primitive (E003 Layer A).

DRAFT v1 — agent-authored 2026-05-06 per Q1 resolution path step-4 (Layer A primitive
implementation). Spec at wiki/log/2026-05-06-204500-q1-step-2-tools-group-py-draft-v1-spec.md.
Operator-revisable per SB-095. Borrows canonical chain/group/tree taxonomy from second-brain
wiki/domains/automation/research-pipeline-orchestration.md (operator's own 2026-04-08 vision).

Three composition modes (operator-stated 2026-05-06):
  - chain    = sequential, each step feeds next (dependent ops)
  - group    = parallel, all run, results merged (independent ops)
  - tree     = root → branches in parallel → merge synthesizes

Per E003 multi-group component — Q1 self-elevation 2026-05-06.

----------------------------------------------------------------------
USAGE EXAMPLES — 5 root-modules pipeline candidates (DRAFT, agent-proposed)
----------------------------------------------------------------------

# Example 1: task-complete-cascade — chain
# Operator example: "updating tasks and such where we know that the task should
# imply than more than just one operation, its a chain" (2026-05-06)
#
#   chain(
#     lambda: read_active_task(),                # T###-slug.md
#     lambda task: mark_status_done(task),       # frontmatter status: done
#     lambda task: bump_readiness(task, 100),    # readiness: 100
#     lambda task: propagate_to_module(task),    # parent_module readiness++
#     lambda task: cursor_advance(task),         # active-task → next
#     lambda task: handoff_snapshot(task),       # snapshot pre-cursor-change
#     lambda task: log_completion(task),         # wiki/log/<ts>-T###-done.md
#   )

# Example 2: stage-transition — chain (gate + verify + log)
# Operator example: "passing through the stage of one document for specs"
#
#   chain(
#     lambda: load_task("T012"),
#     lambda t: verify_stage_allowed(t, "implement"),  # methodology.yaml gate
#     lambda t: run_gate_check(t),                     # install.sh --dry-run, etc.
#     lambda t: write_stage_log(t, "implement"),
#     lambda t: update_frontmatter_stage(t, "implement"),
#     lambda t: notify_dependent_tasks(t),
#   )

# Example 3: sb-closure-batch — chain (4 governance docs in lockstep)
# SB-131 chain-batched-operations precedent, formalized
#
#   chain(
#     lambda: append_sb_row("SB-XXX", "...", "structurally-fixed"),
#     lambda sb_id: append_decision("D###", sb_id, "..."),
#     lambda d_id: refresh_progress_callout(),
#     lambda _: write_log_entry("sb-closure", sb_id),
#   )

# Example 4: multi-file-coherent-edit — group then chain
# Operator example: "updating multiple things like PM file and cursor files
# and aidlc related things and such in a group effect / cascade call"
#
#   results = group(
#     lambda: edit_progress_md(...),             # parallel edits
#     lambda: edit_active_task(...),
#     lambda: edit_decisions_md(...),
#   )
#   chain(                                       # then verify + commit sequentially
#     lambda: run_tests(),
#     lambda r: assert r.ok,
#     lambda _: git_commit("coherent multi-file change"),
#   )

# Example 5: research-then-build — tree
# Operator example: "research-first per principle #5 elevated"
#
#   spec = tree(
#     root=lambda: collect_topic("chain primitive"),
#     branches=[
#       lambda topic: query_second_brain(topic),
#       lambda topic: scan_prior_art(topic),
#       lambda topic: enumerate_risks(topic),
#     ],
#     merge=lambda parts: synthesize_spec_draft(parts),
#   )
#
# ----------------------------------------------------------------------
# Composes-with (DRAFT v1):
# ----------------------------------------------------------------------
# - Slash commands: future /compound or /chain dispatch (not yet wired); /cycle
#   compound-sync step (forward-anchor per compound-and-waterfall.md trigger c)
# - Hooks: output-discipline-guard.sh chain-detect (forward-anchor per trigger a)
# - MCP: future tool wrap (not wired)
# - Sister tools: any tool whose mutations form coherent multi-file groups
#   (governance batches: tools.blockers + tools.decisions + tools.progress)
#
# Operator-stated 5-pattern catalog (DRAFT — preserved verbatim above):
#   task-complete-cascade · stage-transition · sb-closure-batch ·
#   multi-file-coherent-edit · research-then-build
#
# Idempotency invariant: pure functional composition primitive; no I/O;
# composability is at the caller's discretion. Each callable is responsible
# for its own idempotency.
#
# Action vocabulary (Hard Rule 14): no direct emission; this is a primitive
# CONSUMED by other tools/commands which then emit per their action surface.
# When chain/group/tree drives a coherent multi-edit per fire, the calling
# cycle emits ONE action type covering the whole batch (per SB-131 chain-batched
# pattern; chain-operations is the substance pattern, single-edit-per-fire
# is the THIN-output anti-pattern).
#
# Test file: tools/tests/test-group.py (17 assertions — chain/group/tree
# behavior incl. failure semantics; authored 2026-07-03, the first tool-layer
# regression test). Spec:
# wiki/log/2026-05-06-204500-q1-step-2-tools-group-py-draft-v1-spec.md.
#
# E003 multi-group component: this is Layer A primitive; Layer B is per-tool
# adopters; Layer C is /cycle compound-sync step (operator-decision pending).
#
# Brain-improvement mandate: wiki/log/2026-05-06-194730-brain-improvement-mandate-readme-first.md
"""

from __future__ import annotations

from typing import Any, Callable

Step = Callable[..., Any]


class GroupError(Exception):
    """Aggregates failures from a group() invocation across multiple callables."""

    def __init__(self, results: list, errors: list[tuple[int, BaseException]]):
        self.results = results
        self.errors = errors
        msg = f"group() had {len(errors)} failure(s) of {len(results)}: " + ", ".join(
            f"step {i}: {type(e).__name__}: {e}" for i, e in errors
        )
        super().__init__(msg)


def chain(*steps: Step, initial: Any = None) -> Any:
    """Sequential composition: A → B → C, each step's return feeds the next.

    First step is invoked with `initial` if it accepts an arg, else no-arg.
    Subsequent steps receive previous step's return value.
    Returns final step's return value (or `initial` if no steps).

    Failure: chain stops at first exception; subsequent steps NOT called.
    Caller decides recovery.
    """
    if not steps:
        return initial
    result = initial
    for i, step in enumerate(steps):
        if i == 0 and result is None:
            try:
                result = step()
            except TypeError:
                # step accepts no args — try None pass
                result = step(None)
        else:
            result = step(result)
    return result


def group(*callables: Step) -> list:
    """Parallel composition: A + B + C, all run regardless of failures.

    MVP synchronous (sequential execution but conceptually parallel since
    no inter-dependencies). Future v2 could add asyncio.

    Returns: list of results in input order.
    Raises: GroupError aggregating failures (after all callables complete).
    """
    results: list = [None] * len(callables)
    errors: list[tuple[int, BaseException]] = []
    for i, c in enumerate(callables):
        try:
            results[i] = c()
        except BaseException as exc:
            errors.append((i, exc))
            results[i] = exc
    if errors:
        raise GroupError(results, errors)
    return results


def tree(root: Step, branches: list[Step], merge: Step) -> Any:
    """Tree composition: root produces seed → branches run in parallel with seed → merge.

    root(): produces seed value.
    branches: list of callables; each receives seed, returns branch-result.
    merge(branch_results): synthesizes branches into final.

    Returns: merge's return value.
    """
    seed = root()
    branch_results = group(*[lambda b=b: b(seed) for b in branches])
    return merge(branch_results)


if __name__ == "__main__":
    # Smoke test entrypoint — prints PASS/FAIL per primitive
    print("=== tools.group smoke test ===")

    # chain
    r = chain(lambda: 1, lambda x: x + 10, lambda x: x * 2)
    assert r == 22, f"chain expected 22, got {r}"
    print("chain: ✓")

    # group
    r = group(lambda: "a", lambda: "b", lambda: "c")
    assert r == ["a", "b", "c"], f"group expected ['a','b','c'], got {r}"
    print("group: ✓")

    # tree
    r = tree(
        root=lambda: 5,
        branches=[lambda s: s + 1, lambda s: s * 2, lambda s: s - 3],
        merge=lambda parts: sum(parts),
    )
    assert r == (6 + 10 + 2), f"tree expected 18, got {r}"
    print("tree: ✓")

    print("=== all 3 primitives PASS ===")
