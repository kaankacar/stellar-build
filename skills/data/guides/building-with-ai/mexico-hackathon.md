# Hack+ Alebrije CDMX 2026 — Developer Guide

> **Source:** [kaankacar/stellar-ai-guide-mx](https://github.com/kaankacar/stellar-ai-guide-mx)  
> **Context:** Assembled by the SDF DevRel team for the Mexico City hackathon (Hack+ Alebrije | CDMX 2026). Mexico-specific in places (Etherfuse, SPEI, MXN rails), but the AI setup, prompt templates, and Soroban debugging sections are broadly applicable.

Mexico has one of the most active SPEI networks in the world and a massive remittance corridor with the US. Stellar is built for exactly this. This guide helps every developer at the event move fast, regardless of their AI subscription status or Stellar experience level.

## Files in the Source Repo

| File | Description |
|------|-------------|
| `Starter_Prompts.md` | Protocol context block, wallet-vs-dApp prompt patterns, CLAUDE.md template |
| `Dev_Setup_Guide.md` | API keys, testnet contract addresses, auth patterns, critical gotchas |
| `Hackathon_Resources.md` | Regional starter pack, DeFi reference implementations, AI Integration Series |
| `Free_AI_Setup.md` | Free AI model options (NVIDIA Nemotron, Groq, Mistral, Ollama, GPU rental) |
| `Claude_Code_Guide.md` | Plan mode, parallel agents, browser automation, keyboard shortcuts |
| `Recommended_AI_Tools.md` | Broader landscape of available AI tools |

## Suggested Reading Order

1. `Starter_Prompts.md` — before your first Claude Code session
2. `Free_AI_Setup.md` — if you need a free AI setup
3. `Dev_Setup_Guide.md` — before writing any code
4. `Hackathon_Resources.md` — to orient in the Stellar ecosystem
5. `Claude_Code_Guide.md` — for commands, parallel agents, and browser automation

## Key Highlights

### Free AI Setup

Fastest path: NVIDIA Nemotron 3 Super via OpenRouter — 120B parameter model, 262K context window, strong on SWE-Bench, free. Also covers Groq (Llama 3.1 8B, 14,400 req/day), Mistral Codestral (2,000 req/day, code-optimized), Google AI Studio, and local models via Ollama.

### Regional Anchors (Mexico / Latin America)

- **Etherfuse** — MXN ↔ CETES via SPEI. API: `devnet.etherfuse.com`. Auth: `Authorization: your-api-key` (no Bearer prefix).
- **AlfredPay** — MXN ↔ USDC via SPEI.
- **BlindPay** — cross-border payments.

Regional starter pack: [ElliotFriend/regional-starter-pack](https://github.com/ElliotFriend/regional-starter-pack) — SvelteKit app with a portable TypeScript anchor library covering SEP-1, 6, 10, 12, 24, 31, and 38.

### Critical Soroban Gotchas

- Always `simulateTransaction` + `assembleTransaction` before `sendTransaction`
- `sendTransaction` returns `PENDING` — poll with `rpc.Server.pollTransaction`
- DeFindex: amounts are always arrays, endpoint is `/vault/` not `/vaults/`, success is HTTP 201
- Etherfuse: `customer_id` and `bankAccountId` are per-user and permanent — never regenerate per session
- Etherfuse sandbox: POST to `/ramp/order/fiat_received` to simulate fiat arriving (orders don't auto-progress)
- Testnet USDC has multiple issuers that don't share liquidity — pick the wrong one and swaps silently fail

### Auth Pattern Quick Reference

| Protocol | Auth Header Format |
|----------|-------------------|
| Etherfuse | `Authorization: your-api-key` |
| DeFindex | `Authorization: Bearer your-api-key` |
| Trustless Work | `Authorization: x-api-key: your-api-key` |

### AI Integration Reference Implementations (carstenjacobsen)

Built with Claude Code, each paired with a `BUILD_REPORT.md`:

- [ai-freighter-integration](https://github.com/carstenjacobsen/ai-freighter-integration) — Freighter wallet, balances, send, history
- [ai-soroswap-integration](https://github.com/carstenjacobsen/ai-soroswap-integration) — Multi-DEX swap aggregator
- [ai-defindex-integration](https://github.com/carstenjacobsen/ai-defindex-integration) — DeFindex yield vaults
- [ai-passkeys-integration](https://github.com/carstenjacobsen/ai-passkeys-integration) — WebAuthn passkey smart wallet + Etherfuse MXN ramp
- [ai-etherfuse-integration](https://github.com/carstenjacobsen/ai-etherfuse-integration) — Full Etherfuse ramp + DeFindex + Freighter

### Community Resources

- [Stellar Hackathon FAQ](https://github.com/briwylde08/stellar-hackathon-faq)
- [Stellar DeFi Gotchas](https://github.com/kaankacar/stellar-defi-gotchas) — 400+ findings from 60 vibe-coding runs
- [Stellar Ecosystem DB](https://github.com/lumenloop/stellar-ecosystem-db) — 646 Stellar projects, structured

---

*See the full source at [kaankacar/stellar-ai-guide-mx](https://github.com/kaankacar/stellar-ai-guide-mx) for the complete guides with all links and code snippets.*
