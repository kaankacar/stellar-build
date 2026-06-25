#!/usr/bin/env node
// Acceptance test for the stellar-build learning-loop span fix.
//
// Simulates a RESIDENT skill (a BMAD persona) used across 5 turns in one
// session by feeding the real hook scripts synthetic events:
//
//   trace-skill.js  (PostToolUse:Skill)  x1  -> opens the active-skill pointer
//   stop-trace.js   (Stop)               x5  -> one real per-turn record each
//   session-end.js  (SessionEnd)         x1  -> closes the span, bumps once
//
// Then asserts the loop now produces:
//   (a) 5 kind:"turn" records whose result_preview is the REAL assistant text
//       (not the `{"success":true,...}` mount stub),
//   (b) exactly one kind:"span" record,
//   (c) traces_since_optimize incremented by exactly 1 (per span, not per turn),
//   (d) /optimize-skills would count this as 1 usable span and can mine a demo.
//
// Run: node test/loop-acceptance.js
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const cp = require('child_process');

const HOOKS = path.resolve(__dirname, '..', 'skills', 'loop', 'hooks');
const SESSION = 'sess-justin-analyst-001';
const SKILL = 'justin-analyst';            // a resident BMAD persona
const OPENING_PROMPT = 'Talk to Justin — I need a business analysis of my idea.';
const MOUNT_STUB = JSON.stringify({ success: true, commandName: SKILL }); // ~47 chars

let failures = 0;
function check(name, cond, detail) {
  const ok = !!cond;
  if (!ok) failures++;
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  — ${detail}` : ''}`);
  return ok;
}

function runHook(jsName, event, env) {
  cp.execFileSync('node', [path.join(HOOKS, jsName)], {
    input: JSON.stringify(event),
    env,
    stdio: ['pipe', 'ignore', 'ignore'],
  });
}

function readAllRecords(home) {
  const dir = path.join(home, 'traces');
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter((f) => f.endsWith('.jsonl'))
    .flatMap((f) => fs.readFileSync(path.join(dir, f), 'utf8').split('\n'))
    .map((l) => l.trim())
    .filter(Boolean)
    .map((l) => JSON.parse(l));
}

// Build the per-turn assistant text. Two text blocks (prove concatenation) plus
// a tool_use block (prove it's skipped). The marker lets us match exactly.
function assistantText(i) {
  return `Turn ${i}: as the business analyst I recommend `
    + `scoping the MVP first. [marker-${i}]`;
}
function assistantMessageLine(i) {
  const t = assistantText(i);
  const half = Math.ceil(t.length / 2);
  return JSON.stringify({
    type: 'assistant',
    message: {
      role: 'assistant',
      content: [
        { type: 'text', text: t.slice(0, half) },
        { type: 'tool_use', name: 'Read', input: { file: 'x' } }, // must be skipped
        { type: 'text', text: t.slice(half) },
      ],
    },
  });
}
function userMessageLine(i) {
  return JSON.stringify({
    type: 'user',
    message: { role: 'user', content: [{ type: 'tool_result', content: 'noise' }] },
  });
}

