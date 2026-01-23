---
description: Watch a release and announce it on the milestone when complete
argument-hint: <BUILD_TAG> [milestone_id]
allowed-tools: Bash(gh:*, git:*), mcp__flux__dev_add_comment, mcp__flux__dev_list_milestones, mcp__flux__dev_get_issue
---

# Announce Release Command

Watch a GitHub release workflow and announce it on the milestone when complete.

## Arguments

- `$ARGUMENTS` may contain:
  - Build tag (e.g., `next_2026-01-23_762`)
  - Milestone ID (optional, will prompt if not provided)

## Process

### Step 1: Parse arguments or get latest release

If no build tag provided, get the latest release:
```bash
gh run list --repo eyra/mono --workflow Release --limit 1 --json databaseId,displayTitle,status,conclusion
```

### Step 2: Watch the release workflow (if still running)

Check if the workflow is still running:
```bash
gh run list --repo eyra/mono --workflow Release --limit 5 --json databaseId,displayTitle,status,conclusion
```

If running, watch it:
```bash
gh run watch <RUN_ID> --repo eyra/mono
```

If the workflow fails, inform the user and stop.

### Step 3: Find the previous release tag

Get the two most recent release tags to find commits between them:
```bash
git fetch --tags
git tag --list 'next_*' --sort=-version:refname | head -2
```

### Step 4: Extract fixed issues from commits

Get commits between the previous and current release:
```bash
git log <previous_tag>..<current_tag> --oneline
```

Parse `FX#<issue_id>` patterns from commit messages:
```bash
git log <previous_tag>..<current_tag> --format=%B | grep -oE 'FX#[0-9]+' | sort -u
```

For each issue ID found, fetch the issue details using `mcp__flux__dev_get_issue`.

### Step 5: Find the target milestone

If milestone ID was provided in arguments, use that.

Otherwise, try to auto-detect from branch name:
```bash
git branch --show-current
```

If branch matches `milestone/<version>` pattern (e.g., `milestone/20.1`):
- Extract the version number (e.g., `20.1`)
- Use `mcp__flux__dev_list_milestones` to list active milestones
- Match by version number only, ignoring labels like "Release", "Hotfix", "Milestone"
- Examples: branch `milestone/20.1` matches "Hotfix 20.1 - Data Donation" or "Release 20.1"
- If found, use that milestone

If branch is `develop` or no matching milestone found:
- List milestones using `mcp__flux__dev_list_milestones`
- Ask the user which milestone to post to

### Step 6: Compose the announcement

Create a comment in HTML format:

```html
<strong>Release <a href="https://github.com/eyra/mono/releases/tag/{BUILD_TAG}">{BUILD_TAG}</a> is ready for testing</strong>

<strong>Fixed:</strong>
<ul>
<li><a href="https://3.basecamp.com/5734045/buckets/35926565/todos/{ISSUE_ID}">[Program] Issue title</a></li>
</ul>
```

If no FX# issues were found in commits, ask the user what was fixed.

### Step 7: Confirm and post

Show the composed announcement to the user and ask for confirmation.

After confirmation, use `mcp__flux__dev_add_comment` to post to the milestone.

### Step 8: Report completion

Confirm the announcement was posted successfully.
