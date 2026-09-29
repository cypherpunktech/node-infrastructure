# Every disk of the host mirrored (RAID 1) under one ext4 root. Each disk
# also carries its own bootloader, for BIOS and for UEFI, so the machine boots
# whichever firmware it has and whichever disk survives.
{ lib, host, ... }:
let
  esp = i: if i == 0 then "/boot" else "/boot-${toString i}";
in
{
  disko.devices = {
    disk = lib.listToAttrs (
      lib.imap0 (
        i: device:
        lib.nameValuePair "disk${toString i}" {
          type = "disk";
          inherit device;
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "1M";
                type = "EF02";
              };
              esp = {
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = esp i;
                  mountOptions = [ "umask=0077" ];
                };
              };
              raid = {
                size = "100%";
                content = {
                  type = "mdraid";
                  name = "root";
                };
              };
            };
          };
        }
      ) host.disks
    );
    mdadm.root = {
      type = "mdadm";
      level = 1;
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = lib.imap0 (i: device: {
      devices = [ device ];
      path = esp i;
    }) host.disks;
    # disko fills this in for every EF02 partition, which grub turns into a
    # third mirror installing both disks from the first disk's /boot.
    devices = lib.mkForce [ ];
  };
  # mdmonitor refuses to start without somewhere to report to.
  boot.swraid.mdadmConf = "MAILADDR root";
  # Loaded, not merely available: the array never assembled on first boot
  # with raid1 left to on-demand loading, and nixpkgs' own systemd-initrd
  # RAID test loads its level the same way.
  boot.initrd.kernelModules = [ "raid1" ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "sd_mod"
  ];
}
