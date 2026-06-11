---
name: scf-round-watcher
description: Surface current and recent Stellar Community Fund (SCF) round activity. Use when a user says "current SCF round", "what's happening with SCF", "active SCF submissions", "should I apply to SCF this round", "SCF deadline", "who is applying to SCF right now", "SCF round status", or "show me this round's submissions". Fetches live data from communityfund.stellar.org and cross-references with the LumenLoop ecosystem DB to flag repeat builders and category trends.
---

## What this skill does

### 1. Find the active round

Fetch `https://communityfund.stellar.org/awards`. The currently open round has status "Submission". Extract its rec ID from the round's link (`/awards/<rec-id>`).

The site is a client-rendered React app — plain `curl` returns mostly empty HTML. Use the **WebFetch tool** (Claude Code built-in) which handles client-rendered pages via its parsing layer:

```
WebFetch(
  url="https://communityfund.stellar.org/awards",
  prompt="Find the round with status 'Submission' (currently open). Return its name (e.g., 'SCF #44'), its rec-id from the link (/awards/<rec-id>), the deadline date, and the maximum award amount."
)
```

If WebFetch isn't available in the runtime, fall back to a headless-browser fetch (e.g., `playwright` or `puppeteer` via `uvx`) — `curl` alone won't get rendered content for this site.

### 2. Get the round's submissions

Fetch `https://communityfund.stellar.org/awards/<round-rec-id>`. Parse the submissions list — each entry has: project name, requested amount, status.

If a "See All" link is present, follow it for the full list (not just the first 11 visible on the round page).

### 3. Enrich each submission with project detail

For each submission, follow its "view" link → `/project/<submission-rec-id>`. Fetch in parallel (5 at a time, polite to the server). Extract: project description, category, team members + GitHub links, Stellar integration summary, requested amount.

### 4. Cross-reference repeat builders

Load `~/.claude/skills/data/lumenloop/projects.json` (or fetch from `https://raw.githubusercontent.com/lumenloop/stellar-ecosystem-db/main/...` if missing).

For each submission team, check if any team's project is already in the LumenLoop DB. If yes, flag them as **repeat builder** with their past SCF rounds and total prior funding.

### 5. Summarize for the user

Format as:

```
## SCF Round #<N> — <STATUS>
Deadline: <DATE> (<X days remaining>)

### Top facts
- <N> submissions visible
- Total requested: $<sum>K
- Top 3 categories: <category 1> (N), <category 2> (N), <category 3> (N)
- Repeat builders: <N> teams previously funded by SCF
- First-timers: <N>

### Notable submissions

| Project | Asks | Category | Builder status | What they do |
|---------|------|----------|----------------|--------------|
| ... | $X K | ... | repeat / first-time | one-line description |

### Patterns this round
<2-3 sentences on what categories or themes are dominant>
```

### 5.5 Optional: thesis-alignment flagging

For each active submission, optionally cross-reference with:
- `~/.claude/skills/data/ideas/a16z-big-ideas-2025.json` — does this submission ride an a16z 2025 thesis (RWA, agentic payments, prediction markets, etc.)?
- `~/.claude/skills/data/ideas/yc-requests-for-startups.json` — does YC explicitly want something in this category?

Submissions that hit BOTH Stellar ecosystem-fit AND broader investor thesis are 2x more likely to win the round. Flag them as "thesis-aligned" in the summary table.

### 6. Close with next-step suggestions

If user is considering applying:
- Route to `scf-prescreen-checker` to test their idea against the prescreen filter
- Route to `scf-competitor-analyst` if they're worried about overlap with other submissions
- Route to `scf-submission-drafter` if ready to draft

If user is researching:
- Offer to deep-dive any specific submission
- Offer to compare against the last 3 rounds (grep historical `scf.awarded_round` patterns in `projects.json`)

## Constraints

- Be polite to communityfund.stellar.org — sequential fetches or low concurrency (5 max)
- Cache fetched data in `~/.stellar/cache/scf-round/<rec-id>.json` for the session
- If the site is down or returns non-200, report cleanly and suggest the user visit communityfund.stellar.org directly. Do not fabricate data.
- If dates aren't visible on the page, say "deadline not extractable from page" — don't speculate
- The active-round detection assumes exactly one round has status "Submission" at a time. If multiple or none, surface that as a finding
