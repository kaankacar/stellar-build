import {
  Account,
  Address,
  BASE_FEE,
  Contract,
  Keypair,
  Networks,
  TransactionBuilder,
  nativeToScVal,
  scValToNative,
  rpc as StellarRpc,
  xdr,
} from "@stellar/stellar-sdk";

export interface BeneficiaryInput {
  address: string;
  shareBps: number;
}

export interface ContractState {
  owner: string;
  beneficiaries: BeneficiaryInput[];
  lastCheckin: number;
  checkinInterval: number;
  distributed: boolean;
}

const toAddressScVal = (address: string): xdr.ScVal =>
  Address.fromString(address).toScVal();

const toU32ScVal = (value: number): xdr.ScVal =>
  nativeToScVal(value, { type: "u32" });

const createServer = (rpcUrl: string) => new StellarRpc.Server(rpcUrl);

const CONTRACT_ERROR_MESSAGES: Record<string, string> = {
  "0": "Contract is already initialized.",
  "1": "This wallet cannot send check-in for this initialized contract.",
  "2": "Distribution has already been completed.",
  "3": "The heartbeat timer has not expired yet.",
  "4": "Beneficiary shares are invalid.",
};

const formatSimulationError = (message: string): string => {
  const contractError = message.match(/Error\(Contract,\s*#(\d+)\)/);
  if (contractError?.[1] && CONTRACT_ERROR_MESSAGES[contractError[1]]) {
    return CONTRACT_ERROR_MESSAGES[contractError[1]];
  }
  return message || "Soroban simulation failed.";
};

const invokeContract = async ({
  contractId,
  method,
  args,
  sourceAddress,
  rpcUrl,
  networkPassphrase,
}: {
  contractId: string;
  method: string;
  args: xdr.ScVal[];
  sourceAddress: string;
  rpcUrl: string;
  networkPassphrase: string;
}): Promise<string> => {
  const server = createServer(rpcUrl);
  const account = await server.getAccount(sourceAddress);
  const contract = new Contract(contractId);

  let transaction = new TransactionBuilder(account, {
    fee: BASE_FEE,
    networkPassphrase,
  })
    .addOperation(contract.call(method, ...args))
    .setTimeout(180)
    .build();

  const simulation = await server.simulateTransaction(transaction);
  if (StellarRpc.Api.isSimulationError(simulation)) {
    throw new Error(formatSimulationError(simulation.error ?? ""));
  }

  transaction = StellarRpc.assembleTransaction(transaction, simulation).build();
  return transaction.toXDR();
};

const parseContractState = (value: unknown): ContractState => {
  const state = (value ?? {}) as Record<string, unknown>;
  const beneficiariesSource =
    (state.beneficiaries ?? state.beneficiaries_map ?? {}) as
      | Record<string, unknown>
      | Array<[string, unknown]>;

  const beneficiaries: BeneficiaryInput[] = Array.isArray(beneficiariesSource)
    ? beneficiariesSource.map(([address, shareBps]) => ({
        address,
        shareBps: Number(shareBps),
      }))
    : Object.entries(beneficiariesSource).map(([address, shareBps]) => ({
        address,
        shareBps: Number(shareBps),
      }));

  return {
    owner: String(state.owner ?? ""),
    beneficiaries,
    lastCheckin: Number(state.last_checkin ?? state.lastCheckin ?? 0),
    checkinInterval: Number(state.checkin_interval ?? state.checkinInterval ?? 0),
    distributed: Boolean(state.distributed ?? false),
  };
};

/**
 * Reads the current on-chain Harta state via Soroban RPC simulation.
 */
export async function getContractState(contractId: string, rpcUrl: string): Promise<ContractState> {
  const server = createServer(rpcUrl);
  const probe = Keypair.random();
  const account = new Account(probe.publicKey(), "0");
  const contract = new Contract(contractId);

  const transaction = new TransactionBuilder(account, {
    fee: BASE_FEE,
    networkPassphrase: Networks.TESTNET,
  })
    .addOperation(contract.call("get_state"))
    .setTimeout(180)
    .build();

  const simulation = await server.simulateTransaction(transaction);
  if (StellarRpc.Api.isSimulationError(simulation)) {
    const message = formatSimulationError(simulation.error ?? "Failed to read contract state.");
    if (message.includes("UnreachableCodeReached") || message.includes("get_state")) {
      throw new Error("CONTRACT_NOT_INITIALIZED");
    }
    throw new Error(message);
  }

  const rawResult = simulation.result?.retval ?? null;
  const nativeValue = rawResult ? scValToNative(rawResult) : null;

  return parseContractState(nativeValue);
}

export async function buildCheckinTx(
  contractId: string,
  ownerPubkey: string,
  rpcUrl: string,
  networkPassphrase: string,
): Promise<string> {
  return invokeContract({
    contractId,
    method: "checkin",
    args: [toAddressScVal(ownerPubkey)],
    sourceAddress: ownerPubkey,
    rpcUrl,
    networkPassphrase,
  });
}

export async function buildAddBeneficiaryTx(
  contractId: string,
  ownerPubkey: string,
  beneficiaryPubkey: string,
  shareBps: number,
  rpcUrl: string,
  networkPassphrase: string,
): Promise<string> {
  return invokeContract({
    contractId,
    method: "add_beneficiary",
    args: [toAddressScVal(ownerPubkey), toAddressScVal(beneficiaryPubkey), toU32ScVal(shareBps)],
    sourceAddress: ownerPubkey,
    rpcUrl,
    networkPassphrase,
  });
}

export async function buildRemoveBeneficiaryTx(
  contractId: string,
  ownerPubkey: string,
  beneficiaryPubkey: string,
  rpcUrl: string,
  networkPassphrase: string,
): Promise<string> {
  return invokeContract({
    contractId,
    method: "remove_beneficiary",
    args: [toAddressScVal(ownerPubkey), toAddressScVal(beneficiaryPubkey)],
    sourceAddress: ownerPubkey,
    rpcUrl,
    networkPassphrase,
  });
}

export async function buildUpdateCheckinIntervalTx(
  contractId: string,
  ownerPubkey: string,
  newInterval: number,
  rpcUrl: string,
  networkPassphrase: string,
): Promise<string> {
  return invokeContract({
    contractId,
    method: "update_checkin_interval",
    args: [toAddressScVal(ownerPubkey), nativeToScVal(newInterval, { type: "u64" })],
    sourceAddress: ownerPubkey,
    rpcUrl,
    networkPassphrase,
  });
}

export async function buildDistributionTx(
  contractId: string,
  callerPubkey: string,
  tokenContractId: string,
  rpcUrl: string,
  networkPassphrase: string,
): Promise<string> {
  return invokeContract({
    contractId,
    method: "trigger_distribution",
    args: [toAddressScVal(tokenContractId)],
    sourceAddress: callerPubkey,
    rpcUrl,
    networkPassphrase,
  });
}

export async function buildInitializeTx(
  contractId: string,
  ownerPubkey: string,
  checkinInterval: number,
  rpcUrl: string,
  networkPassphrase: string,
): Promise<string> {
  return invokeContract({
    contractId,
    method: "initialize",
    args: [toAddressScVal(ownerPubkey), nativeToScVal(checkinInterval, { type: "u64" })],
    sourceAddress: ownerPubkey,
    rpcUrl,
    networkPassphrase,
  });
}
