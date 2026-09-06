#!/usr/bin/env bash
set -euo pipefail

netrc_path="${HOME}/.mise-artifactory.netrc"
artifact_url="http://localhost:8081/artifactory/example-repo-local/proquint/0.2.8/proquint_0.2.8_windows_amd64.zip"

show_setup_instructions() {
  cat <<'INSTRUCTIONS'
Proquint is not available from the configured Artifactory mirror yet.

1. Sign in to http://localhost:8082/ui/.
2. Open Set Me Up and create or copy an access token with read access.
3. Create ~/.mise-artifactory.netrc with this one-off command, replacing the
   placeholder values:

cat > ~/.mise-artifactory.netrc <<'NETRC'
machine localhost
  login YOUR_USERNAME
  password YOUR_ACCESS_TOKEN
NETRC
chmod 600 ~/.mise-artifactory.netrc

Then rerun: mise run proquint-fetch
INSTRUCTIONS
}

if [[ ! -f "$netrc_path" ]] || ! curl --netrc-file "$netrc_path" -fsSI "$artifact_url" > /dev/null; then
  show_setup_instructions
  exit 1
fi

mise exec "github:iilei/proquint@0.2.8" -- proquint --version
printf "Mirrored proquint is ready. Run: mise run proquint-help\n"