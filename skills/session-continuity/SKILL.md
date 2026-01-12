---
name: session-continuity
description: "Persistent task workflow with state machine. Every message MUST announce state. Uses .claude/ files for multi-session continuity. Never use TodoWrite. Never auto-advance tasks."
version: 2.0.0
---

# Session Continuity

Persistent task workflow that survives session restarts.

## CRITICAL: STATE MACHINE GOVERNANCE

**EVERY SINGLE MESSAGE MUST START WITH YOUR CURRENT STATE**

Format:
```
CHECK_STATUS
WORKING
VERIFY
COMPLETE
AWAITING_COMMIT
MARK_COMPLETE
BLOCKED
```

**NOT JUST THE FIRST MESSAGE. EVERY. SINGLE. MESSAGE.**

When you read a file → prefix with state
When you run tests → prefix with state
When you explain results → prefix with state
When you ask a question → prefix with state

Example:
```
CHECK_STATUS
Reading session.md...

CHECK_STATUS
Status shows "in progress". Routing to WORKING.

TRANSITION: CHECK_STATUS → WORKING

WORKING
Reading requirements.md for task specs...

WORKING
Implementing getUser function with deps...
```

## State Machine

```
                     user: "continue"
                            ↓
                   ┌────────────────┐
               ┌───│ CHECK_STATUS   │←──────────┬──────────┐
               │   │ Read session.md│           │          │
               │   └────────┬───────┘           │          │
               │            │                   │          │
    Status=    │            │ Status=           │          │
    "Complete" │            │ "in progress"     │          │
               │            │                   │          │
               ↓            ↓                   │          │
       ┌───────────┐  ┌──────────────┐         │          │
       │ AWAITING_ │  │ WORKING      │←────┐   │          │
       │ COMMIT    │  │              │     │   │          │
       │           │  │ Read:        │     │   │          │
       │ Ask       │  │ requirements │     │   │          │
       │ permission│  │ tasks.md     │     │   │          │
       │ STOP      │  └──────┬───────┘     │   │          │
       └─────┬─────┘         │             │   │          │
             │               │ task done   │   │          │
   user: yes │               │             │   │          │
             │               ↓             │   │          │
             │        ┌──────────────┐     │   │          │
             │        │ VERIFY       │     │   │          │
             │        │              │     │   │          │
             │        │ Run steps    │─────┘   │          │
             │        │ from         │ fail    │          │
             │        │ requirements │         │          │
             │        └──────┬───────┘         │          │
             │               │                 │          │
             │               │ pass            │          │
             │               │                 │          │
             │               ↓                 │          │
             │        ┌──────────────┐         │          │
             │        │ COMPLETE     │         │          │
             │        │              │         │          │
             │        │ Update:      │         │          │
             │        │ session.md   │─────────┘          │
             │        │ Status=      │                    │
             │        │ "Complete"   │                    │
             │        └──────────────┘                    │
             │                                            │
             ↓                                            │
       ┌──────────────────┐                              │
       │ MARK_COMPLETE    │                              │
       │                  │                              │
       │ Update: tasks [x]│                              │
       │ Update: session  │──────────────────────────────┘
       │ (next task)      │
       └──────────────────┘
```

## Files

All files live in the **project's** `.claude/` directory:

| File | Purpose |
|------|---------|
| `.claude/tasks.md` | Checklist of tasks |
| `.claude/requirements.md` | Implementation specs, verification steps |
| `.claude/session.md` | Current state for resume |

## State: CHECK_STATUS

**Prefix:** `CHECK_STATUS`

**Purpose:** Read session.md and route based on Status field.

### Actions

1. Run `pwd` to verify project directory
2. Read `.claude/session.md`
3. Look at Status field
4. Route:
   - Status="Complete" or "ready to commit" → AWAITING_COMMIT
   - Status="in progress" or missing → WORKING
   - Status="blocked" → BLOCKED

### Critical Rules

- ONLY read session.md and route
- DO NOT read other files, launch agents, or do anything else
- IF ERROR: STOP and tell user what failed

### Transitions

- CHECK_STATUS → AWAITING_COMMIT (Status="complete")
- CHECK_STATUS → WORKING (Status="in progress")
- CHECK_STATUS → BLOCKED (Status="blocked")

## State: AWAITING_COMMIT

**Prefix:** `AWAITING_COMMIT`

**Purpose:** Task is complete. Ask permission to mark done.

### Actions

1. Say: "Task X is complete. May I mark it as complete in tasks.md?"
2. **STOP - wait for user response**
3. If user says yes → MARK_COMPLETE
4. If user says no → STOP, await instruction

### Critical Rules

- ONLY ask permission and STOP
- DO NOT read files, launch agents, work on next task
- DO NOT do anything except ask and wait

### Transitions

- AWAITING_COMMIT → MARK_COMPLETE (user says yes)
- AWAITING_COMMIT → STOP (user says no)

## State: MARK_COMPLETE

**Prefix:** `MARK_COMPLETE`

**Purpose:** Update task files after user approval.

### Actions

1. Update tasks.md: Change `[ ]` to `[x]` for current task
2. Update session.md: Set to next task with Status="in progress"
3. Go to CHECK_STATUS

### Critical Rules

- ONLY update files and route
- DO NOT read other files or research next task
- IF CANNOT EDIT: Say "Cannot edit files: [reason]" and STOP

### Transitions

- MARK_COMPLETE → CHECK_STATUS

## State: WORKING

**Prefix:** `WORKING`

**Purpose:** Implement the current task.

### Actions

1. Read requirements.md for task specs
2. Read tasks.md for task list
3. Work on current task using patterns:
   - fn(args, deps)
   - Result types
   - Zod at boundaries
