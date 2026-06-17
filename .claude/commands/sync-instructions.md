# Sync AI Instructions

Synchronize AI instruction files (CLAUDE.md, GEMINI.md, copilot-instructions.md) across local paths and remote hosts.

## Source of truth

The canonical copies live at:
- `~/.claude/CLAUDE.md` — Claude Code global instructions
- `~/.gemini/GEMINI.md` — Gemini CLI global instructions
- `~/.github/copilot-instructions.md` — Copilot global instructions
- `~/.claude/commands/architect.md` — Architect role command
- `~/.claude/commands/reviewer.md` — Reviewer role command
- `~/.claude/commands/writer.md` — Technical writer role command
- `~/.claude/commands/red-team.md` — Red-team/skeptic role command

## Local backup

Always sync to `~/dotfiles/` as a local backup (same relative paths).

## Behavior

When invoked with no arguments: sync all files to `~/dotfiles/` only.

When invoked with a target:
- **Hostname only** (e.g. `bmg0`): ssh to host, create directories if needed, scp all files to the same `~/` relative paths. Also sync to `~/dotfiles/`.
- **Host:path** (e.g. `bmg0:~/tsg`): ssh to host, create directories under the given path, scp all files relative to that path instead of `~`. Also sync to `~/dotfiles/`.

## Steps

1. Read the three source files from the local canonical paths.
2. Determine the target:
   - If `$ARGUMENTS` is empty → local sync only (verify files are in place).
   - If `$ARGUMENTS` contains `:` → parse as `host:path`. Remote base = path.
   - If `$ARGUMENTS` has no `:` → parse as `host`. Remote base = `~`.
3. Sync to `~/dotfiles/`:
   ```bash
   cp ~/.claude/CLAUDE.md ~/dotfiles/.claude/CLAUDE.md
   cp ~/.gemini/GEMINI.md ~/dotfiles/.gemini/GEMINI.md
   cp ~/.github/copilot-instructions.md ~/dotfiles/.github/copilot-instructions.md
   cp ~/.claude/commands/*.md ~/dotfiles/.claude/commands/
   ```
4. For remote targets, run:
   ```bash
   ssh <host> "mkdir -p <base>/.claude/commands <base>/.gemini <base>/.github"
   scp ~/.claude/CLAUDE.md <host>:<base>/.claude/CLAUDE.md
   scp ~/.gemini/GEMINI.md <host>:<base>/.gemini/GEMINI.md
   scp ~/.github/copilot-instructions.md <host>:<base>/.github/copilot-instructions.md
   scp ~/.claude/commands/architect.md <host>:<base>/.claude/commands/architect.md
   scp ~/.claude/commands/reviewer.md <host>:<base>/.claude/commands/reviewer.md
   scp ~/.claude/commands/writer.md <host>:<base>/.claude/commands/writer.md
   scp ~/.claude/commands/red-team.md <host>:<base>/.claude/commands/red-team.md
   ```
5. Report what was synced and to where.

## Notes

- Do NOT modify the source files — this is a one-way push.
- If ssh/scp fails, report the error and suggest the user check connectivity (`ssh <host> hostname`).
- If the user says "dry run", show what would be copied without executing.
