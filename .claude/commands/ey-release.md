---
description: Trigger a GitHub release workflow
allowed-tools: Bash(git:*, gh:*, mix:*)
---

# Release Command

Trigger a GitHub release workflow for the current branch.

## Process

### Step 1: Check for uncommitted changes

Run `git status` to check for uncommitted changes.

If there are uncommitted changes, warn the user:
"Warning: You have uncommitted local changes. Run `/commit` first to include them in the release."

Ask if they want to continue anyway or stop.

### Step 2: Check remote sync

Verify the local branch is pushed to remote:
```bash
git status -sb
```

If behind or ahead of remote, inform the user and ask if they want to push first.

### Step 3: Trigger release

Run `mix github_release` to trigger the GitHub Actions release workflow.

### Step 4: Report result

Show the user:
- The build tag (e.g., `next_2026-01-23_762`)
- The GitHub Actions URL to monitor the release
- Remind them to run `/announce-release <build_tag>` after the workflow completes
