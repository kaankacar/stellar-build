---
name: optimize-skills
description: Compile your local stellar-build usage traces into sharper skills. Use when the user says "optimize my skills", "optimize-skills", "improve my skills from usage", "learn from my traces", "stellar-loop optimize", or wants the learning loop to refine installed skills based on how they've actually been used. DSPy-style prompt optimization over the local trace store at ~/.stellar/traces — fully local, reversible.
---

## What this skill does

This is the **optimizer** half of the stellar-build learning loop — the analog of
`jarvis optimize skills --policy dspy`. It reads the local trace of how you've
actually used your skills and *compiles* that experience back into the installed
skill files: refined trigger descriptions, tightened instructions, and mined
few-shot examples drawn from your own successful runs.

Think of it in DSPy terms:
- **Trainset** = your trace records in `~/.stellar/traces/*.jsonl`, grouped into
  **spans** (one continuous use of a skill within a session — see below)
- **Metric** = an LLM-as-judge quality label you assign to each *span*
- **Compile** = rewriting the skill's instructions + few-shot demos from the wins

Everything is local and reversible. The original of every edited skill is backed
up to `~/.stellar/backups/<skill>/SKILL.md.<timestamp>` before any change, and
`stellar-loop restore <skill>` undoes the last optimization.

## How to run it

Do these steps in order. Be conservative: this edits files the user relies on.

### 1. Load the traces and group them into spans

Read the trace store:

```
~/.stellar/traces/*.jsonl
```

A skill *use* is a multi-turn **span**, not a single tool call, so records come
in three shapes — key off the `kind` field:

- `kind:"turn"` — one user→assistant turn while a skill was resident:
  `{ kind:"turn", skill, prompt, result_preview, result_len, span_id, turn_index, session, ts }`.
  `result_preview` is the **real assistant output** for that turn (capped ~1500 chars).
- `kind:"span"` — the summary written when the span closed (at SessionEnd or on a
  persona handoff): `{ kind:"span", skill, prompt (opening), result_preview (final
  work product), turns, span_id, session, ts }`.
- **Legacy / coverage-only** — older records and live Codex records have **no
  `kind`** and `event:"skill_invoked"`; their `result_preview` is just the mount
  acknowledgment (`{"success":true,"commandName":"…"}`, ~47 chars). These count
  toward coverage but carry **no work product** — never mine demos from them.

**Group records by span**: a span is identified by `span_id` (fall back to
`session` × `skill` for legacy records). One span = one usage, regardless of how
many turns it spans. The `kind:"span"` record is the span's summary; the
`kind:"turn"` records are its detail.

If `STELLAR_HOME` is set in the environment, use that instead of `~/.stellar`.
If there are no traces, tell the user to use some skills first (and confirm the
hooks are registered — `stellar-loop status` shows this), then stop.

If the user named a specific skill (e.g. "optimize find-stellar-idea"), filter to
that skill. Otherwise consider every skill with **at least 5 spans** — fewer than
that is too little signal to compile from; say so and skip it. (Count spans, not
raw records: five turns of one resident-skill session is **one** span, not five.)

### 2. Score each trace (the metric)

For each candidate skill, judge each **span** (not each raw record) as an honest,
skeptical evaluator. Label each span **win / neutral / loss** using signals you
can see:
- Did the opening `prompt` / `args` clearly match what the skill is for? (good
  trigger fit)
- Does the work product — the `kind:"span"` `result_preview`, or the
  concatenated `kind:"turn"` previews — show the skill did its job vs. flailing,
  asking for re-clarification, or producing something off-target?
- **Re-prompts within a span** are the loss signal: several `kind:"turn"` records
  under one `span_id` where the user keeps re-asking or correcting (rather than
  building forward) suggest the skill missed on the first pass. Judge by the
  *turns within the span*, not by counting separate activations — a resident
  skill legitimately spans many turns.
- A long, on-topic work product after a precise opening prompt is a win signal.

Be calibrated, not generous. If you're unsure, call it neutral. Keep only the
**winning spans** as material to learn from.

### 3. Compile (the optimization)

For each skill, read its currently installed file:

```
~/.claude/skills/<skill>/SKILL.md
```

Now produce an improved version. Two levers, exactly like DSPy optimizes both
instructions and demonstrations:

