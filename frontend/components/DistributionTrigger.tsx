"use client";

type DistributionTriggerProps = {
  isExpired: boolean;
  onTrigger: () => Promise<void>;
  disabled?: boolean;
  loading?: boolean;
  hasToken?: boolean;
};

/**
 * Beneficiary-triggered payout action.
 */
export function DistributionTrigger({ isExpired, onTrigger, disabled, loading, hasToken = true }: DistributionTriggerProps) {
  return (
    <div className="glass-panel rounded-3xl p-5">
      <p className="subtle-label text-xs">Distribution</p>
      <h3 className="mt-2 text-lg font-semibold text-white">Trigger inheritance payout</h3>
      <p className="mt-2 text-sm text-slate-300">
        {isExpired ? "Timeout reached; any wallet can invoke distribution." : "Waiting for timeout."}
      </p>

      <div className="mt-4 rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm text-slate-300">
        <span className={isExpired ? "text-emerald-300" : "text-amber-300"}>
          {isExpired ? "Timeout reached" : "Waiting for timeout"}
        </span>
        <span className="mx-2 text-slate-600">|</span>
        <span>{hasToken ? "Token configured" : "Missing token contract id"}</span>
      </div>

      <button
        type="button"
        onClick={onTrigger}
        disabled={disabled || loading || !isExpired || !hasToken}
        className="mt-5 inline-flex items-center justify-center rounded-full border border-[#f5d8b0]/30 bg-[#f5d8b0] px-5 py-2.5 text-sm font-semibold text-[#0f172a] transition hover:bg-[#ffe7c7] disabled:cursor-not-allowed disabled:opacity-50"
      >
        {loading ? "Triggering..." : "Trigger distribution"}
      </button>
    </div>
  );
}