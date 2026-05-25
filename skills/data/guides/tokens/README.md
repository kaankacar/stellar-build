# Stellar Assets vs Soroban Tokens

This guide explains the different token types on Stellar and when to use each.

## Overview

Stellar has two types of tokens:

| Type | Description | Best For |
|------|-------------|----------|
| **Stellar Assets** | Classic native tokens with built-in operations | Most fungible tokens |
| **Soroban Tokens** | Smart contract-based tokens | Complex token logic |

**Recommendation:** Prefer Stellar Assets for most use cases. They have better ecosystem support and lower costs.

## Stellar Assets (Classic)

### What Are They?

Stellar Assets are native to the Stellar protocol. They use built-in operations (not smart contracts) for issuance and transfers.

### Advantages

- **Ecosystem support** - All wallets, exchanges, and anchors support them
- **Lower costs** - No smart contract execution fees
- **Faster** - Native protocol operations
- **SEP compliance** - Built-in support for SEP-6, SEP-24, SEP-31
- **Trustlines** - Built-in authorization model

### Creating a Stellar Asset

```typescript
import * as StellarSdk from "@stellar/stellar-sdk";

// Asset is defined by code + issuer
const asset = new StellarSdk.Asset("MYTOKEN", issuerPublicKey);

// User must establish trustline first
const trustlineOp = StellarSdk.Operation.changeTrust({
  asset: asset,
  limit: "1000000", // Max amount to hold
});

// Issuer mints by sending payment
const mintOp = StellarSdk.Operation.payment({
  destination: recipientPublicKey,
  asset: asset,
  amount: "1000",
});
```

### Asset Authorization

Stellar Assets support authorization flags:

| Flag | Description |
|------|-------------|
| **AUTH_REQUIRED** | Issuer must approve trustlines |
| **AUTH_REVOCABLE** | Issuer can freeze/unfreeze accounts |
| **AUTH_IMMUTABLE** | Flags cannot be changed |
| **AUTH_CLAWBACK_ENABLED** | Issuer can clawback tokens |

## Stellar Asset Contracts (SAC)

### What Are They?

SAC bridges Stellar Assets to Soroban. Every Stellar Asset automatically has a corresponding SAC, allowing smart contracts to interact with classic assets.

### Use Case

When you need to use a Stellar Asset within a Soroban smart contract:

```rust
use soroban_sdk::{Address, Env};

// SAC address is derived from the asset
pub fn get_sac_address(e: &Env, asset_code: &str, issuer: &Address) -> Address {
    // SAC addresses are deterministic based on asset
    // Use stellar CLI to find the SAC address:
    // stellar contract id asset --asset MYTOKEN:GISSUER --network testnet
}

// Interact with SAC like any token contract
mod token {
    soroban_sdk::contractimport!(
        file = "soroban_token_spec.wasm"
    );
}

pub fn transfer_asset(e: &Env, sac_address: Address, from: Address, to: Address, amount: i128) {
    let client = token::Client::new(&e, &sac_address);
    client.transfer(&from, &to, &amount);
}
```

### Finding SAC Address

```bash
# Get SAC contract ID for an asset
stellar contract id asset \
  --asset USDC:GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN \
  --network mainnet
```

## Custom Soroban Tokens

### When to Use

Only use custom Soroban tokens when you need:

- Complex transfer logic (fees, restrictions)
- Non-standard minting rules
- Integration with specific DeFi mechanics
- Features not available in Stellar Assets

### SEP-41 Token Interface

Standard interface for Soroban tokens:

```rust
pub trait TokenInterface {
    fn allowance(e: Env, from: Address, spender: Address) -> i128;
    fn approve(e: Env, from: Address, spender: Address, amount: i128, expiration_ledger: u32);
    fn balance(e: Env, id: Address) -> i128;
    fn transfer(e: Env, from: Address, to: Address, amount: i128);
    fn transfer_from(e: Env, spender: Address, from: Address, to: Address, amount: i128);
    fn burn(e: Env, from: Address, amount: i128);
    fn burn_from(e: Env, spender: Address, from: Address, amount: i128);
    fn decimals(e: Env) -> u32;
    fn name(e: Env) -> String;
    fn symbol(e: Env) -> String;
}
```

### Using OpenZeppelin Contracts

```rust
use stellar_tokens::fungible::{Base, FungibleToken};
use stellar_macros::default_impl;

#[contract]
pub struct MyToken;

#[default_impl]
#[contractimpl]
impl FungibleToken for MyToken {
    type ContractType = Base;
}
```

## Decision Guide

```
Do you need a fungible token?
  │
  ├─ Standard transfers, ecosystem compatibility
  │   └─► Use Stellar Asset
  │
  ├─ Need to use in Soroban contracts?
  │   └─► Use Stellar Asset + SAC
  │
  ├─ Need custom transfer logic (fees, restrictions)?
  │   └─► Use Custom Soroban Token (SEP-41)
  │
  └─ Need complex DeFi integration?
      └─► Use Custom Soroban Token

Do you need an NFT?
  │
  └─► Use Soroban NFT (SEP-50) via OpenZeppelin Contracts
```

## Comparison Table

| Feature | Stellar Asset | SAC | Soroban Token |
|---------|---------------|-----|---------------|
| Wallet Support | ✅ Full | ✅ Full | ⚠️ Varies |
| Exchange Listings | ✅ Easy | ✅ Easy | ⚠️ Harder |
| Transaction Cost | Lowest | Medium | Highest |
| Custom Logic | ❌ No | ❌ No | ✅ Yes |
| Soroban Compatible | Via SAC | ✅ Yes | ✅ Yes |
| Compliance Features | ✅ Built-in | ✅ Built-in | ✅ Custom |

## Examples

### Stellar Asset for Payments

```typescript
// Simple asset for payments - use Stellar Asset
const paymentToken = new StellarSdk.Asset("PAY", issuerAddress);
// Users create trustlines, issuer mints via payments
```

### Tokenized Asset with Compliance

```typescript
// RWA with compliance - use Stellar Asset with flags
const rwaAsset = new StellarSdk.Asset("REALESTATE", issuerAddress);
// Set AUTH_REQUIRED + AUTH_REVOCABLE for KYC compliance
```

### DeFi LP Token

```rust
// LP token with custom mint/burn - use Soroban Token
// Custom logic for minting based on liquidity deposits
#[contract]
pub struct LPToken;

#[contractimpl]
impl LPToken {
    pub fn mint_lp(e: Env, depositor: Address, amount_a: i128, amount_b: i128) -> i128 {
        depositor.require_auth();
        // Custom LP calculation logic
        let lp_amount = calculate_lp(amount_a, amount_b);
        // Mint LP tokens
        mint_internal(&e, &depositor, lp_amount);
        lp_amount
    }
}
```

## Resources

- [Stellar Assets Documentation](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/assets)
- [SEP-41: Token Interface](https://developers.stellar.org/docs/tokens/token-interface)
- [OpenZeppelin Stellar Contracts](https://github.com/OpenZeppelin/stellar-contracts)
- [Native vs Soroban Tokens (CheesecakeLabs)](https://cheesecakelabs.com/blog/native-tokens-vs-soroban-tokens/)
