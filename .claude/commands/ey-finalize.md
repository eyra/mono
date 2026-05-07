---
description: Finalize a milestone by tagging and merging to master
allowed-tools: Bash(git:*)
---

# Finalize Milestone Command

Create a release tag and merge the milestone branch to master.

## Process

### Step 1: Check for uncommitted changes

Run `git status` to check for uncommitted changes.

If there are uncommitted changes, warn the user:
"Warning: You have uncommitted local changes. Run `/ey-commit` first."

Stop if there are uncommitted changes.

### Step 2: Get milestone version from branch

```bash
git branch --show-current
```

If branch doesn't match `milestone/<version>` pattern, inform the user this command only works on milestone branches and stop.

Extract the version number (e.g., `20.1` from `milestone/20.1`).

### Step 3: Create release tag

Generate tag name: `core_<date>_<version>` (e.g., `core_2026-01-23_20.1`)

```bash
git tag core_$(date +%Y-%m-%d)_<version>
git push origin core_$(date +%Y-%m-%d)_<version>
```

### Step 4: Merge to master

```bash
git checkout master
git pull origin master
git merge milestone/<version> --no-edit
git push origin master
```

If merge fails, inform the user and stop. They need to resolve conflicts manually.

### Step 5: Return to milestone branch

```bash
git checkout milestone/<version>
```

### Step 6: Report result

Show the user:
- The tag created (e.g., `core_2026-01-23_20.1`)
- Confirmation that master was updated
- Remind them to manually merge to `develop` and any other open milestone/epic branches
