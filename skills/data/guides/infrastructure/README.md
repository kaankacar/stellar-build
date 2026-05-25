# Stellar Infrastructure

This guide covers infrastructure components for building production applications on Stellar, including anchors, SEPs, and bulk payment systems.

## Anchors & On/Off Ramps

### What Are Anchors?

Anchors are entities that issue assets on Stellar and provide fiat on/off ramps. They bridge traditional finance with the Stellar network.

### Anchor Platform

SDF-maintained platform for building SEP-compliant anchor services.

| Feature | Details |
|---------|---------|
| **GitHub** | [stellar/java-stellar-anchor-sdk](https://github.com/stellar/java-stellar-anchor-sdk) |
| **Docs** | [developers.stellar.org/docs/category/anchor-platform](https://developers.stellar.org/docs/category/anchor-platform) |
| **Language** | Java/Kotlin |

**Features:**
- Pre-built SEP implementations
- Compliance integrations
- Customer management
- Transaction monitoring

## SEP Standards

Stellar Ecosystem Proposals (SEPs) define standards for interoperability.

### SEP-6: Deposit and Withdrawal API

Programmatic deposits and withdrawals for wallets and exchanges.

| Feature | Details |
|---------|---------|
| **Spec** | [SEP-0006](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0006.md) |
| **Use Case** | Automated fiat on/off ramps |

**Flow:**
1. Wallet requests deposit/withdrawal info
2. Anchor provides instructions
3. User completes fiat transfer
4. Anchor issues/redeems tokens

### SEP-24: Hosted Deposit and Withdrawal

Interactive deposits/withdrawals via hosted web UI.

| Feature | Details |
|---------|---------|
| **Spec** | [SEP-0024](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0024.md) |
| **Use Case** | User-facing on/off ramps |

**Flow:**
1. Wallet opens anchor's web interface
2. User completes KYC/AML
3. User initiates deposit/withdrawal
4. Anchor processes and settles

### SEP-31: Cross-Border Payments

Direct payments between institutions (no end-user interaction).

| Feature | Details |
|---------|---------|
| **Spec** | [SEP-0031](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0031.md) |
| **Use Case** | B2B remittances, institutional transfers |

**Flow:**
1. Sending FI queries receiving FI
2. Payment info exchanged
3. Sender initiates payment
4. Receiver delivers to beneficiary

### SEP-10: Web Authentication

Stellar-based authentication for web services.

| Feature | Details |
|---------|---------|
| **Spec** | [SEP-0010](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0010.md) |
| **Use Case** | Secure user authentication |

### SEP-1: stellar.toml

Metadata file for Stellar entities (anchors, issuers, validators).

| Feature | Details |
|---------|---------|
| **Spec** | [SEP-0001](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0001.md) |
| **Location** | `/.well-known/stellar.toml` |

**Example:**
```toml
# https://example.com/.well-known/stellar.toml

NETWORK_PASSPHRASE="Public Global Stellar Network ; September 2015"
TRANSFER_SERVER="https://api.example.com/sep6"
WEB_AUTH_ENDPOINT="https://api.example.com/auth"

[[CURRENCIES]]
code="USD"
issuer="GEXAMPLEISSUER..."
display_decimals=2
name="US Dollar"
```

## Stellar Disbursement Platform (SDP)

Bulk payment infrastructure for enterprises.

| Feature | Details |
|---------|---------|
| **GitHub** | [stellar/stellar-disbursement-platform](https://github.com/stellar/stellar-disbursement-platform) |
| **Docs** | [developers.stellar.org/docs/category/use-the-stellar-disbursement-platform](https://developers.stellar.org/docs/category/use-the-stellar-disbursement-platform) |

### Use Cases

- **Aid distribution** - Humanitarian organizations
- **Payroll** - Cross-border salary payments
- **Rewards** - Loyalty program distributions
- **Grants** - Scholarship/funding disbursements

### Features

- CSV-based bulk uploads
- Multi-asset support
- Wallet registration workflows
- KYC integration
- Audit trails
- Retry mechanisms

### Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Admin UI  │ ──►  │   SDP API   │ ──►  │   Stellar   │
│             │      │             │      │   Network   │
└─────────────┘      └─────────────┘      └─────────────┘
       │                    │
       │                    ▼
       │              ┌─────────────┐
       │              │  Database   │
       │              └─────────────┘
       ▼
┌─────────────┐
│ Recipients  │
│  (Wallets)  │
└─────────────┘
```

### Getting Started

```bash
# Clone the repository
git clone https://github.com/stellar/stellar-disbursement-platform
cd stellar-disbursement-platform

# Run with Docker
docker-compose up
```

## Block Explorers

### StellarExpert

Comprehensive network explorer with analytics.

| Feature | Details |
|---------|---------|
| **URL** | [stellar.expert](https://stellar.expert) |
| **Features** | Transactions, accounts, assets, contracts |

### Stellar Laboratory

Developer tools and transaction builder.

| Feature | Details |
|---------|---------|
| **URL** | [laboratory.stellar.org](https://laboratory.stellar.org) |
| **Features** | XDR viewer, transaction signing, account viewer |

### StellarChain

Alternative explorer with contract support.

| Feature | Details |
|---------|---------|
| **URL** | [stellarchain.io](https://stellarchain.io) |

## RPC Providers

### Public Endpoints

| Network | RPC URL | Horizon URL |
|---------|---------|-------------|
| **Mainnet** | `https://soroban.stellar.org` | `https://horizon.stellar.org` |
| **Testnet** | `https://soroban-testnet.stellar.org` | `https://horizon-testnet.stellar.org` |

### Third-Party Providers

For high-volume applications, consider:

- **Blockdaemon** - Enterprise RPC
- **QuickNode** - Multi-chain infrastructure
- **Self-hosted** - Run your own nodes

## Self-Hosting

### Quickstart (Development)

```bash
# Run local Stellar network
docker run --rm -it \
  -p 8000:8000 \
  --name stellar \
  stellar/quickstart \
  --testnet
```

### Production Nodes

For production deployments:

| Component | Repository |
|-----------|------------|
| **Stellar Core** | [stellar/stellar-core](https://github.com/stellar/stellar-core) |
| **Horizon** | [stellar/go](https://github.com/stellar/go) |
| **Soroban RPC** | [stellar/soroban-rpc](https://github.com/stellar/soroban-rpc) |

## Monitoring & Observability

### OpenZeppelin Monitor

Track contract events and transactions.

| Feature | Details |
|---------|---------|
| **Docs** | See [openzeppelin/monitor.md](../openzeppelin/monitor.md) |

### Custom Monitoring

```typescript
// Example: Track transaction status
import * as StellarSdk from "@stellar/stellar-sdk";

async function monitorTransaction(hash: string) {
  const rpc = new StellarSdk.rpc.Server("https://soroban-testnet.stellar.org");

  let status = "NOT_FOUND";
  while (status === "NOT_FOUND") {
    const result = await rpc.getTransaction(hash);
    status = result.status;
    if (status === "NOT_FOUND") {
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  return status;
}
```

## Resources

- [Anchor Platform Docs](https://developers.stellar.org/docs/category/anchor-platform)
- [SDP Documentation](https://developers.stellar.org/docs/category/use-the-stellar-disbursement-platform)
- [SEP Index](https://github.com/stellar/stellar-protocol/tree/master/ecosystem)
- [Stellar Ramps Overview](https://stellar.org/use-cases/ramps)