4. Update session.md after TDD cycles
5. When task done → VERIFY

### Session.md Updates

Update at these triggers:

| Trigger | Update |
|---------|--------|
| Start task | Status="in progress" |
| TDD cycle | Brief note in Notes |
| Hit blocker | Status="blocked", describe |
| Task done | → transition to VERIFY |

### Critical Rules

- EVERY message must have state prefix
- DO NOT skip to next task
- DO NOT work on multiple tasks
- IF BLOCKED: Document in session.md, STOP

### Transitions

- WORKING → VERIFY (task implementation done)
- WORKING → BLOCKED (hit blocker)

## State: VERIFY

**Prefix:** `VERIFY`

**Purpose:** Run verification before claiming complete.

### Actions

1. Read Verification section from requirements.md
2. Run ALL verification commands:
   ```bash
   npm test
   npm run lint
   npm run build
   ```
3. Show ALL output verbatim
4. If all pass → COMPLETE
5. If any fail → WORKING (treat as blocker)

### Critical Rules

- EVERY message must have state prefix
- NEVER skip verification
- NEVER claim complete without running checks
- IF ERROR: STOP and tell user

### Transitions

- VERIFY → COMPLETE (all pass)
- VERIFY → WORKING (any fail)

## State: COMPLETE

**Prefix:** `COMPLETE`

**Purpose:** Update session.md to reflect completion.

### Actions

1. Update session.md: Set Status="Complete"
2. Go to CHECK_STATUS

### Critical Rules

- ONLY update session.md and route
- DO NOT ask permission (that's AWAITING_COMMIT)
- IF ERROR: STOP and tell user

### Transitions

- COMPLETE → CHECK_STATUS

## State: BLOCKED

**Prefix:** `BLOCKED`

**Purpose:** Cannot proceed, need user guidance.

### Actions

1. Explain blocking issue clearly
2. Show what you tried
3. **STOP and wait for user guidance**

### Critical Rules

- NEVER improvise workarounds
- ALWAYS stop and wait for user

### Transitions

- BLOCKED → [any state] (based on user guidance)

## Setup: "Plan" or "Setup Tasks"

When user says "create a plan" or "setup tasks":

1. Ask for task list
2. Ask for verification commands
3. Ask for constraints/patterns
4. Create files:

**.claude/tasks.md**
```markdown
- [ ] Task 1: [exact user wording]
- [ ] Task 2: [exact user wording]
```

**.claude/requirements.md**
```markdown
## Verification
Before marking complete:
- `npm test` - all pass
- `npm run lint` - no errors
- `npm run build` - succeeds

## Task 1: [name]
- [specs from conversation]
- [constraints]
```

**.claude/session.md**
```markdown
**Current:** Task 1
**Status:** in progress

## Done
(none yet)

## Notes
- [context for resume]
```

## Anti-Patterns

### WRONG: Investigating Codebase to Figure Out Progress

```
User: "continue"
Claude: *Reads tasks.md*
Claude: "Let me investigate the codebase to understand what's done"
Claude: *Searches 10+ files, runs git log*
Claude: *Wastes tokens figuring out state*
```

**Problem:** All that info is in session.md already.

### RIGHT: Reading session.md First

```
User: "continue"
Claude: "CHECK_STATUS"
Claude: *Reads session.md*
Claude: "Status shows 'in progress'. Routing to WORKING."
Claude: "WORKING"
Claude: "Continuing Task 2..."
```

### WRONG: Skipping Verification

```
Claude: *Completes implementation*
Claude: "Task 1 is complete!"
*User commits and pushes*
*CI fails - tests broken*
```

**Problem:** Skipped verification, introduced bugs.

### RIGHT: Running Verification

```
Claude: "VERIFY"
Claude: *Runs npm test* → All pass
Claude: *Runs npm lint* → All pass
Claude: *Runs npm build* → Success
Claude: "COMPLETE"
Claude: "Task 1 complete, all verification passed."
```

### WRONG: Creating Git Commits

```
Claude: *Completes task*
Claude: *Runs git add . && git commit*
```

**Problem:** User loses control over commits.

### RIGHT: Handing Off to User

```
Claude: "Task complete, ready for you to commit."
Claude: "May I mark this task as complete?"
```

### WRONG: Auto-Advancing Tasks

```
Claude: "Task 1 done. Starting Task 2..."
Claude: *Explores codebase for Task 2*
```

**Problem:** User didn't approve advancing.

### RIGHT: Stopping After Complete

```
Claude: "Task 1 complete. May I mark it done?"
*Waits for user*
```

## Never Use TodoWrite

This skill REPLACES Claude Code's built-in todos:

```
WRONG: TodoWrite tool
RIGHT: .claude/tasks.md file

WRONG: Internal todo state
RIGHT: Visible, editable files
```

**Why:** TodoWrite state is lost between sessions. Files persist.

## Path Troubleshooting

**Symptom:** "File not found" on continue

**Fix:**
1. Run `pwd`
2. Read from `./.claude/session.md` (project root)
3. NOT from skill directory

## Quick Reference

| State | Prefix | Action | Exit |
|-------|--------|--------|------|
| CHECK_STATUS | CHECK_STATUS | Read session.md, route | Status-based |
| AWAITING_COMMIT | AWAITING_COMMIT | Ask permission, STOP | User response |
| MARK_COMPLETE | MARK_COMPLETE | Update files | → CHECK_STATUS |
| WORKING | WORKING | Implement task | → VERIFY |
| VERIFY | VERIFY | Run verification | Pass/Fail |
| COMPLETE | COMPLETE | Update session.md | → CHECK_STATUS |
| BLOCKED | BLOCKED | Explain, STOP | User guidance |
