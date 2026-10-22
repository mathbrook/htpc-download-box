# Automated Docker Updates & Deployment Setup

This guide will help you set up automated Docker image updates using Renovate Bot and automatic deployment via GitHub Actions.

## Overview

- **Renovate Bot**: Automatically creates PRs when new Docker image versions are available
- **GitHub Actions**: Automatically deploys changes to your server when PRs are merged
- **You**: Review PRs and merge when ready to deploy

## Prerequisites

- GitHub repository with admin access
- SSH access to your deployment server
- Docker Compose stack (already set up ✓)

## Step 1: Generate SSH Deploy Key

On your server, create a dedicated SSH key for GitHub Actions deployments:

```bash
# Generate a new SSH key (don't use a passphrase)
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy_key -N ""

# Add the public key to authorized_keys
cat ~/.ssh/github_deploy_key.pub >> ~/.ssh/authorized_keys

# Display the private key (you'll need this for GitHub Secrets)
cat ~/.ssh/github_deploy_key
```

**Important**: Copy the entire private key output (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)

## Step 2: Configure GitHub Secrets

Go to your GitHub repository: https://github.com/mathbrook/htpc-download-box

1. Navigate to: **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add these three secrets:

| Secret Name | Value |
|------------|-------|
| `SSH_PRIVATE_KEY` | The private key from Step 1 (entire output) |
| `SSH_HOST` | Your server's hostname or IP address |
| `SSH_USER` | `ubuntu` (or your server username) |

## Step 3: Enable Renovate Bot

1. Go to: https://github.com/apps/renovate
2. Click **Install** or **Configure**
3. Select your repository: `mathbrook/htpc-download-box`
4. Grant access to the repository
5. Click **Install** or **Save**

That's it! Renovate will automatically:
- Scan your `docker-compose.yml` for Docker images
- Check for updates on the configured schedule (evenings/weekends)
- Create PRs with changelogs and release notes

## Step 4: Test the Setup

### Test Renovate (Optional)

Renovate will run automatically, but you can trigger a manual run:

1. Go to repository **Settings** → **Webhooks**
2. Find the Renovate webhook
3. Click **Redeliver** on a recent delivery

### Test GitHub Actions Deployment

1. Go to **Actions** tab in your repository
2. Select **Deploy Docker Compose Stack** workflow
3. Click **Run workflow** dropdown
4. Enter a reason like "Testing deployment setup"
5. Click **Run workflow**

Monitor the workflow execution. It should:
- ✅ Connect to your server via SSH
- ✅ Pull latest code from git
- ✅ Pull updated Docker images
- ✅ Restart any changed containers

## How It Works

### The Update Flow

1. **Renovate checks for updates** (scheduled: evenings/weekends)
2. **Renovate creates a PR** with:
   - Updated image tags in `docker-compose.yml`
   - Release notes and changelog
   - Digest pins for security
3. **You review the PR**:
   - Check the changelog for breaking changes
   - Review version changes
   - Check labels (major updates are labeled for extra caution)
4. **You merge the PR** when ready
5. **GitHub Actions automatically deploys**:
   - Pulls latest code to server
   - Pulls new Docker images
   - Restarts affected containers
6. **You get notified** of deployment success/failure

### Update Grouping

Renovate groups updates intelligently:

- **Non-major updates**: Grouped together (minor/patch versions)
- **Major updates**: Separate PRs per app (needs careful review)
- **LinuxServer images**: Grouped together (they update frequently)
- **Security patches**: Created immediately (not waiting for schedule)

## Configuration Files

### `renovate.json`

Controls Renovate behavior:
- **Schedule**: When to check for updates (evenings/weekends)
- **Grouping**: How to organize PRs
- **Automerge**: Disabled (you control when to merge)
- **Labels**: Added to PRs for filtering

### `.github/workflows/deploy.yml`

