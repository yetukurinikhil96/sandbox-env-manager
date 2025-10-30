#!/bin/bash

# Safe Git Sync Commands
# Syncs local repository with remote main branch without losing work

echo "=========================================="
echo "Git Repository Sync"
echo "=========================================="
echo ""

# Step 1: Check current branch
echo "Step 1: Checking current branch..."
git branch --show-current
echo ""

# Step 2: Check for uncommitted changes
echo "Step 2: Checking for uncommitted changes..."
git status --short
echo ""

# Step 3: Show detailed status
echo "Step 3: Detailed status..."
git status
echo ""

# Step 4: Stash uncommitted changes if any exist
echo "Step 4: Stashing uncommitted changes (if any)..."
if [[ -n $(git status --porcelain) ]]; then
    echo "Found uncommitted changes. Stashing them..."
    git stash push -m "Auto-stash before sync on $(date +%Y-%m-%d_%H-%M-%S)"
    echo "Changes stashed successfully!"
else
    echo "No uncommitted changes to stash."
fi
echo ""

# Step 5: Switch to main branch
echo "Step 5: Switching to main branch..."
git checkout main
echo ""

# Step 6: Fetch remote updates
echo "Step 6: Fetching remote updates..."
git fetch origin
echo ""

# Step 7: Show what will be pulled
echo "Step 7: Comparing local with remote..."
git log HEAD..origin/main --oneline
echo ""

# Step 8: Pull latest changes
echo "Step 8: Pulling latest changes from remote..."
git pull origin main
echo ""

# Step 9: Show stash list
echo "Step 9: Checking stashed changes..."
git stash list
echo ""

echo "=========================================="
echo "Sync Complete!"
echo "=========================================="
echo ""
echo "Your local main branch is now up to date."
echo ""
echo "If you had uncommitted changes, they are stashed."
echo "To restore them, run:"
echo "  git stash pop"
echo ""
echo "To see all stashes:"
echo "  git stash list"
echo ""
echo "To see what's in the latest stash:"
echo "  git stash show -p"
echo "=========================================="
