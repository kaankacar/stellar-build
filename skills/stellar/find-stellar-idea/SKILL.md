---
name: find-stellar-idea
description: Help users discover what to build on Stellar. Use when a user says "what should I build on Stellar", "Stellar app ideas", "I want to build on Stellar but don't know what", "Stellar startup ideas", "find me a Stellar project idea", "I'm new to Stellar and want to build something", or "what's hot on Stellar right now". Interviews user sharply, then proposes ranked ideas grounded in real ecosystem gaps from the LumenLoop 728-project database and current SCF funding patterns.
---

## What this skill does

When invoked, do these four things in order.

### 1. Load context

Read both Stellar-specific data and broader crypto market signals. The combination matters: ideas that fit a Stellar ecosystem gap **and** align with broader investor thesis (a16z, YC, Alliance) are both ecosystem-coherent and fundable.

**Stellar-specific:**
- `~/.claude/skills/data/lumenloop/projects.json` — 728-project Stellar ecosystem catalog with categories, SCF funding history, GitHub links
- `~/.claude/skills/data/electric-capital/stellar-repos.json` — Stellar developer activity signal (~9000 repos)
- `~/.claude/skills/data/lumenloop/scf/rounds.json` — historical SCF funding patterns (categories funded, average grant size)

**Broader crypto market signals:**
- `~/.claude/skills/data/ideas/a16z-big-ideas-2025.json` — a16z's published "big ideas" thesis for 2025
- `~/.claude/skills/data/ideas/a16z-state-of-crypto-2025.json` — a16z's annual State of Crypto report
- `~/.claude/skills/data/ideas/yc-requests-for-startups.json` — YC's published Request for Startups list (what YC explicitly wants funded)
- `~/.claude/skills/data/ideas/yc-crypto-companies.json` — every YC-backed crypto company (competitive map + signal of what gets funded)
- `~/.claude/skills/data/ideas/alliance-ideas.json` — Alliance DAO's startup ideas
- `~/.claude/skills/data/ideas/rwa-defi-2026-ideas.json` — RWA + DeFi ideas relevant for 2026

If any file is missing, proceed but note "(limited context — install fresh data with `--update`)".

### 2. Ask three sharp questions, one at a time

Wait for each answer before asking the next:

1. **Which Stellar domain pulls you?** — payments, DeFi, stablecoins, RWA (real-world assets), DePIN, consumer apps, dev infrastructure, anchors, agentic payments, or something else.
2. **What's your timeline?** — weekend hack, one month, one quarter, longer.
3. **What's your unfair advantage?** — domain expertise, technical skill, distribution, network, capital. What do you have that most builders don't?

### 3. Propose three ranked ideas

For each idea, write:

- **One-line pitch.** What it is, who it's for.
- **Why Stellar specifically.** What Stellar capability (Soroban, anchors, low fees, native multi-currency, agentic payments, fast finality) makes this work *better* on Stellar than on another chain.
- **Ecosystem gap evidence.** Cite from `projects.json`: what's *already* in this category and at what SCF funding levels, what's *not*.
- **Broader thesis fit.** If the idea aligns with an a16z thesis, a YC RFS line item, or an Alliance DAO area, cite it. If it doesn't, say so plainly — Stellar-specific ideas without broader investor thesis can still be great, but the user should know.
- **Why it might fail.** The single biggest risk.
- **First step.** Smallest concrete thing they could do tomorrow.
- **SCF fit.** Likely yes / no / maybe to receive SCF funding, based on recent round patterns.

Order: best fit for *their* constraints first; most ambitious last.

### 4. Close

End with: "Pick one to refine, or tell me what's missing and I'll regenerate. If you like one, I can route you to `validate-stellar-idea` or `stellar-competitive-landscape` next."

## Constraints

- Do not propose ideas requiring capital they didn't mention
- Do not propose ideas outside their stated domain
- Each idea must be specific enough to start tomorrow — not "build a social network"
- If `projects.json` shows 5+ funded projects already doing this exact thing, either propose a clear differentiation angle or move on
- If they pick "agentic payments" or "ZK proofs," lean into Stellar's recent capability investments — these are intentionally underbuilt and SCF is funding them heavily
