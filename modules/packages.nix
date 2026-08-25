# 系统级软件包
{ config, pkgs, ... }:

{
  # 所有系统级软件包都放在这里
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    python3
    vim
    wireguard-tools
    wget
    zellij
  ];
}
