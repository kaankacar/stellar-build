# Soroban Smart Contract Development

This guide covers the fundamentals of developing smart contracts on Stellar using Soroban and the Rust SDK.

## Overview

Soroban is Stellar's smart contract platform. Contracts are written in Rust and compile to WebAssembly (WASM).

## Getting Started

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Install Stellar CLI
cargo install --locked stellar-cli --features opt
```

### Create a New Project

```bash
stellar contract init my-contract
cd my-contract
```

### Project Structure

```
my-contract/
├── Cargo.toml
├── src/
│   └── lib.rs
└── contracts/
    └── hello_world/
        ├── Cargo.toml
        └── src/
            └── lib.rs
```

## Basic Contract

```rust
#![no_std]
use soroban_sdk::{contract, contractimpl, symbol_short, Env, Symbol};

#[contract]
pub struct HelloContract;

#[contractimpl]
impl HelloContract {
    pub fn hello(env: Env, to: Symbol) -> Symbol {
        symbol_short!("Hello")
    }
}
```

## Storage Types

Soroban has three storage types with different characteristics:

| Type | Duration | Cost | Use Case |
|------|----------|------|----------|
| **Temporary** | ~24 hours | Cheapest | Cache, sessions |
| **Persistent** | Until archived | Medium | User data, balances |
| **Instance** | Contract lifetime | Higher | Config, admin settings |

### Temporary Storage

```rust
// Temporary: Cheapest, expires after ~24 hours
e.storage().temporary().set(&key, &value);
let val: i128 = e.storage().temporary().get(&key).unwrap_or(0);
```

### Persistent Storage

```rust
// Persistent: Main storage for user data
e.storage().persistent().set(&key, &value);
let val: i128 = e.storage().persistent().get(&key).unwrap_or(0);

// Extend TTL to prevent archival
e.storage().persistent().extend_ttl(&key, 100, 1000);
```

### Instance Storage

```rust
// Instance: Stored with the contract instance
e.storage().instance().set(&key, &value);
let admin: Address = e.storage().instance().get(&symbol_short!("admin")).unwrap();
```

## Data Types

### Common Types

```rust
use soroban_sdk::{
    Address,    // Stellar addresses (G... or C...)
    Bytes,      // Raw bytes
    BytesN,     // Fixed-length bytes
    Map,        // Key-value map
    String,     // UTF-8 string
    Symbol,     // Short identifier (max 32 chars)
    Vec,        // Dynamic array
    Val,        // Generic value
};
```

### Custom Types

```rust
use soroban_sdk::contracttype;

#[contracttype]
#[derive(Clone)]
pub struct TokenMetadata {
    pub name: String,
    pub symbol: Symbol,
    pub decimals: u32,
}

#[contracttype]
pub enum DataKey {
    Balance(Address),
    Allowance(Address, Address),
    Admin,
}
```

## Authorization

### Requiring Auth

```rust
pub fn transfer(e: &Env, from: Address, to: Address, amount: i128) {
    // Verify the caller is authorized to act as 'from'
    from.require_auth();

    // ... transfer logic
}
```

### Auth with Arguments

```rust
pub fn transfer(e: &Env, from: Address, to: Address, amount: i128) {
    // Verify auth with specific arguments
    from.require_auth_for_args((&to, amount).into_val(e));

    // ... transfer logic
}
```

## Events

```rust
use soroban_sdk::{symbol_short, Env};

pub fn emit_transfer(e: &Env, from: &Address, to: &Address, amount: i128) {
    let topics = (symbol_short!("transfer"), from, to);
    e.events().publish(topics, amount);
}
```

## Cross-Contract Calls

```rust
use soroban_sdk::{contract, contractimpl, Address, Env};

mod token {
    soroban_sdk::contractimport!(
        file = "../token/target/wasm32-unknown-unknown/release/token.wasm"
    );
}

#[contract]
pub struct MyContract;

