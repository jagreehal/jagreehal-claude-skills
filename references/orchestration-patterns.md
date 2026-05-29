# Orchestration Patterns

Shared rules for coordinating multi-step and multi-agent work safely. Use alongside `parallel-agent-dispatch`, `session-continuity`, `investigation-modes`, and `verification-before-completion`.

## When to Parallelize

Dispatch concurrent agents only when the work is independent: no shared mutable state, no ordering dependency, no agent needing another's output.

```text
Do the tasks share state or depend on each other's output?
  ├─ Yes → keep sequential (or split until the pieces are independent)
  └─ No  → one agent per problem domain, dispatched together
```

| Safe to parallelize | Keep sequential |
|---|---|
| Independent bug investigations in separate modules | Steps where one's output feeds the next |
| Researching several unrelated questions | Edits to the same file or shared state |
| Per-package work in a monorepo | A migration whose later steps assume earlier ones landed |

When work mutates files in parallel, give each agent an isolated workspace (see `git-worktrees`) so edits can't collide.

## Writing an Agent Brief

A dispatched agent has none of your context. Each brief must be self-contained:

- **Goal:** the single outcome, stated as a result not a vibe.
- **Scope:** exact files, directories, or domain the agent owns; what it must NOT touch.
- **Inputs:** paths, commands, fixtures, and any conventions it must follow.
- **Return contract:** what to report back (findings, a diff, a structured object), and that its final message IS the deliverable, not a human-facing note.

A vague brief produces a vague result. Specify the return shape before dispatching.

## Trust but Verify

A sub-agent reporting "done" is a claim, not evidence. Before relaying or building on it, confirm against the rule in `verification-before-completion`: run the relevant command and read the fresh output yourself. Sub-agent success reports are the case that rule exists for.

## State Across Steps and Sessions

Long or multi-session work needs durable state, not memory:

- Announce the current state/mode on every message so skips and drift are visible (`session-continuity`, `investigation-modes`).
- Persist task state to files (`.claude/`) so work survives a restart, compaction, or handoff. Never rely on conversation memory alone.
- Never auto-advance tasks: finishing one step does not authorize starting the next without confirmation.
- Keep modes separate: LEARNING, INVESTIGATION, and SOLVING don't bleed into each other; transition only with the user's consent.

## Anti-Patterns

| Anti-pattern | Why it bites | Instead |
|---|---|---|
| Parallelizing dependent work | Races, lost edits, agents acting on stale assumptions | Split until independent, or stay sequential |
| Thin agent briefs | Agent guesses scope, does the wrong thing confidently | Self-contained brief with an explicit return contract |
| Relaying a sub-agent's "done" unchecked | Propagates a false success claim | Verify the output yourself first |
| Holding task state in conversation only | Lost on compaction or restart | Persist to `.claude/` files |
| Auto-advancing through a plan | Skips review gates, compounds mistakes | One step at a time, confirm before advancing |
