#!/bin/bash

# Setup script for GitHub Actions deployment SSH key
# This script generates an SSH key and configures it for automated deployments

set -e

echo "🔑 GitHub Actions Deployment Key Setup"
echo "======================================="
echo ""

# Check if key already exists
if [ -f ~/.ssh/github_deploy_key ]; then
    echo "⚠️  Deploy key already exists at ~/.ssh/github_deploy_key"
    read -p "Do you want to regenerate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting without changes."
        exit 0
    fi
    rm -f ~/.ssh/github_deploy_key ~/.ssh/github_deploy_key.pub
fi

# Generate SSH key
echo "📝 Generating new ED25519 SSH key..."
ssh-keygen -t ed25519 -C "github-actions-deploy-$(date +%Y%m%d)" -f ~/.ssh/github_deploy_key -N ""

# Set correct permissions
chmod 600 ~/.ssh/github_deploy_key
chmod 644 ~/.ssh/github_deploy_key.pub

echo "✅ SSH key generated successfully!"
echo ""

# Add public key to authorized_keys
echo "📋 Adding public key to authorized_keys..."
cat ~/.ssh/github_deploy_key.pub >> ~/.ssh/authorized_keys
echo "✅ Public key added to authorized_keys"
echo ""

# Get server IP/hostname
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_HOSTNAME=$(hostname)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 GitHub Secrets Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Go to: https://github.com/mathbrook/htpc-download-box/settings/secrets/actions"
echo ""
echo "Create these three secrets:"
echo ""

echo "1️⃣  SSH_HOST"
echo "   Value: $SERVER_IP (or use '$SERVER_HOSTNAME' if DNS is configured)"
echo ""

echo "2️⃣  SSH_USER"
echo "   Value: $(whoami)"
echo ""

echo "3️⃣  SSH_PRIVATE_KEY"
echo "   Value: (copy the private key below, including BEGIN/END lines)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 PRIVATE KEY (copy everything below):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat ~/.ssh/github_deploy_key
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test the key
echo "🧪 Testing SSH key locally..."
if ssh -i ~/.ssh/github_deploy_key -o StrictHostKeyChecking=no $(whoami)@localhost "echo 'SSH test successful!'" 2>/dev/null; then
    echo "✅ SSH key is working correctly!"
else
    echo "⚠️  Local SSH test failed, but key should still work for remote connections"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Copy the private key above"
echo "2. Add the three secrets to GitHub (link above)"
echo "3. Install Renovate: https://github.com/apps/renovate"
echo "4. Test deployment: Go to Actions → Deploy Docker Compose Stack → Run workflow"
echo ""
echo "See AUTOMATION_SETUP.md for detailed instructions."
echo ""
echo "✨ Setup complete! Happy automating! ✨"
