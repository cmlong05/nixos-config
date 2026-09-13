# 员工机安装（msi-wd）—— 固定硬件 AMD 3600 + NVIDIA 3060
# 接线点：硬件(hardware/machines.nix) + 挂载(disk.nix) + 系统领域(shared/) + 用户点名单(users.nix)
# 注意：本机不开蓝牙、不开 podman（不 import 对应模块），hostName 为 msi-wd。
{ ... }:

let
  machines = import ../../hardware/machines.nix;
in
{
  imports = machines.msi-wd ++ [
    # 挂载（跟盘走；员工机内盘）
    ./disk.nix
    # 系统领域（各安装共用）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（bumooby 管理员 + mubimuba 员工）
    ./users.nix
  ];

  networking.hostName = "msi-wd"; # 员工机主机名（与 flake 配置名一致，方便 nh 按主机名取配置）

  system.stateVersion = "26.05"; # Did you read the comment?
}
