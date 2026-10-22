#!/bin/bash

# Setup script for GitHub Actions Self-Hosted Runner
# This script helps you create a GitHub Personal Access Token (PAT) for the runner

set -e

echo "🏃 GitHub Actions Self-Hosted Runner Setup"
echo "==========================================="
echo ""

echo "You need to create a GitHub Personal Access Token (PAT) for the runner."
echo ""
echo "📋 Steps to create a PAT:"
echo ""
echo "1. Go to: https://github.com/settings/tokens?type=beta"
echo ""
echo "2. Click 'Generate new token' (Fine-grained token)"
echo ""
echo "3. Configure the token:"
echo "   - Token name: homelab-runner-token"
echo "   - Expiration: 90 days (or custom)"
echo "   - Repository access: Only select repositories"
echo "   - Select: mathbrook/htpc-download-box"
echo ""
echo "4. Repository permissions (set these):"
echo "   - Actions: Read and write"
echo "   - Administration: Read and write"
echo "   - Metadata: Read-only (auto-selected)"
echo ""
echo "5. Click 'Generate token' and copy it"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Have you created the token? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please create the token first, then run this script again."
    exit 0
fi

echo ""
read -p "Paste your GitHub PAT here: " GITHUB_PAT
echo ""

if [ -z "$GITHUB_PAT" ]; then
    echo "❌ No token provided. Exiting."
    exit 1
fi

# Add to .env file
if grep -q "^GITHUB_PAT=" .env 2>/dev/null; then
    echo "⚠️  GITHUB_PAT already exists in .env file"
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sed -i "s|^GITHUB_PAT=.*|GITHUB_PAT=${GITHUB_PAT}|" .env
        echo "✅ Updated GITHUB_PAT in .env"
    else
        echo "Keeping existing value."
    fi
else
    echo "GITHUB_PAT=${GITHUB_PAT}" >> .env
    echo "✅ Added GITHUB_PAT to .env"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting GitHub Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker compose up -d github-runner

echo ""
echo "⏳ Waiting for runner to start..."
sleep 5

echo ""
echo "📊 Runner logs:"
docker logs github-runner --tail 20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Verify the runner is registered:"
echo "https://github.com/mathbrook/htpc-download-box/settings/actions/runners"
echo ""
echo "You should see 'homelab-runner' with a green status."
echo ""
echo "To test the deployment:"
echo "  gh workflow run deploy.yml"
echo ""
echo "Or go to:"
echo "  https://github.com/mathbrook/htpc-download-box/actions"
echo "  → Deploy Docker Compose Stack → Run workflow"
echo ""
