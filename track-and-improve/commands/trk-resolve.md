---
argument-hint: <timestamp> <resolution>
description: Mark a report as resolved with what was done
---

Mark a report as resolved. Follow these steps:

1. Extract timestamp and resolution description from command

2. Find the report file: `~/.claude/trk-db/active/[timestamp].md`

3. If not found, list available reports:
   ```
   Report not found: [timestamp]

   Available reports:
   - [id1]: [description]
   - [id2]: [description]

   Usage: /trk-resolve <timestamp> <resolution>
   ```

4. Read the report and update:
   - Change `status: active` to `status: resolved`
   - Add `resolved: ISO8601 timestamp`
   - Fill in the Resolution section with user's description

5. Move file from `active/` to `resolved/`:
   ```bash
   mv ~/.claude/trk-db/active/[timestamp].md ~/.claude/trk-db/resolved/
   ```

6. Git commit:
   ```bash
   cd ~/.claude/trk-db && git add . && git commit -m "Resolve: [original description] - [resolution summary]"
   ```

7. Confirm to user:
   ```
   Report resolved: [timestamp]

   Original issue: [description]
   Resolution: [user's resolution]

   File moved to: ~/.claude/trk-db/resolved/[timestamp].md

   Remaining active reports: X
   ```

8. If this was the last active report:
   ```
   All reports resolved!

   Consider running /trk-review periodically to catch new patterns.
   ```
