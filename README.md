# NixOS 配置（flake + home-manager）

| 文档 | 用途 |
|---|---|
| **README.md**（本文） | 仓库结构、设计、踩坑、待办 |
| [`DEPLOY-INSTALL.md`](./DEPLOY-INSTALL.md) | **新增一台机器**：通用装机清单 |
| [`DEPLOY-MAINT.md`](./DEPLOY-MAINT.md) | 已装机器：更新 / 改配置 / 回滚 / 排障 |

## 1. 两层构建

| 层 | 入口 | 谁来做 | 用于 |
|---|---|---|---|
| 系统级 | `nh os switch` | 在 `wheel` 的管理员 | 机器 / 盘 / 服务 / 账户 / `shared/` |
| 用户级 | `nh home switch` | **每个用户自己** | 家目录：dotfiles、用户服务、用户应用 |

系统侧不激活家目录（home-manager 只以 `homeConfigurations` 存在），用户级改动不会被系统 switch 覆盖

## 2. 硬盘OS 与 Machine

| 硬盘OS | 形态 | 用户 |
|---|---|---|---|
| `portable-chen` | 便携盘 |chen |
| `msi-wd` | 内盘盘 | mubimuba + bumooby|
挂载信息在硬盘中 os-disk/*name*/disk.nix中

`machines/<机器>/` = 一台实体机器：`hardware-configuration.nix`（生成，勿手改）+ `default.nix`（手写尾巴）。
`machine-keys.txt` 只是便携盘的指纹表，**独立安装的机器不看它**。

## 3. 目录与判据

```
nixos-config/
├── flake.nix                # nixosConfigurations（每 host）+ homeConfigurations（每人）
├── users/                   # 人：default.nix（账户）+ home.nix（家目录入口）+ 个人 apps/flatpak
│   ├── chen/ mubimuba/ bumooby/
│   └── modules/             # 用户域共享：shell / apps / llm(仅 chen) / remote-desktop / flatpak
├── machines/                # 每台机器一个目录 + machine-keys.txt（便携盘指纹表）
├── os-disk/                 # 一次安装 = 一个目录
│   ├── portable-chen/       # 便携盘：disk / swap(zram) / machine_spe(变体) / boot-machine + auto-machine(认机器)
│   └── msi-wd/              # 员工机：default / disk / users
├── shared/                  # 机级服务：boot networking ssh remote-desktop nix locale desktop printing flatpak packages
├── lib/flatpak-mirror.nix   # flathub 镜像 + 公钥（唯一权威来源）
└── scripts/                 # detect-machine.sh（认机器）、set-default-entry.sh（写默认启动条目）
```

**分配**：
机器硬件 → `machines/`；
硬盘OS安装 → `os-disk/`（`default.nix` **只接线，不放应用**）；
共用机级服务 → `shared/`；
人 → `users/`；
跨机器的硬件差异 → specialisation 变体，不开新 host。

**应用分配**：
机器基础（root / 救援）→ `shared/packages.nix`；
所有用户 → `users/modules/apps.nix`；
个人用户 → `users/<name>/apps.nix` 或 `flatpak.nix`。

## 4. 常用命令

```bash
nh os switch                 # 系统级，按本机 hostname 选；-H msi-wd 显式指定 host
nh os build / nh os info / nh os rollback
nh home switch               # 用户级，各人自己；-c chen@portable-chen 显式指定；--dry 只打印
nix flake update             # 升级输入（只在作者机做）；nix flake check 求值校验

# 便携盘：换机器零命令（见 §6）
scripts/detect-machine.sh            # 打印本机变体名；--probes 打印指纹
nh os switch -s chen-laptop-intel    # 只切「运行中」的系统到该变体（不重启）
nh os switch -S                      # 保留基础系统（控制台救援入口）
```

## 5. 用户级构建（每个用户自己）

```bash
nh home switch            # 激活 / 更新家目录（flake = /etc/nixos）
nh home build             # 只构建
home-manager generations / home-manager --rollback
```

- **装机后必须自己跑一次**：系统里没有 `home-manager-<user>.service`。管理员可代跑 `sudo -u <user> -i nh home switch`。
- **一个家目录只能有一个激活者**：不要再挂 `home-manager.users.<user>`（NixOS 模块），否则会互相覆盖。
- **PATH**：home-manager 激活时用 `nix-env -i` 把本代 `home.path` 装进 `~/.nix-profile`，NixOS 本来就有
  `$HOME/.nix-profile/bin`。⚠️ 别手动把它指到本代 `home-path`（见 §7）。


## 6. 便携盘与 os-disk/portable-chen/machine_spe.nix

一块移动盘、一次安装、跨多台机器；硬件差异通过 `machine_spe.nix/specialisation`引入 machines

- **基础系统只带盘、不带硬件** → 能引导但只有控制台，是救援入口；每增加一台具体机器就多一份系统闭包。
- **自动认机器**（`machine-keys.txt` + `detect-machine.sh`，写条目用 `set-default-entry.sh`）分两段：
  部署期 `boot-machine.nix` 在 `nh os switch` 后把本机变体写成默认条目（**不做就只有基础系统，进不了桌面**）；
  运行期 `auto-machine.nix` 在换机器后开机时补写并把当前这次也切过去。
  默认条目写两处：本机 NVRAM(BIOS/UEFI)的 `LoaderEntryDefault`（跟机器走，优先）+ 盘上 `loader.conf`（跟盘走，兜底）。
  第一次到某台机器仍需菜单手选一次；指纹认不出只打日志，不会卡启动。

