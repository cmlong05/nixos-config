# 用户级应用包（GUI 应用）
#
# 说明：wechat 由 overlays/wechat.nix 覆盖后经全局 pkgs 提供
# （home-manager useGlobalPkgs = true，见 flake.nix）。
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    chromium
    kdePackages.kate
    kdePackages.fcitx5-configtool
    vscodium
    wechat
    karere # whatsapp
  ];
}
