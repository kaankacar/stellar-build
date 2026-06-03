"use client";

import { useEffect, useMemo, useState } from "react";

import { ContractState } from "@/lib/contract";

interface StatusCardProps {
  state: ContractState | null;
}

const formatDuration = (seconds: number): string => {
  const s = Math.max(0, seconds);
  const d = Math.floor(s / 86_400);
  const h = Math.floor((s % 86_400) / 3_600);
  const m = Math.floor((s % 3_600) / 60);
  const sec = s % 60;
  return `${d}d ${h}h ${m}m ${sec}s`;
};

export function StatusCard({ state }: StatusCardProps) {
  // null on server — set after mount to avoid hydration mismatch
  const [now, setNow] = useState<number | null>(null);

  useEffect(() => {
    setNow(Math.floor(Date.now() / 1000));
    const timer = window.setInterval(
      () => setNow(Math.floor(Date.now() / 1000)),
      1_000,
    );
    return () => window.clearInterval(timer);
  }, []);

  const remaining = useMemo(() => {
    if (!state || now === null) return null;
    return state.lastCheckin + state.checkinInterval - now;
  }, [now, state]);

  const progress = useMemo(() => {
    if (!state || remaining === null || state.checkinInterval <= 0) return 0;
    return Math.min(
      100,
      ((state.checkinInterval - Math.max(0, remaining)) / state.checkinInterval) * 100,
    );
  }, [remaining, state]);

  return (
    <div className="glass-panel rounded-3xl p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="subtle-label text-xs">Status</p>
          <h3 className="mt-2 text-lg font-semibold text-white">Contract heartbeat</h3>
        </div>
        <span
          className={`rounded-full px-3 py-1 text-xs ${
            state?.distributed
              ? "bg-emerald-400/15 text-emerald-200"
              : "bg-amber-400/15 text-amber-200"
          }`}
        >
          {state?.distributed ? "Distributed" : "Active"}
        </span>
      </div>

      {!state ? (
        <p className="mt-4 text-sm text-slate-400">Loading contract state.</p>
      ) : (
        <>
          <div className="mt-5 grid gap-4 md:grid-cols-2">
            <div className="rounded-2xl border border-white/10 bg-black/20 px-4 py-3">
              <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Owner</p>
              <p className="mt-2 break-all font-mono text-sm text-white">
                {state.owner || "Not loaded yet"}
              </p>
            </div>
            <div className="rounded-2xl border border-white/10 bg-black/20 px-4 py-3">
              <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Next deadline</p>
              <p className="mt-2 font-semibold text-white" suppressHydrationWarning>
                {remaining === null ? "—" : formatDuration(remaining)}
              </p>
            </div>
          </div>

          <div className="mt-5">
            <div className="h-2 overflow-hidden rounded-full bg-white/5">
              <div
                className="h-full rounded-full bg-gradient-to-r from-[#f5d8b0] via-[#e8b66d] to-emerald-400 transition-all duration-1000"
                style={{ width: `${progress}%` }}
              />
            </div>
            <div className="mt-3 flex items-center justify-between text-xs text-slate-400">
              <span>
                Last check-in: {new Date(state.lastCheckin * 1000).toLocaleString()}
              </span>
              <span>Interval: {formatDuration(state.checkinInterval)}</span>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
