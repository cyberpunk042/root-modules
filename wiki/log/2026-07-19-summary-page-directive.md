# 2026-07-19 — Operator directive: SUMMARY.md page (default vs modules, pros and cons)

## Operator directive (verbatim, sacrosanct)

> "lets create a summary.md page to summarize what the project does by default and the modules you can add and lets make it clean and clear. I want to understand the pros and cons"

## Interpretation (agent, flagged per SB-095)

- New top-level page `SUMMARY.md` — operator-directed, so the "new top-level files need approval" gate is satisfied by the directive itself.
- Content: (1) what the project does **by default** (the foundation — root/home folder upgrader + evolver); (2) the **modules you can add** (the ghostproxy combo: bridge + Suricata + PolarProxy; plus the ccstatusline Features module already implemented); (3) **pros and cons** for the default and for each module.
- "clean and clear" = readable overview page — plain language, short sections, pros/cons tables; NOT the dense cross-reference style of the rule files. Grounded in the empirical install.sh surface (profiles base/full/project/interactive × modes bridge/endpoint/hybrid/auto, 8 op functions), not aspirational claims. Module status honesty: Suricata + PolarProxy are planned (M005, not yet integrated); the bridge half ships in the foundation IaC today via `--mode bridge|hybrid`.
- README gets a one-line pointer to SUMMARY.md (chain ops per Hard Rule 13).
