"use client";

import { BeneficiaryInput } from "@/lib/contract";

type BeneficiaryListProps = {
  beneficiaries: BeneficiaryInput[];
  disabled: boolean;
  loading: boolean;
  onRemove: (address: string) => Promise<void>;
};

/**
 * Lists the beneficiary wallets and their allocated shares.
 */
export function BeneficiaryList({ beneficiaries, disabled, loading, onRemove }: BeneficiaryListProps) {
  return (
    <div className="glass-panel rounded-3xl p-5">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="subtle-label text-xs">Beneficiaries</p>
          <h3 className="mt-2 text-lg font-semibold text-white">Distribution map</h3>
        </div>
        <span className="rounded-full border border-white/10 bg-black/20 px-3 py-1 text-xs text-slate-300">
          {beneficiaries.length} wallets
        </span>
      </div>

      <div className="mt-5 space-y-3">
        {beneficiaries.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-white/10 bg-black/20 px-4 py-6 text-sm text-slate-400">
            No beneficiaries yet. Add the first wallet above.
          </div>
        ) : (
          beneficiaries.map((entry) => (
            <div
              key={entry.address}
              className="flex items-center justify-between gap-4 rounded-2xl border border-white/10 bg-black/20 px-4 py-3"
            >
              <div className="min-w-0">
                <p className="font-mono text-sm break-all text-white">{entry.address}</p>
                <p className="mt-1 text-xs uppercase tracking-[0.2em] text-slate-400">
                  {entry.shareBps / 100}% allocated
                </p>
              </div>
              <button
                type="button"
                onClick={() => onRemove(entry.address)}
                disabled={disabled || loading}
                className="rounded-full border border-white/15 px-4 py-2 text-xs font-semibold text-white transition hover:border-white/30 hover:bg-white/5 disabled:cursor-not-allowed disabled:opacity-60"
              >
                Remove
              </button>
            </div>
          ))
        )}
      </div>
    </div>
  );
}