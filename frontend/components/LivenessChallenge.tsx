"use client";

import { useEffect, useRef, useState } from "react";

/* ─── Challenge types ─────────────────────────────────────────── */

type MathChallenge   = { type: "math";    question: string; answer: number };
type StellarChallenge= { type: "stellar"; question: string; options: string[]; correct: number };
type MascotChallenge = { type: "mascot";  target: number };
type Challenge       = MathChallenge | StellarChallenge | MascotChallenge;

const STELLAR_QUESTIONS: Omit<StellarChallenge, "type">[] = [
  { question: "What is the native currency of the Stellar network?",
    options: ["ETH", "XLM", "BTC", "USDC"], correct: 1 },
  { question: "What smart-contract platform does Harta run on?",
    options: ["EVM", "Wasm/EVM", "Soroban", "Solana BPF"], correct: 2 },
  { question: "What does 'trustless' mean in blockchain?",
    options: ["Nobody trusts anyone", "No bank or middleman needed", "The network is broken", "Only the owner can use it"], correct: 1 },
  { question: "In Harta, what triggers the inheritance payout?",
    options: ["Owner manually clicks pay", "Check-in timer expires", "Beneficiary emails the owner", "Smart contract resets"], correct: 1 },
  { question: "What does the owner do to stay 'alive' in Harta?",
    options: ["Pays a monthly fee", "Sends a check-in transaction", "Emails support", "Transfers all funds"], correct: 1 },
];

function makeMath(): MathChallenge {
  const ops = ["+", "-", "×"] as const;
  const op  = ops[Math.floor(Math.random() * 3)];
  let a: number, b: number, answer: number, question: string;
  if (op === "+")  { a = rand(10,90); b = rand(10,90); answer = a+b; question = `${a} + ${b} = ?`; }
  else if (op==="-"){ a = rand(50,99); b = rand(5,40); answer = a-b; question = `${a} − ${b} = ?`; }
  else              { a = rand(2,12);  b = rand(2,12); answer = a*b; question = `${a} × ${b} = ?`; }
  return { type: "math", question, answer };
}
const rand = (min: number, max: number) => Math.floor(Math.random() * (max - min + 1)) + min;

function makeChallenge(type: "math" | "stellar" | "mascot"): Challenge {
  if (type === "math")    return makeMath();
  if (type === "stellar") return { type: "stellar", ...STELLAR_QUESTIONS[rand(0, STELLAR_QUESTIONS.length-1)] };
  return { type: "mascot", target: 5 };
}

/* ─── Mascot ──────────────────────────────────────────────────── */

const MASCOT = ["😴","🥱","😐","😊","🤩","🎉"];
const MASCOT_MSG = ["Sleeping…","Wake me up!","Getting there…","Feeling alive!","Almost!","ALIVE! ✅"];

/* ─── Countdown ───────────────────────────────────────────────── */

const fmt = (s: number) => {
  s = Math.max(0, s);
  const d=Math.floor(s/86400), h=Math.floor((s%86400)/3600), m=Math.floor((s%3600)/60), sec=s%60;
  if (d>0) return `${d}d ${h}h ${m}m`;
  if (h>0) return `${h}h ${m}m ${sec}s`;
  return `${m}m ${sec}s`;
};

/* ─── Props ───────────────────────────────────────────────────── */

type Props = {
  lastCheckin: number;
  checkinInterval: number;
  onCheckin: () => Promise<void>;
  loading?: boolean;
};

/* ─── Component ───────────────────────────────────────────────── */

const TABS: { key: "math"|"stellar"|"mascot"; label: string; icon: string }[] = [
  { key: "math",    label: "Math",   icon: "🧮" },
  { key: "stellar", label: "Quiz",   icon: "🌟" },
  { key: "mascot",  label: "Mascot", icon: "🐣" },
];

