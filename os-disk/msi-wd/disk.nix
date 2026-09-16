# ⚠️⚠️ 员工机内盘模板（勿直接使用！）⚠️⚠️
# 本文件由作者机 disk.nix 复制而来，仅用于仓库求值/CI。
# 员工机磁盘 UUID 与作者机必然不同，装 NixOS 时必须在员工机上执行：
#   nixos-generate-config --root /mnt
# 挂载行（fileSystems + swapDevices）跟盘走，放本文件；
# 硬件探测部分用 --no-filesystems 直接生成，放 machines/employee-3600/hardware-configuration.nix。
# 再 nixos-install --flake .#msi-wd（详见 DEPLOY-INSTALL.md；日常维护见 DEPLOY-MAINT.md）
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