GitHub Actions workflow that:
- Triggers on changes to `docker-compose.yml` or `.env`
- SSHs into your server
- Pulls latest code and Docker images
- Restarts containers
- Can be manually triggered

## Customization

### Change Renovate Schedule

Edit `renovate.json` and modify the `schedule` array:

```json
"schedule": [
  "after 10pm every weekday",
  "before 5am every weekday",
  "every weekend"
]
```

Common options:
- `"every weekend"` - Only check on Saturdays and Sundays
- `"before 5am"` - Only check before 5 AM
- `"after 10pm on friday"` - Only Friday nights
- `"at any time"` - No restrictions

### Enable Automerge for Patch Updates

If you want to auto-merge small patch updates (risky but convenient):

Edit `renovate.json`, find the non-major packageRule and change:

```json
"automerge": false
```

to:

```json
"automerge": true,
"automergeType": "pr"
```

### Disable Auto-Deployment

If you want to deploy manually instead:

1. Edit `.github/workflows/deploy.yml`
2. Remove the `push:` trigger section
3. Keep only `workflow_dispatch:` to enable manual triggering

## Monitoring

### Check Renovate Status

- PRs will appear in the **Pull Requests** tab
- Renovate adds logs to PR descriptions
- Check the **Dependency Dashboard** issue (if enabled)

### Check Deployment Status

- Go to **Actions** tab in repository
- View workflow runs and their status
- Click on a run to see detailed logs

### Check Server Status

SSH into your server and run:

```bash
cd /home/ubuntu/dev/htpc-download-box
docker compose ps
docker compose logs --tail=50
```

## Troubleshooting

### Renovate Not Creating PRs

1. Check if Renovate app is installed: https://github.com/apps/renovate
2. Look for issues in repository **Issues** tab
3. Check Renovate logs in initial onboarding PR

### GitHub Actions Failing

1. Go to **Actions** tab and click on failed workflow
2. Expand failed steps to see error messages
3. Common issues:
   - **SSH authentication failed**: Check GitHub Secrets are set correctly
   - **Permission denied**: Ensure public key is in `~/.ssh/authorized_keys`
   - **Git conflicts**: May need to manually resolve on server

### SSH Connection Issues

Test SSH connection manually:

```bash
ssh -i ~/.ssh/github_deploy_key ubuntu@YOUR_SERVER_IP "echo 'Success!'"
```

If this fails:
- Check firewall settings
- Verify SSH key permissions (should be 600)
- Check `~/.ssh/authorized_keys` on server

### Containers Not Updating

After deployment, check which containers should have updated:

```bash
docker compose pull
docker compose up -d
```

If specific container isn't updating:
- Check image name in `docker-compose.yml` matches registry
- Verify the image tag exists: `docker pull IMAGE:TAG`
- Check Docker Hub/registry for the image

## Security Notes

- **SSH Key**: The deploy key only has access to your server, not GitHub
- **Least Privilege**: Consider restricting the SSH key to only run specific commands
- **Digest Pinning**: Renovate pins image digests to prevent supply chain attacks
- **Review Major Updates**: Always review major version updates carefully
- **Secrets**: Never commit secrets to git; use GitHub Secrets

## Additional Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Quick Reference Commands

```bash
# View deployment logs on server
cd /home/ubuntu/dev/htpc-download-box
docker compose logs -f

# Manually pull updates
docker compose pull
docker compose up -d

# Check container status
docker compose ps

# Restart specific service
docker compose restart SERVICE_NAME

# View Renovate PRs
gh pr list --label renovate

# Trigger manual deployment
gh workflow run deploy.yml
```

## What's Next?

1. ✅ Complete the setup steps above
2. ✅ Test with a manual workflow run
3. ✅ Wait for first Renovate PR (may take a day)
4. ✅ Review and merge a test PR
5. ✅ Verify automatic deployment works
6. ✅ Adjust schedule/grouping to your preference
7. ✅ Set up notifications (Discord/Slack/email) if desired

Enjoy automated updates! 🎉
