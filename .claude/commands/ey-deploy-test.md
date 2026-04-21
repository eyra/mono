---
description: Deploy to a Fly.io test server and post deploy notes on milestone
allowed-tools: Bash(git:*, gh:*), mcp__flux__dev__get_milestone, mcp__flux__dev__add_comment, Agent
---

# Deploy Test Command

Deploy the current branch to a Fly.io test server, monitor the deploy, and post a deploy comment on the milestone.

ARGUMENTS: $ARGUMENTS (format: `<server> <milestone_id>`, e.g. `test1 9759088283`)

## Process

### Step 1: Parse arguments

Parse the server name and milestone ID from the arguments.
If not provided, ask the user for:
- Server: test1, test2, or staging
- Milestone ID (numeric Basecamp ID)

### Step 2: Check for uncommitted changes

Run `git status` to check for uncommitted changes.

If there are uncommitted changes, warn the user:
"Warning: You have uncommitted local changes. Run `/ey-commit` first to include them in the deploy."

Ask if they want to continue anyway or stop.

### Step 3: Check remote sync

Verify the local branch is pushed to remote:
```bash
git status -sb
```

If ahead of remote, push first.

### Step 4: Determine changes since last deploy

Find the last deploy comment on the milestone to determine the deploy number.
Then use `git log` to find changes since the last deploy. Use the commit messages to build a bullet list of changes.

To find the previous deploy's commit, check the GitHub Actions deploy workflow runs:
```bash
gh run list --workflow="Deploy to Fly.io" --repo eyra/mono --limit 5 --json conclusion,headSha,createdAt
```

Get the SHA of the last successful deploy and diff against current HEAD:
```bash
git log --oneline <last_deploy_sha>..HEAD
```

### Step 5: Trigger deploy

```bash
gh workflow run "Deploy to Fly.io" --repo eyra/mono --ref <current_branch> -f server=<server>
```

Get the run ID:
```bash
sleep 5 && gh run list --workflow="Deploy to Fly.io" --repo eyra/mono --limit 1
```

### Step 6: Monitor deploy

Watch the deploy in the background:
```bash
gh run watch <run_id> --repo eyra/mono
```

Wait for completion. If it fails, report the error and stop.

### Step 7: Post deploy comment on milestone

Determine the next deploy number by reading the milestone thread and finding the last "Deploy to Fly.io #N" comment.

Post a comment on the milestone with format:

```
Deploy to Fly.io #<N+1>

Server: https://eyra-next-<server>.fly.dev

Notes:
- <bullet list of changes based on commit messages>
```

Use `mcp__flux__dev__add_comment` to post the comment. Format with HTML.

### Step 8: Report result

Show the user:
- The deploy number
- The server URL
- Confirmation that the deploy comment was posted
