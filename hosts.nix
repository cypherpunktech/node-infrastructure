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
# Each node is named after a cypherpunk. Taken: finney, may. Next up:
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

  may = {
    # OVH SYS-3, three 4 TB hard drives: pruned, so its 12 GiB database
    # lives in the page cache and the disks barely matter.
    location = "Vint Hill, US East";
    coordinates = [
      38.75
      (-77.67)
    ];
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFdJ6FyNN39UMchE7ouZa3R1iTN+g00M8MlvcMyxRn9";
    ipv4 = "51.81.46.3";
    ipv6 = "2604:2dc0:100:2003::1";
    ipv6Gateway = "2604:2dc0:100:20ff:ff:ff:ff:ff";
    mac = "d0:50:99:d6:c6:cc";
    disk = "/dev/disk/by-id/ata-HGST_HUS726T4TALA6L1_V6JHZYKS";
    # Cold spares: ata-HGST_HUS726T4TALA6L1_V6G0Y7YN, _V6JHPEWS.
    storage = "pruned";
    slot = 8;
  };
}
