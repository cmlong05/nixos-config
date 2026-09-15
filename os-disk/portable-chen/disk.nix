# 盘：chen 的移动硬盘（3 台机器共用同一块盘）—— 本 os-disk 的「盘」部分
# 只放"跟盘走"的行：fileSystems（按 UUID，随盘不随机）+ 读这块盘所需的 initrd 模块。
#
# 读盘模块为什么在这里、而不是各 machines/<机器>/hardware-configuration.nix：
# 「能不能挂上这块盘」是**盘**的属性（换哪台机器都一样），机器维度只管 CPU/GPU 差异。
# 实测（26.05）：NixOS 默认 initrd 已带主控/SCSI 层（xhci-pci、ehci-pci、usbhid、
# sd_mod、ahci、nvme）和 btrfs（由 fileSystems 自动带上），**唯独没有 USB 大容量存储类
# 驱动** —— 缺了 uas/usb-storage，基础条目就挂不上根、起不来（变体以前靠各自
# hardware-configuration.nix 里那两行才起得来）。补上之后，基础系统就是可引导的
# **控制台救援入口**（没有显卡驱动 → 没桌面，但修系统足够了）。
#
# 这里**故意没有 swapDevices**：USB 盘上做磁盘 swap 会带来内核级缺页失败、
# 与根文件系统抢同一条 UAS 队列、以及不可观测的磨损 → 改用 zram，见 ./swap.nix。
# 盘上的 8.8G swap 分区（UUID 30cce407-1bd3-41c3-9c69-f02fa8bf9bb9）保留不启用，
# 应急时仍可手工 `sudo swapon /dev/disk/by-uuid/30cce407-…`。
# ⚠️ 这块盘（含该分区）被 3 台机器共用一份 → 永远不要配休眠/resumeDevice：
#    A 机写下的内存镜像若在 B 机 resume，会得到错乱的内存。
{ ... }:

{
  boot.initrd.availableKernelModules = [
    # USB 主控（USB3 / USB2）+ USB 键盘：默认集里已有，显式写出免得依赖别人的默认值
    "xhci_pci"
    "ehci_pci"
    "usbhid"
    # USB 大容量存储类驱动 —— 就是默认集里缺的那两块
    "uas" # 本盘桥：JMicron 152d，USB Attached SCSI
    "usb_storage" # 通用兜底：别的硬盘盒 / 别的接口
    "sd_mod" # SCSI 磁盘层
  ];

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