export function LivenessChallenge({
  lastCheckin, checkinInterval, onCheckin,
  loading,
}: Props) {
  const [now,           setNow]           = useState<number|null>(null);
  const [tab,           setTab]           = useState<"math"|"stellar"|"mascot">("math");
  const [challenge,     setChallenge]     = useState<Challenge | null>(null);
  const [solved,        setSolved]        = useState(false);
  const [input,         setInput]         = useState("");
  const [wrong,         setWrong]         = useState(false);
  const [selectedOpt,   setSelectedOpt]   = useState<number|null>(null);
  const [mascotClicks,  setMascotClicks]  = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  /* live clock + initial challenge — both run client-only to prevent hydration mismatch */
  useEffect(() => {
    setNow(Math.floor(Date.now()/1000));
    setChallenge(makeMath());
    const t = setInterval(() => setNow(Math.floor(Date.now()/1000)), 1000);
    return () => clearInterval(t);
  }, []);

  const remaining = now !== null && lastCheckin !== 0
    ? Math.max(0, lastCheckin + checkinInterval - now)
    : null;
  const expired = remaining === 0;

  /* switch tab → reset everything */
  const switchTab = (next: typeof tab) => {
    setTab(next);
    setChallenge(makeChallenge(next));
    setSolved(false); setInput(""); setWrong(false);
    setSelectedOpt(null); setMascotClicks(0);
  };

  /* math */
  const submitMath = () => {
    if (!challenge || challenge.type !== "math") return;
    if (Number(input) === challenge.answer) { setSolved(true); setWrong(false); }
    else { setWrong(true); setInput(""); inputRef.current?.focus(); }
  };

  /* quiz */
  const pickOption = (i: number) => {
    if (!challenge || challenge.type !== "stellar" || solved) return;
    setSelectedOpt(i);
    if (i === challenge.correct) setTimeout(() => setSolved(true), 350);
    else { setWrong(true); setTimeout(() => { setWrong(false); setSelectedOpt(null); }, 700); }
  };

  /* mascot */
  const feedMascot = () => {
    if (!challenge || challenge.type !== "mascot" || solved) return;
    const next = mascotClicks + 1;
    setMascotClicks(next);
    if (next >= (challenge as MascotChallenge).target) setSolved(true);
  };

  /* send */
  const handleSend = async () => {
    await onCheckin();
    setSolved(false); setInput(""); setWrong(false);
    setSelectedOpt(null); setMascotClicks(0);
    setChallenge(makeChallenge(tab));
  };

  const canSend = solved && !loading;

  const mascotStep = Math.min(mascotClicks, MASCOT.length - 1);

  return (
    <div className="glass-panel rounded-3xl p-5">
      {/* header */}
      <div className="flex items-start justify-between">
        <div>
          <p className="subtle-label text-xs">Heartbeat</p>
          <h3 className="mt-2 text-lg font-semibold text-white">Prove you&apos;re alive</h3>
        </div>
        <div
          suppressHydrationWarning
          className={`rounded-2xl border px-3 py-2 text-right font-mono text-xs ${
            expired
              ? "border-rose-400/30 bg-rose-400/5 text-rose-300"
              : "border-white/10 bg-black/20 text-slate-300"
          }`}
        >
          {remaining === null ? "—" : expired ? "EXPIRED" : fmt(remaining)}
        </div>
      </div>

      {/* tab selector */}
      <div className="mt-4 flex gap-2">
        {TABS.map(({ key, label, icon }) => (
          <button
            key={key}
            type="button"
            onClick={() => switchTab(key)}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-2xl border py-2.5 text-sm font-medium transition ${
              tab === key
                ? "border-ember-400/50 bg-ember-400/10 text-ember-300"
                : "border-white/10 bg-white/[0.04] text-slate-400 hover:border-white/20 hover:text-slate-200"
            }`}
          >
            <span>{icon}</span> {label}
          </button>
        ))}
      </div>

      {/* challenge body */}
      <div className="mt-4 rounded-2xl border border-white/10 bg-black/20 p-5">

        {!challenge && (
          <p className="text-sm text-slate-400">Loading challenge…</p>
        )}

        {/* ── MATH ── */}
        {challenge && tab === "math" && challenge.type === "math" && (
          <div>
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Solve to unlock</p>
            <p className="mt-3 text-4xl font-semibold text-white">{challenge.question}</p>
            <div className="mt-4 flex gap-3">
              <input
                ref={inputRef}
                type="number"
                value={input}
                onChange={e => { setInput(e.target.value); setWrong(false); }}
                onKeyDown={e => e.key === "Enter" && submitMath()}
                placeholder="Answer"
                disabled={solved}
                className={`w-full rounded-2xl border bg-white/[0.06] px-4 py-3 text-sm text-white outline-none placeholder:text-slate-500 focus:border-ember-400/60 ${wrong ? "border-rose-400/60" : "border-white/10"}`}
              />
              <button
                type="button"
                onClick={submitMath}
                disabled={solved || !input}
                className="rounded-2xl bg-ember-400 px-5 py-3 text-sm font-semibold text-ink-950 transition hover:bg-ember-300 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Check
              </button>
            </div>
            {wrong && <p className="mt-2 text-xs text-rose-300">Wrong — try again.</p>}
          </div>
        )}

        {/* ── QUIZ ── */}
        {challenge && tab === "stellar" && challenge.type === "stellar" && (
          <div>
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Pick the right answer</p>
            <p className="mt-3 text-base font-semibold leading-6 text-white">{challenge.question}</p>
            <div className="mt-4 grid gap-2">
              {challenge.options.map((opt, i) => (
                <button
                  key={opt}
                  type="button"
                  onClick={() => pickOption(i)}
                  disabled={solved}
                  className={`rounded-2xl border px-4 py-3 text-left text-sm transition ${
                    selectedOpt === i && !wrong
                      ? "border-emerald-400/60 bg-emerald-400/10 text-emerald-200"
                      : wrong && selectedOpt === i
                      ? "border-rose-400/60 bg-rose-400/10 text-rose-200"
                      : "border-white/10 bg-white/[0.04] text-slate-300 hover:border-white/20 hover:bg-white/[0.08]"
                  }`}
                >
                  {opt}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* ── MASCOT ── */}
        {challenge && tab === "mascot" && challenge.type === "mascot" && (
          <div className="text-center">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
              Feed the mascot · tap {challenge.target} times
            </p>
            <button
              type="button"
              onClick={feedMascot}
              disabled={solved}
              className="mx-auto mt-4 block select-none text-8xl transition-transform active:scale-90 disabled:cursor-default"
            >
              {MASCOT[mascotStep]}
            </button>
            <p className="mt-2 text-sm text-slate-400">{MASCOT_MSG[mascotStep]}</p>
            <div className="mt-3 flex justify-center gap-1">
              {Array.from({ length: challenge.target }).map((_, i) => (
                <div
                  key={i}
                  className={`h-1.5 w-6 rounded-full transition-all ${i < mascotClicks ? "bg-ember-400" : "bg-white/10"}`}
                />
              ))}
            </div>
          </div>
        )}

        {/* success banner */}
        {solved && (
          <div className="mt-4 flex items-center gap-2 rounded-xl bg-emerald-400/10 px-4 py-3 text-sm text-emerald-300">
            ✓ &nbsp;Challenge complete — send your check-in below.
          </div>
        )}
      </div>

      {/* send button */}
      <div className="mt-4 space-y-2">
        <button
          type="button"
          disabled={!canSend}
          onClick={handleSend}
          className="w-full rounded-full bg-emerald-400 py-3 text-sm font-semibold text-slate-950 transition hover:bg-emerald-300 disabled:cursor-not-allowed disabled:opacity-40"
        >
          {loading ? "Sending…" : solved ? "Send check-in ✓" : "Solve the challenge first"}
        </button>
      </div>
    </div>
  );
}