**(a) Instructions & trigger.** If the wins reveal that the user consistently uses
this skill for a narrower or different purpose than the description claims, tighten
the `description` triggers and the body instructions to match reality. Add defaults
the user clearly prefers (e.g. they always want the weekend-hack framing, or always
target testnet first). Never delete the skill's core capability — only sharpen it.

**(b) Few-shot demos.** Distill 1–3 of the strongest **winning spans** into compact,
generalized examples. Mine them from `kind:"span"` / `kind:"turn"` records — these
now hold the real assistant work product (the opening prompt paired with what the
skill actually produced), which is exactly the demonstration material DSPy needs.
**Never mine a demo from a legacy / coverage-only record** (no `kind`, mount-stub
`result_preview`): it has no work product to learn from. Place the demos in a
clearly delimited, regenerable block at the END of the skill body:

```markdown
<!-- LEARNED:BEGIN (auto-generated by optimize-skills — safe to delete/regenerate) -->
## Learned from your usage

_Compiled from <N> local traces on <UTC date>. These are personalized defaults and
examples mined from how you actually use this skill. Edit or delete freely; rerun
`/optimize-skills` to regenerate. Undo with `stellar-loop restore <skill>`._

**Defaults you tend to want:** <short bullet list, or omit if none clear>

**Example interactions that worked well:**
- _When the user asked_ "<generalized trigger>", _the effective move was_ "<distilled approach>".
- ...
<!-- LEARNED:END -->
```

Rules for the learned block:
- It is the ONLY part of the file the optimizer owns. Replace any existing
  `LEARNED:BEGIN..END` block wholesale; never stack duplicates.
- Keep it short (aim < 40 lines). Generalize — never paste raw user data, secrets,
  paths, addresses, or anything that looks sensitive from `result_preview`.
- Preserve the YAML frontmatter `name` exactly. You may sharpen `description`.

### 4. Back up, then write

Before writing any skill, copy the current file to a timestamped backup:

```
mkdir -p ~/.stellar/backups/<skill>
cp ~/.claude/skills/<skill>/SKILL.md ~/.stellar/backups/<skill>/SKILL.md.<UTC-timestamp>
```

Then write the improved `SKILL.md` to BOTH install locations if they exist:
- `~/.claude/skills/<skill>/SKILL.md`
- `~/.codex/skills/<skill>/SKILL.md`

### 5. Refresh the learned profile (feeds the auto-reprompter)

Across ALL the traces (not per-skill), distill a short profile of how this user
works and write it to `~/.stellar/profile.md` (honor `STELLAR_HOME`). The
per-turn auto-reprompter injects this into every prompt, so it's how the loop
makes your *prompts* — not just your skills — get sharper over time.

Keep it to ~6–10 tight bullets of durable, generalizable signal, e.g.:
- domain(s) they keep returning to (payments, DeFi/Soroban, RWA, …)
- typical scope/timeline (weekend hack vs. quarter-long)
- stack / tools they favor, environment defaults (e.g. testnet-first)
- recurring preferences in how they want answers (brevity, code-first, persona)

Rules: generalize only — no secrets, addresses, file paths, or raw snippets.
Overwrite the file each run (it's a living profile, not a log). If the signal is
too thin to say anything useful, write nothing rather than guessing.

### 6. Record the optimization

Append one line per optimized skill to `~/.stellar/optimizations.jsonl`:

```json
{"ts":"<UTC>","event":"optimized","skill":"<name>","traces_seen":<n>,"wins":<n>,"changed":["description","learned-block"],"backup":"<path>"}
```

### 7. Report

Summarize what changed: which skills, how many traces/wins fed each, a one-line
diff-in-words per skill, and the exact `stellar-loop restore <skill>` command to
undo. Recommend `/bench-skills` to measure whether the change actually helped.

## Guardrails

- **Reversible always.** No edit without a fresh backup first.
- **Local only.** Read only from `~/.stellar` and the installed skills. Never send
  traces anywhere.
- **Conservative.** When the signal is thin or ambiguous, leave the skill unchanged
  and say why. A skill that doesn't improve should not be touched.
- **No sensitive data in skills.** Generalize every mined example.
- **Don't optimize the loop's own skills** (`optimize-skills`, `bench-skills`,
  `learning-loop`) — skip them to avoid feedback loops.
