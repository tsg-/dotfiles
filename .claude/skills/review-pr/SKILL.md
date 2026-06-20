---
name: review-pr
description: Request a GitHub Copilot review on a pull request. Use when asked to trigger a review, get Copilot to look at a PR, or request automated review on PR #N.
---

# review-pr — trigger Copilot review on a PR

## Invocation

```
/review-pr <pr-number-or-url>
```

## Workflow

### 1. Parse the PR

Extract owner, repo, and PR number from the argument.
If only a number is given, detect repo from git remote.

### 2. Request the review

```bash
gh api repos/{owner}/{repo}/pulls/{number}/requested_reviewers \
  -f "reviewers[]=Copilot" \
  --method POST
```

If that fails (Copilot may not be a valid reviewer on all repos),
try the team-based approach:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/requested_reviewers \
  -f "team_reviewers[]=copilot" \
  --method POST
```

If both fail, check if Copilot reviews are enabled:
```bash
gh api repos/{owner}/{repo} --jq '.security_and_analysis'
```

Report the result to the user.

### 3. Monitor (optional)

If the user asks to wait for the review:

```bash
# Poll for Copilot comments (check every 30s, up to 5 min)
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --jq '[.[] | select(.user.login == "Copilot")] | length'
```

Once comments appear, offer to run `/fix-pr` on the results.

## Notes

- Copilot reviews are only available on repos with GitHub Copilot
  enabled (requires GitHub Copilot Enterprise or the free tier for
  public repos).
- The review is asynchronous. It typically takes 30-120 seconds
  for Copilot to post its comments after being requested.
- If the PR has already been reviewed by Copilot, requesting again
  will trigger a re-review against the latest commits.
