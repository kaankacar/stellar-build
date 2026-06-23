#!/usr/bin/env node
// stellar-build learning loop — prompt capture (UserPromptSubmit).
//
// Stashes the latest user prompt per session so trace-skill.js can pair the
// natural-language trigger with whatever skill fires next. Writes nothing to
// stdout (UserPromptSubmit stdout would be injected into the model's context).
// Fully local. Opt out: STELLAR_BUILD_NO_TRACE=1.
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => { raw += d; });
process.stdin.on('end', () => {
  try {
    if (process.env.STELLAR_BUILD_NO_TRACE) return;
    const ev = JSON.parse(raw || '{}');
    const prompt = ev.prompt || ev.user_prompt || '';
    const session = ev.session_id || ev.sessionId;
    if (!prompt || !session) return;

    const home = process.env.STELLAR_HOME || path.join(os.homedir(), '.stellar');
    const dir = path.join(home, '.prompts');
    fs.mkdirSync(dir, { recursive: true });
    const f = path.join(dir, String(session).replace(/[^A-Za-z0-9_.-]/g, '_') + '.txt');
    fs.writeFileSync(f, String(prompt).slice(0, 600));
  } catch (_) {
    // Best-effort; never block prompt submission.
  }
});
