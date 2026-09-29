# One disk, one ext4 root, and a bootloader for BIOS and for UEFI alike.
#
# No RAID: a node is rebuilt from this repository and a snapshot in about an
# hour, which is all a mirror would save. hil-1's mdraid root also never
# assembled in the systemd initrd, twice, with nothing left to say why. A
# host's other disks are cold spares: when the first dies, point `disk` at
# one and reinstall.
{ host, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = host.disk;
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
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  # disko points grub at the disk; efiSupport adds the UEFI install beside it.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "sd_mod"
  ];
}
