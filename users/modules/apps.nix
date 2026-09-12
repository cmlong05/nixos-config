# 用户级应用包（chen 与员工共用）
#
# 判据：这里放「**人**要用」的应用 —— 两个用户共用的放这里；
# 只有某个人要的放 users/<name>/apps.nix。
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
