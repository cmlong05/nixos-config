# 盘：chen 的移动硬盘（3 台机器共用同一块盘）—— 本 os-disk 的「盘」部分
# 只放"跟盘走"的行：fileSystems（按 UUID，随盘不随机）。
# 读盘所需内核模块见各 machines/<机器>/hardware-configuration.nix（availableKernelModules）。
#
# 这里**故意没有 swapDevices**：USB 盘上做磁盘 swap 会带来内核级缺页失败、
# 与根文件系统抢同一条 UAS 队列、以及不可观测的磨损 → 改用 zram，见 ./swap.nix。
# 盘上的 8.8G swap 分区（UUID 30cce407-1bd3-41c3-9c69-f02fa8bf9bb9）保留不启用，
# 应急时仍可手工 `sudo swapon /dev/disk/by-uuid/30cce407-…`。
# ⚠️ 这块盘（含该分区）被 3 台机器共用一份 → 永远不要配休眠/resumeDevice：
#    A 机写下的内存镜像若在 B 机 resume，会得到错乱的内存。
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
}
