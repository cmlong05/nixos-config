# 盘：chen 的移动硬盘（3 台机器共用同一块盘）—— 本 os-disk 的「盘」部分
# 只放"跟盘走"的行：fileSystems + swapDevices（按 UUID，随盘不随机）。
# 硬件探测见 hardware/portable-chen.nix。
{ ... }:

{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/086bf1f6-bdb7-4f9f-b967-bd25fbf82295";
      fsType = "btrfs";
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/086bf1f6-bdb7-4f9f-b967-bd25fbf82295";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/086bf1f6-bdb7-4f9f-b967-bd25fbf82295";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/534A-47F7";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/30cce407-1bd3-41c3-9c69-f02fa8bf9bb9"; }
    ];
}
