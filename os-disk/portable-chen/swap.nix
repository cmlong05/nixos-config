# Swap 策略：只在内存里交换（zram），**不写移动盘**。
#
# 为什么不用盘上那个 8.8G 的 swap 分区（UUID 30cce407-1bd3-41c3-9c69-f02fa8bf9bb9）：
#   1. 故障模式不对等：换页 I/O 失败是内核级的 —— 进程直接收 SIGBUS、卡在 D 状态的
#      任务杀不掉，可能连 reboot 都卡在等 I/O；而普通文件系统掉线还能只读抢救数据。
#   2. 延迟放大：/、/home、/nix 与 swap 同一块 USB SSD、同一条 uas 队列，
#      每次缺页是一次 USB 往返。压力大时症状是**桌面冻结**，不是"变慢"。
#   3. 写量与 root 叠加在同一块 SSD 上，而 USB 桥通常挡 SMART → 磨损不可观测。
#   实测（2026-09-14）：8.8G swap 里已用 1.5G（firefox wrapper 300M、baloo 90M …），
#   也就是换出是真实发生的，不是理论风险。
#
# 已知代价（接受）：
#   - zram 不能休眠。本盘 3 台机器共用一份 / 与 swap，**永远不要**配休眠 /
#     boot.resumeDevice：A 机写下的内存镜像在 B 机 resume 是灾难性错乱。
#   - 没有磁盘兜底：极端压力下由 OOM killer 结束进程，而不是把整机拖死。
#
# NixOS 的 zram 走 systemd 的 zram-generator（generator 自己会 modprobe zram，
# 已在 pkgs/by-name/zr/zram-generator/package.nix 中确认），所以不需要额外
# boot.kernelModules；zramSwap 默认值即 zstd + 50% 内存 + priority 5。
{ ... }:

{
  zramSwap = {
    enable = true;
    algorithm = "zstd";     # 默认值，显式写出便于日后调
    memoryPercent = 50;     # 15G 内存 → 7.5G zram，zstd 压缩后通常等效 2-3 倍
    priority = 100;         # 现在没有磁盘 swap；留着是为了将来加回设备时的次序
  };

  boot.kernel.sysctl = {
    # zram 只有压缩/解压的 CPU 成本，比丢 page cache 便宜 → 允许更积极换出匿名页
    # （旧的磁盘 swap 用默认 60；换成 zram 后再压着换出反而浪费）
    "vm.swappiness" = 100;
    # 不做簇预读：zram 上预读只是白烧 CPU（每次仍要解压）
    "vm.page-cluster" = 0;
  };
}
