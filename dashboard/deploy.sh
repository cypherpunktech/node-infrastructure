#!/usr/bin/env bash
# Publish the dashboard. Needs CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID,
# e.g. from ~/.config/cloudflare.env; hosts.json is generated, never edited.
set -euo pipefail
cd "$(dirname "$0")"
nix eval --json ..#dashboardHosts > hosts.json
# A Global API Key in the environment outranks the token for wrangler, and
# belongs to whatever account set it; only the token may deploy this.
env -u CLOUDFLARE_API_KEY -u CLOUDFLARE_EMAIL nix run nixpkgs#wrangler -- deploy
