# NixOS 配置（多主机：nixos + mubimuba）

使用 flakes + home-manager 的多主机 NixOS 配置仓库。

| 主机 | 用途 | 用户 | 说明 |
|------|------|------|------|
| `nixos`（本机） | 作者日常机 | chen | 全功能：蓝牙 / podman / dsh 等 |
| `mubimuba` | 员工机（同款硬件） | mubimuba（员工）+ bumooby（管理员） | 精简：无蓝牙 / podman / dsh；mubimuba 无 sudo |

## 目录结构

```
nixos-config/
├── flake.nix                    # 入口：inputs + 两主机 nixosConfigurations
├── users/                       # 用户维度：账户 + home + 用户域共享模块
│   ├── chen/                    # 作者
│   │   ├── default.nix          # 账户属性 + home-manager.users.chen
│   │   └── home.nix             # home 入口（shell + apps + llm）
│   ├── mubimuba/                # 员工
│   │   ├── default.nix          # 账户属性 + home-manager.users.mubimuba
│   │   └── home.nix             # home 入口（shell + apps，无 llm）
│   ├── bumooby/                 # 管理员（仅账户，无 home）
│   │   └── default.nix
│   └── modules/                 # 用户域共享 home 模块
│       ├── shell.nix            # bash + direnv
│       ├── apps.nix             # 用户级应用包
│       └── llm.nix              # llm-agents 工具（dsh / reasonix，仅 chen）
├── disks/                       # 硬盘维度：只放"跟盘走"的挂载行
│   ├── portable-ssd.nix         # chen 移动硬盘（fileSystems + swap）
│   └── mubimuba-internal.nix    # 员工机内盘（⚠️ 装机时生成后填入）
├── hosts/                       # 主机维度
│   ├── nixos/                   # 作者机
│   │   ├── default.nix          # 接线点（hostName=nixos）
│   │   ├── hardware.nix         # 硬件探测（机级）
│   │   ├── users.nix            # 用户点名单（chen）
│   │   ├── bluetooth.nix        # 本机开蓝牙
│   │   └── virtualisation.nix   # 本机开 podman
│   └── mubimuba/                # 员工机
│       ├── default.nix          # 接线点（hostName=mubimuba）
│       ├── hardware.nix         # ⚠️ 模板，装机时重新生成
│       └── users.nix            # 点名单（bumooby + mubimuba）
└── shared/                      # 共享系统领域（两台机器一致的部分）
    ├── boot.nix                 # systemd-boot + 内核钉版
    ├── networking.nix           # NetworkManager
    ├── nix.nix                  # 缓存源 / flakes / nh / allowUnfree
    ├── locale.nix               # 时区 / locale / fcitx5 / 字体
    ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire / CUPS
    ├── gpu.nix                  # NVIDIA 驱动
    ├── flatpak.nix              # Flatpak 共享应用（Vivaldi/微信）
    └── packages.nix             # 系统级共享软件包
```

## 常用命令

```bash
# 本机（作者机）应用配置（系统 + home-manager 一起生效）
nh os switch            # 默认按 hostname 取 nixos 配置

# 指定主机（如员工机）
nh os switch --flake .#mubimuba

# 更新锁定输入
nix flake update

# 校验 flake（两主机全部求值）
nix flake check
```

## 注意事项 / 踩坑记录

- **机器差异放 hosts/，共性放 shared/**：hostName、用户点名单、蓝牙/podman
  开关这类机器相关配置都在 `hosts/<name>/` 下，不要写进共享模块。
- **硬件配置拆两半**：`nixos-generate-config` 生成的文件里，挂载行
  （fileSystems/swapDevices）放 `disks/`（跟盘走），探测行（boot.*/hostPlatform）
  放 `hosts/<name>/hardware.nix`（跟机器走）。员工机装机时需重新生成并手工拆一次。
- **内核钉版 7.1**：nvidia-open 595.71.05 与内核 7.2 不兼容（两台同款
  NVIDIA 3060），等驱动支持后再改回 `linuxPackages_latest`（boot.nix）。
- **缓存源**：USTC 镜像 2026-08 验证可用；SJTU 对新路径同步不及时，如遇
  HTTP/2 流中断报错可临时移除 SJTU 源。
- 仓库锁定的 nixpkgs 分支为 `nixos-26.05`，home-manager 为 `release-26.05`，
  两者需保持大版本一致。

## 依赖输入

| 输入 | 用途 |
|------|------|
| nixpkgs | 主包源（NJU 镜像，26.05） |
| nix-flatpak | flatpak 声明式安装模块 |
| home-manager | 用户环境管理 |
| llm-agents | dsh / reasonix 等 LLM 工具包（仅作者机 chen 使用） |
