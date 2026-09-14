# 待办：便携盘硬件适配（**大部分已实施**）

> 精简自早期计划稿（实测时间 2026-09-12，Intel 笔记本从移动硬盘启动本仓库系统）。
> 路径已对齐 2026-09 目录重构：`modules/`→`shared/`、`home/`→`users/`、
> `configuration.nix`→`default.nix`、`hardware-configuration.nix` 生成到
> `machines/<机器>/hardware-configuration.nix`（--no-filesystems，勿改）；
> 手写尾巴放 `machines/<机器>/default.nix`，挂载行单独维护在 `os-disk/<name>/disk.nix`。
> 本文件只保留**待修 bug、待定决策、以及避免重踩的硬事实**；原稿的实测过程与逐节方案已删除。

## 背景

chen 的 3 台机器共用同一块移动硬盘（同一份 `/`、同一份 `/home/chen`），**只有 GPU 不同**；
员工机是独立安装（内盘、硬件固定，bumooby + mubimuba）。硬件差异必须与用户角色解耦。

## A. 待修 bug

**已修（2026-09）**：

- ~~#1 `kvm-amd` 被带到 Intel 机~~ / ~~#2 只有 amd 微码~~ → 改为**每台机器各自生成/拼装硬件**：
  `kvm-*` 与微码都在 `machines/<机器>/hardware-configuration.nix` 里按机器各自声明
  （Intel 机 `kvm-intel` + intel 微码，AMD 机 `kvm-amd` + amd 微码）。
- ~~#3 NVIDIA 配置写在共享层~~ → NVIDIA 驱动写进各 NVIDIA 机的 `machines/<机器>/default.nix` 手写尾巴；
  与厂商无关的部分（图形底座 + 固件）也在同一 `default.nix`。
- ~~#4 `WLR_DRM_DEVICES` 无效行~~ → 已删（原因见 git 历史；KWin 认 `KWIN_DRM_DEVICES`）。
- ~~#5 内核钉 7.1 已 EOL，所有 host 无法重建~~ → 改为发行版默认 `pkgs.linuxPackages`（**6.18.50**），
  并**实测 `nvidia-x11-595.71.05` 在 6.18.50 上编译通过**——`os-interface.c strncpy` 是 **7.2 特有**的。
- ~~#7 固件开关靠 `mkDefault` 隐式传递~~ → 各 `machines/<机器>/default.nix` 里**显式**声明
  `hardware.enableRedistributableFirmware = true`。

**仍未修（1 条）**：

| # | 位置 | 现象 | 修法 |
|---|---|---|---|
| 6 | 全仓库 | Intel 内显无 VA-API 硬解（`/run/opengl-driver/lib` 无 `iHD`/`vpl`），视频解码全靠 CPU | 在 `machines/chen-laptop-intel/default.nix` 取消注释 `hardware.graphics.extraPackages = [ intel-media-driver ]`（可选 `vpl-gpu-rt`） |

## B. 决策记录：便携盘怎么建模

**已定（2026-09）：采用 `specialisation`。**（先试过"多 host 共享一块盘"，已放弃。）

- 一开始做的是多 host：两个 host 目录（`portable-chen` = AMD+NVIDIA、`aiaves` = Intel）都导入
  同一块盘的挂载。代价不可接受：换机器必须在**那台机器上**
  `nh os switch --flake .#<host>`；而且菜单里"另一台"的条目只是**最后一次激活时的过期快照**
  ——菜单能让你"回到过去"，但切不到"另一台的当前配置"。
- 现改为 **1 个 host（`os-disk/portable-chen`）+ 机器变体**：基础系统**只带盘挂载、不带硬件兜底**，
  所以不选变体进不了桌面；每台机器是一个 `specialisation`（`chen-desktop` / `chen-laptop-amd` / `chen-laptop-intel`），
  指向 `machines/<机器>/` 的生成硬件 + 手写尾巴。换机器**零命令**，且所有变体每次 switch 一起重建、**永远同步**。
- 采用 **方案 A**（基础=只带盘，而非完整 NVIDIA）：基础无任何显卡驱动，开机必须选 `chen-desktop` / `chen-laptop-amd` 变体。
- 已知代价：每个变体多出一份自己的系统闭包（**共享的包不重复**，额外占用≈差异部分，nvidia 约 1 GB）；
  `nh os switch` 后默认项会**回到基础系统**
  （要留在变体上得 `-s <变体>`）；**不要给不同变体配不同内核**。
