# DeFi Protocols on Stellar

This guide covers the major DeFi protocols built on Stellar/Soroban.

## Overview

Stellar's DeFi ecosystem has grown significantly with Soroban smart contracts. Key categories include lending/borrowing, DEXs/AMMs, yield vaults, and stablecoin protocols.

## Lending & Borrowing

### Blend Protocol

The most popular lending protocol on Stellar, enabling permissionless lending pools.

| Feature | Details |
|---------|---------|
| **Use Case** | Lending, borrowing, yield generation |
| **GitHub** | [blend-capital/blend-contracts](https://github.com/blend-capital/blend-contracts) |
| **GitHub (v2)** | [blend-capital/blend-contracts-v2](https://github.com/blend-capital/blend-contracts-v2) |
| **Integrations** | Meru, Airtm, LOBSTR, DeFindex, Beans |

**Features:**
- Permissionless pool creation
- Variable interest rates
- Multiple collateral types
- Flash loan support

## DEXs & AMMs

### Soroswap

The first DEX and aggregator on Stellar/Soroban.

| Feature | Details |
|---------|---------|
| **Website** | [soroswap.finance](https://soroswap.finance) |
| **Docs** | [docs.soroswap.finance](https://docs.soroswap.finance) |
| **GitHub (Core)** | [soroswap/core](https://github.com/soroswap/core) |
| **GitHub (Frontend)** | [soroswap/frontend](https://github.com/soroswap/frontend) |
| **GitHub (Aggregator)** | [soroswap/aggregator](https://github.com/soroswap/aggregator) |

**Features:**
- AMM with constant product formula
- DEX aggregator across multiple protocols
- Liquidity provision with LP tokens
- Routes through Aqua, Phoenix, Stellar Classic DEX

### Aquarius / AQUA Network

Governance-driven liquidity layer with AMM functionality.

| Feature | Details |
|---------|---------|
| **Website** | [aqua.network](https://aqua.network) |
| **Docs** | [docs.aqua.network](https://docs.aqua.network) |
| **GitHub** | [AquaToken/soroban-amm](https://github.com/AquaToken/soroban-amm) |
| **Token** | AQUA (governance + rewards) |

**Features:**
- Liquidity incentive programs
- Governance voting
- AMM pools
- Reward distribution

### Phoenix Protocol

AMM protocol on Soroban.

| Feature | Details |
|---------|---------|
| **GitHub** | [Phoenix-Protocol-Group](https://github.com/Phoenix-Protocol-Group) |
| **Use Case** | Token swaps, liquidity pools |

## Yield & Vaults

### DeFindex

Yield aggregation and vault infrastructure by PaltaLabs.

| Feature | Details |
|---------|---------|
| **Docs** | [docs.defindex.io](https://docs.defindex.io) |
| **Use Case** | Tokenized vaults, yield strategies, DeFi abstraction |

**Features:**
- Automated rebalancing
- Vault management
- Blend protocol integration
- Strategy composition

## Stablecoins & CDPs

### Orbit CDP Protocol

Collateralized stablecoin issuance supporting multiple currencies.

| Feature | Details |
|---------|---------|
| **Docs** | [docs.orbitcdp.finance](https://docs.orbitcdp.finance) |
| **Use Case** | Mint stablecoins against collateral |

**Features:**
- Multi-currency stablecoins (USD, EUR, MXN)
- XLM and bond collateral
- Pegkeeper automation
- Blend protocol integration

## Major Stablecoins on Stellar

| Stablecoin | Issuer | Currency |
|------------|--------|----------|
| **USDC** | Circle | USD |
| **EURC** | Circle | EUR |
| **PYUSD** | PayPal | USD |

## Integration Tips

### Using Blend Protocol

```typescript
// Example: Query pool data
import { BlendClient } from "@blend-capital/blend-sdk";

const client = new BlendClient(rpcUrl, networkPassphrase);
const poolData = await client.getPoolData(poolAddress);
```

### Using Soroswap

```typescript
// Example: Get swap quote
import { SoroswapRouter } from "@soroswap/sdk";

const router = new SoroswapRouter(rpcUrl);
const quote = await router.getAmountsOut(amountIn, [tokenA, tokenB]);
```

## Resources

- [Stellar DeFi Overview](https://stellar.org/use-cases/defi)
- [Blend Protocol Docs](https://docs.blend.capital/)
- [Soroswap Docs](https://docs.soroswap.finance)
- [DeFindex Docs](https://docs.defindex.io)
