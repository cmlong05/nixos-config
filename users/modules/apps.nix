# 用户级应用包（所有用户共用）—— 这就是"每个用户都要的基础软件"的统一位置。
#
# 每个用户的 users/<name>/home.nix 都 import 本文件：改一处、各人在自己家目录里生效
# （新架构下系统不再替用户激活家目录，各自跑 `nh home switch`）。
# 注意：要"保证所有用户都有、用户改不掉"的东西请放系统级 shared/packages.nix。
#
# pkgs 与 pkgs-unstable 都由 flake.nix 的 mkHome 注入（standalone 没有 useGlobalPkgs，
# 但注入的 pkgs 与系统同源于 flake.lock，所以拿到的是同一批 store path）。
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