#[contractimpl]
impl MyContract {
    pub fn transfer_token(
        e: Env,
        token_address: Address,
        from: Address,
        to: Address,
        amount: i128
    ) {
        let client = token::Client::new(&e, &token_address);
        client.transfer(&from, &to, &amount);
    }
}
```

## Testing

### Unit Tests

```rust
#![cfg(test)]
use super::*;
use soroban_sdk::Env;

#[test]
fn test_hello() {
    let env = Env::default();
    let contract_id = env.register_contract(None, HelloContract);
    let client = HelloContractClient::new(&env, &contract_id);

    let result = client.hello(&symbol_short!("World"));
    assert_eq!(result, symbol_short!("Hello"));
}
```

### Running Tests

```bash
# Native tests (fast)
cargo test

# WASM tests (accurate)
cargo test --features testutils
```

### Integration Tests

```rust
#![cfg(test)]
use soroban_sdk::{testutils::Address as _, Address, Env};

#[test]
fn test_with_auth() {
    let env = Env::default();
    env.mock_all_auths();  // Auto-approve all auth requests

    let admin = Address::generate(&env);
    let user = Address::generate(&env);

    // ... test logic
}
```

## Building & Deploying

### Build

```bash
stellar contract build
```

### Deploy to Testnet

```bash
# Configure identity
stellar keys generate alice --network testnet
stellar keys fund alice --network testnet

# Deploy
stellar contract deploy \
  --wasm target/wasm32-unknown-unknown/release/my_contract.wasm \
  --source alice \
  --network testnet
```

### Invoke

```bash
stellar contract invoke \
  --id <CONTRACT_ID> \
  --source alice \
  --network testnet \
  -- \
  hello \
  --to World
```

## Common Pitfalls

### 1. Panic Handling

```rust
// Bad: Panics with unhelpful message
let value = storage.get(&key).unwrap();

// Good: Explicit error handling
let value = storage.get(&key).unwrap_or_else(|| panic!("Key not found"));

// Better: Return Result type
pub fn get_value(e: &Env, key: Symbol) -> Result<i128, Error> {
    e.storage().persistent().get(&key).ok_or(Error::NotFound)
}
```

### 2. Integer Overflow

```rust
// Bad: Can panic on overflow
let total = a + b;

// Good: Checked arithmetic
let total = a.checked_add(b).expect("overflow");
```

### 3. Missing Authorization

```rust
// Bad: Anyone can call this!
pub fn set_admin(e: Env, new_admin: Address) {
    e.storage().instance().set(&symbol_short!("admin"), &new_admin);
}

// Good: Require current admin auth
pub fn set_admin(e: Env, new_admin: Address) {
    let current_admin: Address = e.storage().instance().get(&symbol_short!("admin")).unwrap();
    current_admin.require_auth();
    e.storage().instance().set(&symbol_short!("admin"), &new_admin);
}
```

### 4. Storage TTL

```rust
// Remember to extend TTL for persistent storage
pub fn deposit(e: &Env, user: Address, amount: i128) {
    let key = DataKey::Balance(user.clone());
    let balance: i128 = e.storage().persistent().get(&key).unwrap_or(0);
    e.storage().persistent().set(&key, &(balance + amount));

    // Extend TTL to prevent archival
    e.storage().persistent().extend_ttl(&key, 100, 1000);
}
```

## Resources

- [Stellar Developer Docs - Smart Contracts](https://developers.stellar.org/docs/build/smart-contracts)
- [Soroban Examples](https://github.com/stellar/soroban-examples)
- [Soroban SDK Docs](https://docs.rs/soroban-sdk/latest/soroban_sdk/)
- [OpenZeppelin Stellar Contracts](https://github.com/OpenZeppelin/stellar-contracts)
- [Testing Guide](https://stellar.org/blog/developers/the-definitive-guide-to-testing-smart-contracts-on-stellar)
