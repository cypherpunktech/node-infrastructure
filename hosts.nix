# The fleet. Adding a node is adding an entry here, then running
# nixos-anywhere against it once.
#
# storage: "archive" serves the whole chain to peers syncing from genesis;
#          "pruned" keeps what consensus needs (12 GiB) and serves recent blocks.
# coordinates: [ latitude longitude ], its dot on the dashboard's map.
# hostKey: its SSH host key, which signs the heartbeats the dashboard shows;
#          read it with `ssh-keyscan -t ed25519 <ip>` after the install.
# slot:    the UTC hour the node pulls updates. Staggered, so a bad release
#          reaches one slot's nodes and can be reverted before the next.
#
# Each node is named after a cypherpunk. Taken: finney. Next up: may,
# hughes, chaum, szabo, dai, back, zimmermann, diffie, milhon, gilmore.
{
  finney = {
    # OVH SYS-3.
    location = "Hillsboro, US West";
    coordinates = [
      45.52
      (-122.99)
    ];
    # Signs its heartbeats; the dashboard checks them against this.
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESvPP/QW1zNfoNQC7Y1vgLIVB6graUizBJ2eD6Se9wQ";
    ipv4 = "51.81.154.109";
    ipv6 = "2604:2dc0:200:156d::1";
    ipv6Gateway = "2604:2dc0:200:15ff:ff:ff:ff:ff";
    # The public NIC (eno1); eno2 is OVH's private network, unplugged.
    mac = "d0:50:99:dd:fc:74";
    disk = "/dev/disk/by-id/nvme-Micron_7450_MTFDKCC960TFR_24404BE87314";
    # Cold spare: nvme-Micron_7450_MTFDKCC960TFR_24404BE7C94D.
    storage = "archive";
    slot = 6;
  };

}
