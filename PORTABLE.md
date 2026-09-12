# 待办：移动硬盘换机适配 + 硬件层清理（**均未实施**）

> 精简自早期计划稿（实测时间 2026-09-12，Intel 笔记本从移动硬盘启动本仓库系统）。
> 路径已对齐 2026-09 目录重构：`modules/`→`shared/`、`home/`→`users/`、
> `configuration.nix`→`default.nix`、`hardware-configuration.nix` 拆为 `disks/` + `hosts/*/hardware.nix`。
> 本文件只保留**待修 bug、待定决策、以及避免重踩的硬事实**；原稿的实测过程与逐节方案已删除。

## 背景

chen 的 3 台机器共用同一块移动硬盘（同一份 `/`、同一份 `/home/chen`），**只有 GPU 不同**；
员工机是独立安装（内盘、硬件固定，bumooby + mubimuba）。硬件差异必须与用户角色解耦。

## A. 待修 bug

**已修（2026-09，随 `aiaves` host 与 GPU 拆分）**：

- ~~#3 NVIDIA 配置写在**共享**层~~ → 已拆为 `shared/gpu-common.nix` + `gpu-nvidia.nix` + `gpu-intel.nix`，
  各主机按自己显卡叠加：`nixos` / `mubimuba` 用 nvidia，`aiaves` 用 intel。
- ~~#4 `WLR_DRM_DEVICES` 无效行~~ → 已随拆分删除（原因与替代写法留在 `shared/gpu-nvidia.nix` 注释里）。
- ~~#1 `kvm-amd` 被带到 Intel 机 / #2 Intel 无微码~~ → 已由**主机拆分**解决：
  `hosts/aiaves/hardware.nix` 用 `kvm-intel` + intel 微码，`hosts/nixos/hardware.nix` 保留
  `kvm-amd` + amd 微码。**前提是这台 Intel 机切到 `.#aiaves`**；若仍用 `.#nixos` 启动它，报错依旧。

**仍未修（3 条）**：

| # | 位置 | 现象 | 修法 |
|---|---|---|---|
| 5 | `shared/boot.nix` 的 `boot.kernelPackages = pkgs.linuxPackages_7_1` | 内核 7.1 已 EOL → `nix flake check` / `nh os switch` **直接失败**（`linux 7.1 was removed...`） | 改回 `linuxPackages_latest`（需 nvidia 驱动支持 7.2），或换驱动策略解除钉版 |
| 6 | 全仓库 | Intel 内显无 VA-API 硬解（`/run/opengl-driver/lib` 无 `iHD`/`vpl`），视频解码全靠 CPU | 在 `shared/gpu-intel.nix` 取消注释 `hardware.graphics.extraPackages = [ intel-media-driver ]`（可选 `vpl-gpu-rt`） |
| 7 | 隐式 | 固件开关靠生成文件里的 `mkDefault` 传递，重新生成硬件配置就可能变 | 共享层**显式**声明 `hardware.enableRedistributableFirmware = true` |

## B. 决策记录：3 台机器怎么建模

**已定（2026-09）：采用"多 host 共享一块盘"，不用 `specialisation`。**
`hosts/nixos`（AMD+NVIDIA）与 `hosts/aiaves`（Intel 笔电）各自一个 host，都导入
`disks/portable-ssd.nix`（同一块移动硬盘）；换机器时 `nh os switch --flake .#<host>`。
代价是换机要重建一次，换来的是每台机器拿到完全正确的硬件配置（见 A 里 #1/#2 的解决方式）。

以下为**被取代**的原备选方案（`specialisation`），保留备查：

- 基础系统保持**硬件无关**（任何机器插上必能进桌面）；`specialisation.nvidia` / `specialisation.intel`
  作为开机菜单变体，写在 `hosts/nixos/default.nix` 里。
- 理由：**换机器零重建**（换个开机条目即可），正是"同盘换机"的标准解法。
- 子决策（原稿方案 A/B）：
  - **A**：基础=通用、变体=优化。未知机器插上走默认项一定进桌面；缺点是有 3 个菜单条目、NVIDIA 机要记得选变体。
  - **B**：基础=完整 NVIDIA、只加 `intel` 变体（`mkForce` 覆盖）。改动更小，但 Intel 机默认条目仍带无用 NVIDIA 驱动。
  - 若第三台机器确认也是 NVIDIA → 建议 **B**。

## C. 仍需拍板

1. chen 的**第三台机器**是什么硬件 → 决定做 2 个还是 3 个变体。
2. `bumooby` 是否需要 home/桌面配置（当前：不加，仅系统维护账户）。
3. 时间策略：`time.hardwareClockInLocalTime`，还是 Windows 侧改（双系统 RTC 差 8 小时）。
4. 是否加 zram 以减少 USB SSD 写入（swap 现在就在 USB 盘上）。
5. 变体命名与菜单显示名是否需要更友好的标签。

## D. 硬事实（避免重新踩坑）

- **KWin 只认 `KWIN_DRM_DEVICES`**，不认 `WLR_DRM_DEVICES`（grep kwin 包实测，只有 `libkwin.so` 里带 `KWIN_DRM_DEVICES`）。
- **选错变体不会变砖**：Intel 机带着整套 nvidia 驱动也能正常进桌面，最坏是驱动加载失败 + 日志噪音 + 性能退化。
- **每个变体是一份完整系统闭包（GB 级）**；GC 时会被启动条目引用而保留 → 注意 store 占用。
- **不要给不同变体配不同内核**（否则要编译两份内核）。
- **BitLocker**：内盘 Windows 已加密，不要为双系统去改 BIOS 的 Secure Boot/TPM/启动顺序，否则要恢复密钥。
- 日常命令：`bootctl status` 与 `sudo ls /boot/loader/entries` 查启动条目；
  `nh os switch .#nixos -s intel` 指定变体，`-S` 回到基础系统。
