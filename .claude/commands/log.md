Log an operator directive verbatim to $HOME/wiki/log/ (sacrosanct primary source for /root iteration).

> Slash-invoked. Operator types `/log <directive content or quote>` literally. Or `/log` alone to be prompted.
>
> **Path: `$HOME/wiki/log/<YYYY-MM-DD>-<slug>.md`. NOT `/opt/.../raw/notes/`.** The second-brain has its own authoring layer + its own contribute channel (`tools.gateway contribute`, gated on M007). /root iteration directives stay in /root. Operator's binding rule 2026-05-05: *"LET THE SECOND-BRAIN BE ITS OWN."*
>
> Specifically for operator-verbatim quotes that need to land BEFORE acting (per AGENTS.md Hard Rule #4 — operator words are sacrosanct, log first).

## On `/log <content>`

1. Identify what was passed:
   - If args present: use them as the verbatim content
   - If no args: ask operator what to log
2. Decide the slug from the first 6-8 meaningful words of the content (lowercase, hyphenated, no punctuation).
3. Author a verbatim log at `$HOME/wiki/log/<YYYY-MM-DD>-<slug>.md` with:
   - YAML frontmatter (title, type=log, domain=cross-domain, status=active, confidence=high, created/updated, sources, tags including `sacrosanct`, `verbatim`, `operator-directive`)
   - "## Verbatim" section with the operator's words quoted EXACTLY (no paraphrase, no compression)
   - "## Decomposition" section breaking down substance (operator's own words, not interpretation)
   - "## Action plan" section if the directive implies action
   - "## No-conflate guard" section noting what the directive is NOT (questions ≠ decisions, etc.)
4. If the directive is or implies a decision: also append a D### entry to `$HOME/wiki/governance/decisions.md` via `python3 -m tools.decisions append ...` (or do it manually following the format).
5. Confirm to operator: log path created + (if applicable) D### entry appended.

## NEVER write to /opt

Per operator directive 2026-05-05 (severe correction): *"THE ONLY WAY TO SEND TO THE SECOND-BRAIN IS TO USE THE CONTRIBUTE FEATURE... THIS HAD NOTHING TO DO WITH THE SECOND-BRAIN... LET THE SECOND-BRAIN BE ITS OWN."*

The /log command writes to /root only. If a directive is intended for the second-brain's audit trail (rare, second-brain-specific), the channel is `tools.gateway contribute` (gated on M007 connect), not direct write to /opt.

## What `/log` is NOT

- Not a journal — only operator-verbatim quotes that shape rules, decisions, or work
- Not an explanation generator — quote first, decompose afterward
- Not a substitute for the agent's own memory — it's the AUDIT TRAIL of operator words

## When to invoke

- Operator gives a directive worth preserving (rule shape, decision, framing change)
- Before acting on the directive (Hard Rule #4 — log first, act second)
- When the directive is verbose enough that paraphrasing would lose substance
- When the operator explicitly says "log this" or `/log <X>`
