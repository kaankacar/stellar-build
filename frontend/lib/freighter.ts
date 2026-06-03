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

  const server = new StellarRpc.Server(rpcUrl);
  const transaction = TransactionBuilder.fromXDR(
    signResult.signedTxXdr,
    networkPassphrase,
  ) as Transaction;

  const response = await server.sendTransaction(transaction);
  if (response.status === "ERROR") {
    const errMsg = response.errorResult
      ? response.errorResult.toXDR("base64")
      : "Transaction submission failed.";
    throw new Error(errMsg);
  }

  let finalStatus: string = response.status;
  for (let attempt = 0; attempt < 15; attempt += 1) {
    const result = await server.getTransaction(response.hash);
    if (result.status !== StellarRpc.Api.GetTransactionStatus.NOT_FOUND) {
      finalStatus = result.status;
      break;
    }
    await new Promise((resolve) => setTimeout(resolve, 1_000));
  }

  return { hash: response.hash, status: finalStatus };
}
