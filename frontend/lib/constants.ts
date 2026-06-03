/**
 * Shared runtime configuration for the Harta frontend.
 */
const readEnv = (value: string | undefined, fallback = ""): string => {
  const nextValue = value ?? fallback;
  return nextValue.trim();
};

export const CONTRACT_ID = readEnv(process.env.NEXT_PUBLIC_CONTRACT_ID);
export const TOKEN_CONTRACT_ID = readEnv(process.env.NEXT_PUBLIC_TOKEN_CONTRACT_ID);
export const RPC_URL = readEnv(
  process.env.NEXT_PUBLIC_SOROBAN_RPC_URL,
  "https://soroban-testnet.stellar.org",
);
export const NETWORK_PASSPHRASE = readEnv(
  process.env.NEXT_PUBLIC_NETWORK_PASSPHRASE,
  "Test SDF Network ; September 2015",
);
