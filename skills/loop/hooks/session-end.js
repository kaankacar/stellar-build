#!/usr/bin/env node
// stellar-build learning loop — span closer (SessionEnd).
//
// Closes the open skill span for the session: reads the active pointer (no-op
// if none), writes ONE kind:"span" summary record (the opening prompt + the
// final/concatenated work product seen across the span), clears the pointer,
// and bumps the activation counter EXACTLY ONCE for the whole span — never per
// turn — so the SessionStart auto-trigger's "20" still means "20 activations".
//
// Fully local, best-effort. Opt out: STELLAR_BUILD_NO_TRACE=1. Root: STELLAR_HOME.
'use strict';

const fs = require('fs');
const path = require('path');
const lib = require(path.join(__dirname, 'loop-lib.js'));

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => { raw += d; });
process.stdin.on('end', () => {
  try {
    if (process.env.STELLAR_BUILD_NO_TRACE) return;
    if (process.env.STELLAR_LOOP_AUTORUN) return;

    const ev = JSON.parse(raw || '{}');
    const session = ev.session_id || ev.sessionId || null;
    if (!session) return;

    const home = lib.homeDir();
    const ptrFile = lib.activePath(home, session);
    const ptr = lib.readJSON(ptrFile);
    if (!ptr || !ptr.skill) return; // no span open -> nothing to close

    // Prefer the final assistant text from the transcript if available; fall
    // back to the last preview the Stop hook stashed on the pointer.
    const transcript = ev.transcript_path || ev.transcriptPath || null;
    const finalText = lib.lastAssistantText(transcript, 1500);
    const finalLen = transcript ? lib.lastAssistantText(transcript, 0).length : 0;

    const ts = new Date().toISOString();
    const opts = { ts, reason: 'session_end' };
    if (finalText) { opts.result_preview = finalText; opts.result_len = finalLen; }
    lib.closeSpan(home, ptr, opts); // writes the span record + bumps activation once

    // Clear the pointer so a future session starts clean.
    try { fs.unlinkSync(ptrFile); } catch (_) { /* may already be gone */ }
  } catch (_) {
    // Best-effort; SessionEnd must never break shutdown.
  }
});
