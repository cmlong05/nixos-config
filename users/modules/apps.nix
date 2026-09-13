# 用户级应用包（所有用户共用）
#
# home-manager 用全局 pkgs（useGlobalPkgs = true），不再单独取 nixpkgs。
{ config, pkgs, pkgs-unstable, ... }:

{
  home.packages =
    (with pkgs; [
      # 通用 GUI
      chromium
      kdePackages.kate
      kdePackages.krdc
      kdePackages.fcitx5-configtool
      telegram-desktop
      vscodium

      # 终端与办公
      zellij
      libreoffice-qt
      hunspell                 # 拼写检查（供 LibreOffice）
      hunspellDicts.en_US
    ])
    # 需要新版本的包单独从 nixpkgs-unstable 取
    ++ [ pkgs-unstable.safeeyes ];
}
