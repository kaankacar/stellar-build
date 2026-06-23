---
name: reprompt
description: Rewrite a rough request into a sharp, structured prompt before acting on it. Use when the user says "reprompt this", "reprompt", "improve this prompt", "make this prompt better", "structure this request", or hands you a vague/underspecified ask you should sharpen first. Complements the automatic per-turn sharpener (the UserPromptSubmit hook) for explicit, heavier rewrites. Personalizes from ~/.stellar/profile.md when present.
---

## What this skill does

Turns a rough ask into a tight working spec, then acts on it — the explicit,
on-demand counterpart to the loop's automatic per-turn sharpener. Use it when a
request is vague enough to be worth structuring out loud, or when the user
literally asks you to "reprompt this".

## How to run it

### 1. Capture the raw request

Take the text the user wants sharpened (everything after "reprompt this:", or
the preceding message if they just say "reprompt that").

### 2. Load any learned profile

If `~/.stellar/profile.md` exists (the optimizer distills it from real usage),
read it and treat it as defaults — domain, typical scope, preferred stack,
tone — unless the request contradicts them. Honor `STELLAR_HOME` if set.

### 3. Produce the sharpened spec

Rewrite the request into this structure. Keep it tight; don't pad.

```
Goal:        the outcome actually wanted (not the literal words)
Context:     relevant assumptions, environment, prior decisions
Task:        the smallest precise action(s) that achieve the goal
Constraints: scope limits, must-nots, non-negotiables
Success:     how we'll know it's done right
```

### 4. Gate on ambiguity

If a genuine ambiguity would change the result, ask 1–3 sharp questions first
(one at a time) and fill the spec from the answers. If it's clear enough,
proceed directly.

### 5. Act

Show the sharpened spec briefly, then execute on it (or hand off to the right
stellar-build skill — e.g. `find-stellar-idea`, `nicole-pm`, `tyler-architect`).
Don't make the user re-approve unless a clarifying answer is still pending.

## Notes

- This is the manual lever. The automatic version runs every turn via the
  `UserPromptSubmit` hook and needs no invocation; turn it off with
  `STELLAR_BUILD_NO_REPROMPT=1`.
- The more you use stellar-build, the better both get: `/optimize-skills`
  refreshes `~/.stellar/profile.md` from your traces, which feeds these rewrites.
