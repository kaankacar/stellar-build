import {
  isConnected,
  requestAccess,
  getNetwork,
  signTransaction,
} from "@stellar/freighter-api";
import { rpc as StellarRpc, TransactionBuilder } from "@stellar/stellar-sdk";
import type { Transaction } from "@stellar/stellar-sdk";

export interface ConnectedWallet {
  address: string;
  network: string;
  isTestnet: boolean;
}

const formatRpcSubmissionError = (response: StellarRpc.Api.SendTransactionResponse): string => {
  const errorResult = response.errorResult;

  if (!errorResult) {
    return `Transaction submission failed with status ${response.status}.`;
  }

  try {
    const result = errorResult.result();
    const resultSwitch = result.switch();
    return `Transaction submission failed: ${resultSwitch.name}.`;
  } catch {
    return "Transaction submission failed. Please refresh the page and try again.";
  }
};

const normalizeTransactionError = (error: unknown): Error => {
  if (!(error instanceof Error)) {
    return new Error("Transaction failed.");
  }

  if (error.message.toLowerCase().includes("bad union switch")) {
    return new Error("Transaction XDR could not be decoded. Please hard refresh the page and try again.");
  }

  return error;
};

/**
 * Connects to Freighter and returns the current wallet identity.
 * Uses requestAccess (v4 API) which handles both permission prompt and address retrieval.
 */
export async function connectWallet(): Promise<ConnectedWallet> {
  const connectedResult = await isConnected();
  if (connectedResult.error) {
    throw new Error("Could not reach Freighter: " + String(connectedResult.error));
  }
  if (!connectedResult.isConnected) {
    throw new Error("Freighter extension is not installed.");
  }

  const accessResult = await requestAccess();
  if (accessResult.error) {
    throw new Error("Freighter access denied: " + String(accessResult.error));
  }

  const networkResult = await getNetwork();
  if (networkResult.error) {
    throw new Error("Could not read network from Freighter: " + String(networkResult.error));
  }

  const networkName = networkResult.network ?? "";

  return {
    address: accessResult.address,
    network: networkName,
    isTestnet: networkName.toLowerCase().includes("test"),
  };
}

/**
 * Signs an XDR payload via Freighter and submits it to Soroban RPC.
 * Polls up to 15 times (1s apart) for the transaction to be confirmed.
 */
export async function signAndSubmit(
  xdr: string,
  networkPassphrase: string,
  rpcUrl: string,
): Promise<{ hash: string; status: string }> {
  const signResult = await signTransaction(xdr, { networkPassphrase });
  if (signResult.error) {
    throw new Error("Freighter signing failed: " + String(signResult.error));
  }
  if (!signResult.signedTxXdr) {
    throw new Error("Freighter did not return a signed transaction.");
  }

  const server = new StellarRpc.Server(rpcUrl);
  let transaction: Transaction;
  try {
    transaction = TransactionBuilder.fromXDR(signResult.signedTxXdr, networkPassphrase) as Transaction;
  } catch (error) {
    throw normalizeTransactionError(error);
  }

  const response = await server.sendTransaction(transaction).catch((error: unknown) => {
    throw normalizeTransactionError(error);
  });
  if (response.status === "ERROR") {
    throw new Error(formatRpcSubmissionError(response));
  }

  let finalStatus: string = response.status;
  for (let attempt = 0; attempt < 15; attempt += 1) {
    const result = await server.getTransaction(response.hash).catch((error: unknown) => {
      throw normalizeTransactionError(error);
    });
    if (result.status !== StellarRpc.Api.GetTransactionStatus.NOT_FOUND) {
      finalStatus = result.status;
      break;
    }
    await new Promise((resolve) => setTimeout(resolve, 1_000));
  }

  if (finalStatus === StellarRpc.Api.GetTransactionStatus.FAILED) {
    throw new Error("Transaction failed on-chain.");
  }

  return { hash: response.hash, status: finalStatus };
}
