# NixOS 配置（多主机：nixos + aiaves + mubimuba）

使用 flakes + home-manager 的多主机 NixOS 配置仓库。

| 主机 | 用途 | 用户 | 说明 |
|------|------|------|------|
| `nixos` | 作者机 A（AMD + NVIDIA 3060，移动硬盘） | chen | 全功能：蓝牙 / podman / dsh / NVIDIA 驱动 |
| `aiaves` | 作者机 B（Intel Core Ultra 9 285H，仅内显；**与 nixos 共用同一块移动硬盘**） | chen | 全功能：蓝牙 / podman / dsh；Intel 内显，不装 NVIDIA |
| `mubimuba` | 员工机（同款硬件，内盘） | mubimuba（员工）+ bumooby（管理员） | 精简：无蓝牙 / podman / dsh；mubimuba 无 sudo |

## 目录结构

```
nixos-config/
├── flake.nix                    # 入口：inputs + 三主机 nixosConfigurations
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
├── disks/                       # 硬盘维度：只放"跟盘走"的挂载行
│   ├── portable-ssd.nix         # chen 移动硬盘（fileSystems + swap）
│   └── mubimuba-internal.nix    # 员工机内盘（⚠️ 装机时生成后填入）
├── hosts/                       # 主机维度
│   ├── nixos/                   # 作者机 A（AMD + NVIDIA，移动硬盘）
│   │   ├── default.nix          # 接线点（hostName=nixos）
│   │   ├── hardware.nix         # 硬件探测（kvm-amd + amd 微码）
│   │   ├── users.nix            # 用户点名单（chen）
│   │   ├── bluetooth.nix        # 本机开蓝牙
│   │   └── virtualisation.nix   # 本机开 podman
│   ├── aiaves/                  # 作者机 B（Intel 笔电，同一块移动硬盘）
│   │   ├── default.nix          # 接线点（hostName=aiaves）
│   │   ├── hardware.nix         # 硬件探测（kvm-intel + intel 微码）
│   │   ├── users.nix            # 用户点名单（chen）
│   │   ├── bluetooth.nix        # 本机开蓝牙
│   │   └── virtualisation.nix   # 本机开 podman
│   └── mubimuba/                # 员工机
│       ├── default.nix          # 接线点（hostName=mubimuba）
│       ├── hardware.nix         # ⚠️ 模板，装机时重新生成
│       └── users.nix            # 点名单（bumooby + mubimuba）
└── shared/                      # 共享系统领域（各主机共用的机级模块）
    ├── boot.nix                 # systemd-boot + 内核钉版
    ├── networking.nix           # NetworkManager
    ├── nix.nix                  # 缓存源 / flakes / nh / allowUnfree
    ├── locale.nix               # 时区 / locale / fcitx5 / 字体
    ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire / CUPS
    ├── gpu-common.nix           # 显卡通用部分（hardware.graphics.enable）
    ├── gpu-nvidia.nix           # NVIDIA 独显（nixos / mubimuba）
    ├── gpu-intel.nix            # Intel 内显（aiaves）
    ├── flatpak.nix              # Flatpak 共享应用（Vivaldi/微信，系统级）
    └── packages.nix             # 系统级基础软件（含 vim —— root/救援也要用）
```

## 常用命令

```bash
# 本机应用配置（系统 + home-manager 一起生效；按 hostname 自动取对应 host）
nh os switch

# 指定主机（员工机 / 另一台作者机）
nh os switch --flake .#mubimuba
nh os switch --flake .#aiaves

# 更新锁定输入
nix flake update

# 校验 flake（三主机全部求值）
nix flake check
```

## 注意事项 / 踩坑记录

- **机器差异放 hosts/，共性放 shared/**：hostName、用户点名单、蓝牙/podman
  开关这类机器相关配置都在 `hosts/<name>/` 下，不要写进共享模块。
- **应用放哪，判据是"机器要"还是"人要"**：
  - 机器要（root/sudo、救援 TTY 也要能用的，如 `vim`）→ `shared/packages.nix`；
  - 某个人自己的 → `users/<name>/`：Nix 包放 `apps.nix`，Flatpak 放 `flatpak.nix`
    （经 nix-flatpak 的 home-manager 模块以 `--user` 安装，跟人走，别的机器拿不到）；
  - `hosts/<name>/default.nix` **只做接线，不放任何应用**。
- **硬件配置拆两半**：`nixos-generate-config` 生成的文件里，挂载行
  （fileSystems/swapDevices）放 `disks/`（跟盘走），探测行（boot.*/hostPlatform）
  放 `hosts/<name>/hardware.nix`（跟机器走）。员工机装机时需重新生成并手工拆一次。
- **两块作者机共用一块盘**：`nixos`（AMD+NVIDIA）与 `aiaves`（Intel）都导入
  `disks/portable-ssd.nix`。在 Intel 笔电上要切到 `.#aiaves`，才会拿到 Intel 正确的
  硬件配置（`kvm-intel`、intel 微码、不装 NVIDIA）；用 `.#nixos` 启动它会带着 AMD/NVIDIA 的包袱。
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
