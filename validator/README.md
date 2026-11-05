# Shielded Vote validator

`vote.infra.cypherpunk.com`, a Debian 13 VM at Vultr in Amsterdam, on `zvote-1`. It is the only
machine holding its keys; nothing secret belongs in this repository.

| File           | What it is                                                     |
| -------------- | -------------------------------------------------------------- |
| `host.nix`     | Address and host key, read by the dashboard.                   |
| `setup.sh`     | Patching, SSH, firewall, heartbeat. Safe to re-run.            |
| `heartbeat.sh` | Signed status for [infra.cypherpunk.com](https://infra.cypherpunk.com). |

## Rules

- **Never re-run `join.sh` on this VM.** It deletes `~/.svoted` and makes new keys. Repair with Valar's `reset-validator-snapshot.sh`.
- **Never run a second copy of these keys.** Two signers is a double-sign. Stop and disable `svoted` on the old VM first, and stay down long enough that the old one cannot be signing.

## New VM

1. Point the DNS records at it, then run `setup.sh` (see its header).
2. Install as `svote`, once:

   ```console
   $ SVOTE_MONIKER=Cypherpunk bash join.sh --tls-mode custom --domain vote.infra.cypherpunk.com
   ```

   This registers with Valar's admin API automatically.
3. Run `setup.sh` again. It repairs the unit's `PATH` and removes the installer's `sudo`.
4. Back up the keys, below, before anything is funded.
5. Ask Valar to fund the validator. It then bonds itself and writes `~/.svoted/join-complete`.
6. After bonding, add `{"url":"https://vote.infra.cypherpunk.com","label":"Cypherpunk"}` to `vote_servers` in [token-holder-voting-config](https://github.com/valargroup/token-holder-voting-config).

## Keys

Encrypted on the VM, so plaintext never leaves it:

```console
# cd /home/svote/.svoted
# tar -cf - config/priv_validator_key.json config/node_key.json keyring-test pallas.sk pallas.pk ea.sk ea.pk \
    | age -R <recipients-file> -o /root/keys.tar.age
```

Keep it offline in two places, and prove a copy decrypts on a machine that does not run `svoted`:

```console
$ age -d -i <identity> keys.tar.age | tar -tf -
```

Restore into `/home/svote/.svoted` as `svote` with `svoted` stopped. `priv_validator_state.json` is deliberately not in the
backup: a stale one would let the node re-sign old heights. `MsgRotatePallasKey` changes `pallas.*`, so back up again after a rotation.
