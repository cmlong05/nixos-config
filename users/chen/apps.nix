# 仅 chen 个人的 Nix 应用（不进 users/modules/ —— 那里是 chen 与员工共用的）
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    li-ri
  ];
}
