---
name: session-continuity
description: "Persist task state across sessions using .claude/ files. Resume work with 'continue'. Never use TodoWrite - use tasks.md, requirements.md, session.md instead."
version: 1.0.0
---

# Session Continuity

Persistent task management that survives session restarts.

## Files

All files live in the **project's** `.claude/` directory (not the skill directory):

| File | Purpose |
|------|---------|
| `.claude/tasks.md` | Checklist of tasks |
| `.claude/requirements.md` | Implementation specs, verification steps |
| `.claude/session.md` | Current state for resume |

## When User Says "Plan" or "Setup Tasks"

1. Ask for task list
2. Ask for verification commands (npm test, lint, build)
3. Ask for any constraints or patterns
4. Create the three files:

**.claude/tasks.md**
```markdown
- [ ] Task 1: [exact user wording]
- [ ] Task 2: [exact user wording]
- [ ] Task 3: [exact user wording]
```

**.claude/requirements.md**
```markdown
## Verification
Before marking complete:
- `npm test` - all pass
- `npm run lint` - no errors
- `npm run build` - succeeds

## Task 1: [name]
- [implementation details]
- [constraints]

## Task 2: [name]
- [implementation details]
```

**.claude/session.md**
```markdown
**Current:** Task 1
**Status:** in progress

## Done
(none yet)

## Notes
- [any context needed for resume]
```

## When User Says "Continue"

1. Read `.claude/session.md`
2. Route based on Status:

| Status | Action |
|--------|--------|
| `in progress` | Continue working on current task |
| `complete` | Ask permission to mark [x], then advance |
| `blocked` | Show blocker, wait for guidance |

## Workflow

```
continue
    │
    ▼
┌───────────────┐
│ Read session  │
└───────┬───────┘
        │
   ┌────┴────┐
   │         │
   ▼         ▼
in progress  complete
   │         │
   ▼         ▼
 WORK     ASK TO MARK [x]
   │         │
   ▼         ▼
verify    update files
   │         │
   ▼         ▼
complete  next task
```

## Working on a Task

1. Read requirements.md for task specs
2. Implement following patterns (fn(args, deps), Result types)
3. Update session.md after progress
4. When done: run verification from requirements.md
5. If all pass: update session.md Status to "complete"

## Verification Before Complete

**ALWAYS run verification before claiming complete:**

```bash
# From requirements.md Verification section
npm test
npm run lint
npm run build
```

Only set Status="complete" after ALL pass.

## Marking Complete

When Status="complete" and user says "continue":

1. Ask: "Task X complete. Mark it done?"
2. If yes:
   - Update tasks.md: `- [ ]` → `- [x]`
   - Update session.md: advance to next task
3. If no: wait for instruction

## Session.md Updates

Update at these triggers:

| Trigger | Update |
|---------|--------|
| Start task | Current, Status="in progress" |
| TDD cycle complete | Brief note in Notes |
| Hit blocker | Status="blocked", describe in Notes |
| Task verified | Status="complete" |

Keep it brief - this is for resume context, not logs.

## Never Use TodoWrite

This skill replaces Claude Code's built-in todos:

```
WRONG: TodoWrite tool
RIGHT: .claude/tasks.md file

WRONG: Internal todo state
RIGHT: Visible, editable files
```

Why: TodoWrite state is lost between sessions. Files persist.

## Never Create Git Commits

Hand off to user for commits:

```
WRONG: git add . && git commit -m "..."
RIGHT: "Task complete, ready for you to commit"
```

User controls commit message, staging, and timing.

## Never Auto-Advance

Stop after completing a task:

```
WRONG: "Task 1 done. Starting Task 2..."
RIGHT: "Task 1 complete. May I mark it done?"
       [wait for user]
```

User controls pace.

## Path Troubleshooting

**Symptom:** "File not found" on continue

**Cause:** Looking in skill directory instead of project

**Fix:**
1. Run `pwd` to check location
2. Read from `./.claude/session.md` (project root)
3. NOT from `~/.claude/skills/session-continuity/`

## Example Session

```
User: "setup tasks"
Claude: "What tasks? What verification commands?"

User: "Add logging, add tests. npm test to verify"
Claude: Creates .claude/tasks.md, requirements.md, session.md
        "Ready. Say 'continue' to start Task 1"

User: "continue"
Claude: Reads session.md → Task 1, in progress
        Works on Task 1 (add logging)
        Runs npm test → passes
        Updates session.md Status="complete"
        "Task 1 complete, verification passed. Ready to commit."

User: "continue"
Claude: Reads session.md → Status="complete"
        "Task 1 is complete. Mark it done?"

User: "yes"
Claude: Updates tasks.md [x], session.md → Task 2
        "Moving to Task 2. Continue?"

User: "continue"
Claude: Works on Task 2...
```

## Quick Reference

| User Says | Action |
|-----------|--------|
| "plan", "setup tasks" | Create 3 files, ask for specs |
| "continue" | Read session.md, route by Status |
| "yes" (after complete) | Mark [x], advance |
| "skip" | Mark [x] without verification |
| "blocked" | Update session.md, wait |
