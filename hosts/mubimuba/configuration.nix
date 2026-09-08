# 主机 mubimuba（员工机，同款硬件：AMD CPU + NVIDIA 3060）
# 入口模块：机器差异在本目录（users），共享领域配置在 ../../modules/，
# 员工用户级配置在 ../../home/employee.nix。
# 注意：本机不开蓝牙、不开 podman（不 import 对应模块），hostName 为 mubimuba。
{ ... }:

{
  imports =
    [ # 员工机硬件配置：装机时用 nixos-generate-config 生成后替换本目录占位文件。
      ./hardware-configuration.nix
      # 共享领域模块（作者机与员工机一致的部分）
      ../../modules/boot.nix
      ../../modules/networking.nix
      ../../modules/nix.nix
      ../../modules/locale.nix
      ../../modules/desktop.nix
      ../../modules/gpu.nix
      ../../modules/flatpak.nix
      ../../modules/packages.nix
      # 用户账户（bumooby 管理员 + mubimuba 员工）
      ./users.nix
    ];

  networking.hostName = "mubimuba"; # 员工机主机名（与 flake 配置名一致，方便 nh 按主机名取配置）

  # 员工机 home-manager：只有员工 mubimuba（见 home/employee.nix）。
  # 管理员 bumooby 仅作为系统账户用于维护，不额外配桌面 home。
  home-manager.users.mubimuba = ../../home/employee.nix;

  system.stateVersion = "26.05"; # Did you read the comment?
}
