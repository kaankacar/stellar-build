#!/usr/bin/env node
// stellar-build learning loop — automatic prompt sharpener (UserPromptSubmit).
//
// reprompter, but automatic and every time. On each turn it injects a compact
// directive that makes the agent silently rewrite the user's request into a
// sharper working spec (goal / context / task / success criteria) BEFORE
// acting. UserPromptSubmit stdout is added to the model's context, so this
// shapes how the turn is handled without replacing the user's words.
//
// The learning tie-in: if the optimizer has distilled a profile of how this
// user works (~/.stellar/profile.md, written by /optimize-skills from real
// traces), it's injected too — so the rewrite gets more personalized over time.
//
// Skips trivial inputs, slash commands, and bare acknowledgements so it never
// gets in the way. Opt out: STELLAR_BUILD_NO_REPROMPT=1.
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

function truthy(v) { return /^(1|true|yes|on)$/i.test(v || ''); }

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => { raw += d; });
process.stdin.on('end', () => {
  try {
    if (process.env.STELLAR_LOOP_AUTORUN) return;          // don't reprompt the optimizer's own runs
    if (truthy(process.env.STELLAR_BUILD_NO_REPROMPT)) return;

    const ev = JSON.parse(raw || '{}');
    const prompt = (ev.prompt || ev.user_prompt || '').trim();
    if (!prompt) return;
    if (prompt.startsWith('/')) return;                    // slash command / explicit skill
    if (prompt.length < 12) return;                        // too short to be worth structuring
    if (/^(y|yes|yep|ok|okay|k|go|sure|do it|continue|please|thanks|devam|evet|tamam|olur)\b/i.test(prompt)) return;

    const home = process.env.STELLAR_HOME || path.join(os.homedir(), '.stellar');
    let profile = '';
    try {
      const pf = path.join(home, 'profile.md');
      if (fs.existsSync(pf)) profile = fs.readFileSync(pf, 'utf8').trim().slice(0, 800);
    } catch (_) { /* profile is optional */ }

    const lines = [
      '[stellar-build auto-reprompt] Before acting on the message above, silently sharpen it into a working spec, then act on the sharpened version:',
      '- Goal: the outcome the user actually wants (not just the literal words).',
      '- Context & constraints: infer unstated assumptions, scope, and limits.',
      '- Task: the smallest precise action(s) that achieve the goal.',
      '- Success criteria: how you will know it is done right.',
      'If a genuine ambiguity would change the result, ask ONE tight clarifying question first; otherwise proceed. Keep this internal and brief — do not lecture the user about the process.',
    ];
    if (profile) {
      lines.push('');
      lines.push('What local usage has taught us about this user (apply as defaults unless the request contradicts them):');
      lines.push(profile);
    }
    process.stdout.write(lines.join('\n'));
  } catch (_) {
    // Never block prompt submission.
  }
});
