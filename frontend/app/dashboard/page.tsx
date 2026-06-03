"use client";

import { useEffect, useMemo, useState } from "react";
import toast from "react-hot-toast";

import Link from "next/link";

import { BeneficiaryList } from "@/components/BeneficiaryList";
import { LivenessChallenge } from "@/components/LivenessChallenge";
import { DistributionTrigger } from "@/components/DistributionTrigger";
import { PlanSetup } from "@/components/PlanSetup";
import { StatusCard } from "@/components/StatusCard";
import { WalletConnect } from "@/components/WalletConnect";
import {
  buildAddBeneficiaryTx,
  buildCheckinTx,
  buildDistributionTx,
  buildInitializeTx,
  buildRemoveBeneficiaryTx,
  buildUpdateCheckinIntervalTx,
  getContractState,
  type ContractState,
} from "@/lib/contract";
import { CONTRACT_ID, NETWORK_PASSPHRASE, RPC_URL, TOKEN_CONTRACT_ID } from "@/lib/constants";
import { connectWallet, signAndSubmit } from "@/lib/freighter";

const EXPLORER_BASE = "https://stellar.expert/explorer/testnet/tx";

const emptyState: ContractState = {
  owner: "",
  beneficiaries: [],
  lastCheckin: Math.floor(Date.now() / 1000),
  checkinInterval: 86_400,
  distributed: false,
};

