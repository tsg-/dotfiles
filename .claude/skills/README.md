# Claude Code Skills

Custom skills for this project. Available as slash commands in any
Claude Code session within this repo.

## /review-pr — request automated review

Triggers a GitHub Copilot review on a pull request. Copilot posts
inline comments within 1-2 minutes.

```
/review-pr 97
```

That's it. Wait a minute, then use /fix-pr to address the feedback.

## /fix-pr — address PR review feedback

Fetches all review comments on a PR, triages them, applies fixes
after your confirmation, resolves the threads on GitHub, and pushes.

```
/fix-pr 97
```

Output looks like:

```
PR #97 — 10 review comments (Copilot: 10)

 #  File:Line                Issue                     Rec
 1  test_p2p_stress.cpp:32   Missing <chrono> header   fix
 2  test_p2p_stress.cpp:166  io_errors never used      fix
 3  README.md:103            Stale known-failures      fix
 4  test_p2p_boundary.cpp:64 Shared path order-dep     won't-fix
 5  repro_hole_zero.c:162    No read-error gate        fix
 ...

Proposed: fix [1,2,3,5], won't-fix [4], dismiss [6]
Apply? [y/n]
```

Say yes, it makes the changes, commits, resolves each thread on
GitHub with a reply, and pushes.

### Options

```
/fix-pr 97 --author=Copilot    # only Copilot's comments
/fix-pr 97 --author=reviewer   # only one person's comments
```

## /checkpoint — save context before /clear

Saves session state to memory, captures pending tasks, and prints a
continuation prompt to paste into the fresh session.

```
/checkpoint
```

Then issue `/clear`, paste the prompt, and keep going.

## Typical workflow

```
# 1. Push your branch, open a PR
git push -u tsg feat/my-feature

# 2. Get automated review
/review-pr 102

# 3. Wait ~1 min for comments to appear, then fix them
/fix-pr 102

# 4. Done — threads resolved, fixes pushed
```
