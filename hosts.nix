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
# Each node is named after a cypherpunk. Taken: finney, may, hughes, chaum, szabo, dai, cohen,
# zimmermann, diffie, sassaman, gilmore, back, milhon, barlow, hellman.
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
    # OVH SYS-3.
    location = "Vint Hill, US East";
    coordinates = [
      38.75
      (-77.67)
    ];
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMF3aetu5cAV129uoouuxWjcsk2pxQ50WkzqXTPSayR";
    ipv4 = "135.148.169.201";
    ipv6 = "2604:2dc0:100:46c9::1";
    ipv6Gateway = "2604:2dc0:100:46ff:ff:ff:ff:ff";
    mac = "d0:50:99:fb:17:1b";
    disk = "/dev/disk/by-id/nvme-SAMSUNG_MZQLB960HAJR-00007_S437NC0R703868";
    # Cold spare: nvme-SAMSUNG_MZQLB960HAJR-00007_S437NC0R703860.
    storage = "archive";
    slot = 8;
  };

  hughes = {
    # Vultr bare metal, E-2286G. IPv6 by router advertisement.
    location = "Paris, France";
    coordinates = [
      48.86
      2.35
    ];
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9jb96/xReCjLWOmaU8rbIJJqISyl/oGg8inL8Rs45F";
    ipv4 = "217.69.4.15";
    ipv6 = "2001:19f0:6801:1ad8:3eec:efff:febc:8da4";
    mac = "3c:ec:ef:bc:8d:a4";
    disk = "/dev/disk/by-id/ata-INTEL_SSDSC2KG960G8_PHYG144400BL960CGN";
    # Cold spare: ata-INTEL_SSDSC2KG960G8_PHYG1444001Y960CGN.
    storage = "archive";
    slot = 10;
  };

  chaum = {
    # Vultr bare metal, E-2286G. IPv6 by router advertisement.
    location = "Singapore";
    coordinates = [
      1.35
      103.82
    ];
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMw2fMc/nE8e1nBByzhc6pI0r2lB7+Ot529HQfnNyLdr";
    ipv4 = "45.32.111.221";
    ipv6 = "2401:c080:1400:684d:3eec:efff:feb9:c940";
    mac = "3c:ec:ef:b9:c9:40";
    disk = "/dev/disk/by-id/ata-INTEL_SSDSC2KG960G8_PHYG1261000N960CGN";
    # Cold spare: ata-INTEL_SSDSC2KG960G8_PHYG126101YB960CGN.
    storage = "archive";
    slot = 12;
  };

  szabo = {
    # Vultr bare metal, E-2286G. IPv6 by router advertisement.
    location = "São Paulo, Brazil";
    coordinates = [
      (-23.55)
      (-46.63)
    ];
    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjo9lH3FIZvcqfGMLnHXokg65VZQounKVLX54TFsn1u";
    ipv4 = "216.128.171.195";
    ipv6 = "2001:19f0:b800:227f:3eec:efff:febc:8cb2";
    mac = "3c:ec:ef:bc:8c:b2";
    disk = "/dev/disk/by-id/ata-INTEL_SSDSC2KG960G8_PHYG144400A2960CGN";
    # Cold spare: ata-INTEL_SSDSC2KG960G8_PHYG1446005U960CGN.
    storage = "archive";
    slot = 14;
  };

  dai = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Tokyo, Japan";
    coordinates = [
      35.68
      139.69
    ];
    hostKey = "";
    ipv4 = "34.104.226.177";
    mac = "42:01:0a:92:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 16;
  };

  cohen = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Mumbai, India";
    coordinates = [
      19.08
      72.88
    ];
    hostKey = "";
    ipv4 = "35.244.47.80";
    mac = "42:01:0a:a0:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 18;
  };

  zimmermann = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Sydney, Australia";
    coordinates = [
      (-33.87)
      151.21
    ];
    hostKey = "";
    ipv4 = "34.151.153.36";
    mac = "42:01:0a:98:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 20;
  };

  diffie = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Johannesburg, South Africa";
    coordinates = [
      (-26.2)
      28.05
    ];
    hostKey = "";
    ipv4 = "34.35.70.171";
    mac = "42:01:0a:da:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 22;
  };

  sassaman = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Frankfurt, Germany";
    coordinates = [
      50.11
      8.68
    ];
    hostKey = "";
    ipv4 = "34.185.255.47";
    mac = "42:01:0a:9c:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 0;
  };

  gilmore = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Toronto, Canada";
    coordinates = [
      43.65
      (-79.38)
    ];
    hostKey = "";
    ipv4 = "34.130.110.3";
    mac = "42:01:0a:bc:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 2;
  };

  back = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "London, UK";
    coordinates = [
      51.51
      (-0.13)
    ];
    hostKey = "";
    ipv4 = "34.39.40.194";
    mac = "42:01:0a:9a:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 4;
  };

  milhon = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Hong Kong";
    coordinates = [
      22.32
      114.17
    ];
    hostKey = "";
    ipv4 = "34.92.10.23";
    mac = "42:01:0a:aa:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 7;
  };

  barlow = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Doha, Qatar";
    coordinates = [
      25.29
      51.53
    ];
    hostKey = "";
    ipv4 = "34.18.77.126";
    mac = "42:01:0a:d4:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 9;
  };

  hellman = {
    # Google Cloud e2-medium, IPv4 only for now.
    location = "Querétaro, Mexico";
    coordinates = [
      20.59
      (-100.39)
    ];
    hostKey = "";
    ipv4 = "34.51.89.91";
    mac = "42:01:0a:e0:00:02";
    disk = "/dev/disk/by-id/google-persistent-disk-0";
    storage = "pruned";
    slot = 11;
  };
}
