#![no_std]

use soroban_sdk::{
    contract, contracterror, contractimpl, contracttype, panic_with_error, token, Address, Env,
    Map,
};

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct State {
    pub owner: Address,
    pub beneficiaries: Map<Address, u32>,
    pub last_checkin: u64,
    pub checkin_interval: u64,
    pub distributed: bool,
}

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
enum DataKey {
    Owner,
    Beneficiaries,
    LastCheckin,
    CheckinInterval,
    Distributed,
}

#[contracterror]
#[derive(Copy, Clone, Debug, Eq, PartialEq, PartialOrd, Ord)]
pub enum ContractError {
    AlreadyInitialized = 0,
    NotOwner = 1,
    AlreadyDistributed = 2,
    NotExpired = 3,
    InvalidShares = 4,
}

#[contract]
pub struct HartaContract;

fn refresh_ttl(env: &Env) {
    env.storage().instance().extend_ttl(100, 10_000);
}

fn read_owner(env: &Env) -> Address {
    env.storage().instance().get(&DataKey::Owner).unwrap()
}

fn read_beneficiaries(env: &Env) -> Map<Address, u32> {
    env.storage()
        .instance()
        .get(&DataKey::Beneficiaries)
        .unwrap_or(Map::new(env))
}

fn read_last_checkin(env: &Env) -> u64 {
    env.storage().instance().get(&DataKey::LastCheckin).unwrap_or(0)
}

fn read_checkin_interval(env: &Env) -> u64 {
    env.storage().instance().get(&DataKey::CheckinInterval).unwrap_or(0)
}

fn read_distributed(env: &Env) -> bool {
    env.storage().instance().get(&DataKey::Distributed).unwrap_or(false)
}

fn ensure_owner(env: &Env, caller: &Address) {
    let owner = read_owner(env);
    if caller != &owner {
        panic_with_error!(env, ContractError::NotOwner);
    }
}

fn ensure_not_distributed(env: &Env) {
    if read_distributed(env) {
        panic_with_error!(env, ContractError::AlreadyDistributed);
    }
}

fn total_shares(beneficiaries: &Map<Address, u32>) -> u32 {
    let mut total = 0u32;
    for (_, share) in beneficiaries.iter() {
        total = total.saturating_add(share);
    }
    total
}

#[contractimpl]
impl HartaContract {
    /// Initializes the inheritance contract with the owner and check-in cadence.
    pub fn initialize(env: Env, owner: Address, checkin_interval: u64) {
        if env.storage().instance().has(&DataKey::Owner) {
            panic_with_error!(env, ContractError::AlreadyInitialized);
        }

        owner.require_auth();
        env.storage().instance().set(&DataKey::Owner, &owner);
        env.storage()
            .instance()
            .set(&DataKey::Beneficiaries, &Map::<Address, u32>::new(&env));
        env.storage().instance().set(&DataKey::LastCheckin, &env.ledger().timestamp());
        env.storage()
            .instance()
            .set(&DataKey::CheckinInterval, &checkin_interval);
        env.storage().instance().set(&DataKey::Distributed, &false);
        refresh_ttl(&env);
    }

    /// Adds or replaces a beneficiary share in basis points.
    pub fn add_beneficiary(env: Env, caller: Address, beneficiary: Address, share_bps: u32) {
        caller.require_auth();
        ensure_owner(&env, &caller);
        ensure_not_distributed(&env);

        let mut beneficiaries = read_beneficiaries(&env);
        let existing = beneficiaries.get(beneficiary.clone()).unwrap_or(0);
        let current_total = total_shares(&beneficiaries);
        let new_total = current_total.saturating_sub(existing).saturating_add(share_bps);

        if new_total > 10_000 {
            panic_with_error!(env, ContractError::InvalidShares);
        }

        beneficiaries.set(beneficiary, share_bps);
        env.storage().instance().set(&DataKey::Beneficiaries, &beneficiaries);
        refresh_ttl(&env);
    }

    /// Removes a beneficiary from the distribution map.
    pub fn remove_beneficiary(env: Env, caller: Address, beneficiary: Address) {
        caller.require_auth();
        ensure_owner(&env, &caller);
        ensure_not_distributed(&env);

        let mut beneficiaries = read_beneficiaries(&env);
        beneficiaries.remove(beneficiary);
        env.storage().instance().set(&DataKey::Beneficiaries, &beneficiaries);
        refresh_ttl(&env);
    }

