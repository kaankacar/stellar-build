---
name: bench-skills
description: Benchmark stellar-build skills to measure quality and the lift from optimization. Use when the user says "bench my skills", "bench-skills", "benchmark skills", "did optimization help", "measure my skills", "stellar-loop bench", or wants to quantify whether /optimize-skills actually improved things. Held-out eval prompts scored by an LLM judge, reproducible with fixed seeds. Fully local.
---

## What this skill does

This is the **measurement** half of the stellar-build learning loop — the analog of
`jarvis bench skills --max-samples 5 --seeds 42`. It scores a skill's quality on a
held-out set of eval prompts so you can tell whether `/optimize-skills` actually
helped, instead of guessing.

It is read-only: it never edits skills. It only produces scores and a report.

## Arguments (optional, natural language is fine)

- a **skill name** to bench just one skill (default: all skills that have an eval set)
- `--max-samples N` — cap eval prompts per skill (default 5)
- `--seeds a,b,...` — fixed seeds for reproducible sampling/judging (default 42)

## How to run it

### 1. Assemble the eval set per skill

For each target skill, build a small held-out set of representative prompts:

1. If `~/.stellar/bench/<skill>.jsonl` exists, use it. Each line:
   `{ "prompt": "...", "rubric": "what a great response must do" }`.
2. Otherwise, mine candidates from `~/.stellar/traces/*.jsonl`. Records are
   grouped into **spans** (see optimize-skills for the schema): take the real
   opening `prompt` of each span the user triggered this skill with, **hold them
   out** (do not also use them as optimization demos), and pair each with a short
   rubric you infer from the skill's stated purpose. Use one prompt **per span**,
   not per turn, and skip legacy / coverage-only records (no `kind`, mount-stub
   `result_preview`) — they carry no usable trigger. Then persist them to
   `~/.stellar/bench/<skill>.jsonl` so future runs are stable.
3. If there is neither a saved set nor enough traces, synthesize 3 plausible prompts
   from the skill's `description` and note that the set is synthetic.

Sample up to `--max-samples` prompts using the given `--seeds` deterministically
(e.g. stable sort by a hash of `seed + prompt`, take the first N). Reuse the same
seed across before/after runs so comparisons are apples-to-apples.

### 2. Score the skill

For each eval prompt, read the skill's current `~/.claude/skills/<skill>/SKILL.md`
and reason about how that skill, as written, would handle the prompt. Then act as a
strict judge and score the **expected response quality** on a 1–5 scale against the
rubric:

- 5 — nails the rubric, no gaps
- 4 — strong, minor gaps
- 3 — acceptable, real gaps
- 2 — weak / partially off-target
- 1 — wrong or unusable

Judge the skill *as instructions* — clarity, correct triggering, whether its steps
and any `LEARNED` block would produce a rubric-satisfying result. Be consistent
across runs; the same skill text and seed should yield the same score.

### 3. Before/after mode

If the user wants the lift from a recent optimization (or just asks "did it help"):
1. Score the current installed skill (the "after").
2. Score the most recent backup at `~/.stellar/backups/<skill>/SKILL.md.<latest>`
   as the "before", using the **same** prompts and seeds.
3. Report both and the delta.

### 4. Report

Per skill: mean score, per-prompt scores, and — in before/after mode — the lift
(`after − before`) with a one-line interpretation. Roll up an overall mean across
skills. Call out any skill that regressed (after < before) and suggest
`stellar-loop restore <skill>`.

Optionally append a run record to `~/.stellar/bench/results.jsonl`:

```json
{"ts":"<UTC>","skill":"<name>","mean":4.2,"n":5,"seeds":[42],"mode":"after"}
```

## Guardrails

- **Read-only.** Never modify a skill from this flow.
- **Reproducible.** Same skill text + same seed ⇒ same score. Hold seeds fixed
  across before/after.
- **Honest.** A synthetic or tiny eval set is a weak signal — say so in the report.
- **Local only.** Everything reads from `~/.stellar` and the installed skills.
