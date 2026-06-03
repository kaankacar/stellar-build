"use client";

import { useEffect, useState } from "react";

type CheckinButtonProps = {
  lastCheckin: number;
  checkinInterval: number;
  onCheckin: () => Promise<void>;
  disabled?: boolean;
  loading?: boolean;
};

const formatCountdown = (seconds: number): string => {
  const s = Math.max(0, seconds);
  const d = Math.floor(s / 86_400);
  const h = Math.floor((s % 86_400) / 3_600);
  const m = Math.floor((s % 3_600) / 60);
  const sec = s % 60;
  if (d > 0) return `${d}d ${h}h ${m}m`;
  if (h > 0) return `${h}h ${m}m ${sec}s`;
  return `${m}m ${sec}s`;
};

export function CheckinButton({ lastCheckin, checkinInterval, onCheckin, disabled, loading }: CheckinButtonProps) {
  const [now, setNow] = useState(() => Math.floor(Date.now() / 1000));

  useEffect(() => {
    const timer = window.setInterval(() => setNow(Math.floor(Date.now() / 1000)), 1_000);
    return () => window.clearInterval(timer);
  }, []);

  const deadline = lastCheckin + checkinInterval;
  const remaining = Math.max(0, deadline - now);
  const expired = remaining === 0;

  return (
    <div className="glass-panel rounded-3xl p-5">
      <p className="subtle-label text-xs">Heartbeat</p>
      <h3 className="mt-2 text-lg font-semibold text-white">Dead Man&apos;s Switch check-in</h3>

      <div className={`mt-3 rounded-2xl border px-4 py-3 ${expired ? "border-rose-400/30 bg-rose-400/5" : "border-white/10 bg-black/20"}`}>
        <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Time until deadline</p>
        <p className={`mt-1 font-mono text-2xl font-semibold ${expired ? "text-rose-300" : "text-white"}`}>
          {expired ? "EXPIRED" : formatCountdown(remaining)}
        </p>
      </div>

      <button
        type="button"
        disabled={disabled || loading}
        onClick={onCheckin}
        className="mt-5 rounded-full bg-emerald-400 px-5 py-3 text-sm font-semibold text-slate-950 transition hover:bg-emerald-300 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {loading ? "Sending check-in..." : "Send check-in"}
      </button>
    </div>
  );
}