// ===== Scenario 1: one resident skill used across 5 turns (the required test). =====
function scenarioResident() {
  console.log('\nScenario 1 — resident skill across 5 turns\n');
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'stellar-loop-test-'));
  const env = Object.assign({}, process.env, { STELLAR_HOME: home });
  delete env.STELLAR_BUILD_NO_TRACE;
  delete env.STELLAR_LOOP_AUTORUN;

  const transcript = path.join(home, 'transcript.jsonl');
  const promptFile = path.join(home, '.prompts', SESSION.replace(/[^A-Za-z0-9_.-]/g, '_') + '.txt');
  const pointerFile = path.join(home, '.active', SESSION.replace(/[^A-Za-z0-9_.-]/g, '_') + '.json');

  fs.mkdirSync(path.dirname(promptFile), { recursive: true });
  fs.writeFileSync(transcript, '');

  console.log(`\nstellar-build learning loop — acceptance test`);
  console.log(`  STELLAR_HOME = ${home}\n`);

  // --- Step A: skill mounts (PostToolUse:Skill). Should write a POINTER, not a trace. ---
  fs.writeFileSync(promptFile, OPENING_PROMPT);
  runHook('trace-skill.js', {
    session_id: SESSION,
    tool_name: 'Skill',
    tool_input: { skill: SKILL },
    tool_response: MOUNT_STUB,           // the bug: this used to be the recorded preview
    cwd: '/work',
  }, env);

  const afterMount = readAllRecords(home);
  check('mount writes NO trace record (just a pointer)', afterMount.length === 0,
    `${afterMount.length} record(s) after mount`);
  const ptr = fs.existsSync(pointerFile) ? JSON.parse(fs.readFileSync(pointerFile, 'utf8')) : null;
  check('active pointer created with skill + span_id + turns:0',
    ptr && ptr.skill === SKILL && ptr.turns === 0 && !!ptr.span_id && ptr.prompt === OPENING_PROMPT,
    ptr ? `skill=${ptr.skill} turns=${ptr.turns}` : 'no pointer');
  const spanId = ptr && ptr.span_id;

  // --- Step B: 5 turns. Each Stop appends one real per-turn record. ---
  for (let i = 0; i < 5; i++) {
    fs.appendFileSync(transcript, userMessageLine(i) + '\n' + assistantMessageLine(i) + '\n');
    fs.writeFileSync(promptFile, `Turn ${i} follow-up for the analysis.`);
    runHook('stop-trace.js', {
      session_id: SESSION,
      transcript_path: transcript,
      cwd: '/work',
    }, env);
  }

  // --- Step C: session ends. Close the span with one summary record. ---
  runHook('session-end.js', {
    session_id: SESSION,
    transcript_path: transcript,
    reason: 'clear',
    cwd: '/work',
  }, env);

  const records = readAllRecords(home);
  const turns = records.filter((r) => r.kind === 'turn');
  const spans = records.filter((r) => r.kind === 'span');
  const state = JSON.parse(fs.readFileSync(path.join(home, 'state.json'), 'utf8'));

  console.log('');
  // (a) 5 turn records with REAL assistant text (not the mount stub).
  check('(a) exactly 5 kind:"turn" records', turns.length === 5, `got ${turns.length}`);
  const allRealText = turns.every((r, idx) => {
    const expect = assistantText(r.turn_index);
    return r.result_preview === expect
      && !r.result_preview.includes('"success":true')
      && r.result_len > 0;
  });
  check('(a) every turn preview is the REAL assistant text (not the mount stub)', allRealText,
    turns.map((r) => `[t${r.turn_index} len=${r.result_len}]`).join(' '));
  check('(a) turn indices are 0..4 and share one span_id',
    turns.map((r) => r.turn_index).sort().join(',') === '0,1,2,3,4'
      && turns.every((r) => r.span_id === spanId),
    `span_id=${spanId}`);

  // (b) one span record.
  check('(b) exactly one kind:"span" record', spans.length === 1, `got ${spans.length}`);
  const span = spans[0];
  check('(b) span summarizes 5 turns, opening prompt + final work product',
    span && span.turns === 5 && span.prompt === OPENING_PROMPT
      && span.result_preview === assistantText(4)
      && !span.result_preview.includes('"success":true'),
    span ? `turns=${span.turns} preview="${(span.result_preview || '').slice(0, 30)}..."` : 'no span');

  // (c) activation counter bumped exactly once (per span, not per turn).
  check('(c) traces_since_optimize incremented by exactly 1 (per span, not 5)',
    state.traces_since_optimize === 1 && state.traces_total === 1,
    `since_optimize=${state.traces_since_optimize} total=${state.traces_total}`);

  // (d) /optimize-skills view: group by span_id (fallback session×skill) and
  // confirm one usable span with a mineable demo (real output, not the stub).
  const bySpan = new Map();
  for (const r of records) {
    if (r.kind !== 'turn' && r.kind !== 'span') continue; // legacy/coverage-only excluded
    const key = r.span_id || `${r.session}:${r.skill}`;
    if (!bySpan.has(key)) bySpan.set(key, { skill: r.skill, prompt: null, output: null, turns: 0 });
    const s = bySpan.get(key);
    if (r.kind === 'span') { s.prompt = r.prompt; s.output = r.result_preview; s.turns = r.turns; }
    if (r.kind === 'turn') { if (!s.prompt) s.prompt = r.prompt; if (!s.output) s.output = r.result_preview; }
  }
  const usable = [...bySpan.values()].filter(
    (s) => s.skill === SKILL && s.output && !s.output.includes('"success":true'));
  check('(d) optimize-skills counts this as exactly 1 usable span', usable.length === 1,
    `usable spans=${usable.length}`);
  const demo = usable[0] && { trigger: usable[0].prompt, approach: usable[0].output };
  check('(d) a few-shot demo is mineable from the span (real trigger + output)',
    demo && demo.trigger === OPENING_PROMPT && demo.approach && demo.approach.length > 40,
    demo ? `trigger="${demo.trigger}" approachLen=${demo.approach.length}` : 'no demo');

  console.log('\n  Mined demo /optimize-skills would learn from this session:');
  if (demo) {
    console.log(`    when the user asked: "${demo.trigger}"`);
    console.log(`    the effective output was: "${demo.approach.slice(0, 70)}..."`);
  }

  if (failures === 0) { try { fs.rmSync(home, { recursive: true, force: true }); } catch (_) {} }
  else console.log(`  (left STELLAR_HOME for inspection: ${home})`);
}

