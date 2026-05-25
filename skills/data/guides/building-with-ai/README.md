# Building on Stellar with AI

> **Note:** This section will be updated over time as AI tooling for Stellar development evolves.

## In this Directory

| Item | Link |
|------|------|
| Mexico Hackathon Guide | [`mexico-hackathon.md`](./mexico-hackathon.md) |
| Stellar Dev Skill | [stellar/stellar-dev-skill](https://github.com/stellar/stellar-dev-skill) |
| OpenZeppelin Skills | [OpenZeppelin/openzeppelin-skills](https://github.com/OpenZeppelin/openzeppelin-skills) |
| Stellar MCP Server | [kalepail/stellar-mcp-server](https://github.com/kalepail/stellar-mcp-server) |
| XDR MCP | [stellar-experimental/mcp-stellar-xdr](https://github.com/stellar-experimental/mcp-stellar-xdr) |
| x402 Payments | [stellar/x402-stellar](https://github.com/stellar/x402-stellar) |

AI-powered tools are increasingly available to help developers build on Stellar more efficiently. This guide covers the current landscape.

## Available Tools

### Stella — Official Stellar AI Assistant

The official AI assistant for Stellar developer questions, maintained by the Stellar Development Foundation.

- **Docs site:** Yellow chat icon on [developers.stellar.org](https://developers.stellar.org/)
- **Direct link:** [developers.stellar.org/docs/tools/developer-tools/ai-bot](https://developers.stellar.org/docs/tools/developer-tools/ai-bot)
- **Discord:** `#stella-help` channel on [Stellar Dev Discord](https://discord.gg/stellardev)

### llms.txt — Machine-Readable Stellar Docs

A structured digest of the Stellar documentation formatted for feeding directly into LLMs. Covers Build, Learn, Tokens, Data, Tools, Networks, and Validators sections.

- **URL:** [developers.stellar.org/llms.txt](https://developers.stellar.org/llms.txt)
- **Use:** Paste into your AI assistant's context window to provide up-to-date Stellar context and help reduce hallucinations.

### OpenZeppelin MCP Server

Generate secure Stellar smart contracts using AI through the Model Context Protocol.

| Feature | Details |
|---------|---------|
| **URL** | [mcp.openzeppelin.com](https://mcp.openzeppelin.com/) |
| **Purpose** | AI-assisted contract generation |
| **Based On** | OpenZeppelin Stellar Contracts |

**Capabilities:**
- Generate fungible tokens (SEP-41)
- Generate NFTs (SEP-50)
- Generate stablecoins
- Configure features via natural language

**Example Prompt:**
> "Create a fungible token called 'MyToken' with symbol 'MTK', 18 decimals, mintable and burnable, with role-based access control"

### OpenZeppelin Skills (Claude Code)

Claude Code plugin providing three skills for secure Stellar contract development.

**Install:**
```bash
/plugin marketplace add OpenZeppelin/openzeppelin-skills
```

**Skills included:**
- `setup-stellar-contracts` — scaffold an audited Soroban contract project
- `upgrade-stellar-contracts` — migrate and upgrade existing contracts safely
- `develop-secure-contracts` — guided secure development workflow

Also auto-installs the OpenZeppelin MCP server for AI-assisted contract generation.

**Repository:** [OpenZeppelin/openzeppelin-skills](https://github.com/OpenZeppelin/openzeppelin-skills)

### Stellar MCP Server (kalepail)

An MCP server running on Cloudflare Workers that exposes Stellar wallet, token, and contract tools directly to Claude and other AI clients.

- **Repository:** [kalepail/stellar-mcp-server](https://github.com/kalepail/stellar-mcp-server)
- **Use:** Give your AI agent live access to Stellar network operations — no manual SDK wiring needed.

### XDR MCP (leighmcculloch)

An MCP server that decodes and encodes Stellar XDR to and from JSON for AI agents.

- **Repository:** [stellar-experimental/mcp-stellar-xdr](https://github.com/stellar-experimental/mcp-stellar-xdr)
- **Use:** Let AI agents read and construct raw Stellar transactions and envelopes without manual XDR parsing.

### x402 — HTTP Payments for AI Agents

Repurposes the HTTP 402 Payment Required status into a real payment mechanism powered by Soroban auth entry signing. AI agents can autonomously pay for API calls without human intervention.

**How it works:**
1. Agent hits a paywalled endpoint, receives a `402` with payment instructions
2. Agent signs a Soroban auth entry and retries with the payment header
3. Facilitator (OpenZeppelin Relayer) settles on-chain

- **Docs:** [developers.stellar.org/docs/build/apps/x402](https://developers.stellar.org/docs/build/apps/x402)
- **Official monorepo:** [stellar/x402-stellar](https://github.com/stellar/x402-stellar)
- **Community demo:** [jamesbachini/x402-Stellar-Demo](https://github.com/jamesbachini/x402-Stellar-Demo)
- **Supported wallets:** Freighter, Albedo, Hana, HOT, Klever, OneKey

### Context7 for Documentation

Use Context7 to query up-to-date Stellar documentation in AI assistants.

**Library IDs:**
- Stellar SDK documentation
- Soroban contract examples
- Integration guides

### Stellar Dev Skill

An AI skill that gives assistants deep, current knowledge of the Stellar development ecosystem.

**Repository:** [stellar/stellar-dev-skill](https://github.com/stellar/stellar-dev-skill)

**Covers:**
- Soroban smart contracts (Rust SDK, WebAssembly)
- Client SDKs: stellar-sdk (JavaScript), Python, Go, Rust
- Stellar RPC (preferred) and Horizon (legacy)
- Stellar Assets, SAC, trustlines
- Wallets: Freighter, Stellar Wallets Kit, Smart Accounts
- ZK proofs, security patterns, common pitfalls
- DeFi protocols and ecosystem tools

**Installing in Claude Code:**
```bash
/plugin marketplace add stellar/stellar-dev-skill
/plugin install stellar-dev@stellar-dev-skill
```

**Other agents:**
```bash
npx skills add https://github.com/stellar/stellar-dev-skill
```

> **Note:** This skill is AI-generated and currently under manual review. Contributions and PRs are welcome.

### Hack+ Alebrije CDMX 2026 — AI Guide (Mexico)

A developer guide assembled for the Mexico City hackathon, covering free AI setup, regional anchor integrations, and Soroban gotchas.

**File:** [`mexico-hackathon.md`](./mexico-hackathon.md)  
**Repository:** [kaankacar/stellar-ai-guide-mx](https://github.com/kaankacar/stellar-ai-guide-mx)

Primarily Mexico-focused (Etherfuse MXN rails, SPEI, peso corridors) but the AI setup, prompt templates, and Soroban debugging sections are broadly applicable.

## Resources

**Stellar-native AI tools:**
- [Stella — Official AI Bot](https://developers.stellar.org/docs/tools/developer-tools/ai-bot)
- [llms.txt — Machine-Readable Stellar Docs](https://developers.stellar.org/llms.txt)
- [Stellar Dev Skill](https://github.com/stellar/stellar-dev-skill)
- [OpenZeppelin Skills (Claude Code)](https://github.com/OpenZeppelin/openzeppelin-skills)
- [Stellar MCP Server](https://github.com/kalepail/stellar-mcp-server)
- [XDR MCP](https://github.com/stellar-experimental/mcp-stellar-xdr)
- [x402 — HTTP Payments for AI Agents](https://developers.stellar.org/docs/build/apps/x402)
- [OpenZeppelin MCP Server](https://mcp.openzeppelin.com/)
- [OpenZeppelin Contract Wizard](https://wizard.openzeppelin.com/stellar)
- [AI Guide — Mexico / Hack+ Alebrije CDMX 2026](./mexico-hackathon.md)

**General:**
- [Stellar Developer Docs](https://developers.stellar.org/)
- [Stellar Developer Discord](https://discord.gg/stellardev)

---

*Last updated: April 2026*

*This guide will be expanded as new AI tools become available for Stellar development.*
