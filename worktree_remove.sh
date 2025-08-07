#!/bin/bash
# Remove a worktree from the mono-worktree repository
# Usage: ./worktree_remove.sh <branch-name>

set -e

#check for branch name
if [ -z "$1" ]; then
    echo "Usage: ./worktree_remove.sh <branch-name>"
    exit 1
fi

#check if branch does not exist
if [ ! -d "../mono-worktree/$1" ]; then
    echo "Branch $1 does not exist"
    exit 1
fi

#remove worktree
git worktree remove ../mono-worktree/$1

echo "Worktree $1 removed successfully"






