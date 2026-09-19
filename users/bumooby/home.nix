# Home Manager 配置入口（用户 bumooby，员工机 msi-wd 管理员）
{ config, pkgs, ... }:

{
  imports = [
    # 与 mubimuba 完全同一套用户级基线：shell（bash + direnv）+ 共享应用包
    ../modules/shell.nix
    ../modules/apps.nix
  ];

  # 无需手写 home.username / home.homeDirectory：由 flake.nix 的 mkHome 注入
  # （standalone 模式下没有 NixOS 集成来推导它们）；home.stateVersion 同。

  # standalone 模式下这个开关才会真的把 home-manager CLI 装进用户环境
  # （作为 NixOS 子模块时它是空操作），用于 home-manager generations / --rollback。
  programs.home-manager.enable = true;
}
