# stellar-build

![Installs](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fabacus.jasoncameron.dev%2Fget%2Fkaankacar.stellar-build%2Finstall&query=%24.value&label=installs&color=blue)

A one-command install that drops an end-to-end Stellar development journey into your Claude Code and OpenAI Codex CLI setup. From "what should I build?" to mainnet deploy and Stellar Community Fund grant submission, in 46 skills plus curated ecosystem data.

And it gets better the more you use it: a **fully automatic, fully local learning loop** auto-sharpens every prompt, traces how you actually work, and quietly retunes your skills in the background — hands-free, nothing ever leaves your machine. [Jump to the learning loop ↓](#learning-loop)

```bash
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash
```

## What you get

**46 skills across the full journey:**

- **Idea phase.** Discover what to build on Stellar, validate against the 728-project ecosystem and ~9000-repo developer activity signal, cross-reference with broader investor thesis (a16z, YC, Alliance DAO), and watch the live SCF round.
- **Planning phase.** PRD, UX design, and product brief, driven by personas from the SDF DevRel team.
- **Solutioning phase.** Architecture, epics, stories, plus deep Soroban + dapp + asset knowledge from `stellar/stellar-dev-skill`.
- **Implementation phase.** Story-driven dev, code review, and debugging.
- **Launch phase.** Devnet to mainnet deploy plus 10 SCF grant lifecycle skills.
- **Learning loop.** A local, private, **fully automatic** feedback loop (`learning-loop`, `optimize-skills`, `bench-skills`, `reprompt`) that auto-sharpens every prompt, traces how you use your skills, and retunes them in the background over time — hands-free. See [Learning loop](#learning-loop).

**Curated data layer:**

- The full LumenLoop ecosystem catalog (728 projects, SCF rounds, audits, tokens)
- Electric Capital's Stellar developer taxonomy (9,027 catalogued repos, with bootcamp-noise filtering instructions baked into the skills)
- Stellar Foundation's ecosystem-resources reference docs
- Broader crypto market thesis catalogs: a16z Big Ideas 2025, a16z State of Crypto 2025, YC Requests for Startups, every YC-backed crypto company, Alliance DAO published ideas

Skills that do market or competitive work (Justin the analyst, Nicole the PM, the PRFAQ + PRD + product-brief flows, the find/landscape/SCF-round skills) all read from this data layer for grounded, evidence-based recommendations.

## Meet your team

stellar-build gives you six AI agents with distinct roles, named for the SDF DevRel team. Call any of them by name to swap into their persona:

| Persona | Role | Call them when... |
|---------|------|-------------------|
| **Justin** | Business Analyst | you need market research, competitive analysis, requirements elicitation |
| **Bri** | Tech Writer | you need documentation, knowledge curation, technical writing |
| **Nicole** | Product Manager | you need PRDs, requirements discovery, stakeholder alignment |
| **Kaan** | UX Designer | you need interaction design, UX specifications |
| **Tyler** | System Architect | you need architecture decisions, Soroban contract design |
| **Elliot** | Senior Developer | you need code, story execution, implementation |

Talk to any of them naturally:

```
"talk to Tyler"             → adopts the architect persona
"Justin, who are my competitors on Stellar?"  → analyst with context
"party mode"                → all six in one group discussion (see note below)
```

### Multi-agent party mode requirement

For `/party-mode` to spawn each persona as a real isolated subagent (rather than one LLM roleplaying everyone in solo mode), your project folder needs to be a git repo with at least one commit. Claude Code uses git worktrees for subagent isolation, which need a HEAD ref to branch from.

If you see "not in a git repository" or "no HEAD" errors when running party mode, run:

```bash
git init
git commit --allow-empty -m "init"
```

The empty commit is the trick. Once you have it, `/party-mode` spawns each persona in its own worktree and they think independently. Without the commit, party mode still runs but in solo mode (single LLM, six voices).

## Getting started

Skills install to both `~/.claude/skills/` and `~/.codex/skills/`, so the same prompts work whether you're in Claude Code, Codex CLI, or any agent that reads from those paths. Open your CLI and type prompts directly. There are two ways to invoke skills.

**Natural language.** Describe what you want and the right skill auto-activates:

```
what should I build on Stellar?          → find-stellar-idea
current SCF round                        → scf-round-watcher
deploy to mainnet                        → deploy-stellar-mainnet
talk to Nicole and write a PRD           → nicole-pm
```

**Slash commands.** Use these when you know exactly which skill you want:

```
/stellar-help        how does this all work?
/navigate-skills     browse all 46 skills
/scf-round-watcher   explicit scf round fetch
```

### A typical journey

```
# 1. Idea
what should I build on Stellar?
  → find-stellar-idea interviews you, proposes 3 ranked ideas

# 2. Validate against existing ecosystem
who are my competitors?
  → stellar-competitive-landscape queries the 728-project DB

# 3. Plan with Nicole
talk to Nicole, let's write a PRD
  → nicole-pm walks PRD creation

# 4. Architect with Tyler
talk to Tyler, design the architecture
  → tyler-architect + soroban/dapp skills

# 5. Build with Elliot
talk to Elliot, implement the first story
  → elliot-dev + dev-story

# 6. Review before ship
code review
  → code-review + review-edge-case-hunter

# 7. Deploy
deploy to Stellar mainnet
  → deploy-stellar-mainnet checklist

# 8. Apply for SCF
current SCF round              see what's open
draft my SCF submission        → scf-submission-drafter
```

## How it works

The install pulls from four canonical sources at install time:

1. **This repo** (`kaankacar/stellar-build`). 20 paraphrased BMAD methodology skills, 5 new Stellar-specific skills, 4 learning-loop skills, the installer, plus the bundled data layer: LumenLoop's 728-project ecosystem catalog (converted to JSON at build time), Electric Capital's 9,027-repo Stellar taxonomy, and the broader market thesis catalogs (a16z Big Ideas, a16z State of Crypto, YC Requests for Startups, YC crypto companies, Alliance DAO ideas).
2. **`lumenloop/awesome-stellar-community-fund`.** 10 SCF lifecycle skills.
3. **`stellar/stellar-dev-skill`.** 7 Stellar dev knowledge modules (Soroban, dapp, assets, data, agentic-payments, zk-proofs, standards).

We don't redistribute upstream content from sources 2-3. Instead, the installer points your machine at the canonical sources. See [NOTICES.md](./NOTICES.md) for attribution and licenses.

## Learning loop

Your skills get sharper the more you use them — and none of it leaves your machine.
This mirrors OpenJarvis's `jarvis optimize skills` / `jarvis bench skills` cycle,
adapted for markdown skills.

```
  every prompt ─▶ UserPromptSubmit hook auto-sharpens it (reprompter, automatic)
                        + injects your learned profile (~/.stellar/profile.md)

   use skills ─▶ ~/.stellar/traces/*.jsonl     PostToolUse hook captures every skill run
                       │                        (prompt paired via UserPromptSubmit hook)
                       │
        SessionStart hook: enough new usage? ──▶ auto-run  (DEFAULT, hands-free)
                       │                     └─▶ nudge      (fallback: no claude CLI / AUTO_OPTIMIZE=0)
                       ▼
            /optimize-skills   DSPy-style: judge wins, mine demos, refine skills + refresh profile.md
                       │
                       ▼
       sharper ~/.claude/skills/<skill>/SKILL.md   ◀── stellar-loop restore <skill>  (one-step undo)
                       │
             /bench-skills    held-out prompts, fixed seeds, before/after lift
```

**It runs itself, end to end.** No command to remember:

1. **Every prompt is auto-sharpened.** A `UserPromptSubmit` hook (`reprompt.sh`) silently restructures your request into a working spec (goal / context / task / success criteria) before the agent acts — reprompter, but automatic and on every turn. It also injects your learned profile so the rewrite is personalized.
2. **Every skill run is traced**, locally.
3. **Your skills auto-retune.** Once you've used skills enough since the last tune-up (default 20), a `SessionStart` hook **runs `/optimize-skills` for you in the background** — hands-free, the default. (If the `claude` CLI isn't on PATH, or you set `STELLAR_BUILD_AUTO_OPTIMIZE=0`, it falls back to a zero-cost nudge instead.)

The optimizer also distils a profile of how you work into `~/.stellar/profile.md`, which feeds step 1 — so over time the loop sharpens your **prompts**, not just your skills.

**The pieces:**

- **Auto-reprompt.** `UserPromptSubmit` hook → sharpens every non-trivial prompt and injects `profile.md`. Skips slash commands and bare acks. Off with `STELLAR_BUILD_NO_REPROMPT=1`. Also available on demand as the `reprompt` skill ("reprompt this: …").
- **Capture.** `PostToolUse` hook appends one truncated record per skill invocation to `~/.stellar/traces/<day>.jsonl`, paired with the triggering prompt. Fully local — no API calls, no telemetry. **Works in Claude Code and Codex** (same hooks registered in `~/.codex/hooks.json`); `stellar-loop ingest-codex` backfills older Codex sessions.
- **Self-trigger.** `SessionStart` hook decides auto vs. nudge, with a cooldown so it never nags and a recursion guard so an auto-run never re-triggers itself.
- **`/optimize-skills`.** Labels traces win/neutral/loss as an LLM judge, compiles the wins into sharper skills (tightened triggers + a delimited `Learned from your usage` block), and refreshes `profile.md`. Every edit is backed up and fully reversible.
- **`/bench-skills`.** Scores skills against a held-out eval set with fixed seeds (`--max-samples`, `--seeds`) to measure the lift and catch regressions.

**The `stellar-loop` CLI** (`~/.stellar/bin/stellar-loop`) handles the deterministic parts:

```bash
stellar-loop status            # capture + auto-tune state, counts, since-last-tune
stellar-loop stats             # per-skill usage from your local traces
stellar-loop optimize [skill]  # drive /optimize-skills (headless if the claude CLI is present)
stellar-loop bench  [skill]    # drive /bench-skills
stellar-loop restore <skill>   # undo the last optimization for a skill
stellar-loop ingest-codex      # backfill skill usage from Codex session rollouts
stellar-loop clear [--all]     # delete traces (--all also clears backups)
```

Add it to your PATH with `export PATH="$PATH:$HOME/.stellar/bin"`.

**Knobs (env):**

| Variable | Default | Effect |
|----------|---------|--------|
| `STELLAR_BUILD_AUTO_OPTIMIZE` | **on** | hands-free background retune (needs the `claude` CLI). `0`/`false`/`off` = nudge instead |
| `STELLAR_BUILD_NO_REPROMPT` | off | `1` = disable the per-prompt auto-sharpener |
| `STELLAR_BUILD_OPTIMIZE_THRESHOLD` | `20` | skill uses since last tune before triggering |
| `STELLAR_BUILD_OPTIMIZE_COOLDOWN_HOURS` | `6` | minimum gap between tune-ups |
| `STELLAR_BUILD_NO_LOOP` | off | `1` = disable the auto-trigger (keep manual `/optimize-skills`) |
| `STELLAR_BUILD_NO_TRACE` | off | `1` = disable capture entirely |
| `STELLAR_HOME` | `~/.stellar` | move the data root |

**Privacy & control.** Everything lives under `~/.stellar/`. Result previews are truncated and mined examples are generalized before they ever land in a skill. `--uninstall` removes every hook (from both Claude and Codex), the CLI, and the trace store. `/optimize-skills` and `/bench-skills` themselves work in any agent that reads the skills.

## Sandboxed / per-project install

You can install stellar-build into a specific project folder instead of your global `$HOME`. This is useful when you want the skills *scoped to one project*:

```bash
mkdir my-stellar-project && cd my-stellar-project
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash -s -- --prefix=$(pwd)
```

This installs to `./my-stellar-project/.claude/skills/` and `./my-stellar-project/.codex/skills/`. When you `cd` into the project and run `claude` (or `codex`), the CLI reads project-local skills from `.claude/skills/` automatically, so all 46 skills work for *this project only*.

That makes sandboxed install useful in two scenarios:

1. **Per-project skills.** You want stellar-build active for one specific Stellar project, not globally.
2. **Testing without affecting your real `$HOME`.** Try the bundle on a throwaway folder before committing to a global install.

Project-local installs don't conflict with each other or with a global install. Claude Code merges global and project skills automatically.

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/kaankacar/stellar-build/main/install.sh | bash -s -- --update
```

This re-runs the install, pulling fresh versions of all sources. Skills you've added manually to `~/.claude/skills/` from other places are untouched.

## Uninstall

```bash
./install.sh --uninstall                              # global
./install.sh --uninstall --prefix=$(pwd)/my-project   # project-local
```

The manifest at `~/.stellar/manifest.json` (or `$PREFIX/.stellar/manifest.json`) tracks every path and permission stellar-build touched, so uninstall reverses cleanly.

## Built on

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** (MIT). Methodology skill backbone. Personas paraphrased to match the SDF DevRel team.
- **[stellar/stellar-dev-skill](https://github.com/stellar/stellar-dev-skill)** (Apache 2.0). Official Stellar developer skills, fetched as-is from upstream at install time.
- **[lumenloop/awesome-stellar-community-fund](https://github.com/lumenloop/awesome-stellar-community-fund)**. SCF grant lifecycle skills.
- **[lumenloop/stellar-ecosystem-db](https://github.com/lumenloop/stellar-ecosystem-db)**. 728-project Stellar ecosystem database.
- **[electric-capital/open-dev-data](https://github.com/electric-capital/open-dev-data)** (MIT + CC-BY 4.0). Developer activity taxonomy.
- **[stellar/ecosystem-resources](https://github.com/stellar/ecosystem-resources)**. Curated Stellar reference docs.

Full attributions in [NOTICES.md](./NOTICES.md). Inspired by the [solana.new](https://www.solana.new) install pattern.
