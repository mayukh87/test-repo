#!/bin/bash

# Helper script to get recent commits for deployment
# Usage: ./get_recent_commits.sh [branch_name] [number_of_commits]

BRANCH=${1:-$(git branch --show-current)}
NUM_COMMITS=${2:-10}

echo "🔍 Recent commits on branch: $BRANCH"
echo "================================================"

git log $BRANCH --oneline -n $NUM_COMMITS --pretty=format:"%C(yellow)%h%C(reset) - %C(green)(%cr)%C(reset) %s %C(blue)<%an>%C(reset)"

echo ""
echo ""
echo "💡 To deploy a specific commit:"
echo "   1. Copy the commit hash (yellow text above)"
echo "   2. Go to Bitbucket > Pipelines > Run pipeline"
echo "   3. Select branch: $BRANCH"
echo "   4. Select pipeline: custom: deploy_dags"
echo "   5. Paste the commit hash in COMMIT_SHA field"
echo "   6. Select your environment and run"
echo ""
echo "📍 Leave COMMIT_SHA empty to deploy the latest commit (HEAD)"