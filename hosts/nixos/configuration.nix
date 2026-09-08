# 主机 nixos（作者日常机）
# 入口模块：机器差异在本目录（hardware/bluetooth/virtualisation/users），
# 共享领域配置在 ../../modules/，用户级配置在 ../../home/。
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan（本机生成，勿改）。
      ./hardware-configuration.nix
      # 机器差异：本机开蓝牙 / podman
      ./bluetooth.nix
      ./virtualisation.nix
      # 共享领域模块（作者机与员工机一致的部分）
      ../../modules/boot.nix
      ../../modules/networking.nix
      ../../modules/nix.nix
      ../../modules/locale.nix
      ../../modules/desktop.nix
      ../../modules/gpu.nix
      ../../modules/flatpak.nix
      ../../modules/packages.nix
      # 用户账户（chen）
      ./users.nix
    ];

  networking.hostName = "nixos"; # 作者机主机名

  # 作者机专属软件（员工机不需要）：已从共享 modules/packages.nix 中移出
  environment.systemPackages = with pkgs; [
    vim
    li-ri
  ];
  # 作者机专属 flatpak 应用（员工机不需要）：已从共享 modules/flatpak.nix 中移出
  services.flatpak.packages = [ "com.tux4kids.tuxmath" ];

  # 作者机 home-manager：用户 chen
  home-manager.users.chen = ../../home/home.nix;

  system.stateVersion = "26.05"; # Did you read the comment?
}
