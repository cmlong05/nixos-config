# 主机 nixos（作者日常机，移动硬盘安装）
# 接线点：身份(hardware.nix) + 挂载(disks) + 系统领域(shared) + 用户点名单(users.nix)
# 这里不放应用：系统级基础工具在 shared/packages.nix，chen 个人的应用在 users/chen/。
{ ... }:

{
  imports = [
    # 硬件探测（机级）
    ./hardware.nix
    # 机器差异：本机开蓝牙 / podman
    ./bluetooth.nix
    ./virtualisation.nix
    # 挂载（跟盘走）
    ../../disks/portable-ssd.nix
    # 共享系统领域（作者机与员工机一致的部分）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/gpu-common.nix
    ../../shared/gpu-nvidia.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（chen）
    ./users.nix
  ];

  networking.hostName = "nixos"; # 作者机主机名

  system.stateVersion = "26.05"; # Did you read the comment?
}
