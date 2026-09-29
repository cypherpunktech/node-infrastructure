# The fleet. Adding a node is adding an entry here, then running
# nixos-anywhere against it once.
#
# storage: "archive" serves the whole chain to peers syncing from genesis;
#          "pruned" keeps what consensus needs (12 GiB) and serves recent blocks.
# slot:    the UTC hour the node pulls updates. Staggered, so a bad release
#          reaches one slot's nodes and can be reverted before the next.
{
  hil-1 = {
    # OVH SYS-3, Hillsboro (US West).
    ipv4 = "51.81.154.109";
    ipv6 = "2604:2dc0:200:156d::1";
    ipv6Gateway = "2604:2dc0:200:15ff:ff:ff:ff:ff";
    # The public NIC (eno1); eno2 is OVH's private network, unplugged.
    mac = "d0:50:99:dd:fc:74";
    disks = [
      "/dev/disk/by-id/nvme-Micron_7450_MTFDKCC960TFR_24404BE87314"
      "/dev/disk/by-id/nvme-Micron_7450_MTFDKCC960TFR_24404BE7C94D"
    ];
    storage = "archive";
    slot = 6;
  };
}
