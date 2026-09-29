# What every node is: a public Zakura node that updates itself from this
# repository and holds nothing worth stealing.
{
  lib,
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

  # IPv4 by DHCP, as OVH hands it out; IPv6 is static, and its gateway sits
  # outside the /64, so the route has to be declared on-link.
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = host.mac;
    networkConfig.DHCP = "ipv4";
    address = [ "${host.ipv6}/64" ];
    routes = [
      {
        Gateway = host.ipv6Gateway;
        GatewayOnLink = true;
      }
    ];
  };

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

  # Logs live in RAM and go nowhere: nothing on disk to subpoena or leak.
  services.journald.storage = "volatile";

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
    };
  };

  # Pull, never push: nothing outside the node holds a key to it. A failed
  # build or eval leaves the running system as it was.
  system.autoUpgrade = {
    enable = true;
    flake = "github:cypherpunktech/node-infrastructure";
    dates = "*-*-* ${lib.fixedWidthNumber 2 host.slot}:00:00 UTC";
    randomizedDelaySec = "30min";
  };
}
