#!/usr/bin/env bash
# Same signature and endpoint as the fleet's heartbeat in node.nix. Fields stay
# null while svoted cannot answer, so a dead service reports itself.
set -u
valoper=svvaloper14qh2k30k7nmatf4echm5fu9wucs739kuq2vamu
get() {
  r=$(curl -s -m 5 "http://127.0.0.1:$1" | jq -c . 2>/dev/null) || true
  echo "${r:-null}"
}
body=$(jq -nc \
  --argjson s "$(get 26657/status)" \
  --argjson n "$(get 26657/net_info)" \
  --argjson a "$(get 26657/abci_info)" \
  --argjson v "$(get "1317/cosmos/staking/v1beta1/validators/$valoper")" \
  --arg disk "$(df --output=pcent / | tail -1 | tr -d ' ')" \
  '$s.result.sync_info as $i | {host: "benaloh", time: (now | floor), disk: $disk,
    height: (($i.latest_block_height | tonumber)? // null),
    blockTime: (($i.latest_block_time | sub("\\.[0-9]+Z$"; "Z") | fromdate)? // null),
    catchingUp: ($i.catching_up // false),
    peers: (($n.result.n_peers | tonumber)? // null),
    version: $a.result.response.version,
    power: (($s.result.validator_info.voting_power | tonumber)? // null),
    bond: $v.validator.status, jailed: ($v.validator.jailed // false)}')
sig=$(printf %s "$body" | ssh-keygen -q -Y sign -f /etc/ssh/ssh_host_ed25519_key -n fleet-heartbeat -)
curl -sf -m 10 https://nodes.cypherpunk-fleet.workers.dev/beat \
  --json "$(jq -nc --arg body "$body" --arg sig "$sig" '{body: $body, sig: $sig}')"
