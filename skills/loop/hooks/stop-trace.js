#!/usr/bin/env node
// stellar-build learning loop — per-turn trace writer (Stop).
//
// This is the REAL writer. trace-skill.js only marks which skill is resident;
// the actual work product shows up turn by turn. On each Stop we:
//   1. read the per-session active pointer (no-op if no skill is resident),
//   2. parse the transcript_path JSONL for the LAST assistant message text
//      (concatenate type:"text" blocks; skip tool_use / tool_result / user),
//   3. pair it with this turn's stashed prompt (.prompts/<session>.txt), and
//   4. append a kind:"turn" record with that real output (capped ~1500 chars).
// Then we bump the pointer's turn count (and stash the latest preview so the
// SessionEnd span summary has a final work product even without the transcript).
//
// The activation counter is NOT bumped here — it is bumped once per span at
// SessionEnd, so the "20 activations" auto-trigger keeps its meaning.
//
// Fully local, best-effort. Opt out: STELLAR_BUILD_NO_TRACE=1. Root: STELLAR_HOME.
'use strict';

const fs = require('fs');
const path = require('path');
const lib = require(path.join(__dirname, 'loop-lib.js'));

const PREVIEW_CAP = 1500;

let raw = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => { raw += d; });
process.stdin.on('end', () => {
  try {
    if (process.env.STELLAR_BUILD_NO_TRACE) return;
    if (process.env.STELLAR_LOOP_AUTORUN) return; // don't trace the optimizer's own runs

    const ev = JSON.parse(raw || '{}');
    const session = ev.session_id || ev.sessionId || null;
    if (!session) return;

    const home = lib.homeDir();
    const ptrFile = lib.activePath(home, session);
    const ptr = lib.readJSON(ptrFile);
    if (!ptr || !ptr.skill) return; // no skill resident this turn -> nothing to record

    const transcript = ev.transcript_path || ev.transcriptPath || null;
    const text = lib.lastAssistantText(transcript, PREVIEW_CAP);
    const fullLen = lib.lastAssistantText(transcript, 0).length;

    const ts = new Date().toISOString();
    const turnIndex = ptr.turns || 0;
    const prompt = lib.readPrompt(home, session, 600);

    lib.appendTrace(home, {
      ts,
      kind: 'turn',
      event: 'skill_turn',
      agent: ptr.agent || 'claude',
      skill: ptr.skill,
      prompt,                       // this turn's prompt
      result_preview: text,         // real assistant output, not the mount stub
      result_len: fullLen,
      span_id: ptr.span_id || null,
      turn_index: turnIndex,
      cwd: ev.cwd || ptr.cwd || null,
      session,
    });

    // Advance the span and remember the latest work product for the span summary.
    ptr.turns = turnIndex + 1;
    if (text) { ptr.last_preview = text; ptr.last_result_len = fullLen; }
    lib.writeJSON(ptrFile, ptr);
  } catch (_) {
    // Best-effort; a Stop hook must never break the session.
  }
});
