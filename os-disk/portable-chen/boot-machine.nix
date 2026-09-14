# 方案 B（部署期选择）：`nh os switch` 装完 bootloader 后，把 systemd-boot 的
# 默认条目指向「本机」对应的 specialisation 条目。
#
# 为什么必须做：基础系统条目的 initrd 不含 USB 读盘模块（读盘模块按设计放在各
# machines/<机器>/hardware-configuration.nix），**基础系统挂不上这块盘** —— 所以
# 菜单倒计时一过进基础系统 = 起不来。默认条目必须落在本机变体上，才能开机零操作。
#
# 为什么是部署期而不是构建期：flake 求值是纯的，构建时既不知道、也读不到目标机的
# DMI；而 bootloader 安装脚本是 root 在本机上跑的，读 /sys/class/dmi/id/* 没问题。
#
# 效果：开机菜单 5 秒（boot.loader.timeout 默认）过后直接进本机变体 —— 和手动选
# 那一条完全一样（启动变体自己的 kernel/initrd）。菜单里所有条目照旧可选。
# 盘插到「没 rebuild 过」的机器上时，由 auto-machine.nix 兜底。
{ config, pkgs, ... }:

let
  detect = ../../scripts/detect-machine.sh;
  keys = ../../machines/machine-keys.txt;

  # 条目和 loader.conf 写在 $BOOT：配了 XBOOTLDR 分区就是它，否则是 ESP
  bootMount =
    if config.boot.loader.systemd-boot.xbootldrMountPoint != null then
      config.boot.loader.systemd-boot.xbootldrMountPoint
    else
      config.boot.loader.efi.efiSysMountPoint;

  coreutils = "${pkgs.coreutils}/bin";
in
{
  boot.loader.systemd-boot.extraInstallCommands =
    ''
      # 这段会拼进 bootloader 安装脚本（set -euo pipefail）的末尾，任何失败都会让
      # `nh os switch` 失败 —— 所以整段 set +e：认不出机器/找不到条目时只打日志，
      # 绝不影响安装与开关机（默认条目留在基础系统，开机后由方案 A 兜底）。
      set +e
      machine="$(${pkgs.bash}/bin/bash ${detect} --table ${keys} 2>/dev/null)"
      if [ -z "$machine" ]; then
        echo "portable-chen: 认不出本机（scripts/detect-machine.sh --probes 看指纹，往 machines/machine-keys.txt 加行），默认条目留在基础系统" >&2
      else
        # 同一台机器会有历代条目，按「代号」数值排序取最新的一代（= 刚 rebuild 出来的那代）；
        # 条目名形如 nixos-generation-<代号>-specialisation-<机器>.conf
        entry="$(${coreutils}/ls -1 ${bootMount}/loader/entries/*-specialisation-"$machine".conf 2>/dev/null | ${coreutils}/sort -t- -k3,3n | ${coreutils}/tail -n1)"
        if [ -n "$entry" ]; then
          id="$(${coreutils}/basename "$entry")"
          if ${pkgs.gnused}/bin/sed -i "s|^default .*|default $id|" ${bootMount}/loader/loader.conf; then
            echo "portable-chen: 默认启动条目 → $id（本机 = $machine）"
          else
            echo "portable-chen: 改 ${bootMount}/loader/loader.conf 失败，默认条目不变" >&2
          fi
        else
          echo "portable-chen: 没找到 $machine 的启动条目，默认条目不变" >&2
        fi
      fi
    '';
}
