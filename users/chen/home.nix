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

  # 无需手写 home.username / home.homeDirectory：本文件经 home-manager.users.chen
  # 挂载时，home-manager 的 NixOS 集成会自动从 users.users.chen 注入用户名与家目录
  # （见 home-manager 源码 nixos/common.nix），避免在两处重复维护用户名。

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
  programs.home-manager.enable = true;
}
