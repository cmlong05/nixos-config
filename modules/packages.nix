# 系统级软件包
{ config, pkgs, pkgs-unstable, ... }:

let
  # 常规软件：来自 nixos-26.05 稳定分支
  stablePackages = with pkgs; [
    git
    python3
    vim
    wireguard-tools
    wget
    zellij
    li-ri
  ];

  # 从 nixos-unstable 单独取的软件（需要新版本，或需要补 nixpkgs 没默认装的可选依赖）。
  # 这类包集中放这里，与上面的稳定包分开，便于区分升级来源。
  unstablePackages = with pkgs-unstable; [
    safeeyes
  ];
in
{
  environment.systemPackages = stablePackages ++ unstablePackages;
}
