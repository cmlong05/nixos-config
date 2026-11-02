# 仅 chen 个人的 Nix 应用
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    li-ri
    telegram-desktop
  ];

  programs.microsoft-edge = {
    enable = true;
    # 与 Firefox 的 Homepage.StartPage = "previous-session" 对应
    commandLineArgs = [ "--restore-last-session" ];
  };
}