- 若将来某台机器的差异超出"显卡变体"的范围（例如需要不同的用户/服务），那才应该另开独立 host。
- **2026-09-14 补：菜单条目「自动选」= 部署期 + 运行期两段式。**（开机菜单选哪条是 bootloader
  的事，任何系统内代码都改不了；`boot.loader.timeout = 0` 也只能自动进**默认条目**。）
  - 实测硬事实：**基础系统条目在这块盘上起不来** —— 基础 initrd 里只有 `xhci-pci / sd_mod / nvme`，
    没有 `usb-storage.ko` / `uas.ko`（读盘模块按设计放在各 `machines/<机器>/hardware-configuration.nix`），
    而这块 JMicron 桥走 uas。三个变体的 initrd 都有 `usb-storage.ko + uas.ko` → 都能正常起。
    所以"默认条目 = 基础系统"等于"倒计时一过就起不来"，必须让它落在变体上。
  - **部署期**（`os-disk/portable-chen/boot-machine.nix`）：`nh os switch` 装完 bootloader 后
    （`boot.loader.systemd-boot.extraInstallCommands`，root 在本机跑）读 DMI/CPU 指纹，把
    `$BOOT/loader/loader.conf` 的 `default` 指向本机变体条目（按代号数值取最新一代）。认不出机器
    只打日志、不改 loader.conf，且整段 `set +e` —— 绝不让 `nh os switch` 失败。
  - **运行期**（`os-disk/portable-chen/auto-machine.nix`，被各变体继承）：换到**没 rebuild 过**的
    机器时默认条目还是上一个机器的变体，开机后一个 oneshot 调
    `<变体>/bin/switch-to-configuration test` 切到对的那台。官方文档就是这个用法；`test`
    不重写 /boot、不动 profile。已经在正确变体里时按 `readlink /run/current-system` 比对直接退出。
    ⚠️ 该服务**故意不与 display-manager 建顺序关系**：`switch-to-configuration` 自己会
    start/restart 一批单元（含 display-manager），把它排在我们之前会形成环，排在我们之后则它的
    restart 要先停我们 —— 两个方向都是死锁。所以流程是：切完 → 由服务 `systemctl restart
    display-manager.service` 收尾（这条路径上桌面会闪一下，之后就是本机变体的桌面）。
  - **踩过的坑（2026-09-14 实测）**：激活（`nh os switch` / `nixos-rebuild`）会「启动新增单元」，
    所以本单元第一次进入新配置时是被**那次激活自己**拉起来的；它起来后又跑一次
    `switch-to-configuration` → 两次切换并发 → `nh` 报 `auto-machine-specialisation.service failed`
    （激活退出码 4）。修法：脚本第一件事扫 `/proc/<pid>/exe`，有进程的可执行文件是
    `switch-to-configuration` 就不动手。**别用 `pgrep -f`**：它匹配整条命令行，实测在 shell 里跑
    诊断命令（命令行里含该串字）就会被误命中；看 `/proc/<pid>/exe`（服务以 root 跑，全都可读）既准
    又不受 argv[0]/cmdline 影响，测试时假进程也必须把那个名字做成真的可执行文件。
    三个附带事实：1) systemd 生成的 unit 脚本外壳自带 **`set -e`**，任何一步失败都会让单元变 failed
    并带崩激活 —— 所以每步都要显式兜住（`|| true` / `if !` / 结尾 `exit 0`），内层切换失败也只记日志；
    2) `switch-to-configuration test` 会通过激活脚本更新 `/run/current-system`
    （`activation-script.nix`：`ln -sfn "$(readlink -f "$systemConfig")" /run/current-system`），
    所以切完之后 `readlink` 幂等判断是准的（实测在本机跑新脚本会直接输出"已经在 chen-laptop-amd 里"）；
    3) Nix 缩进字符串 `''…''` 里 `''` 是转义符 —— 写 `read -d ''` 会把字符串截断（踩过），
    所以空字符相关的解析尽量别放进 `.nix` 里的 shell 片段。
  - 认机器只有一处实现：`machines/machine-keys.txt`（指纹表，子串匹配 product_name / board_name /
    CPU model name）+ `scripts/detect-machine.sh`。台式机与 Intel 笔电两行是**按硬件表推测**的 CPU
    型号，到机后用 `scripts/detect-machine.sh --probes` 核实。
  - 兜底：认不出 → 只打日志，退化为"变体条目 + 手动菜单"，不会卡启动；`journalctl -u
    auto-machine-specialisation -b` 看结果。想手工切：`sudo systemctl restart
    auto-machine-specialisation`（或直接跑上面那条 `switch-to-configuration test`）。
  - 可选加固（**未做**，属于另一个决定）：把 `usb-storage`/`uas`/`xhci_pci` 也加进基础系统
    （`os-disk/portable-chen/disk.nix`），基础条目就能起来、成为真正的救援入口。
    现在 `disk.nix` 第 3 行明确把这几个模块"按机器"放在 machines 里，故未擅自改。

