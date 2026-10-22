# Automated Docker Updates & Deployment Setup

This guide will help you set up automated Docker image updates using Renovate Bot and automatic deployment via GitHub Actions with a self-hosted runner.

## Overview

- **Renovate Bot**: Automatically creates PRs when new Docker image versions are available
- **Self-Hosted GitHub Runner**: Runs on your server to execute deployments locally (no public internet access needed!)
- **GitHub Actions**: Orchestrates the deployment workflow
- **You**: Review PRs and merge when ready to deploy

## Prerequisites

- GitHub repository with admin access
- Docker Compose stack (already set up ✓)
- Your server (doesn't need to be publicly accessible!)

## Step 1: Create GitHub Personal Access Token (PAT)

The self-hosted runner needs a token to authenticate with GitHub.

Run the setup script:

```bash
./setup-github-runner.sh
```

Or manually:

1. Go to: https://github.com/settings/tokens?type=beta
2. Click **Generate new token** (Fine-grained token)
3. Configure:
   - **Token name**: `homelab-runner-token`
   - **Expiration**: 90 days (or your preference)
   - **Repository access**: Only select repositories → `mathbrook/htpc-download-box`
   - **Repository permissions**:
     - Actions: **Read and write**
     - Administration: **Read and write**
     - Metadata: **Read-only** (auto-selected)
4. Click **Generate token** and copy it
5. Add to your `.env` file:
   ```bash
   echo "GITHUB_PAT=your_token_here" >> .env
   ```

## Step 2: Start the GitHub Runner

Start the runner container:

```bash
docker compose up -d github-runner
```

Verify it's running:

```bash
docker logs github-runner --tail 20
```

You should see messages about the runner connecting to GitHub.

## Step 3: Verify Runner Registration

Go to: https://github.com/mathbrook/htpc-download-box/settings/actions/runners

You should see **homelab-runner** with a green "Idle" status.

## Step 4: Enable Renovate Bot

1. Go to: https://github.com/apps/renovate
2. Click **Install** or **Configure**
3. Select your repository: `mathbrook/htpc-download-box`
4. Grant access to the repository
5. Click **Install** or **Save**

That's it! Renovate will automatically:
- Scan your `docker-compose.yml` for Docker images
- Check for updates on the configured schedule (evenings/weekends)
- Create PRs with changelogs and release notes

## Step 5: Test the Setup

### Test GitHub Actions Deployment

From your server:

```bash
gh workflow run deploy.yml
```

Or via GitHub web:

1. Go to: https://github.com/mathbrook/htpc-download-box/actions
2. Select **Deploy Docker Compose Stack** workflow
3. Click **Run workflow** dropdown
4. Enter a reason like "Testing self-hosted runner"
5. Click **Run workflow**

Monitor the workflow execution. It should:
- ✅ Run on your self-hosted runner (you'll see "homelab-runner" in the logs)
- ✅ Pull latest code from git
- ✅ Pull updated Docker images
- ✅ Restart any changed containers
- ✅ Show container status

### Test Renovate (Optional)

Renovate will run automatically on its schedule. To test immediately, wait for the onboarding PR that Renovate creates when first installed, then merge it.

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

From your server:

```bash
cd /home/ubuntu/dev/htpc-download-box
docker compose ps
docker compose logs --tail=50

# Check runner status
docker logs github-runner --tail=50
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
   - **Runner offline**: Check `docker logs github-runner`
   - **Permission denied**: Runner needs access to docker socket
   - **Git conflicts**: May need to manually resolve on server
   - **PAT expired**: Generate new token and update `.env`

### Runner Not Connecting

Check runner logs:

```bash
docker logs github-runner --tail 50
```

Common issues:
- **Invalid PAT**: Verify token has correct permissions
- **Token expired**: Generate new token (check expiration date)
- **Network issues**: Runner needs internet to reach GitHub API

Restart the runner:

```bash
docker compose restart github-runner
```

### Runner Shows Offline in GitHub

1. Check if container is running: `docker ps | grep github-runner`
2. Check logs: `docker logs github-runner`
3. Verify PAT in `.env` file
4. Restart: `docker compose restart github-runner`

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

- **GitHub PAT**: Store in `.env` file (already in `.gitignore`), never commit to git
- **Token Scope**: PAT is limited to only your repository with minimal required permissions
- **Token Expiration**: Set reasonable expiration (90 days) and rotate regularly
- **Runner Isolation**: Runner runs in Docker container with limited host access
- **Docker Socket**: Runner has access to Docker socket (required for deployments)
- **Digest Pinning**: Renovate pins image digests to prevent supply chain attacks
- **Review Major Updates**: Always review major version updates carefully
- **Local Only**: Runner runs on your private network, no public exposure needed

## Additional Resources

- [Renovate Documentation](https://docs.renovatebot.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Quick Reference Commands

```bash
# View deployment logs on server
cd /home/ubuntu/dev/htpc-download-box
docker compose logs -f

# Check runner status
docker logs github-runner --tail 50
docker compose ps | grep github-runner

# Restart runner
docker compose restart github-runner

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

# Check runner registration
# Visit: https://github.com/mathbrook/htpc-download-box/settings/actions/runners
```

## What's Next?

1. ✅ Run `./setup-github-runner.sh` to create GitHub PAT
2. ✅ Start runner: `docker compose up -d github-runner`
3. ✅ Verify runner is online in GitHub settings
4. ✅ Install Renovate Bot on your repository
5. ✅ Test with a manual workflow run: `gh workflow run deploy.yml`
6. ✅ Wait for first Renovate PR (may take a day)
7. ✅ Review and merge a test PR
8. ✅ Verify automatic deployment works
9. ✅ Adjust schedule/grouping to your preference

Enjoy automated updates with your self-hosted runner! 🎉
