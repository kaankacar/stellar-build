# stellar-build

A one-command install that drops an end-to-end Stellar development journey into your Claude Code and OpenAI Codex CLI setup. From "what should I build?" to mainnet deploy and Stellar Community Fund grant submission, in 42 skills plus curated ecosystem data.

```bash
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash
```

## What you get

**42 skills across the full journey:**

- **Idea phase.** Discover what to build on Stellar, validate against the 728-project ecosystem, watch the live SCF round.
- **Planning phase.** PRD, UX design, and product brief, driven by personas from the SDF DevRel team.
- **Solutioning phase.** Architecture, epics, stories, plus deep Soroban + dapp + asset knowledge from `stellar/stellar-dev-skill`.
- **Implementation phase.** Story-driven dev, code review, and debugging.
- **Launch phase.** Devnet to mainnet deploy plus 10 SCF grant lifecycle skills.

**Curated data:**

- The full LumenLoop ecosystem catalog (728 projects, SCF rounds, audits, tokens)
- Electric Capital's Stellar developer taxonomy (9,027 catalogued repos)
- Stellar Foundation's ecosystem-resources reference docs

## Meet your team

stellar-build gives you six AI agents with distinct roles, named for the SDF DevRel team. Call any of them by name to swap into their persona:

| Persona | Role | Call them when... |
|---------|------|-------------------|
| **Justin** | Business Analyst | you need market research, competitive analysis, requirements elicitation |
| **Bri** | Tech Writer | you need documentation, knowledge curation, technical writing |
| **Nicole** | Product Manager | you need PRDs, requirements discovery, stakeholder alignment |
| **Kaan** | UX Designer | you need interaction design, UX specifications |
| **Tyler** | System Architect | you need architecture decisions, Soroban contract design |
| **Elliot** | Senior Developer | you need code, story execution, implementation |

Talk to any of them naturally:

```
"talk to Tyler"             → adopts the architect persona
"Justin, who are my competitors on Stellar?"  → analyst with context
"party mode"                → all six in one group discussion
```

## Getting started

Skills install to both `~/.claude/skills/` and `~/.codex/skills/`, so the same prompts work whether you're in Claude Code, Codex CLI, or any agent that reads from those paths. Open your CLI and type prompts directly. There are two ways to invoke skills.

**Natural language.** Describe what you want and the right skill auto-activates:

```
what should I build on Stellar?          → find-stellar-idea
current SCF round                        → scf-round-watcher
deploy to mainnet                        → deploy-stellar-mainnet
talk to Nicole and write a PRD           → nicole-pm
```

**Slash commands.** Use these when you know exactly which skill you want:

```
/stellar-help        how does this all work?
/navigate-skills     browse all 42 skills
/scf-round-watcher   explicit scf round fetch
```

### A typical journey

```
# 1. Idea
what should I build on Stellar?
  → find-stellar-idea interviews you, proposes 3 ranked ideas

# 2. Validate against existing ecosystem
who are my competitors?
  → stellar-competitive-landscape queries the 728-project DB

# 3. Plan with Nicole
talk to Nicole, let's write a PRD
  → nicole-pm walks PRD creation

# 4. Architect with Tyler
talk to Tyler, design the architecture
  → tyler-architect + soroban/dapp skills

# 5. Build with Elliot
talk to Elliot, implement the first story
  → elliot-dev + dev-story

# 6. Review before ship
code review
  → code-review + review-edge-case-hunter

# 7. Deploy
deploy to Stellar mainnet
  → deploy-stellar-mainnet checklist

# 8. Apply for SCF
current SCF round              see what's open
draft my SCF submission        → scf-submission-drafter
```

## How it works

The install pulls from four canonical sources at install time:

1. **This repo** (`kaankacar/stellar-build`). 20 paraphrased BMAD methodology skills plus 5 new Stellar-specific skills plus the installer plus bundled data.
2. **`lumenloop/awesome-stellar-community-fund`.** 10 SCF lifecycle skills.
3. **`stellar/stellar-dev-skill`.** 7 Stellar dev knowledge modules (Soroban, dapp, assets, data, agentic-payments, zk-proofs, standards).
4. **`lumenloop/stellar-ecosystem-db`.** Bundled snapshot of the 728-project YAML catalog, converted to JSON at build time.

We don't redistribute upstream content from sources 2-3. Instead, the installer points your machine at the canonical sources. See [NOTICES.md](./NOTICES.md) for attribution and licenses.

## Sandboxed / per-project install

You can install stellar-build into a specific project folder instead of your global `$HOME`. This is useful when you want the skills *scoped to one project*:

```bash
mkdir my-stellar-project && cd my-stellar-project
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash -s -- --prefix=$(pwd)
```

This installs to `./my-stellar-project/.claude/skills/` and `./my-stellar-project/.codex/skills/`. When you `cd` into the project and run `claude` (or `codex`), the CLI reads project-local skills from `.claude/skills/` automatically, so all 42 skills work for *this project only*.

That makes sandboxed install useful in two scenarios:

1. **Per-project skills.** You want stellar-build active for one specific Stellar project, not globally.
2. **Testing without affecting your real `$HOME`.** Try the bundle on a throwaway folder before committing to a global install.

Project-local installs don't conflict with each other or with a global install. Claude Code merges global and project skills automatically.

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash -s -- --update
```

This re-runs the install, pulling fresh versions of all sources. Skills you've added manually to `~/.claude/skills/` from other places are untouched.

## Uninstall

```bash
./install.sh --uninstall                              # global
./install.sh --uninstall --prefix=$(pwd)/my-project   # project-local
```

The manifest at `~/.stellar/manifest.json` (or `$PREFIX/.stellar/manifest.json`) tracks every path and permission stellar-build touched, so uninstall reverses cleanly.

## Built on

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** (MIT). Methodology skill backbone; personas paraphrased to match the SDF DevRel team.
- **[stellar/stellar-dev-skill](https://github.com/stellar/stellar-dev-skill)** (Apache 2.0). Official Stellar developer skills.
- **[lumenloop/awesome-stellar-community-fund](https://github.com/lumenloop/awesome-stellar-community-fund)**. SCF grant lifecycle skills.
- **[lumenloop/stellar-ecosystem-db](https://github.com/lumenloop/stellar-ecosystem-db)**. 728-project database.
- **[electric-capital/open-dev-data](https://github.com/electric-capital/open-dev-data)** (MIT + CC-BY 4.0). Developer activity taxonomy.
- **[stellar/ecosystem-resources](https://github.com/stellar/ecosystem-resources)**. Curated Stellar reference docs.

Inspired by the [solana.new](https://www.solana.new) install pattern.
