---
name: navigate-skills
description: Meta-skill — browse and discover all installed stellar.new skills. Use when a user says "what skills do I have", "show me available skills", "what can I do", "find a skill for X", "which skill should I use", "help me navigate", "what does stellar.new do", or "where do I start". Lists skills by journey phase, surfaces the SKILL_ROUTER trigger phrases, and recommends the next skill given current context.
---

## What this skill does

### 1. Survey installed skills

Scan `~/.claude/skills/` for: (a) skill folders with `SKILL.md`, (b) flat `.md` skill files (the SCF skills ship as flat files). Group them into journey phases:

- **Idea** — `find-stellar-idea`, `brainstorming`, `advanced-elicitation`, `stellar-competitive-landscape`, `scf-round-watcher`, `justin-analyst`
- **Planning** — `prfaq`, `product-brief`, `prd`, `nicole-pm`, `kaan-ux-designer`, `create-ux-design`
- **Solutioning** — `tyler-architect`, `create-architecture`, `create-epics-and-stories`, `soroban`, `dapp`, `assets`, `data`, `agentic-payments`, `zk-proofs`, `standards`
- **Implementation** — `elliot-dev`, `dev-story`, `investigate`, `party-mode`
- **Review** — `code-review`, `review-edge-case-hunter`
- **Launch** — `deploy-stellar-mainnet`, `scf-prescreen-checker`, `scf-interest-form-drafter`, `scf-submission-drafter`, `scf-budget-builder`, `scf-competitor-analyst`, `scf-referral-preparer`, `scf-reviewer`, `scf-round-reviewer`, `scf-tranche-reporter`, `fetch-external-doc`
- **Meta** — `navigate-skills`, `stellar-help`, `bri-tech-writer`

### 2. Read the SKILL_ROUTER

Load `~/.claude/skills/SKILL_ROUTER.md` if present — that's the canonical trigger-phrase → skill mapping.

### 3. Respond based on user intent

**If user is exploring** ("what skills do I have", "show me everything"):
- Print the journey map above
- Mention there are 42 total skills
- Suggest starting with `find-stellar-idea` for early-stage builders

**If user has a specific task** ("I need to write a PRD", "I want to deploy to mainnet"):
- Match against trigger phrases in `SKILL_ROUTER.md`
- Surface the matching skill name + how to invoke it
- Mention 1-2 related skills they might want next

**If user is stuck** ("I'm lost", "which one do I use", "where do I start"):
- Ask: "Where are you in the journey — figuring out what to build, planning, implementing, or shipping?"
- Based on the answer, suggest the 2-3 most relevant skills for that phase

### 4. Always offer a concrete next step

Every response ends with one specific next-skill suggestion, not a list.

## Constraints

- Don't list skills that aren't actually installed — verify against the filesystem
- Don't invent skill names — only use what's in `~/.claude/skills/`
- If installed skill count doesn't match expected (42), suggest the user run `--update` to refresh
- For the 6 personas (justin-analyst, bri-tech-writer, nicole-pm, kaan-ux-designer, tyler-architect, elliot-dev), explain they're invokable by name ("talk to Nicole") — these are role-based agents, not phase-bound skills
