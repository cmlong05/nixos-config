# 便携盘安装（portable-chen）—— AMD+NVIDIA 台式机 / Intel 笔电 共用这一块移动硬盘
#
# 接线点：硬件(hardware/machines.nix) + 挂载(disk.nix) + 系统领域(shared/) + 用户点名单(users.nix)
# 这里不放应用：系统级基础工具在 shared/packages.nix，chen 个人的应用在 users/chen/。
# 机器 ↔ 硬件组合的映射见 hardware/machines.nix。
{ ... }:

let
  machines = import ../../hardware/machines.nix;
in
{
  imports = machines.portable-base ++ [
    # 系统服务（本安装特有）
    ./virtualisation.nix         # podman
    # 挂载（跟盘走）
    ./disk.nix
    # 系统领域（各安装共用）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（chen）
    ./users.nix
  ];

  networking.hostName = "portable-chen"; # 便携盘用固定主机名（换机器不变）

  # 硬件变体：便携盘 3 台机器的差异只有 GPU（见 hardware/machines.nix）。
  # inheritParentConfig 默认 true = 基础配置 + 这里的增量；不选变体就进基础系统（任何机器都能进桌面）。
  specialisation.nvidia.configuration.imports = machines.nvidia;
  specialisation.intel.configuration.imports  = machines.intel;

  system.stateVersion = "26.05";
}
