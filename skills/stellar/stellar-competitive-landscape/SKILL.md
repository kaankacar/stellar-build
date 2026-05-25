---
name: stellar-competitive-landscape
description: Map the competitive landscape for a Stellar project idea. Use when a user says "who are my competitors on Stellar", "competitive analysis Stellar", "what already exists in this space on Stellar", "show me similar Stellar projects", "is anyone else building this on Stellar", or "map the Stellar landscape for X". Queries the 728-project LumenLoop ecosystem database and Electric Capital developer activity to rank competitors by SCF funding history and repo activity.
---

## What this skill does

### 1. Get the project context

If the user hasn't described their idea, ask: "What are you building, in one sentence?"

Then ask: "Any specific category to compare against? — Financial Protocols, Applications, Developer Tooling, Infrastructure & Services, Payments, Education & Community, or other."

### 2. Search the ecosystem DB

Read `~/.claude/skills/data/lumenloop/projects.json`. If missing, fetch from `https://raw.githubusercontent.com/lumenloop/stellar-ecosystem-db/main/` (the YAML files in `projects/` — convert on the fly if needed).

Filter by:

- `attributes.category` matching the user's stated category (case-insensitive partial match)
- Description keyword overlap with the user's idea — extract 3-5 keywords from the idea, score each project by how many keywords appear in its description

Return top 10-15 matches ranked by relevance score.

### 3. Enrich with developer activity

For each top match, look up its GitHub org/repo in `~/.claude/skills/data/electric-capital/stellar-repos.jsonl`. Note: last-commit recency, total contributors if available. Flag dormant repos (no commits in 6+ months) as "low activity."

### 4. Build the competitive map

Present as a markdown table, sorted by SCF funding desc, then dev activity desc:

| Project | Category | SCF rounds + total | GitHub activity | One-line description | Overlap with user's idea |
|---------|----------|----------------------|-----------------|----------------------|--------------------------|

Use `scf.awarded_total` from the project entry. If null, mark as "—" (community-listed but not SCF-funded).

### 5. Differentiation guidance

After the table, write 2-3 sentences answering:

- **Strongest competitor**: which project is closest to the user's idea, what they do, and where their visible gap is (missing feature, dormant repo, narrow scope)
- **Saturated vs open space**: does the category have 1-2 dominant players (saturated) or many small players (fragmented, possibly open). Saturation is judged on SCF-funded count, not community-listed count.
- **Recommended differentiation**: one concrete angle the user could lean into

Close with: "Want me to route you to `validate-stellar-idea` to stress-test against the top competitor, or back to `find-stellar-idea` to pivot the angle?"

## Constraints

- Only count SCF-funded projects toward "saturation" — unfunded community-listed projects are weaker competitive signal
- If user's category isn't recognized, ask for clarification rather than guessing
- If `projects.json` returns 0 matches, the category may be genuinely open — surface that as a *finding*, not a failure
- Do not invent project names. If the DB doesn't have something, say so honestly
