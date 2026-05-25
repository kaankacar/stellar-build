# Data Indexing on Stellar

This guide covers data indexing solutions for Stellar applications - when you need them, what options exist, and how to choose.

## Why Do You Need an Indexer?

When building on Stellar, you'll initially get everything you need from RPC calls. But as your app grows, you'll hit limitations:

### Common Pain Points

| Problem | Example |
|---------|---------|
| **Too many RPC calls** | NFT app: 1 call for list + 20 calls for NFT data + 20 calls for images |
| **Historical data needed** | Show every time an NFT changed ownership |
| **Complex queries** | Find all tokens held by users who interacted with your contract |
| **Performance** | Real-time updates without polling |

### When RPC Is Enough

- Simple read operations
- Current state queries
- Low-traffic applications
- Prototypes and hackathons

### When You Need an Indexer

- Historical transaction data
- Complex aggregations
- High-performance requirements
- Analytics and reporting
- Real-time event streaming

## Indexing Categories

### 1. Portfolio APIs (Off-the-Shelf)

Pre-built APIs for common data needs. Great for getting started quickly.

**Best for:** Account balances, token holdings, transaction history

[See providers →](./providers.md#portfolio-apis)

### 2. Custom ETL Pipelines

Stream and transform blockchain data to your own database.

**Best for:** App-specific data models, complex queries, custom analytics

[See providers →](./providers.md#custom-etl)

### 3. Analytics Platforms

Big-data solutions for business intelligence and compliance.

**Best for:** Enterprise reporting, compliance, DeFi metrics

[See providers →](./providers.md#analytics)

### 4. Build Your Own

Roll your own indexing with SDF's tools.

**Best for:** Maximum control, specific requirements, learning

[See providers →](./providers.md#build-your-own)

## Quick Decision Guide

```
What data do you need?
  │
  ├─ Account balances, token holdings, basic tx history
  │   └─► Portfolio API (OBSRVR)
  │
  ├─ Custom contract events, app-specific data
  │   └─► Custom ETL (Goldsky, Mercury, SubQuery)
  │
  ├─ Enterprise analytics, compliance, BI
  │   └─► Analytics Platform (Space and Time, Hubble)
  │
  └─ Full control, learning, edge cases
      └─► Build Your Own (Galexie, Ingest SDK)
```

## Horizon Deprecation Notice

> **Important:** Horizon API is being deprecated. For new projects, use Stellar RPC for real-time data and indexing services for historical data.

Migration guide: [developers.stellar.org/docs/data/apis/migrate-from-horizon-to-rpc](https://developers.stellar.org/docs/data/apis/migrate-from-horizon-to-rpc)

## Getting Started

### For Hackathons / Prototypes

Start with **Mercury** or **OBSRVR** - they have free tiers and quick setup.

### For Production Apps

Evaluate based on:
1. Data requirements (what do you need?)
2. Query patterns (how will you access it?)
3. Scale expectations (how much data?)
4. Budget (managed vs self-hosted?)

### For Enterprise

Consider **Space and Time** for ZK-verified indexing.

## Resources

- [Provider Comparison](./providers.md)
- [Stellar Data Overview](https://developers.stellar.org/docs/data)
- [Build Your Own Indexer Tutorial](https://developers.stellar.org/docs/build/apps/ingest-sdk/overview)
