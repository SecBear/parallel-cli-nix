#!/usr/bin/env bash
#
# Update parallel-cli to a new version.
#
# Usage:
#   ./scripts/update.sh              # check for latest version
#   ./scripts/update.sh --check      # same as above
#   ./scripts/update.sh 0.0.15       # update to specific version
#

set -euo pipefail

REPO="parallel-web/parallel-web-tools"
PACKAGE_NIX="$(cd "$(dirname "$0")/.." && pwd)/package.nix"

current_version() {
  grep 'version = "' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/'
}

latest_version() {
  curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"v\(.*\)".*/\1/'
}

fetch_hashes() {
  local version="$1"
  local platforms=("linux-x64" "linux-arm64" "darwin-x64" "darwin-arm64")

  for platform in "${platforms[@]}"; do
    local hash
    hash=$(curl -fsSL "https://github.com/${REPO}/releases/download/v${version}/parallel-cli-${platform}.zip.sha256")
    echo "    \"${platform}\" = \"sha256:${hash}\";"
  done
}

# --- main ---

CURRENT=$(current_version)
echo "Current version: ${CURRENT}"

if [[ "${1:-}" == "--check" ]] || [[ $# -eq 0 ]]; then
  LATEST=$(latest_version)
  echo "Latest version:  ${LATEST}"
  if [[ "$CURRENT" == "$LATEST" ]]; then
    echo "Already up to date."
    exit 0
  fi
  echo ""
  echo "Update available! Run:"
  echo "  ./scripts/update.sh ${LATEST}"
  exit 0
fi

NEW_VERSION="$1"
echo "Updating to:     ${NEW_VERSION}"
echo ""

echo "Fetching SHA256 hashes..."
HASHES=$(fetch_hashes "$NEW_VERSION")
echo "$HASHES"
echo ""

# Update version
sed -i '' "s/version = \"${CURRENT}\"/version = \"${NEW_VERSION}\"/" "$PACKAGE_NIX"

# Update hashes - replace the block between `hashes = {` and `};`
# Use a temp file approach for multi-line sed
python3 -c "
import re, sys

with open('$PACKAGE_NIX', 'r') as f:
    content = f.read()

new_hashes = '''$HASHES'''

pattern = r'(hashes = \{)\n.*?\n(  \};)'
replacement = r'\1\n' + new_hashes + r'\n\2'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('$PACKAGE_NIX', 'w') as f:
    f.write(content)
"

echo "Updated package.nix"
echo ""
echo "Next steps:"
echo "  1. nix build      # verify it builds"
echo "  2. nix run . -- --version  # verify version"
echo "  3. git add -p && git commit -m 'Update parallel-cli to ${NEW_VERSION}'"
