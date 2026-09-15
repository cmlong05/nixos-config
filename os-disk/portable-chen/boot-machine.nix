# 方案 B（部署期选择）：`nh os switch` 装完 bootloader 后，把 systemd-boot 的
# 默认条目指向「本机」对应的 specialisation 条目。
#
# 为什么必须做：基础系统虽然起得来（读盘模块已放进 ./disk.nix，是控制台救援入口），
# 但它**不带任何机器硬件、没有显卡驱动** —— 落进基础系统就只有控制台、没有桌面。
# 所以菜单倒计时结束后必须落在**本机变体**上，才能"开机零操作直接进桌面"。
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
  setDefault = ../../scripts/set-default-entry.sh;
  keys = ../../machines/machine-keys.txt;

  # 条目和 loader.conf 写在 $BOOT：配了 XBOOTLDR 分区就是它，否则是 ESP
  # （auto-machine.nix 里有一份同样的算法：那处从运行中的 config 取）
  bootMount =
    if config.boot.loader.systemd-boot.xbootldrMountPoint != null then
      config.boot.loader.systemd-boot.xbootldrMountPoint
    else
      config.boot.loader.efi.efiSysMountPoint;
in
{
  boot.loader.systemd-boot.extraInstallCommands =
    ''
      # 这段会拼进 bootloader 安装脚本（set -euo pipefail）的末尾，任何失败都会让
      # `nh os switch` 失败 —— 所以整段 set +e，认不出机器时只打日志、不动 loader.conf。
      set +e
      machine="$(${pkgs.bash}/bin/bash ${detect} --table ${keys} 2>/dev/null)"
      if [ -z "$machine" ]; then
        echo "portable-chen: 认不出本机（scripts/detect-machine.sh --probes 看指纹，往 machines/machine-keys.txt 加行），默认条目留在基础系统" >&2
      else
        # 找条目 + 改 default 的逻辑在 scripts/set-default-entry.sh（与 A 共用同一份实现）
        ${pkgs.bash}/bin/bash ${setDefault} --machine "$machine" --boot ${bootMount}
      fi
    '';
}
