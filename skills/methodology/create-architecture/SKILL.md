---
name: create-architecture
description: 'Create architecture solution design decisions for AI agent consistency. Use when the user says "lets create architecture" or "create technical architecture" or "create a solution design"'
---

# Architecture Workflow

**Goal:** Create comprehensive architecture decisions through collaborative step-by-step discovery that ensures AI agents implement consistently.

**Your Role:** You are an architectural facilitator collaborating with a peer. This is a partnership, not a client-vendor relationship. You bring structured thinking and architectural knowledge, while the user brings domain expertise and product vision. Work together as equals to make decisions that prevent implementation conflicts.

## Conventions

- Bare paths (e.g. `steps/step-01-init.md`) resolve from the skill root.
- `{skill-root}` resolves to this skill's installed directory (where `customize.toml` lives).
- `{project-root}`-prefixed paths resolve from the project working directory.
- `{skill-name}` resolves to the skill directory's basename.

## WORKFLOW ARCHITECTURE

This uses **micro-file architecture** for disciplined execution:

- Each step is a self-contained file with embedded rules
- Sequential progression with user control at each step
- Document state tracked in frontmatter
- Append-only document building through conversation
- You NEVER proceed to a step file if the current step file indicates the user must approve and indicate continuation.

## On Activation

### Step 1: Resolve the Workflow Block

Resolve the `workflow` block by reading these three files in base → team → user order and applying the structural merge rules below:

1. `{skill-root}/customize.toml` — defaults
2. `{project-root}/.stellar-build/custom/{skill-name}.toml` — team overrides
3. `{project-root}/.stellar-build/custom/{skill-name}.user.toml` — personal overrides

Any missing file is skipped — in a fresh project only the first exists. Scalars override, tables deep-merge, arrays of tables keyed by `code` or `id` replace matching entries and append new entries, and all other arrays append.

### Step 2: Execute Prepend Steps

Execute each entry in `{workflow.activation_steps_prepend}` in order before proceeding.

### Step 3: Load Persistent Facts

Treat every entry in `{workflow.persistent_facts}` as foundational context you carry for the rest of the workflow run. Entries prefixed `file:` are paths or globs under `{project-root}` — load the referenced contents as facts. All other entries are facts verbatim.

### Step 4: Load Config

Resolve config with a layered lookup — for each key, the first source that defines it wins:

1. `{project-root}/.stellar-build/bmm/config.yaml` (+ `config.user.yaml` beside it) — optional project config
2. `~/.stellar-build/config.yaml` — global config written by the installer (in sandboxed installs it lives under the install prefix instead)
3. Built-in defaults — `{user_name}` from `git config user.name`, `{communication_language}` and `{document_output_language}` English, `{planning_artifacts}` `{project-root}/docs`, `{project_knowledge}` `{project-root}/docs`, `{project_name}` the project directory name

- Use `{user_name}` for greeting
- Use `{communication_language}` for all communications
- Use `{document_output_language}` for output documents
- Use `{planning_artifacts}` for output location and artifact scanning
- Use `{project_knowledge}` for additional context scanning

Never block on missing config files. Treat configured paths as relative to `{project-root}` and ask before reading or writing outside the project root. If no project config exists, note it once in passing (one short line, not a warning). When the user asks to "set up project config", create `{project-root}/.stellar-build/bmm/config.yaml` from the `templates/project-config.yaml` in the same `.stellar-build` directory as the global config (or write the keys above manually) and confirm the values with them.

### Step 5: Greet the User

Greet `{user_name}`, speaking in `{communication_language}`.

### Step 6: Execute Append Steps

Execute each entry in `{workflow.activation_steps_append}` in order.

Activation is complete. Begin the workflow below.

## Execution

Read fully and follow: `./steps/step-01-init.md` to begin the workflow.

**Note:** Input document discovery and all initialization protocols are handled in step-01-init.md.
