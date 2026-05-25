# Skill Router — stellar.new

> **For AI agents**: If the user's request doesn't match the active skill, find the right one below and switch with: "This looks like a [phase] task — switching to `[skill-name]`."

42 skills organized by the Stellar development journey: idea → planning → solutioning → implementation → review → launch.

---

## Idea phase — what to build

| Trigger phrases | Skill |
|-----------------|-------|
| "what should I build on Stellar", "Stellar app ideas", "I'm new to Stellar and want to build something", "find me a Stellar project idea" | `find-stellar-idea` |
| "brainstorm with me", "ideation session", "creative thinking", "explore ideas" | `brainstorming` |
| "who are my competitors on Stellar", "competitive analysis Stellar", "what already exists in this space" | `stellar-competitive-landscape` |
| "current SCF round", "active SCF submissions", "SCF deadline", "should I apply this round" | `scf-round-watcher` |
| "talk to Justin", "business analyst", "market research", "competitive analysis", "requirements elicitation" | `justin-analyst` |
| "push me to think deeper", "refine this output", "improve this", "elicit more details" | `advanced-elicitation` |

## Planning phase — turning idea into spec

| Trigger phrases | Skill |
|-----------------|-------|
| "talk to Nicole", "product manager", "drive PRD creation", "user interviews" | `nicole-pm` |
| "talk to Kaan", "UX designer", "interaction design", "UX specification" | `kaan-ux-designer` |
| "create a PRD", "write the PRD", "product requirements", "validate PRD" | `prd` |
| "PRFAQ", "Working Backwards", "press release driven development" | `prfaq` |
| "product brief", "create a brief", "summarize the product" | `product-brief` |
| "UX design", "create UX patterns", "design specifications" | `create-ux-design` |

## Solutioning phase — architecture + breakdown

| Trigger phrases | Skill |
|-----------------|-------|
| "talk to Tyler", "system architect", "technical design", "architecture decisions" | `tyler-architect` |
| "create architecture", "design the system", "technical solution design" | `create-architecture` |
| "create epics and stories", "break this into stories", "work breakdown" | `create-epics-and-stories` |
| "Soroban contracts", "write a smart contract", "Rust SDK", "contract patterns" | `soroban` |
| "build a frontend", "wallet integration", "Freighter", "Stellar Wallets Kit", "Smart Account Kit" | `dapp` |
| "Stellar assets", "trustlines", "SAC", "Stellar Asset Contract" | `assets` |
| "Stellar RPC", "Horizon API", "indexer", "fetch on-chain data" | `data` |
| "agentic payments", "x402", "MPP", "AI-driven payments", "Charge + Channel" | `agentic-payments` |
| "ZK proofs", "zero-knowledge", "BLS12-381", "BN254", "Poseidon" | `zk-proofs` |
| "SEPs", "CAPs", "Stellar standards", "protocol proposals" | `standards` |

## Implementation phase — building

| Trigger phrases | Skill |
|-----------------|-------|
| "talk to Elliot", "developer", "code this", "implement the story" | `elliot-dev` |
| "execute story", "dev story", "implement based on spec" | `dev-story` |
| "investigate", "debug", "find the bug", "forensic analysis" | `investigate` |
| "party mode", "multi-agent discussion", "let's all chime in", "bring everyone in" | `party-mode` |

## Review phase — quality before shipping

| Trigger phrases | Skill |
|-----------------|-------|
| "code review", "review my code", "adversarial review", "audit my code" | `code-review` |
| "edge cases", "find edge cases", "boundary conditions", "what could break" | `review-edge-case-hunter` |

## Launch phase — to mainnet + SCF grant

| Trigger phrases | Skill |
|-----------------|-------|
| "deploy to Stellar mainnet", "go live on Stellar", "mainnet deployment checklist" | `deploy-stellar-mainnet` |
| "SCF interest form", "Interest Form draft", "how do I get invited to SCF" | `scf-interest-form-drafter` |
| "SCF referral", "approach a referrer", "SCF referral package" | `scf-referral-preparer` |
| "SCF prescreen", "will my submission pass prescreen", "check my SCF eligibility" | `scf-prescreen-checker` |
| "draft SCF submission", "write my SCF application", "SCF Build Award draft" | `scf-submission-drafter` |
| "SCF budget", "validate my budget", "budget structure" | `scf-budget-builder` |
| "SCF competitor analysis", "differentiate my SCF submission" | `scf-competitor-analyst` |
| "review SCF submission", "evaluate this SCF application" | `scf-reviewer` |
| "review whole SCF round", "rank an SCF round", "review CSV of submissions" | `scf-round-reviewer` |
| "tranche report", "milestone deliverable report", "SCF tranche submission" | `scf-tranche-reporter` |
| "fetch external doc", "get Google Doc", "retrieve IPFS doc", "Notion doc" | `fetch-external-doc` |

## Meta — discovery and help

| Trigger phrases | Skill |
|-----------------|-------|
| "what skills do I have", "show me available skills", "what can I do", "where do I start" | `navigate-skills` |
| "stellar help", "help me with stellar.new", "how does this work" | `stellar-help` |
| "talk to Bri", "tech writer", "documentation", "knowledge curation" | `bri-tech-writer` |

---

## How to use this router

1. Read the user's request
2. Match against the trigger phrases above
3. If the active skill doesn't match, tell the user: "This looks like a [phase] task — switching to `[skill-name]`."
4. Load that skill's `SKILL.md` and follow its instructions
5. When the user shifts intent mid-conversation, re-check the router and switch again

## Phase handoff context

Skills that span phases pass context via files under `.stellar-new/` in the user's working dir:

| File | Written by | Read by |
|------|-----------|---------|
| `idea-context.md` | `find-stellar-idea`, `stellar-competitive-landscape` | planning-phase skills |
| `prd.md` | `prd`, `nicole-pm` | `create-architecture`, `create-epics-and-stories` |
| `architecture.md` | `create-architecture`, `tyler-architect` | `create-epics-and-stories`, `dev-story` |
| `stories.md` | `create-epics-and-stories` | `dev-story`, `elliot-dev` |
| `deploy-context.md` | `deploy-stellar-mainnet` | `scf-tranche-reporter` |

If a downstream skill expects a context file that doesn't exist, ask the user where they're starting from and route back to the upstream skill if needed.
