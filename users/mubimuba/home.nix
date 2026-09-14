# Home Manager 配置入口（用户 mubimuba）
{ config, pkgs, ... }:

{
  imports = [
    # 员工机沿用同一套 shell（bash + direnv）
    ../modules/shell.nix
    # 用户级 GUI 应用（chromium / kate / krdc / fcitx5-configtool / telegram / vscodium）
    ../modules/apps.nix
    # 仅 mubimuba 个人的应用（员工机 msi-wd）
    ./apps.nix
    # 不引入 llm.nix：员工机不装 dsh / reasonix（也就不用拉取 llm-agents 输入）
  ];

  # 无需手写 home.username / home.homeDirectory：本文件经 home-manager.users.mubimuba
  # 挂载时自动从 users.users.mubimuba 注入（单一事实来源在 users/mubimuba/default.nix）。

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
