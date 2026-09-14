# 便携盘安装（portable-chen）—— 一次安装跨 3 台机器
#
# 硬件全部下放到每台机器的 specialisation（machines/chen-*.nix：硬件探测 +
# 手写尾巴）。基础系统只保留盘挂载（./disk.nix，3 台机器共用同一块盘），
# 不带任何硬件兜底 —— 不选 specialisation 进不了桌面。
{ ... }:

{
  imports = [
    # 挂载（跟盘走；3 台机器共用同一块移动盘）
    ./disk.nix
    # 系统服务（本安装特有）
    ./virtualisation.nix                     # podman
    # 系统领域（各安装共用）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/ssh.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（chen）
    ./users.nix
    # 机器变体（specialisation）
    ./machine_spe.nix
  ];

  networking.hostName = "portable-chen";

  system.stateVersion = "26.05";
}
