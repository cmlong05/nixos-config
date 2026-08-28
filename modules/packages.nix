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
    # SafeEyes 休息提醒：用 unstable 的 3.5（与 flathub 同版本，config_version 6.0.5 迁移无版本合并）。
    # nixpkgs 把 pywayland/croniter 列为可选依赖，KDE Wayland 下缺 pywayland 会让 smartpause 插件
    # 启动崩溃（ModuleNotFoundError）→ 调度器不启动 → 托盘“无可用的休息”，故显式补上。
    # 注意：unstable 的 python3Packages(=py3.14) 集合里没有 safeeyes 属性，要用顶层 safeeyes。
    (safeeyes.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ [
        python3Packages.pywayland
        python3Packages.croniter
      ];
    }))
  ];
in
{
  environment.systemPackages = stablePackages ++ unstablePackages;
}
