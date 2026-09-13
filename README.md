# NixOS 配置（portable-chen：便携盘 + 硬件变体 / msi-wd：员工机）

使用 flakes + home-manager 的 NixOS 配置仓库。

| 主机 | 用途 | 用户 | 说明 |
|------|------|------|------|
| `portable-chen` | **便携盘系统**（chen 的多台机器共用同一块移动硬盘） | chen | 全功能：蓝牙 / podman / dsh；**基础硬件无关**，开机菜单选 `nvidia` / `intel` 变体 |
| `msi-wd` | 员工机（同款硬件，内盘独立安装） | mubimuba（员工）+ bumooby（管理员） | 精简：无蓝牙 / podman / dsh；mubimuba 无 sudo |

> chen 的硬件差异**不用多个 host**，而用 `specialisation`：基础系统插到任何机器都能进桌面，
> 开机时在菜单里选 `nvidia`（AMD 台式机）或 `intel`（Intel 笔电）。换机器**零命令**。

## 目录结构

```
nixos-config/
├── flake.nix                    # 入口：inputs + 两主机 nixosConfigurations
├── users/                       # 用户维度：账户 + home + 用户域共享模块
│   ├── chen/                    # 作者
│   │   ├── default.nix          # 账户属性 + home-manager.users.chen
│   │   ├── home.nix             # home 入口（shell + apps + llm + 个人应用）
│   │   ├── apps.nix             # 仅 chen 的 Nix 应用（li-ri）
│   │   └── flatpak.nix          # 仅 chen 的 Flatpak（QQ / tuxmath，--user 安装）
│   ├── mubimuba/                # 员工
│   │   ├── default.nix          # 账户属性 + home-manager.users.mubimuba
│   │   └── home.nix             # home 入口（shell + apps，无 llm）
│   ├── bumooby/                 # 管理员（仅账户，无 home）
│   │   └── default.nix
│   └── modules/                 # 用户域共享 home 模块
│       ├── shell.nix            # bash + direnv
│       ├── apps.nix             # 用户级应用包
│       └── llm.nix              # llm-agents 工具（dsh / reasonix，仅 chen）
├── machines/                    # 机器维度：每台实体机器一个文件（组件组合）
│   ├── chen-desktop.nix         # AMD 3900X + NVIDIA 3060
│   ├── chen-laptop-amd.nix      # AMD 4800H + NVIDIA 3060（含 Vega 核显）
│   ├── chen-laptop-intel.nix    # Intel 285H（仅内显）
│   └── employee-3600.nix        # AMD 3600 + NVIDIA 3060
├── hardware/                    # 硬件原子：探测 / CPU / GPU / 能力
│   ├── common.nix               # 底座（图形 + 固件）
│   ├── cpu-amd.nix              # 微码（AMD）
│   ├── cpu-intel.nix            # 微码（Intel）
│   ├── gpu-nvidia.nix           # NVIDIA 独显
│   ├── gpu-intel.nix            # Intel 内显
│   ├── gpu-amd-vega.nix         # AMD 核显（占位）
│   ├── probe-portable-chen.nix  # 探测（便携盘，硬件无关）
│   ├── probe-msi-wd.nix         # 探测（员工机，固定 AMD）
│   ├── bluetooth.nix            # 蓝牙
│   └── wifi.nix                 # wifi（占位）
├── os-disk/                     # OS 维度：一个子目录 = 一次安装
│   ├── portable-chen/           # 便携盘（一次安装跨 3 台机器）
│   │   ├── default.nix          # 接线点 + specialisation（chen-desktop / laptop-amd / laptop-intel）
│   │   ├── disk.nix             # 挂载（fileSystems + swap，跟盘走）
│   │   ├── users.nix            # 用户点名单（chen）
│   │   └── virtualisation.nix   # podman
│   └── msi-wd/                  # 员工机（独立安装）
│       ├── default.nix          # 接线点（imports = machines/employee-3600）
│       ├── disk.nix             # ⚠️ 模板（内盘 UUID，装机时生成后填入）
│       └── users.nix            # 点名单（bumooby + mubimuba）
└── shared/                      # 系统领域（各安装共用的机级服务）
    ├── boot.nix                 # systemd-boot + 内核
    ├── networking.nix           # NetworkManager
    ├── nix.nix                  # 缓存源 / flakes / nh / allowUnfree
    ├── locale.nix               # 时区 / locale / fcitx5 / 字体
    ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire / CUPS
    ├── flatpak.nix              # Flatpak 共享应用（Vivaldi/微信，系统级）
    └── packages.nix             # 系统级基础软件（含 vim —— root/救援也要用）
```

