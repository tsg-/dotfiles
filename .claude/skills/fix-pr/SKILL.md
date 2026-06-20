---
name: fix-pr
description: Fetch PR review comments, triage them (fix/dismiss/won't-fix), apply fixes after user confirmation, resolve threads, commit and push. Use when asked to address PR feedback, fix review comments, or handle PR #N.
---

# fix-pr — address PR review comments

## Invocation

```
/fix-pr <pr-number-or-url> [--author=<login>]
```

- `<pr-number-or-url>`: PR number (e.g. 97) or full GitHub URL
- `--author=<login>`: optional filter to only show comments from a
  specific author (e.g. `Copilot`, `username`). Default: all.

## Workflow

### 1. Fetch comments

```bash
# Get all review comments
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '.[] | {id, path, line: (.line // .original_line), author: .user.login, body}'
```

Parse the PR number from the argument. If it's a URL, extract
owner/repo/number from it. Detect the repo from git remote if
only a number is given.

### 2. Triage

For each comment, assess:
- **fix**: the comment identifies a real issue that should be changed
- **dismiss**: the comment is incorrect, irrelevant, or already handled
- **won't-fix**: the comment is valid but we intentionally chose this
  approach (document why)

Group comments by file and present a summary table to the user:

```
PR #97 — 10 review comments (Copilot: 10)

 #  File:Line              Issue                    Recommendation
 1  test_p2p_stress.cpp:32 Missing <chrono> header  fix
 2  test_p2p_stress.cpp:166 io_errors unused        fix
 3  README.md:103           Stale entry             fix
 ...

Proposed: fix [1,2,3,6,7,8], dismiss [9,10], won't-fix [4,5]
```

Wait for user confirmation or adjustment before proceeding.

### 3. Apply fixes

For each "fix" item:
- Read the file at the indicated line
- Make the minimal change that addresses the comment
- Do not refactor adjacent code

For each "won't-fix" item:
- Prepare a brief reply explaining the rationale

For "dismiss" items:
- No code change, no reply (just resolve)

### 4. Resolve threads

After all changes are applied:

```bash
# Reply to the comment (for fix and won't-fix)
# NOTE: use -F (not -f) for in_reply_to so it sends as integer
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  -F body="Fixed in <commit-sha>." \
  -F in_reply_to=<comment_database_id> \
  --method POST
```

Then resolve each thread via GraphQL:

```bash
# 1. Get thread node IDs for unresolved threads
gh api graphql -f query='
  {
    repository(owner: "{owner}", name: "{repo}") {
      pullRequest(number: {number}) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 1) { nodes { databaseId } }
          }
        }
      }
    }
  }
' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved == false) | .id'

# 2. Resolve each thread
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "<thread_node_id>"}) {
      thread { isResolved }
    }
  }
'
```

Match comment databaseId from the fetch step to identify which
thread corresponds to which comment.

### 5. Commit and push

```bash
git add <changed-files>
git commit -s -m "fix: address review feedback on PR #N

<one-line summary per fix>

Signed-off-by: ..."
git push
```

## Rules

- Never amend existing commits. Always create a new fixup commit.
- Match existing code style in each file.
- One commit for all fixes (not one per comment).
- If a fix would require significant refactoring, flag it to the user
  rather than making a large change silently.
- For "won't-fix" replies, be concise and professional. State the
  rationale in 1-2 sentences.
- If the push fails (e.g. branch protection), report the error.
