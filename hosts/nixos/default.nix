# 便携盘 host（AMD+NVIDIA 台式机 / Intel 笔电 共用这一块移动硬盘）
#
# 接线点：身份(hardware.nix) + 挂载(disks) + 系统领域(shared) + 用户点名单(users.nix)
# 这里不放应用：系统级基础工具在 shared/packages.nix，chen 个人的应用在 users/chen/。
#
# 硬件差异不用「多 host」，而用 specialisation：基础系统硬件无关（插哪台都能进桌面），
# 开机菜单里再选 nvidia / intel 变体 —— 换机器零命令。
{ ... }:

{
  imports = [
    # 硬件探测（硬件无关，可跨机器）
    ./hardware.nix
    # 机器差异：本机开蓝牙 / podman
    ./bluetooth.nix
    ./virtualisation.nix
    # 挂载（跟盘走）
    ../../disks/portable-ssd.nix
    # 共享系统领域
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/hardware-common.nix   # 图形底座 + 固件 + 双微码（厂商无关）
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（chen）
    ./users.nix
  ];

  networking.hostName = "nixos"; # 便携盘用固定主机名（换机器不变）

  # 开机菜单里的硬件变体。inheritParentConfig 默认 true = 基础配置 + 这里的增量。
  # 不选变体时跑基础系统：任何机器都能进桌面（NVIDIA 机会退到 nouveau）。
  specialisation.nvidia.configuration.imports = [ ../../shared/gpu-nvidia.nix ];
  specialisation.intel.configuration.imports  = [ ../../shared/gpu-intel.nix ];

  system.stateVersion = "26.05";
}