    /// Updates the owner's heartbeat and preserves the contract as active.
    pub fn checkin(env: Env, caller: Address) {
        caller.require_auth();
        ensure_owner(&env, &caller);
        ensure_not_distributed(&env);

        env.storage()
            .instance()
            .set(&DataKey::LastCheckin, &env.ledger().timestamp());
        refresh_ttl(&env);
    }

    /// Distributes the token balance to all configured beneficiaries after expiry.
    pub fn trigger_distribution(env: Env, token: Address) {
        ensure_not_distributed(&env);

        let last_checkin = read_last_checkin(&env);
        let interval = read_checkin_interval(&env);
        let now = env.ledger().timestamp();
        if now < last_checkin.saturating_add(interval) {
            panic_with_error!(env, ContractError::NotExpired);
        }

        let beneficiaries = read_beneficiaries(&env);
        let share_total = total_shares(&beneficiaries);
        if share_total == 0 || share_total > 10_000 {
            panic_with_error!(env, ContractError::InvalidShares);
        }

        let token_client = token::Client::new(&env, &token);
        let contract_address = env.current_contract_address();
        let balance = token_client.balance(&contract_address);

        let count = beneficiaries.len();
        let mut index = 0u32;
        let mut sent = 0i128;

        for (beneficiary, share_bps) in beneficiaries.iter() {
            index += 1;
            let amount = if index == count && share_total == 10_000 {
                balance.saturating_sub(sent)
            } else {
                balance.saturating_mul(share_bps as i128) / 10_000i128
            };

            if amount > 0 {
                token_client.transfer(&contract_address, &beneficiary, &amount);
                sent = sent.saturating_add(amount);
            }
        }

        env.storage().instance().set(&DataKey::Distributed, &true);
        refresh_ttl(&env);
    }

    /// Updates the required heartbeat interval in seconds.
    pub fn update_checkin_interval(env: Env, caller: Address, new_interval: u64) {
        caller.require_auth();
        ensure_owner(&env, &caller);
        ensure_not_distributed(&env);

        env.storage()
            .instance()
            .set(&DataKey::CheckinInterval, &new_interval);
        refresh_ttl(&env);
    }

    /// Returns the current contract snapshot.
    pub fn get_state(env: Env) -> State {
        State {
            owner: read_owner(&env),
            beneficiaries: read_beneficiaries(&env),
            last_checkin: read_last_checkin(&env),
            checkin_interval: read_checkin_interval(&env),
            distributed: read_distributed(&env),
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use soroban_sdk::{
        testutils::{Address as _, Ledger as _},
        Address, Env,
    };

    fn create_token_contract<'a>(env: &'a Env, admin: &Address) -> (Address, token::Client<'a>, token::StellarAssetClient<'a>) {
        let sac = env.register_stellar_asset_contract_v2(admin.clone());
        (
            sac.address(),
            token::Client::new(env, &sac.address()),
            token::StellarAssetClient::new(env, &sac.address()),
        )
    }

    #[test]
    fn deploy_add_checkin_and_distribute() {
        let env = Env::default();
        env.mock_all_auths();

        env.ledger().set_timestamp(1_000);

        let owner = Address::generate(&env);
        let beneficiary_one = Address::generate(&env);
        let beneficiary_two = Address::generate(&env);
        let token_admin = Address::generate(&env);

        let contract_id = env.register_contract(None, HartaContract);
        let client = HartaContractClient::new(&env, &contract_id);

        client.initialize(&owner, &60);
        client.add_beneficiary(&owner, &beneficiary_one, &6_000);
        client.add_beneficiary(&owner, &beneficiary_two, &4_000);
        client.checkin(&owner);

        let state = client.get_state();
        assert_eq!(state.owner, owner);
        assert_eq!(state.checkin_interval, 60);
        assert_eq!(state.distributed, false);
        assert_eq!(state.beneficiaries.get(beneficiary_one.clone()).unwrap(), 6_000);
        assert_eq!(state.beneficiaries.get(beneficiary_two.clone()).unwrap(), 4_000);

        let (token_contract_id, _token_client, token_admin_client) = create_token_contract(&env, &token_admin);
        token_admin_client.mint(&contract_id, &1_000_000i128);

        env.ledger().set_timestamp(1_061);
        client.trigger_distribution(&token_contract_id);

        let token_client = token::Client::new(&env, &token_contract_id);
        let beneficiary_one_balance = token_client.balance(&beneficiary_one);
        let beneficiary_two_balance = token_client.balance(&beneficiary_two);
        let contract_balance = token_client.balance(&contract_id);

        assert_eq!(beneficiary_one_balance, 600_000);
        assert_eq!(beneficiary_two_balance, 400_000);
        assert_eq!(contract_balance, 0);
        assert!(client.get_state().distributed);
    }
}
