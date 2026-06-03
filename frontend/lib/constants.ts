/**
 * Shared runtime configuration for the Harta frontend.
 */
const readEnv = (name: string, fallback = ""): string => {
  const value = process.env[name] ?? fallback;
  return value.trim();
};

export const CONTRACT_ID = readEnv("NEXT_PUBLIC_CONTRACT_ID");
export const TOKEN_CONTRACT_ID = readEnv("NEXT_PUBLIC_TOKEN_CONTRACT_ID");
export const RPC_URL = readEnv("NEXT_PUBLIC_SOROBAN_RPC_URL", "https://soroban-testnet.stellar.org");
export const NETWORK_PASSPHRASE = readEnv(
  "NEXT_PUBLIC_NETWORK_PASSPHRASE",
  "Test SDF Network ; September 2015",
);