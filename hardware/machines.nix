# 机器 ↔ 硬件组合（代码形式，唯一权威来源）
#
# 一台机器 = 一份「硬件组合」= 若干原子模块（探测 + 驱动 + 能力）。
# 组合按「硬件类别」分，不按「每台机器」分——两台 NVIDIA 机共用一个 nvidia 组合。
#
# 用法：
#   - os-disk/portable-chen/default.nix：imports 用 portable-base，
#     specialisation.nvidia / intel 用这里的 nvidia / intel 作为增量。
#   - os-disk/msi-wd/default.nix：imports 用 msi-wd。
{
  # ---- 便携盘（portable-chen）：3 台机器共用一块盘，基础硬件无关 ----
  portable-base = [
    ./probe-portable-chen.nix   # 探测（硬件无关）
    ./common.nix                # 图形底座 + 固件 + intel/amd 双微码
    ./bluetooth.nix             # 蓝牙
  ];

  # GPU 变体（specialisation 的增量）：
  nvidia = [ ./gpu-nvidia.nix ];  # chen 台式机 AMD 3900X / 笔记本 AMD 4800H
  intel  = [ ./gpu-intel.nix ];   # chen Intel 笔记本 285H（仅内显）

  # ---- 员工机（msi-wd）：固定 AMD 3600 + NVIDIA 3060，独立安装 ----
  msi-wd = [
    ./probe-msi-wd.nix          # 探测（固定 AMD）
    ./common.nix
    ./gpu-nvidia.nix
  ];
}
