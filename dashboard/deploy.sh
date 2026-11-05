#!/usr/bin/env bash
# Publish the dashboard. Needs CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID,
# e.g. from ~/.config/cloudflare.env; hosts.json is generated, never edited.
set -euo pipefail
cd "$(dirname "$0")"
# A deploy replaces every asset, and this licensed font is not in the repository:
# without the local copy, it would silently vanish from the live page.
[ -f public/fonts/new-science-bold.woff2 ] || { echo "missing public/fonts/new-science-bold.woff2" >&2; exit 1; }
nix eval --json ..#dashboardHosts > hosts.json
nix eval --json ..#dashboardValidators > validators.json
# A Global API Key in the environment outranks the token for wrangler, and
# belongs to whatever account set it; only the token may deploy this.
env -u CLOUDFLARE_API_KEY -u CLOUDFLARE_EMAIL nix run nixpkgs#wrangler -- deploy
