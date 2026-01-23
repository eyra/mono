---
description: Commit and push changes with FX# issue linking
allowed-tools: Bash(git:*), mcp__flux__dev_get_issue
---

# Commit Command

Commit all staged and unstaged changes and push to remote.

## Process

### Step 1: Check for changes

Run `git status` to see what files have changed.

If there are no changes to commit, inform the user and stop.

### Step 2: Review changes

Show a brief summary of what will be committed:
- Run `git diff --stat` to show changed files
- If there are untracked files, list them

### Step 3: Ask for Flux issue ID(s)

Ask the user: "What Flux issue ID(s) does this commit fix? (e.g., 9496247794, or multiple separated by commas, or 'none')"

If issue IDs are provided:
- Fetch each issue title using `mcp__flux__dev_get_issue`
- Include them in the commit message

### Step 4: Generate commit message

Based on the changes, generate a descriptive commit message following the project conventions:
- Start with a short summary line (imperative mood, e.g., "Fix bug" not "Fixed bug")
- Add blank line followed by bullet points explaining the changes
- If issue IDs were provided, add a line: `Fixes: FX#<issue_id>` (one per issue)
- End with `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>`

Example:
```
Fix consent decline crash and add Wallaby integration tests

- Fix FunctionClauseError in onboarding_identifier when declining consent
- Add Wallaby integration tests for consent decline flow

Fixes: FX#9496247794

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Ask the user to confirm or modify the commit message before proceeding.

### Step 5: Commit and push

1. Stage all changes: `git add -A`
2. Commit with the approved message
3. Push to remote: `git push`

If the pre-commit hook modifies files, stage and commit again.

### Step 6: Report result

Show the user:
- The commit hash
- A brief confirmation that changes were pushed