// ===== Scenario 2: persona handoff mid-session rotates + closes the prior span. =====
function scenarioHandoff() {
  console.log('\nScenario 2 — persona handoff (justin-analyst -> nicole-pm)\n');
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'stellar-loop-handoff-'));
  const env = Object.assign({}, process.env, { STELLAR_HOME: home });
  delete env.STELLAR_BUILD_NO_TRACE;
  delete env.STELLAR_LOOP_AUTORUN;

  const session = 'sess-handoff-001';
  const key = session.replace(/[^A-Za-z0-9_.-]/g, '_');
  const promptFile = path.join(home, '.prompts', key + '.txt');
  const transcript = path.join(home, 'transcript.jsonl');
  fs.mkdirSync(path.dirname(promptFile), { recursive: true });
  fs.writeFileSync(transcript, '');

  const mount = (skill) => runHook('trace-skill.js', {
    session_id: session, tool_name: 'Skill', tool_input: { skill },
    tool_response: JSON.stringify({ success: true, commandName: skill }), cwd: '/work',
  }, env);
  const turn = (skill, text, prompt) => {
    fs.appendFileSync(transcript,
      JSON.stringify({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text }] } }) + '\n');
    fs.writeFileSync(promptFile, prompt);
    runHook('stop-trace.js', { session_id: session, transcript_path: transcript, cwd: '/work' }, env);
  };

  fs.writeFileSync(promptFile, 'Talk to Justin about my idea.');
  mount('justin-analyst');
  turn('justin-analyst', 'Justin: the market analysis suggests a narrow MVP wedge.', 'analyze the market');
  mount('nicole-pm'); // handoff: must close justin's span first
  turn('nicole-pm', 'Nicole: here is the PRD outline with goals and scope.', 'now write the PRD');
  runHook('session-end.js', { session_id: session, transcript_path: transcript, reason: 'clear', cwd: '/work' }, env);

  const records = readAllRecords(home);
  const spans = records.filter((r) => r.kind === 'span');
  const state = JSON.parse(fs.readFileSync(path.join(home, 'state.json'), 'utf8'));

  check('handoff closes the prior span: 2 span records (justin, nicole)',
    spans.length === 2 && spans[0].skill === 'justin-analyst' && spans[1].skill === 'nicole-pm',
    spans.map((s) => `${s.skill}/${s.reason}`).join(' '));
  check('prior span closed with reason "handoff", final with "session_end"',
    spans[0] && spans[0].reason === 'handoff' && spans[1] && spans[1].reason === 'session_end');
  check('each persona span carries its OWN real work product',
    spans[0] && spans[0].result_preview.includes('market analysis')
      && spans[1] && spans[1].result_preview.includes('PRD outline'));
  check('activation counter bumped once PER SPAN (=2), not per turn',
    state.traces_since_optimize === 2, `since_optimize=${state.traces_since_optimize}`);

  if (!spans.length || failures) console.log(`  (left STELLAR_HOME for inspection: ${home})`);
  else try { fs.rmSync(home, { recursive: true, force: true }); } catch (_) {}
}

scenarioResident();
scenarioHandoff();

console.log('');
if (failures === 0) {
  console.log(`  ALL CHECKS PASSED — span model works end to end.\n`);
  process.exit(0);
} else {
  console.log(`  ${failures} CHECK(S) FAILED.\n`);
  process.exit(1);
}
