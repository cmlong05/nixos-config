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
├── hosts/                       # 每台机器的配置
│   ├── nixos/                   # 作者机
│   │   ├── configuration.nix    # 入口（hostName=nixos）
│   │   ├── hardware-configuration.nix  # 本机生成，勿改
│   │   ├── bluetooth.nix        # 本机开蓝牙
│   │   ├── virtualisation.nix   # 本机开 podman
│   │   └── users.nix            # 用户 chen
│   └── mubimuba/                # 员工机
│       ├── configuration.nix    # 入口（hostName=mubimuba）
│       ├── hardware-configuration.nix  # ⚠️ 模板，装机时必须在员工机重新生成
│       └── users.nix            # mubimuba（员工）+ bumooby（管理员）
├── modules/                     # 共享领域模块（两台机器一致的部分）
│   ├── boot.nix                 # systemd-boot + 内核钉版
│   ├── networking.nix           # NetworkManager（hostName 在各主机配置）
│   ├── nix.nix                  # 缓存源 / flakes / nh / allowUnfree
│   ├── locale.nix               # 时区 / locale / fcitx5 / 字体
│   ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire / CUPS
│   ├── gpu.nix                  # NVIDIA 驱动
│   ├── flatpak.nix              # Flatpak 共享应用（Vivaldi/微信）
│   └── packages.nix             # 系统级共享软件包
└── home/                        # home-manager 配置
    ├── home.nix                 # chen 入口（作者机；含 dsh 等）
    ├── employee.nix             # mubimuba 入口（员工机；不含 llm/dsh）
    └── modules/
        ├── shell.nix            # bash + direnv
        ├── apps.nix             # 用户级应用包
        └── llm.nix              # llm-agents 工具（dsh / reasonix，仅作者机）
```

## 常用命令

```bash
# 本机（作者机）应用配置
nh os switch            # 默认按 hostname 取 nixos 配置

# 指定主机（如员工机）
nh os switch --flake .#mubimuba

# 仅 home-manager（chen）
home-manager switch --flake .#nixos

# 更新锁定输入
nix flake update

# 校验 flake（两主机全部求值）
nix flake check
```

> nh 的 `programs.nh.flake` 已在共享模块 `modules/nix.nix` 统一设为
> `/etc/nixos`（两机装机后仓库都在该路径），无需按主机手动配置。

## 员工机（mubimuba）部署清单

在**同款硬件**（AMD CPU + NVIDIA 3060）的新电脑上装 NixOS：

1. 用 U 盘引导并分区（EFI + btrfs，可照抄本机布局），挂载后
   `nixos-generate-config --root /mnt` 生成**该机专属**的
   `hardware-configuration.nix`（磁盘 UUID 每台不同，勿用仓库里的模板）。
2. 把本仓库放到 `/mnt/etc/nixos/`，并用新生成的 hardware-configuration.nix
   **覆盖 `hosts/mubimuba/hardware-configuration.nix`**。
3. `nixos-install --flake /mnt/etc/nixos#mubimuba`。
4. 首次登录前设置密码（本配置不含密码）：
   `passwd mubimuba`（员工）、`passwd bumooby`（管理员）。
5. 员工机上 mubimuba **没有 wheel（无 sudo）**；如需提权，把 `wheel`
   加回 `hosts/mubimuba/users.nix` 的 mubimuba extraGroups。
6. 员工机上需要哪些用户级应用，改 `home/employee.nix`。

## 注意事项 / 踩坑记录

- **机器差异放 hosts/，共性放 modules/**：hostName、用户、蓝牙/podman
  开关这类机器相关配置都在 `hosts/<name>/` 下，不要写进共享模块。
- **hardware-configuration.nix 是生成文件**：由 `nixos-generate-config`
  生成，改动会被覆盖；`hosts/mubimuba/` 下的版本只是让仓库可求值的模板。
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
