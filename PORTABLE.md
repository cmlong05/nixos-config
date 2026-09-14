# 待办：便携盘硬件适配（**大部分已实施**）

> 精简自早期计划稿（实测时间 2026-09-12，Intel 笔记本从移动硬盘启动本仓库系统）。
> 路径已对齐 2026-09 目录重构：`modules/`→`shared/`、`home/`→`users/`、
> `configuration.nix`→`default.nix`、`hardware-configuration.nix` 拆为
> `machines/<机器>/hardware-configuration.nix`（生成，勿改）+ `machines/<机器>/default.nix`（手写尾巴）+ `os-disk/<name>/disk.nix`（挂载）。
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

## C. 仍需拍板

1. ~~chen 的第三台机器是什么硬件~~ → 已确认：AMD 4800H 笔记本（`chen-laptop-amd`），已进 `machines/`。
2. `bumooby` 是否需要 home/桌面配置（当前：不加，仅系统维护账户）。
3. 时间策略：`time.hardwareClockInLocalTime`，还是 Windows 侧改（双系统 RTC 差 8 小时）。
4. 是否加 zram 以减少 USB SSD 写入（swap 现在就在 USB 盘上）。
5. ~~变体命名~~ → 已按机器名命名（chen-desktop / chen-laptop-amd / chen-laptop-intel）。

## D. 硬事实（避免重新踩坑）

- **KWin 只认 `KWIN_DRM_DEVICES`**，不认 `WLR_DRM_DEVICES`（grep kwin 包实测，只有 `libkwin.so` 里带 `KWIN_DRM_DEVICES`）。
- **选错变体不会变砖**：Intel 机带着整套 nvidia 驱动也能正常进桌面，最坏是驱动加载失败 + 日志噪音 + 性能退化。
- **每个变体多出一份系统闭包**，但共享的包是同一份 store 路径（额外占用≈差异部分）；GC 时会被启动条目引用而保留。
- **不要给不同变体配不同内核**（否则要编译两份内核）。
- **BitLocker**：内盘 Windows 已加密，不要为双系统去改 BIOS 的 Secure Boot/TPM/启动顺序，否则要恢复密钥。
- 日常命令：`bootctl status` 与 `sudo ls /boot/loader/entries` 查启动条目；
  `nh os switch .#portable-chen -s chen-laptop-intel` 指定机器变体，`-S` 回到基础系统。
