# Oracles on Stellar

This guide covers oracle solutions for bringing off-chain data to Stellar/Soroban smart contracts.

## Overview

Oracles provide external data (prices, events, etc.) to smart contracts. On Stellar, the primary oracle solution is Reflector Network, with additional options like DIA.

## Why Use an Oracle?

Smart contracts can't access external data directly. Oracles bridge this gap for:

- **Price feeds** - Token prices for DeFi protocols
- **Random numbers** - Gaming and lottery applications
- **External events** - Real-world data triggers
- **Cross-chain data** - Information from other blockchains

## Oracle Providers

### Reflector Network

The primary community-powered price oracle for Stellar, implementing SEP-40.

| Feature | Details |
|---------|---------|
| **Website** | [reflector.network](https://reflector.network) |
| **Docs** | [Stellar Oracle Providers](https://developers.stellar.org/docs/data/oracles/oracle-providers) |
| **Standard** | SEP-40 compatible |

**Features:**
- On-chain and off-chain price data
- Webhook notifications
- Community-operated nodes
- Multiple asset support

**Integrations:**
- Blend Protocol
- Orbit CDP
- DeFindex
- Laina
- EquitX
- Slender

### DIA Oracle

Cross-chain oracle with extensive asset coverage.

| Feature | Details |
|---------|---------|
| **Website** | [diadata.org](https://diadata.org) |
| **Blog** | [DIA on Soroban](https://www.diadata.org/blog/post/soroban-stellar-oracle-dia/) |
| **Assets** | 20,000+ supported |

**Features:**
- VWAPIR pricing methodology
- Custom feed configuration
- Cross-chain compatibility
- Enterprise support

## Using Oracles in Contracts

### Reading Price Data (SEP-40)

```rust
use soroban_sdk::{contract, contractimpl, Address, Env};

#[contract]
pub struct MyContract;

#[contractimpl]
impl MyContract {
    pub fn get_price(e: &Env, oracle: Address, asset: Address) -> i128 {
        // Call oracle contract to get price
        let price: i128 = e.invoke_contract(
            &oracle,
            &Symbol::new(e, "lastprice"),
            vec![&e, asset.into_val(e)],
        );
        price
    }
}
```

### Price Feed Structure

SEP-40 oracles typically return:

```rust
pub struct PriceData {
    pub price: i128,      // Price in base units
    pub timestamp: u64,   // Unix timestamp
}
```

## Best Practices

1. **Use multiple sources** - Cross-reference prices when possible
2. **Check staleness** - Verify timestamp is recent
3. **Handle failures** - Gracefully handle oracle unavailability
4. **Set boundaries** - Reject prices outside reasonable ranges
5. **Consider latency** - Account for block time in time-sensitive operations

## Security Considerations

- **Oracle manipulation** - Be aware of flash loan attacks
- **Stale data** - Always check price freshness
- **Single point of failure** - Consider decentralized oracles
- **Price deviation** - Implement circuit breakers for large swings

## Resources

- [SEP-40: Oracle Standard](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0040.md)
- [Reflector Network](https://reflector.network)
- [DIA Documentation](https://docs.diadata.org/)
- [Stellar Oracle Providers](https://developers.stellar.org/docs/data/oracles/oracle-providers)
