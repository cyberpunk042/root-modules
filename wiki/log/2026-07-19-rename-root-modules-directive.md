# 2026-07-19 — Operator directive: root-ghostproxy renamed to root-modules

## Operator directive (verbatim, sacrosanct)

> "root-ghostproxy has just been renamed into root-modules. lets update the repo as such. its at first and by default a root or home folder upgrader, evolver and secondly you can install supplementary modules like the ghostproxy combo."

Received 2026-07-19, in the session working branch `claude/rename-root-ghostproxy-modules-tv1ljj`. The operator had already landed commit `f3ff662` ("Rename project to root-modules and update README") changing the README title line to `# root-modules`.

## What this directive establishes

1. **The project name is now `root-modules`** (GitHub repo `cyberpunk042/root-modules`, formerly `root-ghostproxy`).
2. **Primary identity (reframed)**: *"at first and by default a root or home folder upgrader, evolver"* — the foundation layer (install.sh, agent brain, hooks, methodology, endpoint AI safety) that upgrades/evolves a root or home folder.
3. **Secondary identity**: *"secondly you can install supplementary modules like the ghostproxy combo"* — the modules concept generalizes; the transparent L2 bridge + Suricata + PolarProxy stack is now named **the ghostproxy combo**, one installable module set among (potentially) others.

## Interpretation notes (agent, flagged per SB-095)

- "ghostproxy" survives as the NAME OF THE MODULE COMBO (bridge + IDS/IPS + TLS inspection), not as the project name. Template files (`templates/systemd-networkd/*ghostproxy-bridge*`) and bridge-related naming keep "ghostproxy" — they belong to that combo.
- Historical records (`wiki/log/*`, `docs/SESSION-*`, operator-verbatim quotes citing "root-ghostproxy") are NOT rewritten — sacrosanct + additive-not-destructive (Hard Rule 11). The prior name remains in the historical record; live identity/brain/tooling files are updated.
- `RGP_*` env var names (e.g. `RGP_SECOND_BRAIN_ROOT`) are kept unchanged in this pass to avoid breaking operator environments; flagged as a follow-up decision.
- Canonical second-brain artefacts (`sister-projects.yaml` entry, identity-profile path `wiki/ecosystem/project_profiles/root-ghostproxy/`) live in the second-brain repo and are updated from THERE, not from here ($HOME scope discipline). References in this repo point at the current second-brain paths until the second brain renames them.

## Action taken in this session

Repo-wide rename of live project-name references (`root-ghostproxy` → `root-modules`), backlog module file renames, MCP server name update, and additive identity reframing in README.md / CLAUDE.md / AGENTS.md / .claude/rules/self-reference.md per the directive above. See the branch diff for the full change set.
