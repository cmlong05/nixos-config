# 便携盘安装（portable-chen）—— 一次安装跨 3 台机器
#
# 基础系统 = 硬件无关的最小兜底（读盘 + 固件 + 双微码），任何机器都能进桌面；
# 每台机器是一个 specialisation，指向 machines/ 里的完整组件组合。
{ ... }:

{
  imports = [
    # 兜底底座（硬件无关）
    ../../hardware/storage-usb.nix           # 读盘（USB 根盘）
    ../../hardware/storage-nvme.nix          # 读盘（内盘 NVMe）
    ../../hardware/common.nix                # 图形 + 固件 + 架构
    ../../hardware/cpu-amd.nix               # 双微码（任何机器都能进）
    ../../hardware/cpu-intel.nix
    # 系统服务（本安装特有）
    ./virtualisation.nix                     # podman
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
    # 机器变体（specialisation）
    ./machine_spe.nix.nix
  ];

  networking.hostName = "portable-chen";

  system.stateVersion = "26.05";
}
