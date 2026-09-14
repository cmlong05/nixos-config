# 仅 mubimuba 个人的 Nix 应用（员工机 msi-wd）
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gimp                 # 图像处理软件（GIMP）
  ];
}
