# stellar-build

A one-command install that drops an end-to-end Stellar development journey into your Claude Code and OpenAI Codex CLI setup. From "what should I build?" to mainnet deploy and Stellar Community Fund grant submission — 42 skills + curated ecosystem data.

```bash
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash
```

## What you get

**42 skills across the full journey:**

- **Idea phase** — discover what to build on Stellar, validate against the 728-project ecosystem
- **Planning phase** — PRD, UX design, product brief (with personas from the SDF DevRel team)
- **Solutioning phase** — architecture, epics, stories, plus deep Soroban + dapp + asset knowledge
- **Implementation phase** — story-driven dev, code review, debugging
- **Launch phase** — devnet → mainnet deploy + 10 SCF grant lifecycle skills

**Curated data:**

- The full LumenLoop ecosystem DB (728 projects, SCF rounds, audits, tokens)
- Electric Capital's Stellar developer activity data
- Stellar Foundation's ecosystem-resources reference docs

## How it works

The install pulls from four canonical sources at install time:

1. This repo (`kaankacar/stellar-build`) — paraphrased methodology skills + 5 new Stellar-specific skills + installer
2. `lumenloop/awesome-stellar-community-fund` — 10 SCF lifecycle skills
3. `stellar/stellar-dev-skill` — 7 Stellar dev knowledge modules (Soroban, dapp, assets, data, agentic payments, ZK proofs, standards)
4. `lumenloop/stellar-ecosystem-db` — the 728-project YAML database, converted to JSON

We don't redistribute upstream content — we point your install at the canonical sources. See [NOTICES.md](./NOTICES.md) for attribution.

## Sandboxed install (no real $HOME touched)

For testing or trying it out without affecting your real Claude Code config:

```bash
./install.sh --prefix=$(pwd)/test-install
```

This puts everything under `./test-install/.claude/skills/` and `./test-install/.codex/skills/` instead of your real `$HOME`.

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash -s -- --update
```

## Uninstall

```bash
./install.sh --uninstall
```

Manifest-tracked — only removes what we installed.

## Built on

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** (MIT) — methodology skill backbone, with personas customized for the SDF DevRel team
- **[stellar/stellar-dev-skill](https://github.com/stellar/stellar-dev-skill)** (Apache 2.0) — official Stellar developer skills
- **[lumenloop/awesome-stellar-community-fund](https://github.com/lumenloop/awesome-stellar-community-fund)** — SCF grant lifecycle skills
- **[lumenloop/stellar-ecosystem-db](https://github.com/lumenloop/stellar-ecosystem-db)** — 728-project database
- **[electric-capital/open-dev-data](https://github.com/electric-capital/open-dev-data)** (MIT + CC-BY 4.0) — developer activity data
- **[stellar/ecosystem-resources](https://github.com/stellar/ecosystem-resources)** — curated Stellar reference docs

Inspired by [solana.new](https://www.solana.new).
