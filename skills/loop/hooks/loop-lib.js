// stellar-build learning loop — shared hook helpers.
//
// A skill *use* is a multi-turn span, not a single synchronous tool call. These
// helpers let the three writers cooperate on that model:
//
//   trace-skill.js (PostToolUse:Skill) -> opens/rotates a per-session ACTIVE
//                                          pointer (.active/<session>.json)
//   stop-trace.js  (Stop)              -> appends one kind:"turn" record per turn
//   session-end.js (SessionEnd)        -> closes the span: one kind:"span" record
//
// Everything is local, best-effort, and must never throw into a session.
// Honors STELLAR_HOME (data root) just like the rest of the loop.
'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

function homeDir() {
  return process.env.STELLAR_HOME || path.join(os.homedir(), '.stellar');
}

// Filesystem-safe session id for use in file names.
function sessionKey(session) {
  return String(session == null ? '' : session).replace(/[^A-Za-z0-9_.-]/g, '_');
}

function activePath(home, session) {
  return path.join(home, '.active', sessionKey(session) + '.json');
}

function promptPath(home, session) {
  return path.join(home, '.prompts', sessionKey(session) + '.txt');
}

function readJSON(f) {
  try { return JSON.parse(fs.readFileSync(f, 'utf8') || '{}') || {}; }
  catch (_) { return null; }
}

function writeJSON(f, obj) {
  fs.mkdirSync(path.dirname(f), { recursive: true });
  const tmp = f + '.' + process.pid + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(obj));
  fs.renameSync(tmp, f);
}

// The opening (or per-turn) natural-language prompt stashed by capture-prompt.js.
function readPrompt(home, session, cap) {
  try {
    const f = promptPath(home, session);
    if (fs.existsSync(f)) return fs.readFileSync(f, 'utf8').slice(0, cap || 600);
  } catch (_) { /* prompt pairing is best-effort */ }
  return null;
}

// A reasonably unique, sortable-ish span id. Hooks run as ordinary node
// processes, so Date.now()/Math.random() are fine here (unlike workflow scripts).
function newSpanId(session) {
  const rnd = Math.random().toString(36).slice(2, 8);
  return sessionKey(session).slice(0, 16) + '-' + Date.now().toString(36) + '-' + rnd;
}

// Parse a Claude Code transcript (JSONL) and return the text of the LAST
// assistant message: concatenate its type:"text" blocks, skip tool_use /
// tool_result / user turns. Walks backwards through assistant messages so a
// trailing tool-only message doesn't blank the result.
function lastAssistantText(transcriptPath, cap) {
  try {
    if (!transcriptPath || !fs.existsSync(transcriptPath)) return '';
    const lines = fs.readFileSync(transcriptPath, 'utf8').split('\n');
    let last = '';
    for (const line of lines) {
      const s = line.trim();
      if (!s) continue;
      let obj;
      try { obj = JSON.parse(s); } catch (_) { continue; }
      const msg = obj && obj.message ? obj.message : obj;
      const role = (obj && obj.type) || (msg && msg.role);
      if (role !== 'assistant' && !(msg && msg.role === 'assistant')) continue;
      const content = msg && msg.content;
      let text = '';
      if (typeof content === 'string') {
        text = content;
      } else if (Array.isArray(content)) {
        text = content
          .filter((b) => b && b.type === 'text' && typeof b.text === 'string')
          .map((b) => b.text)
          .join('');
      }
      if (text && text.trim()) last = text; // keep the last non-empty assistant text
    }
    return cap ? last.slice(0, cap) : last;
  } catch (_) {
    return '';
  }
}

function dayFile(home, ts) {
  return path.join(home, 'traces', String(ts).slice(0, 10) + '.jsonl');
}

function appendTrace(home, rec) {
  const dir = path.join(home, 'traces');
  fs.mkdirSync(dir, { recursive: true });
  fs.appendFileSync(dayFile(home, rec.ts), JSON.stringify(rec) + '\n');
}

// One activation == one span. Bumped exactly once per closed span so the
// SessionStart auto-trigger's "20" keeps meaning "20 skill activations".
function bumpActivation(home, ts) {
  try {
    const sf = path.join(home, 'state.json');
    const st = readJSON(sf) || {};
    st.traces_total = (st.traces_total || 0) + 1;
    st.traces_since_optimize = (st.traces_since_optimize || 0) + 1;
    st.last_trace_ts = ts;
    writeJSON(sf, st);
  } catch (_) { /* counter is best-effort */ }
}

// Close an open span: write one kind:"span" summary record (opening prompt +
// final work product accumulated across the span) and bump the activation
// counter once. Does NOT remove the pointer file — the caller decides whether
// to clear it (SessionEnd) or overwrite it with a new span (handoff).
function closeSpan(home, ptr, opts) {
  if (!ptr || !ptr.skill) return false;
  opts = opts || {};
  const ts = opts.ts || new Date().toISOString();
  const preview = (opts.result_preview != null ? opts.result_preview : ptr.last_preview) || '';
  const rec = {
    ts,
    kind: 'span',
    event: 'skill_span',
    agent: ptr.agent || 'claude',
    skill: ptr.skill,
    prompt: ptr.prompt || null,         // the opening prompt of the span
    result_preview: String(preview).slice(0, 1500),
    result_len: opts.result_len != null ? opts.result_len : (ptr.last_result_len || 0),
    span_id: ptr.span_id || null,
    turns: ptr.turns || 0,
    since: ptr.since || null,
    reason: opts.reason || null,        // e.g. "handoff" | "session_end"
    cwd: ptr.cwd || null,
    session: ptr.session || null,
  };
  try { appendTrace(home, rec); } catch (_) { return false; }
  bumpActivation(home, ts);
  return true;
}

module.exports = {
  homeDir,
  sessionKey,
  activePath,
  promptPath,
  readJSON,
  writeJSON,
  readPrompt,
  newSpanId,
  lastAssistantText,
  appendTrace,
  bumpActivation,
  closeSpan,
};
