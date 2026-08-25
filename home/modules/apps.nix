# 用户级应用包（GUI 应用）
#

# 不再从 nixpkgs 安装（home-manager useGlobalPkgs = true）。
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    chromium
    kdePackages.kate
    kdePackages.fcitx5-configtool
    vscodium
  ];
}
