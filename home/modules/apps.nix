# 用户级应用包（GUI 应用）
#
# 说明：微信改用 nixpkgs 自带的 wechat-uos（UOS 商店 deb 版，4.x 同源）。
# 原 AppImage 版 wechat 及其下载源修复 overlay 仍保留在 overlays/wechat.nix，
# 想换回时把下面 wechat-uos 改回 wechat 即可（home-manager useGlobalPkgs = true）。
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    chromium
    kdePackages.kate
    kdePackages.fcitx5-configtool
    vscodium
    wechat-uos # 微信（UOS 商店版 4.x）
    karere # whatsapp
  ];
}
