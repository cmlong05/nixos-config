# Nix 相关配置：缓存源、flake 特性、nh 清理、非自由软件
{ config, pkgs, ... }:

{
  # custom binary caches
  nix.settings = {
    substituters = [
      # cache mirror located in China
      # USTC：2026-08 验证可用（此前注释"Access denied"已过时）
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      # status: https://mirror.sjtu.edu.cn/
      # SJTU 对新路径同步不及时（narinfo 已同步但 nar 文件缺失/不完整，下载报 HTTP/2 流中断）
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
  };

  # flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 启用 nh 并配置自动清理
  # 注意：programs.nh.flake 属于机器差异（每台机器仓库位置可能不同），
  # 在各主机 configuration.nix 中设置。
  programs.nh = {
    enable = true;
    clean.enable = true;
    # 清理策略：保留7天内和最近5个 generation
    clean.extraArgs = "--keep-since 7d --keep 5";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
