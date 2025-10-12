#!/bin/bash

# Validate Public Branch Script
# This script ensures the public branch doesn't contain sensitive content
# Run this before pushing to the public branch

set -e

echo "Validating public branch for sensitive content..."

# Check if we're on the public branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "public" ]; then
    echo "Warning: Not on public branch. Current branch: $current_branch"
fi

# Get the commit range to check
if [ "$GITHUB_ACTIONS" = "true" ]; then
    # In GitHub Actions, check the last commit
    commit_range="HEAD~1..HEAD"
else
    # Locally, check unstaged changes or last commit
    commit_range="HEAD"
fi

# Check for vault directory references
if git diff --name-only $commit_range | grep -q "vault/"; then
    echo "Error: Vault directory references found in public branch"
    exit 1
fi

# Check for secret files
if git diff --name-only $commit_range | grep -q -E "\.(secret|key|pem|enc)$"; then
    echo "Error: Secret files detected in public branch"
    exit 1
fi

# Check for common sensitive patterns
sensitive_patterns=(
    "BEGIN PRIVATE KEY"
    "BEGIN RSA PRIVATE KEY"
    "ansible-vault"
    "token:"
    "password:"
    "secret:"
)

for pattern in "${sensitive_patterns[@]}"; do
    if git diff $commit_range | grep -q "$pattern"; then
        echo "Error: Sensitive pattern '$pattern' found in public branch"
        exit 1
    fi
done

# Check for IP addresses (warning only)
if git diff $commit_range | grep -qE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"; then
    echo "Warning: IP addresses found, verify they're not sensitive"
fi

echo "Validation passed! Public branch is safe to push."