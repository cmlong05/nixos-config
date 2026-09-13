# 员工机安装（固定硬件：AMD 3600 + NVIDIA 3060）
# 接线点：硬件(hardware/) + 挂载(disk.nix) + 系统领域(shared/) + 用户点名单(users.nix)
# 注意：本机不开蓝牙、不开 podman（不 import 对应模块），hostName 为 msi-wd。
{ ... }:

{
  imports = [
    # 硬件：探测（固定 AMD）+ 底座 + NVIDIA 驱动
    ../../hardware/probe-msi-wd.nix  # 员工机探测（装机时生成后拆入）
    ../../hardware/common.nix    # 图形底座 + 固件 + 双微码（厂商无关）
    ../../hardware/gpu-nvidia.nix
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
