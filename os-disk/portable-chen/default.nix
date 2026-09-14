# 便携盘安装（portable-chen）—— 一次安装跨 3 台机器
#
# 硬件全部下放到每台机器的 specialisation（machines/chen-*.nix：硬件探测 +
# 手写尾巴）。基础系统只保留盘挂载（./disk.nix，3 台机器共用同一块盘），
# 不带任何机器硬件 —— 读盘模块和显卡都在变体里，所以**基础条目在这块盘上起不来**
# （initrd 里没有 USB 读盘模块），开机必须落在某个变体上。
#
# 「自动选机器」由两个模块配合（开机菜单里的条目本身没法由系统自动选，
# 那一层是 bootloader 决定的，所以一个在部署期选、一个在运行期兜底）：
#   ./boot-machine.nix  部署期：nh os switch 装完 bootloader 后，把默认条目
#                       指向本机变体 → 开机零选择直接进本机
#   ./auto-machine.nix  运行期：盘插到没 rebuild 过的机器上时，开机后自动切变体
# 两个都靠 machines/machine-keys.txt 的硬件指纹 + scripts/detect-machine.sh 认机器。
{ ... }:

{
  imports = [
    # 挂载（跟盘走；3 台机器共用同一块移动盘）
    ./disk.nix
    # swap 策略（跟盘走：USB 盘不做磁盘 swap，改用 zram）
    ./swap.nix
    # 系统服务（本安装特有）
    ./virtualisation.nix                     # podman
    # 系统领域（各安装共用）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/ssh.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（chen）
    ./users.nix
    # 机器变体（specialisation）
    ./machine_spe.nix
    # 认机器：部署期把默认启动条目指向本机变体（方案 B）
    ./boot-machine.nix
    # 认机器：换到没 rebuild 过的机器上时，开机后自动切到对应变体（方案 A）
    ./auto-machine.nix
  ];

  networking.hostName = "portable-chen";

  system.stateVersion = "26.05";
}
