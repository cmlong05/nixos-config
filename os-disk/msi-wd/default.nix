# 员工机安装（msi-wd）—— 固定硬件，见 machines/employee-3600/
{ ... }:

{
  imports = [
    ../../machines/employee-3600            # 机器（生成硬件 + 手写尾巴）
    # 挂载（跟盘走；员工机内盘）
    ./disk.nix
    # 系统领域（各安装共用）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/ssh.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（bumooby 管理员 + mubimuba 员工）
    ./users.nix
  ];

  networking.hostName = "msi-wd";

  system.stateVersion = "26.05";
}
