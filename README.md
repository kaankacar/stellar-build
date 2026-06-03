# Harta — Crypto Inheritance on Stellar

> *$2 trillion in crypto assets will be lost forever because there's no trustless way to pass them on. Harta fixes this with 3 on-chain transactions and zero intermediaries.*

Harta is a decentralized inheritance layer built on Soroban (Stellar). The owner checks in periodically via a dead man's switch; when the heartbeat timer expires, any wallet can trigger the distribution and assets flow to pre-defined beneficiaries — trustlessly.

**Live testnet contract:** `CBJNI4GNQQMULSWLRTE7LSCGOGIEX46DAMR75BGHOQHTM5JFHGQLFAPS`
[View on Stellar Expert →](https://stellar.expert/explorer/testnet/contract/CBJNI4GNQQMULSWLRTE7LSCGOGIEX46DAMR75BGHOQHTM5JFHGQLFAPS)

---

## How it works

```
Owner sets up a plan (beneficiaries + check-in interval)
         ↓
Owner sends periodic check-ins (heartbeat)
         ↓
Timer expires → anyone triggers distribution
         ↓
Token balance flows to beneficiaries by share (bps)
```

## Project structure

```
contracts/harta/    Soroban smart contract (Rust)
frontend/           Next.js 14 App Router dApp
.env.example        Required environment variables
```

## Quick start

### 1. Frontend

```bash
cd frontend
cp ../.env.example .env.local   # fill in contract ID
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000), then go to `/dashboard`.

### 2. Environment variables

Create `frontend/.env.local`:

```env
NEXT_PUBLIC_CONTRACT_ID=CBJNI4GNQQMULSWLRTE7LSCGOGIEX46DAMR75BGHOQHTM5JFHGQLFAPS
NEXT_PUBLIC_TOKEN_CONTRACT_ID=          # SAC address of the token held by the contract
NEXT_PUBLIC_SOROBAN_RPC_URL=https://soroban-testnet.stellar.org
NEXT_PUBLIC_NETWORK_PASSPHRASE=Test SDF Network ; September 2015
```

### 3. Deploy your own contract

```bash
# Build
cd contracts/harta
stellar contract build

# Create and fund a testnet key
stellar keys generate my-key --network testnet
curl "https://friendbot.stellar.org/?addr=$(stellar keys address my-key)"

# Deploy
stellar contract deploy \
  --network testnet \
  --source my-key \
  --wasm target/wasm32v1-none/release/harta.wasm

# Initialize (replace values)
stellar contract invoke \
  --network testnet \
  --source my-key \
  --id <CONTRACT_ID> \
  -- initialize \
  --owner <OWNER_ADDRESS> \
  --checkin_interval 86400
```

---

## Live demo flow (60-second version)

To show the full end-to-end flow during a demo, deploy a fresh contract and initialize it with `--checkin_interval 60`, then:

1. Connect Freighter in `/dashboard`
2. Add at least one beneficiary wallet + share (e.g. 10000 bps = 100%)
3. Click **Send check-in** — note the explorer link that appears
4. Wait 60 seconds (or skip forward via `update_checkin_interval 1`)
5. Click **Trigger distribution** — assets move on-chain

Every transaction produces an explorer link directly in the UI under **Last transaction — on-chain proof**.

---

## Contract API

| Function | Who calls | What it does |
|---|---|---|
| `initialize(owner, checkin_interval)` | owner | Sets up the contract |
| `checkin(caller)` | owner | Resets the heartbeat timer |
| `add_beneficiary(caller, beneficiary, share_bps)` | owner | Adds/updates a beneficiary |
| `remove_beneficiary(caller, beneficiary)` | owner | Removes a beneficiary |
| `update_checkin_interval(caller, new_interval)` | owner | Changes the timeout |
| `trigger_distribution(token)` | anyone (after expiry) | Distributes token balance |
| `get_state()` | anyone | Returns the current snapshot |

Shares are in **basis points** (100 bps = 1%). Total must equal exactly 10,000 bps for a full distribution.

---

## Tech stack

| Layer | Tech |
|---|---|
| Smart contract | Rust + Soroban SDK 21 |
| Frontend | Next.js 14 App Router + TypeScript |
| Styling | Tailwind CSS |
| Wallet | Freighter API |
| Network | Stellar Testnet (Soroban RPC) |
