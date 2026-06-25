#!/usr/bin/env node
// stellar-build learning loop — skill-activation capture (PostToolUse:Skill).
//
// A skill *use* is a multi-turn span, not a single tool call. The Skill tool
// fires exactly ONCE when a skill mounts (the harness forbids re-invoking an
// already-loaded skill), and at that instant the tool_response is only the
// mount acknowledgment — `{"success":true,"commandName":"<skill>"}` — not any
// work the skill produced. So this hook no longer writes a trace record here.
//
// Instead it opens a per-session ACTIVE pointer at
// <STELLAR_HOME>/.active/<session>.json describing which skill is now resident.
// The Stop hook (stop-trace.js) writes one record per turn against that pointer
// with the real assistant output, and the SessionEnd hook (session-end.js)
// closes the span. A *new* Skill invocation rotates the pointer and closes the
// previous span first, which is how persona handoffs (e.g. justin-analyst ->
// nicole-pm) get captured cleanly.
//
// Codex is the exception: it has no reliable Stop/SessionEnd + transcript
// pipeline, and backfills via `stellar-loop ingest-codex`, so for Codex we keep
// the original synchronous record so its coverage does not go dark.
//
// Fully local. Never throws, never blocks the session.
// Opt out: STELLAR_BUILD_NO_TRACE=1. Data root: STELLAR_HOME.
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

    const ev = JSON.parse(raw || '{}');
    const ti = ev.tool_input || {};
    const toolName = ev.tool_name || ev.toolName || '';

    // Precise detection. A skill invocation either carries tool_input.skill
    // (the Skill tool's argument shape on both Claude Code and Codex) or the
    // tool itself is literally named "Skill". We deliberately do NOT fall back
    // to a generic `name` field — that would mis-capture unrelated MCP tools.
    let skill = null;
    if (typeof ti.skill === 'string' && ti.skill) skill = ti.skill;
    else if (/^skill$/i.test(toolName) && typeof ti.skill === 'string') skill = ti.skill;
    if (!skill) return;

    const home = lib.homeDir();
    const agent = process.env.STELLAR_TRACE_AGENT || 'claude';
    const session = ev.session_id || ev.sessionId || null;
    const ts = new Date().toISOString();
    const prompt = session ? lib.readPrompt(home, session, 600) : null;

    // --- Codex: preserve the legacy synchronous record (no Stop pipeline). ---
    if (agent === 'codex') {
      let resp = ev.tool_response;
      if (typeof resp !== 'string') {
        try { resp = JSON.stringify(resp || ''); } catch (_) { resp = ''; }
      }
      const rec = {
        ts,
        event: 'skill_invoked',
        agent,
        skill,
        prompt,
        args: typeof ti.args === 'string' ? ti.args.slice(0, 600) : (ti.args || null),
        result_preview: resp ? resp.slice(0, 1000) : '',
        result_len: resp ? resp.length : 0,
        cwd: ev.cwd || null,
        session,
      };
      lib.appendTrace(home, rec);
      lib.bumpActivation(home, ts);
      return;
    }

    // --- Claude Code: open / rotate the active-skill pointer. ---
    if (!session) return; // can't track a span without a session id

    const ptrFile = lib.activePath(home, session);
    const prev = lib.readJSON(ptrFile);

    // A new Skill invocation closes any span already open for this session
    // (handoff or re-mount), then starts a fresh span.
    if (prev && prev.skill) {
      lib.closeSpan(home, prev, { ts, reason: 'handoff' });
    }

    lib.writeJSON(ptrFile, {
      skill,
      since: ts,
      prompt,                 // opening prompt of this span
      span_id: lib.newSpanId(session),
      turns: 0,
      agent,
      args: typeof ti.args === 'string' ? ti.args.slice(0, 600) : (ti.args || null),
      cwd: ev.cwd || null,
      session,
      last_preview: '',
      last_result_len: 0,
    });
  } catch (_) {
    // Tracing is best-effort. A bad event must never break the user's session.
  }
});
