#!/usr/bin/env node
// stellar-build learning loop — trace capture (PostToolUse).
//
// Reads a Claude Code / Codex CLI hook event from stdin and appends ONE local
// trace record to ~/.stellar/traces/<UTC-day>.jsonl, then bumps the rolling
// counter the auto-trigger reads. Fully local: nothing is transmitted anywhere.
// Designed to never throw, never block the session.
//
// Opt out entirely with STELLAR_BUILD_NO_TRACE=1.
// Override the data root with STELLAR_HOME.
// The wrapper sets STELLAR_TRACE_AGENT=codex for Codex; defaults to "claude".
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

    const home = process.env.STELLAR_HOME || path.join(os.homedir(), '.stellar');
    const dir = path.join(home, 'traces');
    fs.mkdirSync(dir, { recursive: true });

    const agent = process.env.STELLAR_TRACE_AGENT || 'claude';
    const session = ev.session_id || ev.sessionId || null;

    let resp = ev.tool_response;
    if (typeof resp !== 'string') {
      try { resp = JSON.stringify(resp || ''); } catch (_) { resp = ''; }
    }
    const fullLen = resp ? resp.length : 0;

    // Pair with the user's natural-language prompt if capture-prompt stored one
    // for this session. This is the single biggest quality lift for mined demos:
    // it lets the optimizer learn "when the user phrases it like X, do Y".
    let prompt = null;
    try {
      if (session) {
        const pf = path.join(home, '.prompts',
          String(session).replace(/[^A-Za-z0-9_.-]/g, '_') + '.txt');
        if (fs.existsSync(pf)) prompt = fs.readFileSync(pf, 'utf8').slice(0, 600);
      }
    } catch (_) { /* prompt pairing is best-effort */ }

    const ts = new Date().toISOString();
    const rec = {
      ts,
      event: 'skill_invoked',
      agent,
      skill,
      prompt,
      args: typeof ti.args === 'string' ? ti.args.slice(0, 600) : (ti.args || null),
      result_preview: resp ? resp.slice(0, 1000) : '',
      result_len: fullLen,
      cwd: ev.cwd || null,
      session,
    };

    fs.appendFileSync(
      path.join(dir, ts.slice(0, 10) + '.jsonl'),
      JSON.stringify(rec) + '\n'
    );

    // Bump the rolling counter the SessionStart auto-trigger reads, so the loop
    // can decide when enough new usage has accumulated to retune.
    try {
      const sf = path.join(home, 'state.json');
      let st = {};
      try { st = JSON.parse(fs.readFileSync(sf, 'utf8') || '{}') || {}; } catch (_) { st = {}; }
      st.traces_total = (st.traces_total || 0) + 1;
      st.traces_since_optimize = (st.traces_since_optimize || 0) + 1;
      st.last_trace_ts = ts;
      fs.writeFileSync(sf, JSON.stringify(st));
    } catch (_) { /* counter is best-effort */ }
  } catch (_) {
    // Tracing is best-effort. A bad event must never break the user's session.
  }
});
