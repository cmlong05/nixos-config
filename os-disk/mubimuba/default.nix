# 主机 mubimuba（员工机，同款硬件：AMD CPU + NVIDIA 3060）
# 接线点：身份(hardware.nix) + 挂载(disk.nix) + 系统领域(shared) + 用户点名单(users.nix)
# 注意：本机不开蓝牙、不开 podman（不 import 对应模块），hostName 为 mubimuba。
{ ... }:

{
  imports = [
    # 硬件探测（机级，装机时用 nixos-generate-config 生成后拆入）
    ./hardware.nix
    # 挂载（跟盘走；员工机内盘）
    ./disk.nix
    # 共享系统领域（作者机与员工机一致的部分）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/hardware-common.nix
    ../../shared/gpu-nvidia.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（bumooby 管理员 + mubimuba 员工）
    ./users.nix
  ];

  networking.hostName = "mubimuba"; # 员工机主机名（与 flake 配置名一致，方便 nh 按主机名取配置）

  system.stateVersion = "26.05"; # Did you read the comment?
}
