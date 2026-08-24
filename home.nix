{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "chen";
  home.homeDirectory = "/home/chen";

  # DeepSeek Harness (dsh) — 声明式安装，与 nix run github:numtide/llm-agents.nix#dsh 同一来源
  home.packages = [
    inputs.llm-agents.packages.${pkgs.system}.dsh
  ];

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
