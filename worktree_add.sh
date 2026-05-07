#!/bin/bash
# Add a worktree to the mono-worktree repository
# Usage: ./add_worktree <branch-name>

set -e

#check for branch name
if [ -z "$1" ]; then
    echo "Usage: ./spin_worktree <branch-name>"
    exit 1
fi

#check if branch already exists
if [ -d "../../mono-worktree/$1" ]; then
    echo "Branch $1 already exists"
    exit 1
fi

#add worktree
git worktree add ../mono-worktree/$1 -b feature/$1

# copy dev.secret.exs if exists
if [ -f ./core/config/dev.secret.exs ]; then
    cp ./core/config/dev.secret.exs ../mono-worktree/$1/core/config/dev.secret.exs
fi

cd ../mono-worktree/$1

git checkout feature/$1

cd banking_proxy
mix deps.get

cd ../core
mix deps.get

echo "Worktree $1 added successfully to mono-worktree"






