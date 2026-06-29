---
name: checkpoint
description: Save session context to memory, capture pending tasks to beads, and give the user a continuation prompt to paste after /clear. Use before clearing context or ending a long session.
---

# checkpoint — save context and prepare for /clear

## Purpose

Before the user issues `/clear`, this skill:
1. Saves key session context (what was accomplished, what's in progress,
   current branch/state, open decisions) to a memory file.
2. Captures any remaining tasks to the task list ("beads") so they
   survive the context reset.
3. Prints a ready-to-paste continuation prompt the user can send in
   the fresh session to pick up where they left off.

## Invocation

```
/checkpoint
```

No arguments needed.

## Workflow

### 1. Gather context

Collect the following from the current session:

- **Branch & repo state**: current branch, uncommitted changes, commits
  ahead/behind remote
- **What was accomplished**: summarize completed work this session
- **What's in progress / remaining**: unfinished tasks, next steps
- **Key decisions made**: any non-obvious choices or constraints discovered
- **Blockers or open questions**: anything unresolved

### 2. Save to memory

Write a **project** memory file:
`/home/dev/tsg/.claude/projects/-home-dev-tsg-gds-liburing-cufilewrapper/memory/project_session-checkpoint.md`

Use the standard memory frontmatter format. Overwrite the file each time
(only the latest checkpoint matters). Include an absolute date.

### 3. Capture pending tasks

Check if there are outstanding tasks (incomplete work, next steps the
user mentioned, follow-ups discovered during the session). For each one,
create a task via TaskCreate so it appears in the task list ("beads").

Skip this step if there's nothing pending.

### 4. Print continuation prompt

Output a fenced code block the user can paste after `/clear`. Format:

```
Continue from checkpoint. Key context:
- Branch: <branch>
- Last commit: <short-sha> <subject>
- Status: <clean/dirty + summary>
- Remaining work: <bulleted list of pending items>

Read memory file project_session-checkpoint.md for full details.
Check task list for pending items.
```

Keep it concise — just enough for the next session to orient itself
without reading the full memory file. The memory file has the details;
the prompt is the spark.

## Notes

- The memory file is intentionally overwritten each checkpoint (not
  accumulated) — it represents "where we are now", not a journal.
- If the user runs `/checkpoint` multiple times, each overwrites the
  previous. That's fine.
- The continuation prompt should be self-contained enough that pasting
  it cold into a fresh session gives Claude enough to load context and
  continue.
