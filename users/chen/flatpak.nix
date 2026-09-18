# 仅 chen 个人的 Flatpak 应用
#

{ ... }:

{
  imports = [
    ../modules/flatpak.nix
  ];

  services.flatpak.packages = [
    "com.tux4kids.tuxmath"
    "com.qq.QQ"
  ];
}
