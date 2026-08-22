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


  # 浏览器相关配置
  # Install firefox.
  programs.firefox.enable = true;
}
