# Home Manager 配置入口（员工用户 mubimuba，员工机 mubimuba 主机专用）
{ config, pkgs, ... }:

{
  imports = [
    # 员工机沿用同一套 shell（bash + direnv）
    ./modules/shell.nix
    # 用户级 GUI 应用（chromium / kate / krdc / fcitx5-configtool / telegram / vscodium）
    ./modules/apps.nix
    # 不引入 llm.nix：员工机不装 dsh / reasonix（也就不用拉取 llm-agents 输入）
  ];

  home.username = "mubimuba";
  home.homeDirectory = "/home/mubimuba";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
