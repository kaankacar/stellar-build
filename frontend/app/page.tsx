import Link from "next/link";

const highlights = [
  "Trustless inheritance flow on Soroban",
  "Testnet signing with Freighter",
  "Countdown + beneficiary management",
];

export default function HomePage() {
  return (
    <main className="noise min-h-screen px-6 py-10 text-white lg:px-10">
      <div className="mx-auto flex min-h-[calc(100vh-5rem)] max-w-7xl flex-col justify-between gap-10">
        <section className="grid items-center gap-10 lg:grid-cols-[1.2fr_0.8fr] lg:gap-16">
          <div className="space-y-6">
            <p className="subtle-label text-xs">Harta / Stellar Testnet</p>

            {/* Problem statement — the hook */}
            <p className="max-w-xl rounded-2xl border border-amber-400/20 bg-amber-400/5 px-4 py-3 text-sm text-amber-200">
              $2 trillion in crypto assets will be lost forever — there&apos;s no trustless way to pass them on.
              Harta fixes this with <strong>3 on-chain transactions and zero intermediaries.</strong>
            </p>

            <h1 className="hero-heading max-w-4xl text-5xl font-semibold leading-[0.95] text-white sm:text-6xl lg:text-7xl">
              The platform that ties your crypto legacy to a <span className="text-ember-300">wallet</span>,{" "}
              a <span className="text-ember-300">timer</span>, and a{" "}
              <span className="text-ember-300">rule set</span>.
            </h1>
            <p className="max-w-2xl text-lg leading-8 text-slate-300 md:text-xl">
              Harta is a crypto inheritance layer powered by a Soroban smart contract. The owner checks in
              periodically; when the timer expires, distribution is triggered and assets flow to
              pre-defined beneficiaries — trustlessly, on Stellar.
            </p>

            <div className="flex flex-wrap gap-3">
              {highlights.map((item) => (
                <span
                  key={item}
                  className="rounded-full border border-white/10 bg-white/[0.06] px-4 py-2 text-sm text-slate-200"
                >
                  {item}
                </span>
              ))}
            </div>

            <div className="flex flex-wrap gap-4 pt-2">
              <Link
                href="/dashboard"
                className="rounded-full bg-ember-400 px-6 py-3 text-sm font-semibold text-ink-950 transition hover:bg-ember-300"
              >
                Open Dashboard
              </Link>
              <a
                href="#architecture"
                className="rounded-full border border-white/10 bg-white/[0.06] px-6 py-3 text-sm font-semibold text-white transition hover:border-ember-400/40 hover:bg-white/[0.12]"
              >
                View Architecture
              </a>
            </div>
          </div>

          <div className="glass-panel relative overflow-hidden rounded-[2rem] p-6 shadow-halo">
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(240,179,111,0.18),transparent_32%),radial-gradient(circle_at_bottom_left,rgba(97,144,255,0.12),transparent_28%)]" />
            <div className="relative space-y-5">
              <div className="rounded-3xl border border-white/10 bg-ink-900/80 p-5">
                <p className="text-xs uppercase tracking-[0.28em] text-ember-300">Flow</p>
                <p className="mt-3 text-2xl font-semibold text-white">Wallet → Plan → Check-in → Distribution</p>
                <p className="mt-2 text-sm leading-6 text-slate-300">
                  Connect with Freighter on testnet, create your plan, track the timer, and trigger distribution.
                </p>
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
                  <p className="text-xs uppercase tracking-[0.24em] text-slate-400">Network</p>
                  <p className="mt-2 text-sm text-white">Test SDF Network</p>
                </div>
                <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
                  <p className="text-xs uppercase tracking-[0.24em] text-slate-400">Wallet</p>
                  <p className="mt-2 text-sm text-white">Freighter API</p>
                </div>
                <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
                  <p className="text-xs uppercase tracking-[0.24em] text-slate-400">Contract</p>
                  <p className="mt-2 text-sm text-white">Soroban instance storage</p>
                </div>
                <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
                  <p className="text-xs uppercase tracking-[0.24em] text-slate-400">UX</p>
                  <p className="mt-2 text-sm text-white">Toast + live countdown</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section
          id="architecture"
          className="grid gap-4 border-t border-white/10 pt-8 text-sm text-slate-400 sm:grid-cols-3"
        >
          <div>
            <p className="text-white">Soroban</p>
            <p className="mt-2 leading-6">Owner, beneficiaries, heartbeat, and distribution state are stored in instance storage.</p>
          </div>
          <div>
            <p className="text-white">Frontend</p>
            <p className="mt-2 leading-6">Fully interactive dashboard built with Next.js App Router, Tailwind, and Freighter integration.</p>
          </div>
          <div>
            <p className="text-white">Testnet</p>
            <p className="mt-2 leading-6">RPC endpoint, network passphrase, and contract ID are read from <code>.env.local</code>.</p>
          </div>
        </section>
      </div>
    </main>
  );
}
