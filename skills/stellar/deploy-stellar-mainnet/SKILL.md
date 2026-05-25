---
name: deploy-stellar-mainnet
description: Walk through the devnet → mainnet deployment checklist for a Soroban contract or Stellar dApp. Use when a user says "deploy to Stellar mainnet", "going live on Stellar", "deploy my Soroban contract", "Stellar production deployment", "mainnet checklist", or "ship it on Stellar". Covers pre-deployment verification, deployment mechanics with stellar CLI, and post-deployment monitoring with Soroban-specific gates.
---

## What this skill does

Walk through three gates. Do not let the user skip a gate.

### Gate 1: Pre-deployment verification

Check each item. If any fails, stop and fix before moving on.

**Contract correctness:**
- [ ] All contract tests pass on testnet (`stellar contract invoke ...` against a deployed testnet copy)
- [ ] At least one end-to-end integration test exists (deploy → invoke → assert state)
- [ ] Storage usage profiled — no unbounded growth, TTL extension wired up for long-lived data
- [ ] Authorization paths reviewed — every `require_auth` is justified, no missing auth on sensitive operations
- [ ] CPI (cross-contract call) safety considered if calling other contracts (reentrancy patterns)

**Security:**
- [ ] No `unwrap()` on user-controlled paths — use `?` with proper error types
- [ ] No panics on malformed input
- [ ] Integer overflow handled — `checked_*` arithmetic or `i128` where appropriate
- [ ] Admin operations gated by explicit role checks
- [ ] If accepting assets, contract uses the Stellar Asset Contract (SAC) correctly

**Audit / formal verification (for high-value contracts):**
- [ ] At least informal peer review by someone outside the team
- [ ] For contracts holding >$100K TVL or critical infra: third-party audit (Certora, OtterSec, Code4rena are active on Stellar — see `data/lumenloop/audits/registry.json`)
- [ ] If skipping audit, document explicit risk acceptance with reasoning

**Operational:**
- [ ] Admin keys: who holds them, where stored (hardware wallet preferred, NOT in CI secrets)
- [ ] Upgrade path: contract is upgradeable via WASM hot-swap, OR explicitly immutable and documented as such
- [ ] Emergency pause exists and is admin-only if user-facing funds are involved
- [ ] Deploy SOPs documented (1-pager — at minimum: who can deploy, network config, contract ID location)

### Gate 2: Deployment mechanics

Check `stellar` CLI is installed: `stellar --version` (install: `cargo install stellar-cli` or `brew install stellar-cli`).

```bash
# 1. Ensure mainnet network is configured
stellar network add mainnet \
  --rpc-url https://mainnet.sorobanrpc.com \
  --network-passphrase "Public Global Stellar Network ; September 2015"

# 2. Build optimized WASM
stellar contract build
# Artifact lands at target/wasm32-unknown-unknown/release/<contract>.wasm

# 3. Upload to mainnet
stellar contract upload \
  --network mainnet \
  --source <DEPLOYER_KEY> \
  --wasm target/wasm32-unknown-unknown/release/<contract>.wasm
# Save the returned WASM hash

# 4. Deploy (instantiate) from the uploaded hash
stellar contract deploy \
  --network mainnet \
  --source <DEPLOYER_KEY> \
  --wasm-hash <HASH>
# Save the returned contract ID

# 5. Initialize if your contract has a constructor
stellar contract invoke \
  --network mainnet \
  --id <CONTRACT_ID> \
  --source <DEPLOYER_KEY> \
  -- initialize <ARGS>

# 6. Verify by reading state
stellar contract invoke \
  --network mainnet \
  --id <CONTRACT_ID> \
  -- <read_method>
```

After successful deploy:
- [ ] Verify contract responds to expected read methods on mainnet RPC
- [ ] Run the smoke test from Gate 1 against the mainnet contract ID
- [ ] Save contract ID to repo README + `deployment-log.md` (date, ID, WASM hash, deployer key fingerprint, commit SHA)
- [ ] View on `stellar.expert/explorer/public/contract/<CONTRACT_ID>` and confirm it matches expectations

### Gate 3: Post-deployment

**Monitoring:**
- [ ] Indexer or event stream set up (Mercury, Subquery, or custom) to capture contract events
- [ ] Alerting on: unexpected admin operations, large value transfers, paused state changes, error rate spikes
- [ ] Dashboard for key metrics (TVL, user count, transaction volume) — even a simple Streamlit or Notion page works

**Ecosystem distribution:**
- [ ] Announce on X / Discord with contract ID and a `stellar.expert` link to verify
- [ ] Submit project to lumenloop.com if not already listed
- [ ] Open PR to `github.com/lumenloop/stellar-ecosystem-db` adding a YAML entry — free distribution to the Stellar ecosystem

**Funding / grants:**
- [ ] If pre-launch SCF Build Award already received: prepare tranche reports — route to `scf-tranche-reporter`
- [ ] If not yet funded and round is open: route to `scf-round-watcher` for active round status, then `scf-submission-drafter`

## Constraints

- Do not let the user skip any Gate 1 checkbox. A broken mainnet contract is dramatically harder to fix than a delayed deploy
- For first-time deployers, walk them through `stellar` CLI installation if `which stellar` returns nothing
- For high-value contracts (anything holding user funds or being core infrastructure), refuse to proceed without at least informal peer-review evidence
- Mainnet network passphrase is critical — never copy from testnet config. The mainnet passphrase contains "September 2015"; testnet contains "September 2015" too but with "Test" prefix — always verify
