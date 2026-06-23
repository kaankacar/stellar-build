#!/usr/bin/env node
// stellar-build learning loop — self-trigger (SessionStart).
//
// This is what makes the loop *automatic*. On each new session it checks how
// many skill invocations have accumulated since the last tune-up. Once that
// crosses a threshold (and a cooldown has elapsed) it either:
//
//   • nudges (DEFAULT) — prints a one-line reminder that SessionStart injects
//     into the model's context, so the agent can offer to optimize. Zero cost.
//   • auto-runs (opt-in, STELLAR_BUILD_AUTO_OPTIMIZE=1) — spawns a detached
//     `claude -p` that runs /optimize-skills in the background, hands-free.
//
// Hands-free auto-run is opt-in on purpose: it spends LLM tokens without the
// user watching, so we don't enable it silently.
//
// Knobs: STELLAR_BUILD_AUTO_OPTIMIZE (default ON; set 0/false/off to disable),
//        STELLAR_BUILD_OPTIMIZE_THRESHOLD (default 20),
//        STELLAR_BUILD_OPTIMIZE_COOLDOWN_HOURS (default 6),
//        STELLAR_BUILD_NO_LOOP=1 disables the trigger entirely,
//        STELLAR_HOME overrides the data root.
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const cp = require('child_process');

function readJSON(f) { try { return JSON.parse(fs.readFileSync(f, 'utf8') || '{}') || {}; } catch (_) { return {}; } }
function truthy(v) { return /^(1|true|yes|on)$/i.test(v || ''); }
function disabled(v) { return /^(0|false|no|off)$/i.test(v || ''); }
function hasClaude() { try { cp.execSync('command -v claude', { stdio: 'ignore' }); return true; } catch (_) { return false; } }

(function () {
  try {
    // Recursion guard: never trigger from inside an automated optimize run.
    if (process.env.STELLAR_LOOP_AUTORUN) return;
    if (truthy(process.env.STELLAR_BUILD_NO_LOOP)) return;

    const home = process.env.STELLAR_HOME || path.join(os.homedir(), '.stellar');
    const sf = path.join(home, 'state.json');
    const st = readJSON(sf);

    const since = st.traces_since_optimize || 0;
    const threshold = parseInt(process.env.STELLAR_BUILD_OPTIMIZE_THRESHOLD || '20', 10);
    if (since < threshold) return;

    // Cooldown since the last tune-up (nudge or auto), so we don't nag.
    const cooldownH = parseFloat(process.env.STELLAR_BUILD_OPTIMIZE_COOLDOWN_HOURS || '6');
    const now = Date.now();
    const last = st.last_optimize_ts ? Date.parse(st.last_optimize_ts) : 0;
    if (last && (now - last) < cooldownH * 3600 * 1000) return;

    // Auto-run is ON by default — the loop closes itself. Disable with
    // STELLAR_BUILD_AUTO_OPTIMIZE=0 (or NO_LOOP=1 to silence it entirely).
    const auto = !disabled(process.env.STELLAR_BUILD_AUTO_OPTIMIZE);

    if (auto && hasClaude()) {
      // Lock so two concurrent sessions don't both launch an optimize run.
      const lock = path.join(home, '.optimize.lock');
      try {
        const ls = fs.existsSync(lock) ? fs.statSync(lock).mtimeMs : 0;
        if (ls && (now - ls) < 3600 * 1000) return; // a run is already in flight
        fs.writeFileSync(lock, String(process.pid));
      } catch (_) { /* lock is best-effort */ }

      const prompt = 'Automated background run: use the optimize-skills skill to read my '
        + '~/.stellar usage traces and compile them into sharper skills. Be conservative '
        + 'and skip any skill with thin signal. Do not ask me questions; just do it.';
      try {
        const child = cp.spawn('claude', ['-p', prompt], {
          detached: true,
          stdio: 'ignore',
          env: Object.assign({}, process.env, {
            STELLAR_BUILD_NO_TRACE: '1',   // don't trace the optimizer's own skill calls
            STELLAR_LOOP_AUTORUN: '1',     // and don't let it re-trigger this hook
          }),
        });
        child.unref();
      } catch (_) { /* if spawn fails we simply fall through without resetting */ }

      st.traces_since_optimize = 0;
      st.last_optimize_ts = new Date(now).toISOString();
      try { fs.writeFileSync(sf, JSON.stringify(st)); } catch (_) {}

      process.stdout.write(
        `stellar-build learning loop: auto-tuning your skills in the background from ${since} `
        + `recent uses. Changes land in your installed skills shortly and are reversible with `
        + `\`stellar-loop restore <skill>\`.`
      );
      return;
    }

    // Nudge mode (default). Reset the counter so we surface this once per
    // accumulation rather than every session.
    st.traces_since_optimize = 0;
    st.last_optimize_ts = new Date(now).toISOString();
    st.last_nudge_ts = new Date(now).toISOString();
    try { fs.writeFileSync(sf, JSON.stringify(st)); } catch (_) {}

    process.stdout.write(
      `stellar-build learning loop: you've used skills ${since} times since the last tune-up. `
      + `Run \`/optimize-skills\` (or \`stellar-loop optimize\`) to compile what worked into sharper `
      + `skills. (Hands-free auto-tuning is the default but needs the \`claude\` CLI on PATH; it's `
      + `disabled here via STELLAR_BUILD_AUTO_OPTIMIZE.)`
    );
  } catch (_) {
    // Never break session start.
  }
})();
