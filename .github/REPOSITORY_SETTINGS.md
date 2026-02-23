# Repository Settings

Required GitHub settings for automated version updates.

## Actions Permissions

1. **Settings > Actions > General**
2. Under "Workflow permissions":
   - Select **"Read and write permissions"**
   - Check **"Allow GitHub Actions to create and approve pull requests"**
3. Save

## How It Works

The `update.yml` workflow runs daily at 08:00 UTC:

1. Checks `parallel-web/parallel-web-tools` for new GitHub releases
2. If a new version exists, runs `scripts/update.sh` to update hashes
3. Verifies the build passes on Ubuntu
4. Creates a PR with the version bump
5. Enables auto-merge (squash)

The `test-pr.yml` workflow then validates the PR on both Linux and macOS before merge.

## Manual Trigger

```bash
# Trigger update check manually
gh workflow run "Check for Updates"

# Trigger with a specific version
gh workflow run "Check for Updates" -f version=0.0.15
```
