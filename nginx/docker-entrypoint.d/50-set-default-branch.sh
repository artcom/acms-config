#!/usr/bin/env bash

# Set the default branch for the config repository

cd /srv/config

# Use the actual existing branch, not HEAD (which may point to a non-existent ref in bare repos)
CURRENT_BRANCH=$(git branch --format '%(refname:short)' | head -1)

if [ -z "$CURRENT_BRANCH" ]; then
    echo "50-set-default-branch: No branches found in /srv/config" >&2
    exit 1
fi

if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    COMMIT=$(git rev-parse "refs/heads/$CURRENT_BRANCH")
    git update-ref "refs/heads/$DEFAULT_BRANCH" "$COMMIT"
    git update-ref -d "refs/heads/$CURRENT_BRANCH"
fi

git symbolic-ref HEAD "refs/heads/$DEFAULT_BRANCH"
