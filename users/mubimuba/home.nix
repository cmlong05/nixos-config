# Home Manager 配置入口（用户 mubimuba）
{ config, pkgs, ... }:

{
  imports = [
    # 员工机沿用同一套 shell
    ../modules/shell.nix
    # 用户级 GUI 应用
    ../modules/apps.nix
    # 仅 mubimuba 个人的应用（员工机 msi-wd）
    ./apps.nix
    # 用户级 Flatpak
    ./flatpak.nix
    # 桌面上的 office 网络文件夹链接（smb://10.10.10.9/Operation/Product/）
    ./desktop.nix
    # 不引入 llm.nix：员工机不装 dsh / reasonix（也就不用拉取 llm-agents 输入）
  ];

  # 无需手写 home.username / home.homeDirectory：由 flake.nix 的 mkHome 注入
  # （standalone 模式下没有 NixOS 集成来推导它们）。
  #
  # 激活方式：`nh home switch`。mubimuba 没有 wheel 也不需要提权 ——
  # 用户级构建只写自己的家目录和用户 profile。
  # standalone 模式下会真的把 home-manager CLI 装进用户环境
  programs.home-manager.enable = true;
}
