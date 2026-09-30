# What every node is: a public Zakura node that updates itself from this
# repository and holds nothing worth stealing.
{
  lib,
  pkgs,
  name,
  host,
  ...
}:
let
  # The only way in. Hardware-backed keys: a stolen laptop is not enough.
  admins = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINj9R+GU468nUwqD998pglgP8ZkXUx5VuQTA+oJP7cEU maxdesalle@pm.me"
  ];
in
{
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.05";
  networking.hostName = name;

  # IPv4 by DHCP everywhere. IPv6 as the provider hands it out: OVH gives a
  # /64 and a gateway outside it, declared on-link (a host with
  # ipv6Gateway); Vultr advertises both, so the address and route come from
  # router advertisements.
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = host.mac;
    networkConfig.DHCP = "ipv4";
    networkConfig.IPv6AcceptRA = !(host ? ipv6Gateway);
  }
  // lib.optionalAttrs (host ? ipv6Gateway) {
    address = [ "${host.ipv6}/64" ];
    routes = [
      {
        Gateway = host.ipv6Gateway;
        GatewayOnLink = true;
      }
    ];
  };

  # Name resolution for this machine only: no LLMNR or mDNS answering the
  # network. The firewall already drops them; this closes them at the source.
  services.resolved.settings.Resolve = {
    LLMNR = "false";
    MulticastDNS = "false";
  };

  # Per source address, before Zakura or sshd ever accept: at most 4 open
  # P2P connections, and new ones to P2P or SSH at 10 a minute after a burst
  # of 20. Peers reconnect rarely; a flood from one address stops here. P2P
  # v2 is UDP and throttled inside Zakura instead, where QUIC is understood.
  networking.firewall.extraCommands = ''
    ip46tables -I nixos-fw -p tcp -m multiport --dports 22,8233 -m conntrack --ctstate NEW \
      -m hashlimit --hashlimit-above 10/minute --hashlimit-burst 20 \
      --hashlimit-mode srcip --hashlimit-name newconn -j DROP
    ip46tables -I nixos-fw -p tcp --dport 8233 -m conntrack --ctstate NEW \
      -m connlimit --connlimit-above 4 -j DROP
  '';

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = admins;
  assertions = [
    {
      assertion = admins != [ ];
      message = "node.nix: no admin keys, so the installed host would be unreachable.";
    }
  ];

  # Logs stay on this machine, briefly: enough to read why a boot failed,
  # too little to be an archive worth subpoenaing. Zakura already redacts
  # peer addresses in them.
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=3day
  '';
  # A root shell on the KVM console when boot fails. Whoever can open that
  # console already controls the OVH account, and with it rescue mode.
  boot.initrd.systemd.emergencyAccess = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  services.zcash.binaryCache.enable = true;

  services.zcash.zakura.mainnet = {
    enable = true;
    openFirewall = true;
    snapshot.enable = true;
    watchdog.enable = true;
    settings = {
      network = {
        # Both stacks: v2 with the peers that speak it, legacy for the rest.
        p2p_stack = "dual";
        external_addr = "${host.ipv4}:8233";
      };
      state.storage_mode = host.storage;
      health.listen_addr = "127.0.0.1:8080";
      # /ready estimates the tip from the time since the last block, so a
      # four-minute gap (4% of blocks at 75 s) reads as three behind while
      # the node sits on the tip. Five tolerates all but <1% of honest gaps.
      health.ready_max_blocks_behind = 5;
      # Loopback, cookie-authenticated: for the heartbeat below, and for us
      # over SSH. The firewall never opens it.
      rpc.listen_addr = "127.0.0.1:8232";
    };
  };

  # Every minute, what the dashboard shows, signed with this host's SSH key
  # so nothing else needs one. The dashboard knows the public half from
  # hosts.nix and throws away anything it cannot verify.
  systemd.services.fleet-heartbeat = {
    path = with pkgs; [
      coreutils
      curl
      jq
      openssh
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      state=/var/lib/zakura-mainnet
      # null while the node cannot answer, e.g. during a snapshot restore.
      rpc() {
        # No cookie until the node first starts; an empty -u makes curl prompt.
        auth=()
        [ -r $state/.cookie ] && auth=(-u "$(cat $state/.cookie)")
        r=$(curl -sf -m 5 "''${auth[@]}" -H 'content-type: application/json' \
          --data "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"$1\",\"params\":[]}" \
          http://127.0.0.1:8232 | jq -c .result) || true
        echo "''${r:-null}"
      }
      body=$(jq -nc \
        --arg host ${name} \
        --argjson chain "$(rpc getblockchaininfo)" \
        --argjson peers "$(rpc getpeerinfo)" \
        --argjson info "$(rpc getinfo)" \
        --arg ready "$(curl -s -o /dev/null -w '%{http_code}' -m 5 http://127.0.0.1:8080/ready)" \
        --arg restoring "$(test -d $state/snapshot && echo true || echo false)" \
        --arg disk "$(df --output=pcent / | tail -1 | tr -d ' ')" \
        '{host: $host, time: (now | floor), height: $chain.blocks, tip: $chain.bestblockhash,
          peers: ($peers | length?), version: $info.subversion, ready: ($ready == "200"),
          restoring: ($restoring == "true"), disk: $disk}')
      sig=$(printf %s "$body" | ssh-keygen -q -Y sign -f /etc/ssh/ssh_host_ed25519_key -n fleet-heartbeat -)
      curl -sf -m 10 https://nodes.cypherpunk-fleet.workers.dev/beat \
        --json "$(jq -nc --arg body "$body" --arg sig "$sig" '{body: $body, sig: $sig}')"
    '';
  };
  systemd.timers.fleet-heartbeat = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "minutely";
  };

  # Pull, never push: nothing outside the node holds a key to it. A failed
  # build or eval leaves the running system as it was.
  system.autoUpgrade = {
    enable = true;
    # By name, not by hostname: a renamed host keeps its old hostname until
    # it reboots, and would look itself up under the old name until then.
    flake = "github:cypherpunktech/node-infrastructure#${name}";
    dates = "*-*-* ${lib.fixedWidthNumber 2 host.slot}:00:00 UTC";
    randomizedDelaySec = "30min";
  };
}
