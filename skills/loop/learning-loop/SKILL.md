---
name: learning-loop
description: Explain and control the stellar-build learning loop — the system that improves your skills from how you use them. Use when the user says "learning loop", "how does the learning loop work", "what is the learning loop", "self-improving skills", "stellar-loop", "show my skill usage", "is tracing on", or wants an overview / status of the local trace-capture + optimize + bench cycle.
---

## What the learning loop is

stellar-build ships with a **local learning loop**: the more you use your skills,
the better they get — without anything leaving your machine. It mirrors OpenJarvis's
`jarvis optimize skills` / `jarvis bench skills` cycle, adapted for markdown skills.

Three moving parts:

1. **Capture** — a Claude Code `PostToolUse:Skill` hook records every skill
   invocation (skill name, trigger args, a truncated result preview) to
   `~/.stellar/traces/<day>.jsonl`. Fully local. Opt out with
   `STELLAR_BUILD_NO_TRACE=1`.
2. **Optimize** (`/optimize-skills`) — compiles those traces into sharper skills:
   tightened triggers/instructions and few-shot examples mined from your own
   successful runs. Every edit is backed up and reversible.
3. **Bench** (`/bench-skills`) — scores skills on held-out prompts so you can
   measure whether an optimization actually helped.

```
   use skills  ──▶  ~/.stellar/traces/*.jsonl
                          │
              /optimize-skills  (DSPy-style compile)
                          │
                          ▼
            sharper ~/.claude/skills/<skill>/SKILL.md   ◀── stellar-loop restore (undo)
                          │
                /bench-skills  (measure the lift)
```

## What to do when invoked

- **Overview / "how does it work"** → explain the three parts above, then point to
  the two action skills and the CLI.
- **"status" / "is tracing on" / "show my usage"** → run the CLI and relay the
  output:
  - `stellar-loop status` — install + capture + hook state, trace/optimization counts
  - `stellar-loop stats` — per-skill usage from local traces
  - `stellar-loop tail` — most recent trace records
  The CLI is installed at `~/.stellar/bin/stellar-loop` (add `~/.stellar/bin` to
  PATH, or call it by full path).
- **"optimize" / "improve my skills"** → hand off to the `optimize-skills` skill.
- **"benchmark" / "did it help"** → hand off to the `bench-skills` skill.
- **"undo" / "restore"** → `stellar-loop restore <skill>` reverts the last
  optimization for that skill from its backup.

## Data & privacy

- Everything lives under `~/.stellar/` (`traces/`, `backups/`, `bench/`,
  `optimizations.jsonl`). Override the root with `STELLAR_HOME`.
- Nothing is transmitted anywhere — no API calls, no telemetry. The "optimizer" is
  your own agent session reasoning over local files.
- Result previews are truncated and examples are generalized before they ever land
  in a skill, so traces and learned blocks should not accumulate secrets. Wipe
  anytime with `stellar-loop clear` (`--all` also clears backups).

## Quick reference

| Goal | Do this |
|------|---------|
| See if it's working | `stellar-loop status` |
| See what you use most | `stellar-loop stats` |
| Make skills sharper | `/optimize-skills` (or `stellar-loop optimize`) |
| Measure the lift | `/bench-skills` (or `stellar-loop bench`) |
| Undo an optimization | `stellar-loop restore <skill>` |
| Turn capture off | `export STELLAR_BUILD_NO_TRACE=1` |
| Delete all traces | `stellar-loop clear` |
