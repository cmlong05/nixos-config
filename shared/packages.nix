# 系统级软件包（各主机共享的机级基础软件）
#
# 判据：这里放"**机器**需要"而不是"某个人需要"的东西 —— 尤其是 root/sudo
# 也要能用、或救援 TTY / 登录前就要有的工具。
# 某个人自己的应用请放用户维度（users/<name>/），别放这里，也别放 host。
{ config, pkgs, pkgs-unstable, ... }:

let
  # 常规软件：来自 nixos-26.05 稳定分支
  stablePackages = with pkgs; [
    vim              # root/sudo 改配置、救援 TTY 都要用 → 系统级
    git
    python3
    wireguard-tools
    wget
    zellij
    libreoffice-qt
    hunspell
    hunspellDicts.en_US
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