## 机器 ↔ 硬件映射

映射的**唯一权威来源是代码**：`machines/`（每台机器一个文件 = 组件组合；`hardware/` 是原子库，`specialisation` 按机器名选择）。

## 常用命令

```bash
# 本机应用配置（系统 + home-manager 一起生效；按 hostname 自动取对应 host）
nh os switch

# 指定主机（员工机）
nh os switch --flake .#msi-wd

# 便携盘的机器变体：不指定就停在基础系统
nh os switch -s chen-laptop-intel   # 在 Intel 笔电上
nh os switch -s chen-desktop        # 在 AMD+NVIDIA 台式机上
nh os switch -S                     # 忽略变体，回到基础系统

# 更新锁定输入
nix flake update

# 校验 flake（两主机 + 全部变体一起求值）
nix flake check
```

## 注意事项 / 踩坑记录

- **维度判据**：硬件 → `hardware/`；一份 OS 的身份 + 盘 → `os-disk/<name>/`；
  机级服务（各安装共用）→ `shared/`；人 → `users/`。
  `os-disk/<name>/default.nix` 只做接线：把 hardware / disk / shared / users 拼起来。
  跨机器**可变**的硬件差异（GPU）走 `specialisation`，不新增目录。
- **应用放哪，判据是"机器要"还是"人要"**：
  - 机器要（root/sudo、救援 TTY 也要能用的，如 `vim`）→ `shared/packages.nix`；
  - 某个人自己的 → `users/<name>/`：Nix 包放 `apps.nix`，Flatpak 放 `flatpak.nix`
    （经 nix-flatpak 的 home-manager 模块以 `--user` 安装，跟人走，别的机器拿不到）；
  - `os-disk/<name>/default.nix` **只做接线，不放任何应用**。
- **硬件配置拆两半**：`nixos-generate-config` 生成的文件里，挂载行
  （fileSystems/swapDevices）放 `os-disk/<name>/disk.nix`（跟盘走），探测行（boot.*/hostPlatform）
  放 `hardware/<name>.nix`（跟机器走）。员工机装机时需重新生成并手工拆一次。
  ⚠️ 便携盘的 `hardware/probe-portable-chen.nix` 必须保持**硬件无关**——不能出现
  `kvm-amd`/`kvm-intel`、微码之类机器专属项，否则换机器就出问题。
- **便携盘用 specialisation，不用多 host**：`os-disk/portable-chen` 的基础系统硬件无关
  （`hardware/probe-portable-chen.nix` 不写死 kvm-*，intel/amd 微码在兜底 base 都开），
  插到任何机器都能进桌面；`chen-desktop` / `chen-laptop-amd` / `chen-laptop-intel` 是**开机菜单里的机器变体**，换机器零命令。
  ⚠️ 两个代价：(1) 每个变体多出一份系统闭包（共享的包不重复，额外≈差异部分）；
  (2) `nh os switch` 之后默认项会**回到基础系统**，要留在变体上得加 `-s <机器>`。
- **内核**：用发行版默认 `pkgs.linuxPackages`（6.18.x）。曾钉 7.1 是为了避开 7.2
  与 nvidia-open 595.71.05 的编译不兼容（`os-interface.c strncpy`），但 7.1 已 EOL，
  nixpkgs 对它直接 throw，会让**所有 host 无法重建**。换回 `linuxPackages_latest`
  的条件：nvidia 驱动支持 7.2 之后（细节见 `shared/boot.nix` 注释）。
- **缓存源**：USTC 镜像 2026-08 验证可用；SJTU 对新路径同步不及时，如遇
  HTTP/2 流中断报错可临时移除 SJTU 源。
- 仓库锁定的 nixpkgs 分支为 `nixos-26.05`，home-manager 为 `release-26.05`，
  两者需保持大版本一致。

## 依赖输入

| 输入 | 用途 |
|------|------|
| nixpkgs | 主包源（NJU 镜像，26.05） |
| nix-flatpak | flatpak 声明式安装模块（系统级 + home-manager 用户级） |
| home-manager | 用户环境管理 |
| llm-agents | dsh / reasonix 等 LLM 工具包（仅作者机 chen 使用） |
