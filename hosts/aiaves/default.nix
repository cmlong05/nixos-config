# 主机 aiaves（chen 的 Intel 笔电：Core Ultra 9 285H + 内显 i915）
# 与 host nixos 并存，共用同一块移动硬盘（disks/portable-ssd.nix）。
# 接线点：身份(hardware.nix) + 挂载(disks) + 系统领域(shared) + 用户点名单(users.nix)
{ config, pkgs, ... }:

{
  imports = [
    # 硬件探测（机级）
    ./hardware.nix
    # 机器差异：本机开蓝牙 / podman
    ./bluetooth.nix
    ./virtualisation.nix
    # 挂载（跟盘走；与 nixos 共用同一块移动硬盘）
    ../../disks/portable-ssd.nix
    # 共享系统领域
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    # 显卡：通用部分 + Intel 内显（本机无独显）
    ../../shared/gpu-common.nix
    ../../shared/gpu-intel.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（chen）
    ./users.nix
  ];

  networking.hostName = "aiaves"; # 本机主机名

  # chen 的个人软件（与 nixos 对齐）
  environment.systemPackages = with pkgs; [
    vim
    li-ri
  ];
  services.flatpak.packages = [
    "com.tux4kids.tuxmath"
    "com.qq.QQ"
  ];

  system.stateVersion = "26.05";
}
