# 待办：便携盘硬件适配（**大部分已实施**）

> 精简自早期计划稿（实测时间 2026-09-12，Intel 笔记本从移动硬盘启动本仓库系统）。
> 路径已对齐 2026-09 目录重构：`modules/`→`shared/`、`home/`→`users/`、
> `configuration.nix`→`default.nix`、`hardware-configuration.nix` 拆为 `os-disk/<name>/disk.nix` + `hardware/<name>.nix`。
> 本文件只保留**待修 bug、待定决策、以及避免重踩的硬事实**；原稿的实测过程与逐节方案已删除。

## 背景

chen 的 3 台机器共用同一块移动硬盘（同一份 `/`、同一份 `/home/chen`），**只有 GPU 不同**；
员工机是独立安装（内盘、硬件固定，bumooby + mubimuba）。硬件差异必须与用户角色解耦。

## A. 待修 bug

**已修（2026-09）**：

- ~~#1 `kvm-amd` 被带到 Intel 机~~ / ~~#2 只有 amd 微码~~ → 便携盘改为**硬件无关**：
  `hardware/portable-chen.nix` 不再写死任何 `kvm-*`（KVM 模块按需自动加载），
  intel / amd **两个微码都在 `hardware/common.nix` 同时开**。
- ~~#3 NVIDIA 配置写在共享层~~ → 拆成 `hardware/gpu-nvidia.nix` / `hardware/gpu-intel.nix`；
  与厂商无关的部分（图形底座 + 固件 + 双微码）统一在 `hardware/common.nix`。
- ~~#4 `WLR_DRM_DEVICES` 无效行~~ → 已删（原因与替代写法留在 `hardware/gpu-nvidia.nix` 注释里）。
- ~~#5 内核钉 7.1 已 EOL，所有 host 无法重建~~ → 改为发行版默认 `pkgs.linuxPackages`（**6.18.50**），
  并**实测 `nvidia-x11-595.71.05` 在 6.18.50 上编译通过**——`os-interface.c strncpy` 是 **7.2 特有**的。
- ~~#7 固件开关靠 `mkDefault` 隐式传递~~ → `hardware/common.nix` 里**显式**声明
  `hardware.enableRedistributableFirmware = true`。

**仍未修（1 条）**：

| # | 位置 | 现象 | 修法 |
|---|---|---|---|
| 6 | 全仓库 | Intel 内显无 VA-API 硬解（`/run/opengl-driver/lib` 无 `iHD`/`vpl`），视频解码全靠 CPU | 在 `hardware/gpu-intel.nix` 取消注释 `hardware.graphics.extraPackages = [ intel-media-driver ]`（可选 `vpl-gpu-rt`） |

## B. 决策记录：便携盘怎么建模

**已定（2026-09）：采用 `specialisation`。**（先试过"多 host 共享一块盘"，已放弃。）

- 一开始做的是多 host：两个 host 目录（`portable-chen` = AMD+NVIDIA、`aiaves` = Intel）都导入
  同一块盘的挂载。代价不可接受：换机器必须在**那台机器上**
  `nh os switch --flake .#<host>`；而且菜单里"另一台"的条目只是**最后一次激活时的过期快照**
  ——菜单能让你"回到过去"，但切不到"另一台的当前配置"。
- 现改为 **1 个 host（`os-disk/portable-chen`）+ 开机变体**：基础系统**硬件无关**，插到任何机器都能进桌面；
  `specialisation.nvidia` / `specialisation.intel` 写在 `os-disk/portable-chen/default.nix`。
  换机器**零命令**，且所有变体每次 switch 一起重建、**永远同步**。
- 采用 **方案 A**（基础=硬件无关，而非完整 NVIDIA）：保证"未知机器插上必能进桌面"。
  代价是 AMD+NVIDIA 台式机默认走 nouveau，要手动选 `nvidia` 变体。
- 已知代价：每个变体多出一份自己的系统闭包（**共享的包不重复**，额外占用≈差异部分，nvidia 约 1 GB）；
  `nh os switch` 后默认项会**回到基础系统**
  （要留在变体上得 `-s <变体>`）；**不要给不同变体配不同内核**。
- 若将来某台机器的差异超出"显卡变体"的范围（例如需要不同的用户/服务），那才应该另开独立 host。

## C. 仍需拍板

1. chen 的**第三台机器**是什么硬件 → 若属于 NVIDIA / Intel 之一，复用现有变体即可；都不像再加第三个变体。
2. `bumooby` 是否需要 home/桌面配置（当前：不加，仅系统维护账户）。
3. 时间策略：`time.hardwareClockInLocalTime`，还是 Windows 侧改（双系统 RTC 差 8 小时）。
4. 是否加 zram 以减少 USB SSD 写入（swap 现在就在 USB 盘上）。
5. 变体命名与菜单显示名是否需要更友好的标签。

## D. 硬事实（避免重新踩坑）

- **KWin 只认 `KWIN_DRM_DEVICES`**，不认 `WLR_DRM_DEVICES`（grep kwin 包实测，只有 `libkwin.so` 里带 `KWIN_DRM_DEVICES`）。
- **选错变体不会变砖**：Intel 机带着整套 nvidia 驱动也能正常进桌面，最坏是驱动加载失败 + 日志噪音 + 性能退化。
- **每个变体多出一份系统闭包**，但共享的包是同一份 store 路径（额外占用≈差异部分）；GC 时会被启动条目引用而保留。
- **不要给不同变体配不同内核**（否则要编译两份内核）。
- **BitLocker**：内盘 Windows 已加密，不要为双系统去改 BIOS 的 Secure Boot/TPM/启动顺序，否则要恢复密钥。
- 日常命令：`bootctl status` 与 `sudo ls /boot/loader/entries` 查启动条目；
  `nh os switch .#portable-chen -s intel` 指定变体，`-S` 回到基础系统。
