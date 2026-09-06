#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://github.com/iilei/proquint/releases/download/v0.2.8"
REPO="example-repo-local"
ARTIFACTORY="http://localhost:8081/artifactory"
CRED="admin:password"

FILES=(
  "checksums.txt"
  "checksums.txt.sig"
  "proquint_0.2.8_darwin_universal2.tar.gz"
  "proquint_0.2.8_darwin_universal2.tar.gz.sha256"
  "proquint_0.2.8_darwin_universal2.tar.gz.sig"
  "proquint_0.2.8_linux_arm64.tar.gz"
  "proquint_0.2.8_linux_arm64.tar.gz.sha256"
  "proquint_0.2.8_linux_arm64.tar.gz.sig"
  "proquint_0.2.8_linux_armv7.tar.gz"
  "proquint_0.2.8_linux_armv7.tar.gz.sha256"
  "proquint_0.2.8_linux_armv7.tar.gz.sig"
  "proquint_0.2.8_linux_x86_64.tar.gz"
  "proquint_0.2.8_linux_x86_64.tar.gz.sha256"
  "proquint_0.2.8_linux_x86_64.tar.gz.sig"
  "proquint_0.2.8_windows_amd64.zip"
  "proquint_0.2.8_windows_amd64.zip.sha256"
  "proquint_0.2.8_windows_amd64.zip.sig"
  "proquint_0.2.8_windows_arm64.zip"
  "proquint_0.2.8_windows_arm64.zip.sha256"
  "proquint_0.2.8_windows_arm64.zip.sig"
)

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
echo $TMPDIR

for f in "${FILES[@]}"; do
  echo "==> $f"
  echo "curl -sfL -o" "$TMPDIR/$f" "$BASE_URL/$f"
  # Download
  curl -sfL -o "$TMPDIR/$f" "$BASE_URL/$f"
  # Push to Artifactory, preserving relative path under a namespace
  curl -sf -u "$CRED" -T "$TMPDIR/$f" \
    "$ARTIFACTORY/$REPO/proquint/0.2.8/$f"
done

echo "All done."   