# Home Manager 配置入口（用户 chen，便携盘 portable-chen）
{ config, pkgs, inputs, ... }:

{
  imports = [
    ../modules/shell.nix
    ../modules/apps.nix
    ../modules/llm.nix
    # 仅 chen 个人的应用
    ./apps.nix
    ./flatpak.nix
  ];

  # 无需手写 home.username / home.homeDirectory：由 flake.nix 的 mkHome 注入
  # （standalone 模式下没有 NixOS 集成来推导它们）。
  #
  # 激活方式：`nh home switch`（不需要 sudo；系统侧不再激活家目录，
  # 所以本文件的改动只在这条命令跑完后生效）。

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "26.05";

  # Let Home Manager install and manage itself.
  # standalone 模式下这个开关会真的把 home-manager CLI 装进用户环境
  # （作为 NixOS 子模块时它是空操作），用于 home-manager generations / --rollback。
  programs.home-manager.enable = true;
}