## C. 仍需拍板

1. ~~chen 的第三台机器是什么硬件~~ → 已确认：AMD 4800H 笔记本（`chen-laptop-amd`），已进 `machines/`。
2. `bumooby` 是否需要 home/桌面配置（当前：不加，仅系统维护账户）。
3. 时间策略：`time.hardwareClockInLocalTime`，还是 Windows 侧改（双系统 RTC 差 8 小时）。
4. ~~是否加 zram 以减少 USB SSD 写入（swap 现在就在 USB 盘上）~~
   → **已定（2026-09-14）：zram 独占，删掉磁盘 swap。** 实测该盘是 USB 桥（JMicron `152d` / **uas** 驱动）
   + SSD（`rotational=0`，内核把 swap 标 `SS`），8.8G swap 里**已在用 1.5G**（firefox wrapper 300M、baloo 90M…），
   换出是真实发生的。三条理由：换页 I/O 出错是**内核级**的（进程 SIGBUS、D 状态任务杀不掉、reboot 可能卡住）、
   与 `/` 同盘同一条 uas 队列（抖动 = 桌面冻结而非变慢）、写量叠加而 USB 桥挡 SMART（磨损不可观测）。
   落地：`os-disk/portable-chen/swap.nix`（zram，zstd / 50% / prio 100，`swappiness=100`、`page-cluster=0`），
   `disk.nix` 不再声明 `swapDevices`；盘上分区保留不启用，应急可手工 `swapon`。
   代价（接受）：无磁盘兜底（极端压力靠 OOM killer 收尾）、zram 不能休眠。
5. ~~变体命名~~ → 已按机器名命名（chen-desktop / chen-laptop-amd / chen-laptop-intel）。

## D. 硬事实（避免重新踩坑）

- **KWin 只认 `KWIN_DRM_DEVICES`**，不认 `WLR_DRM_DEVICES`（grep kwin 包实测，只有 `libkwin.so` 里带 `KWIN_DRM_DEVICES`）。
- **选错变体不会变砖**：Intel 机带着整套 nvidia 驱动也能正常进桌面，最坏是驱动加载失败 + 日志噪音 + 性能退化。
- **每个变体多出一份系统闭包**，但共享的包是同一份 store 路径（额外占用≈差异部分）；GC 时会被启动条目引用而保留。
- **不要给不同变体配不同内核**（否则要编译两份内核）。
- **BitLocker**：内盘 Windows 已加密，不要为双系统去改 BIOS 的 Secure Boot/TPM/启动顺序，否则要恢复密钥。
- **移动盘不做磁盘 swap**：`os-disk/portable-chen/` 只有 zram（`swap.nix`），盘上的 swap 分区保留但**不启用**。
  **永远不要**给这块盘配休眠 / `boot.resumeDevice` —— 3 台机器共用一份 `/`，A 机写下的内存镜像在 B 机 resume 会错乱。
- 日常命令：`bootctl status` 与 `sudo ls /boot/loader/entries` 查启动条目，
  `sudo grep default /boot/loader/loader.conf` 看默认条目（正常应指向**本机变体**）；
  `scripts/detect-machine.sh [--probes]` 认机器 / 看本机指纹；
  `nh os switch .#portable-chen -s chen-laptop-intel` 指定机器变体，`-S` 回到基础系统；
  `sudo systemctl restart auto-machine-specialisation` 让运行中的系统立刻切回本机变体。
