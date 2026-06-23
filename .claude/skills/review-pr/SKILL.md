---
name: review-pr
description: Request an automated code review on a pull request. Supports GitHub-hosted reviewers (Copilot, CodeRabbit) and local LLM-based review (Claude, Gemini, Codex) that posts findings to the PR. Use when asked to trigger a review or get feedback on a PR.
---

# review-pr -- trigger automated code review on a PR

## Invocation

```
/review-pr <pr-number-or-url> [--agent=<name>] [--model=<model>]
```

Default agent: `copilot`

## Agents

### GitHub-hosted (async, external service posts comments)

| Agent | Flag | Requires |
|-------|------|----------|
| Copilot | `--agent=copilot` | GitHub Copilot enabled on repo |
| CodeRabbit | `--agent=coderabbit` | CodeRabbit app installed |

### Local LLM-based (sync, runs here, posts under your identity)

| Agent | Flag | Model default | Alternatives |
|-------|------|---------------|--------------|
| Claude | `--agent=claude` | inherited from session | `--model=opus`, `--model=sonnet` |
| Copilot CLI | `--agent=copilot-cli` | copilot default | n/a |
| Gemini/Agy | `--agent=gemini` or `--agent=agy` | gemini-2.5-pro | `--model=gemini-2.5-flash` |
| Codex | `--agent=codex` | codex | n/a |

## GitHub-hosted agents

### copilot (default)

Copilot reviews are triggered by GitHub's internal automation, not
by requesting a reviewer. The bot login is
`copilot-pull-request-reviewer[bot]`.

To trigger a re-review:
1. Push a new commit to the PR branch (may auto-trigger depending
   on repo settings), or
2. Use the GitHub UI: click "Re-request review" next to Copilot
   on the PR page.

There is no public API to programmatically re-trigger Copilot.
The skill will push an empty commit to force a re-review:

```bash
git commit --allow-empty -m "chore: trigger Copilot re-review"
git push
```

Then poll for new comments from `copilot-pull-request-reviewer[bot]`.

### coderabbit

```bash
gh api repos/{owner}/{repo}/issues/{number}/comments \
  -f body="@coderabbitai review" \
  --method POST
```

## Local LLM-based agents

All local agents follow a fix-in-place workflow (no round-trip
through PR comments):

1. Fetch the PR diff:
   ```bash
   gh pr diff {number}
   ```

2. Send the diff to the LLM with a review prompt asking for
   correctness bugs, simplification, and style issues. Each
   finding must include file path, line number, and explanation.

3. Triage findings (same format as /fix-pr):
   - Present a summary table to the user with fix/dismiss/won't-fix
   - Wait for confirmation

4. Apply fixes locally:
   - Checkout the PR branch
   - Make minimal changes for each "fix" item
   - For "won't-fix" items, prepare a brief reply

5. Commit and push:
   ```bash
   git add <changed-files>
   git commit -s -m "fix: address <agent> review feedback

   <one-line summary per fix>

   Signed-off-by: ..."
   git push
   ```

6. Resolve threads on GitHub:
   - Reply to fix items with "Fixed in <sha>."
   - Reply to won't-fix items with rationale
   - Resolve all threads via GraphQL

Do NOT post findings as PR comments first — fix them directly.
Only post comments for won't-fix items that need an explanation.

### claude

Uses Claude (this session) to review the diff. No external API
call needed -- the review happens inline.

Review prompt focus:
- Correctness bugs (data races, use-after-free, off-by-one)
- Missing error handling at system boundaries
- Simplification opportunities (dead code, unnecessary abstractions)
- API misuse

### copilot-cli

Uses the GitHub Copilot CLI (`copilot` binary) in programmatic
mode. Requires `copilot` installed and authenticated.

```bash
DIFF=$(gh pr diff {number})
copilot -p "Review this diff for correctness bugs, security issues, \
  and style problems. Output ONLY a JSON array where each element \
  has keys: path, line, body. No markdown fences, no explanation.

$DIFF" -s
```

Flags:
- `-p`: non-interactive single-shot prompt
- `-s`: silent mode (raw output only, no UI chrome)

Parse the JSON response and post as inline PR comments.

Note: LLM output is not guaranteed to be valid JSON. The skill
should validate the parse and retry once if malformed.

### gemini / agy

Both `--agent=gemini` and `--agent=agy` invoke the same backend.
("agy" is the Antigravity CLI, the renamed Gemini CLI.)

Calls the Gemini API to review the diff.

```bash
# Requires GEMINI_API_KEY in environment
curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"<review-prompt-with-diff>"}]}]}'
```

Parse the response for findings with file/line/body structure,
then post to GitHub as above.

### codex

Calls the OpenAI API with the Codex model.

```bash
# Requires OPENAI_API_KEY in environment
curl -s "https://api.openai.com/v1/responses" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"codex","input":"<review-prompt-with-diff>"}'
```

Parse the response and post findings to GitHub.

## Workflow

### 1. Parse the PR

Extract owner, repo, and PR number from the argument.
If only a number is given, detect repo from git remote.

### 2. Dispatch

- GitHub-hosted agents: make the API call, report success.
- Local agents: fetch diff, call LLM, post comments.

### 3. Monitor (optional, GitHub-hosted only)

If the user asks to wait:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '[.[] | select(.user.login == "<agent_login>")] | length'
```

Agent login names:
- Copilot: `copilot-pull-request-reviewer[bot]`
- CodeRabbit: `coderabbitai`
- Local agents: your gh login (posted under your identity)

Once comments appear, offer to run `/fix-pr` on the results.

## Examples

```
/review-pr 97                          # Copilot GitHub-hosted (default)
/review-pr 97 --agent=copilot-cli      # Copilot CLI (local, programmatic)
/review-pr 97 --agent=coderabbit       # CodeRabbit
/review-pr 97 --agent=claude           # Claude (this session)
/review-pr 97 --agent=claude --model=sonnet  # Claude Sonnet
/review-pr 97 --agent=gemini           # Gemini 2.5 Pro
/review-pr 97 --agent=agy              # Same as gemini (Antigravity CLI)
/review-pr 97 --agent=gemini --model=gemini-2.5-flash
/review-pr 97 --agent=codex            # OpenAI Codex
```

## Notes

- GitHub-hosted agents are async (1-5 min). Local agents are sync.
- Local agents post under your GitHub identity, not a bot account.
- Gemini requires `GEMINI_API_KEY` env var.
- Codex requires `OPENAI_API_KEY` env var.
- After any review completes, use `/fix-pr` to address the feedback.
- Multiple agents can review the same PR (run the command multiple
  times with different --agent flags for diverse perspectives).
