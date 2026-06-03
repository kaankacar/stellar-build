"use client";

import { useMemo, useState } from "react";

import { BeneficiaryInput } from "@/lib/contract";

type PlanSetupProps = {
  beneficiaries: BeneficiaryInput[];
  checkinInterval: number;
  disabled: boolean;
  loading: boolean;
  onAddBeneficiary: (address: string, shareBps: number) => Promise<void>;
  onUpdateInterval: (intervalSeconds: number) => Promise<void>;
};

/**
 * Collects beneficiary addresses, shares, and the heartbeat interval.
 */
export function PlanSetup({
  beneficiaries,
  checkinInterval,
  disabled,
  loading,
  onAddBeneficiary,
  onUpdateInterval,
}: PlanSetupProps) {
  const [beneficiaryAddress, setBeneficiaryAddress] = useState("");
  const [shareBps, setShareBps] = useState("");
  const [intervalDays, setIntervalDays] = useState(String(Math.max(1, Math.round(checkinInterval / 86_400))));

  const totalShareBps = useMemo(
    () => beneficiaries.reduce((sum, entry) => sum + entry.shareBps, 0),
    [beneficiaries],
  );

  const remainingBps = useMemo(() => Math.max(0, 10_000 - totalShareBps), [totalShareBps]);

  const handleAdd = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await onAddBeneficiary(beneficiaryAddress.trim(), Number(shareBps));
    setBeneficiaryAddress("");
    setShareBps("");
  };

  const handleInterval = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    await onUpdateInterval(Number(intervalDays) * 86_400);
  };

  return (
    <div className="glass-panel rounded-3xl p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="subtle-label text-xs">Plan</p>
          <h3 className="mt-2 text-lg font-semibold text-white">Inheritance setup</h3>
          <p className="mt-2 text-sm text-slate-300">
            Add beneficiary wallets and keep the check-in cadence aligned with the owner’s rhythm.
          </p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-right">
          <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Allocated</p>
          <p className={`mt-1 text-lg font-semibold ${totalShareBps <= 10_000 ? "text-white" : "text-rose-300"}`}>
            {totalShareBps / 100}%
          </p>
        </div>
      </div>

      <form onSubmit={handleAdd} className="mt-5 space-y-4">
        <div className="grid gap-3 md:grid-cols-[1.3fr_0.7fr_auto]">
          <input
            value={beneficiaryAddress}
            onChange={(event) => setBeneficiaryAddress(event.target.value)}
            placeholder="Beneficiary wallet address"
            className="w-full rounded-2xl border border-white/10 bg-white/[0.06] px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-500 focus:border-ember-400/60"
          />
          <input
            value={shareBps}
            onChange={(event) => setShareBps(event.target.value)}
            placeholder="Share bps"
            type="number"
            min={1}
            max={10_000}
            className="w-full rounded-2xl border border-white/10 bg-white/[0.06] px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-500 focus:border-ember-400/60"
          />
          <button
            type="submit"
            disabled={disabled || loading}
            className="rounded-2xl bg-ember-400 px-5 py-3 text-sm font-semibold text-ink-950 transition hover:bg-ember-300 disabled:cursor-not-allowed disabled:opacity-60"
          >
            Add beneficiary
          </button>
        </div>

        <p className="text-xs text-slate-400">
          Enter share in basis points: <strong className="text-slate-300">100 bps = 1%</strong>, 5000 = 50%, 10000 = 100%.
          Remaining capacity: <strong className="text-slate-300">{remainingBps / 100}%</strong> ({remainingBps} bps).
        </p>
      </form>

      <form onSubmit={handleInterval} className="mt-5 grid gap-3 md:grid-cols-[1fr_auto]">
        <input
          value={intervalDays}
          onChange={(event) => setIntervalDays(event.target.value)}
          type="number"
          min={1}
          step={1}
          className="w-full rounded-2xl border border-white/10 bg-white/[0.06] px-4 py-3 text-sm text-white outline-none transition placeholder:text-slate-500 focus:border-ember-400/60"
          placeholder="Heartbeat interval in days"
        />
        <button
          type="submit"
          disabled={disabled || loading}
          className="rounded-2xl border border-white/15 px-5 py-3 text-sm font-semibold text-white transition hover:border-white/30 hover:bg-white/[0.12] disabled:cursor-not-allowed disabled:opacity-60"
        >
          Update interval
        </button>
      </form>

      <div className="mt-5 rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm text-slate-300">
        Current interval: <span className="font-semibold text-white">{checkinInterval} seconds</span>
      </div>
    </div>
  );
}