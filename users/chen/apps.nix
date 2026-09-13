# 仅 chen 个人的 Nix 应用
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    li-ri
  ];
}
