![node-infrastructure](./banner.png)

# node-infrastructure [![X][x-badge]][x]

[x]: https://x.com/cypherpunk
[x-badge]: https://img.shields.io/twitter/follow/cypherpunk

Cypherpunk's [Zakura](https://zakura.com) nodes on the [Zcash](https://z.cash) network, as one NixOS flake.

Status: [nodes.cypherpunk-fleet.workers.dev](https://nodes.cypherpunk-fleet.workers.dev)

| File         | What it is                                                                 |
| ------------ | -------------------------------------------------------------------------- |
| `hosts.nix`  | The nodes: address, disk, storage mode, update hour.                       |
| `node.nix`   | What every node runs: Zakura from [zcash.nix](https://github.com/cypherpunktech/zcash.nix), SSH, heartbeat, updates. |
| `disk.nix`   | Disk layout.                                                               |
| `dashboard/` | The status page, a Cloudflare Worker fed by heartbeats each node signs.    |

Nodes pull this repository every day at their hour in `hosts.nix` and switch to it. Reverting a
commit on `main` rolls them back.

## Adding a node

1. Add it to `hosts.nix`.
2. Install NixOS over whatever Linux the provider gave it:

   ```console
   $ nix run github:nix-community/nixos-anywhere -- --flake .#<name> --build-on remote --target-host root@<ip>
   ```

3. Put its host key (`ssh-keyscan -t ed25519 <ip>`) in `hosts.nix`, then `./dashboard/deploy.sh`.
