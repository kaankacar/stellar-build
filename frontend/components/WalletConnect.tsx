"use client";

interface WalletConnectProps {
  address: string | null;
  network: string | null;
  connected: boolean;
  loading: boolean;
  isTestnet: boolean;
  isOwner: boolean;
  freighterMissing?: boolean;
  onConnect: () => Promise<void>;
  onDisconnect: () => void;
}

export function WalletConnect({
  address,
  network,
  connected,
  loading,
  isTestnet,
  isOwner,
  freighterMissing,
  onConnect,
  onDisconnect,
}: WalletConnectProps) {
  return (
    <div className="glass-panel rounded-3xl p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="subtle-label text-xs">Wallet</p>
          <h3 className="mt-2 text-lg font-semibold text-white">Freighter</h3>

          <p className="mt-2 text-sm text-slate-300">
            {connected && address
              ? `${address.slice(0, 6)}...${address.slice(-6)}`
              : "No wallet connected"}
          </p>

          {connected && (
            <p className="mt-1 text-xs text-slate-400">
              {network
                ? `${network}${isTestnet ? " · Testnet" : " · Mainnet"}`
                : "Stellar Testnet"}
            </p>
          )}

          {/* Owner badge */}
          {connected && isOwner && (
            <span
              className="mt-2 inline-block rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-medium text-emerald-300"
            >
              ✓ Owner
            </span>
          )}

          {freighterMissing && (
            <a
              href="https://freighter.app"
              target="_blank"
              rel="noreferrer"
              className="mt-2 block text-xs text-ember-300 underline hover:text-ember-400"
            >
              Install Freighter extension →
            </a>
          )}
        </div>

        {connected ? (
          <button
            type="button"
            onClick={onDisconnect}
            className="rounded-full border border-white/10 bg-white/[0.06] px-4 py-2 text-sm font-medium text-white transition hover:border-ember-400/50 hover:bg-white/[0.12]"
          >
            Disconnect
          </button>
        ) : (
          <button
            type="button"
            onClick={onConnect}
            disabled={loading}
            className="rounded-full bg-ember-400 px-4 py-2 text-sm font-semibold text-ink-950 transition hover:bg-ember-300 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {loading ? "Connecting..." : "Connect Freighter"}
          </button>
        )}
      </div>
    </div>
  );
}