export default function DashboardPage() {
  const [walletAddress, setWalletAddress] = useState<string | null>(null);
  const [walletNetwork, setWalletNetwork] = useState<string | null>(null);
  const [isTestnet, setIsTestnet] = useState(true);
  const [loadingWallet, setLoadingWallet] = useState(false);
  const [loadingAction, setLoadingAction] = useState(false);
  const [loadingState, setLoadingState] = useState(false);
  const [contractState, setContractState] = useState<ContractState>(emptyState);
  const [contractInitialized, setContractInitialized] = useState(false);
  const [lastTxHash, setLastTxHash] = useState<string | null>(null);
  const [freighterMissing, setFreighterMissing] = useState(false);

  const beneficiaries = contractState.beneficiaries;
  const totalShareBps = useMemo(
    () => beneficiaries.reduce((sum, b) => sum + b.shareBps, 0),
    [beneficiaries],
  );

  const hasContract = CONTRACT_ID.length > 0;
  const hasToken = TOKEN_CONTRACT_ID.length > 0;
  const isOwner = Boolean(
    walletAddress && contractState.owner && walletAddress === contractState.owner,
  );
  const canInteract = Boolean(isOwner && hasContract && !contractState.distributed);
  const expired = Math.floor(Date.now() / 1000) >= contractState.lastCheckin + contractState.checkinInterval;

  const reloadState = async () => {
    if (!hasContract) return;
    setLoadingState(true);
    try {
      const nextState = await getContractState(CONTRACT_ID, RPC_URL);
      setContractInitialized(true);
      setContractState((current) => ({
        ...current,
        ...nextState,
        beneficiaries: nextState.beneficiaries ?? current.beneficiaries,
      }));
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to load state.";
      if (message === "CONTRACT_NOT_INITIALIZED") {
        setContractInitialized(false);
        setContractState(emptyState);
        return;
      }
      toast.error(message);
    } finally {
      setLoadingState(false);
    }
  };

  useEffect(() => {
    reloadState().catch(() => undefined);
  }, [hasContract]);

  useEffect(() => {
    const timer = window.setInterval(() => {
      reloadState().catch(() => undefined);
    }, 20_000);
    return () => window.clearInterval(timer);
  }, [hasContract]);

  const submitAction = async (action: () => Promise<string>, successMessage: string) => {
    if (!walletAddress) {
      toast.error("Connect your Freighter wallet first.");
      return;
    }
    if (!hasContract) {
      toast.error("NEXT_PUBLIC_CONTRACT_ID is missing.");
      return;
    }

    setLoadingAction(true);
    try {
      const xdr = await action();
      const result = await signAndSubmit(xdr, NETWORK_PASSPHRASE, RPC_URL);
      setLastTxHash(result.hash);
      toast.success(successMessage);
      await reloadState();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Transaction failed.";
      toast.error(message);
    } finally {
      setLoadingAction(false);
    }
  };

  const handleConnect = async () => {
    setLoadingWallet(true);
    try {
      const wallet = await connectWallet();
      setWalletAddress(wallet.address);
      setWalletNetwork(wallet.network);
      setIsTestnet(wallet.isTestnet);
      toast.success("Freighter connected.");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Wallet connection failed.";
      if (message.toLowerCase().includes("not installed") || message.toLowerCase().includes("freighter")) {
        setFreighterMissing(true);
      }
      toast.error(message);
    } finally {
      setLoadingWallet(false);
    }
  };

  const handleDisconnect = () => {
    setWalletAddress(null);
    setWalletNetwork(null);
    setIsTestnet(true);
    toast("Disconnected.");
  };

  const handleAddBeneficiary = async (address: string, shareBps: number) => {
    if (totalShareBps + shareBps > 10_000) {
      toast.error("Total share cannot exceed 10,000 bps.");
      return;
    }
    await submitAction(
      () => buildAddBeneficiaryTx(CONTRACT_ID, walletAddress ?? "", address, shareBps, RPC_URL, NETWORK_PASSPHRASE),
      "Beneficiary added.",
    );
  };

  const handleRemoveBeneficiary = async (address: string) => {
    await submitAction(
      () => buildRemoveBeneficiaryTx(CONTRACT_ID, walletAddress ?? "", address, RPC_URL, NETWORK_PASSPHRASE),
      "Beneficiary removed.",
    );
  };

  const handleUpdateInterval = async (intervalSeconds: number) => {
    await submitAction(
      () => buildUpdateCheckinIntervalTx(CONTRACT_ID, walletAddress ?? "", intervalSeconds, RPC_URL, NETWORK_PASSPHRASE),
      "Check-in interval updated.",
    );
  };

  const handleInitialize = async () => {
    await submitAction(
      () => buildInitializeTx(CONTRACT_ID, walletAddress ?? "", 300, RPC_URL, NETWORK_PASSPHRASE),
      "Contract initialized — you are the owner.",
    );
  };

  const handleCheckin = async () => {
    await submitAction(
      () => buildCheckinTx(CONTRACT_ID, walletAddress ?? "", RPC_URL, NETWORK_PASSPHRASE),
      "Check-in sent.",
    );
  };

  const handleDistribution = async () => {
    if (!TOKEN_CONTRACT_ID) {
      toast.error("NEXT_PUBLIC_TOKEN_CONTRACT_ID is missing.");
      return;
    }
    await submitAction(
      () => buildDistributionTx(CONTRACT_ID, walletAddress ?? "", TOKEN_CONTRACT_ID, RPC_URL, NETWORK_PASSPHRASE),
      "Distribution triggered.",
    );
  };

  return (
    <main className="noise min-h-screen px-6 py-8 text-white lg:px-10">
      <div className="mx-auto flex max-w-7xl flex-col gap-6">

        {/* Back navigation */}
        <div className="flex items-center gap-3">
          <Link href="/" className="text-xs text-slate-500 hover:text-slate-300 transition">
            ← Harta
          </Link>
          <span className="text-slate-700">/</span>
          <span className="text-xs text-slate-400">Dashboard</span>
        </div>

        {/* Demo flow banner */}
        <div className="rounded-2xl border border-ember-400/20 bg-ember-400/5 px-5 py-4 text-sm text-slate-300">
          <span className="mr-3 font-semibold text-ember-300">Live demo flow →</span>
          <span className="opacity-70">
            1. Connect Freighter &nbsp;·&nbsp; 2. Add beneficiaries &nbsp;·&nbsp; 3. Send check-in &nbsp;·&nbsp; 4. Let timer expire &nbsp;·&nbsp; 5. Trigger distribution
          </span>
        </div>

        <header className="flex flex-col gap-4 rounded-[2rem] border border-white/10 bg-white/[0.05] p-6 backdrop-blur md:flex-row md:items-center md:justify-between">
          <div>
            <p className="subtle-label text-xs">Dashboard</p>
            <h1 className="hero-heading mt-2 text-4xl font-semibold">Harta Control Panel</h1>
            <p className="mt-2 max-w-2xl text-sm text-slate-400">
              Connect with Freighter, manage your inheritance plan, send check-ins, and trigger distribution when the timeout expires.
            </p>
          </div>
          <WalletConnect
            address={walletAddress}
            network={walletNetwork}
            connected={Boolean(walletAddress)}
            loading={loadingWallet}
            isTestnet={isTestnet}
            isOwner={isOwner}
            freighterMissing={freighterMissing}
            onConnect={handleConnect}
            onDisconnect={handleDisconnect}
          />
        </header>

        {walletAddress && hasContract && !contractInitialized && (
          <div className="rounded-[2rem] border border-ember-400/30 bg-ember-400/10 p-6">
            <p className="text-xs uppercase tracking-[0.2em] text-ember-300">One-time setup</p>
            <h2 className="mt-2 text-xl font-semibold text-white">Claim contract ownership</h2>
            <p className="mt-2 max-w-2xl text-sm text-slate-300">
              This contract is not initialized yet. Freighter will ask you to sign as{" "}
              <span className="font-mono text-white">{walletAddress}</span> — that wallet becomes the on-chain owner.
            </p>
            <button
              type="button"
              onClick={handleInitialize}
              disabled={loadingAction}
              className="mt-4 rounded-full bg-ember-400 px-5 py-2.5 text-sm font-semibold text-ink-950 transition hover:bg-ember-300 disabled:opacity-60"
            >
              {loadingAction ? "Signing…" : "Initialize as owner (5 min check-in interval)"}
            </button>
          </div>
        )}

        <section className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
          <div className="grid gap-6">
            <StatusCard state={contractState} />
            <PlanSetup
              beneficiaries={beneficiaries}
              checkinInterval={contractState.checkinInterval}
              disabled={!canInteract}
              loading={loadingAction}
              onAddBeneficiary={handleAddBeneficiary}
              onUpdateInterval={handleUpdateInterval}
            />
          </div>

          <div className="grid gap-6">
            <BeneficiaryList
              beneficiaries={beneficiaries}
              disabled={!canInteract}
              loading={loadingAction}
              onRemove={handleRemoveBeneficiary}
            />
            <LivenessChallenge
              lastCheckin={contractState.lastCheckin}
              checkinInterval={contractState.checkinInterval}
              onCheckin={handleCheckin}
              disabled={!canInteract || loadingAction}
              walletConnected={Boolean(walletAddress)}
              isOwner={isOwner}
              needsInitialize={Boolean(walletAddress && hasContract && !contractInitialized)}
              loading={loadingAction}
            />
            <DistributionTrigger
              disabled={!walletAddress || loadingAction || !hasContract}
              isExpired={expired}
              loading={loadingAction}
              hasToken={hasToken}
              onTrigger={handleDistribution}
            />
          </div>
        </section>

        {/* Proof of Life + Runtime panel */}
        <section className="glass-panel rounded-[2rem] p-6 text-sm text-slate-300">
          <p className="subtle-label text-xs">Runtime</p>
          <div className="mt-4 grid gap-4 md:grid-cols-3">
            <div>
              <p className="text-white">Contract ID</p>
              <p className="mt-1 break-all text-slate-400">
                {CONTRACT_ID ? (
                  <a
                    href={`https://stellar.expert/explorer/testnet/contract/${CONTRACT_ID}`}
                    target="_blank"
                    rel="noreferrer"
                    className="underline decoration-slate-600 hover:text-white hover:decoration-ember-400"
                  >
                    {CONTRACT_ID}
                  </a>
                ) : (
                  "Waiting for NEXT_PUBLIC_CONTRACT_ID"
                )}
              </p>
            </div>
            <div>
              <p className="text-white">RPC URL</p>
              <p className="mt-1 break-all text-slate-400">{RPC_URL}</p>
            </div>
            <div>
              <p className="text-white">Network</p>
              <p className="mt-1 break-all text-slate-400">{NETWORK_PASSPHRASE}</p>
            </div>
          </div>

          {/* Proof of Life: last on-chain transaction */}
          {lastTxHash && (
            <div className="mt-5 rounded-2xl border border-emerald-400/20 bg-emerald-400/5 px-4 py-3">
              <p className="text-xs uppercase tracking-[0.2em] text-emerald-300">Last transaction — on-chain proof</p>
              <a
                href={`${EXPLORER_BASE}/${lastTxHash}`}
                target="_blank"
                rel="noreferrer"
                className="mt-2 block break-all font-mono text-xs text-emerald-200 underline decoration-emerald-800 hover:decoration-emerald-400"
              >
                {lastTxHash}
              </a>
              <p className="mt-1 text-xs text-slate-500">↗ Opens in Stellar Expert</p>
            </div>
          )}

          {/* Fund the contract — needed for distribution to pay out */}
          {CONTRACT_ID && (
            <div className="mt-5 rounded-2xl border border-amber-400/20 bg-amber-400/5 px-4 py-3 text-xs text-slate-400">
              <p className="font-semibold text-amber-200">Fund the contract to enable distribution</p>
              <p className="mt-1">
                Send XLM (or any SAC token) to the contract address below. Distribution pays out whatever balance the contract holds.
              </p>
              <p className="mt-2 break-all font-mono text-slate-300">{CONTRACT_ID}</p>
            </div>
          )}

          <div className="mt-4 text-xs text-slate-500">
            State refresh: {loadingState ? "refreshing…" : "idle"} &nbsp;·&nbsp; auto every 20s
          </div>
        </section>
      </div>
    </main>
  );
}
