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
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NIX="${SCRIPT_DIR}/../package.nix"
PLATFORMS=("linux-x64" "linux-arm64" "darwin-x64" "darwin-arm64")

current_version() {
  grep 'version = "' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/'
}

latest_version() {
  if command -v gh >/dev/null 2>&1; then
    gh release view --repo "$REPO" --json tagName -q '.tagName' | sed 's/^v//'
  else
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep '"tag_name"' \
      | sed 's/.*"v\(.*\)".*/\1/'
  fi
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
for platform in "${PLATFORMS[@]}"; do
  hash=$(curl -fsSL "https://github.com/${REPO}/releases/download/v${NEW_VERSION}/parallel-cli-${platform}.zip.sha256")
  echo "  ${platform}: ${hash}"

  # Update hash in package.nix (portable sed: write to temp file)
  tmp=$(mktemp)
  awk -v platform="$platform" -v hash="$hash" '
    /hashes = \{/ { in_block=1 }
    in_block && $0 ~ "\"" platform "\"" {
      sub(/= "sha256:[^"]*"/, "= \"sha256:" hash "\"")
    }
    in_block && /\};/ { in_block=0 }
    { print }
  ' "$PACKAGE_NIX" > "$tmp"
  mv "$tmp" "$PACKAGE_NIX"
done

# Update version (portable: use temp file instead of sed -i)
tmp=$(mktemp)
sed "s/version = \"${CURRENT}\"/version = \"${NEW_VERSION}\"/" "$PACKAGE_NIX" > "$tmp"
mv "$tmp" "$PACKAGE_NIX"

echo ""
echo "Updated package.nix to v${NEW_VERSION}"
echo ""
echo "Next steps:"
echo "  1. nix build      # verify it builds"
echo "  2. nix run . -- --version  # verify version"
echo "  3. git add -p && git commit -m 'update parallel-cli to ${NEW_VERSION}'"
