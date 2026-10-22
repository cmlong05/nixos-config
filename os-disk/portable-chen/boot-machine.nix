# 部署后把默认启动条目指向本机机器变体。
# 基础系统仅用于控制台救援，不带机器硬件和桌面。
# 构建时读不到目标机硬件，因此在本机运行的 bootloader 安装阶段探测。
# 同时写 NVRAM 的 LoaderEntryDefault（按机器记忆）和盘上的 loader.conf（兜底）。
# extraInstallCommands 在 bootloader 安装末尾执行，可覆盖刚写入的基础系统条目。
{ config, pkgs, ... }:

let
  detect = ../../scripts/detect-machine.sh;
  setDefault = ../../scripts/set-default-entry.sh;
  keys = ../../machines/machine-fingerprints.conf;

  # 启动条目和 loader.conf 写入 ESP（当前配置的 /boot）。
  bootMount = config.boot.loader.efi.efiSysMountPoint;
in
{
  boot.loader.systemd-boot.extraInstallCommands =
    ''
      # 该段在 bootloader 安装末尾执行；避免失败中断 nh os switch。
      set +e
      machine="$(${pkgs.bash}/bin/bash ${detect} --table ${keys} 2>/dev/null)"
      if [ -z "$machine" ]; then
        echo "portable-chen: 认不出本机（scripts/detect-machine.sh --probes 看网卡 MAC，往 machines/machine-fingerprints.conf 添加），默认条目留在基础系统" >&2
      else
        # 复用 set-default-entry.sh：NVRAM 按机器记忆，loader.conf 跟随磁盘作为兜底。
        ${pkgs.bash}/bin/bash ${setDefault} --machine "$machine" --boot ${bootMount} \
          --efi --bootctl ${pkgs.systemd}/bin/bootctl
      fi
    '';
}
