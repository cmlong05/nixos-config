# NixOS 配置
使用 flakes + home-manager 的 NixOS 配置仓库。

| os+disk | 用途 | 用户 | 说明 |
|------|------|------|------|
| `portable-chen` | **便携盘系统**（chen 的多台机器共用同一块移动硬盘） | chen | 全功能：蓝牙 / podman / dsh；**基础只带盘、不带硬件**，机器变体按硬件指纹**自动选**（菜单里也照旧可选） |
| `msi-wd` | 员工机（同款硬件，内盘独立安装） | mubimuba（员工）+ bumooby（管理员） | 精简：无蓝牙 / podman / dsh；mubimuba 无 sudo |

> chen 的硬件差异**不用多个 host**，而用 `specialisation`：基础系统只带盘挂载、不带硬件兜底，
> 每台机器对应菜单里的一条 `chen-desktop` / `chen-laptop-amd` / `chen-laptop-intel`。
> 选哪条由硬件指纹自动决定（部署期把默认条目指向本机 + 运行期兜底，见 `os-disk/portable-chen/boot-machine.nix`
> 与 `auto-machine.nix`），换机器**零命令**；菜单里手动选也照旧可用。

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
│   │   ├── home.nix             # home 入口（shell + apps，无 llm）
│   │   └── apps.nix             # 仅 mubimuba 的 Nix 应用（gimp）
│   ├── bumooby/                 # 管理员（仅账户，无 home）
│   │   └── default.nix
│   └── modules/                 # 用户域共享 home 模块
│       ├── shell.nix            # bash + direnv
│       ├── apps.nix             # 用户级应用包
│       └── llm.nix              # llm-agents 工具（dsh / reasonix，仅 chen）
├── machines/                    # 机器维度：每台实体机器一个目录
│   ├── machine-keys.txt         # 机器指纹表（DMI 型号/主板/CPU → 变体名；认机器只看它）
│   ├── chen-desktop/            # AMD 3900XT + NVIDIA 3060
│   │   ├── hardware-configuration.nix  # 生成（--no-filesystems），勿手改
│   │   └── default.nix                 # imports 上面 + 手写尾巴
│   ├── chen-laptop-amd/         # AMD 4800H + NVIDIA 3060（Vega 核显被 BIOS/MUX 禁用）
│   │   ├── hardware-configuration.nix
│   │   └── default.nix
│   ├── chen-laptop-intel/       # Intel 285H（仅内显）
│   │   ├── hardware-configuration.nix  # 旧组件拼装，待真机重生成
│   │   └── default.nix
│   └── employee-3600/           # AMD 3600 + NVIDIA 3060（员工机）
│       ├── hardware-configuration.nix  # 旧组件拼装，待真机重生成
│       └── default.nix
├── os-disk/                     # OS 维度：一个子目录 = 一次安装
│   ├── portable-chen/           # 便携盘（一次安装跨 3 台机器）
│   │   ├── default.nix          # 接线点（盘 + shared + 用户 + 变体 + 认机器）
│   │   ├── machine_spe.nix      # 机器变体（specialisation：chen-desktop / laptop-amd / laptop-intel）
│   │   ├── boot-machine.nix     # 认机器（部署期）：把默认启动条目指向本机变体
│   │   ├── auto-machine.nix     # 认机器（运行期）：换机器后开机自动切到对应变体
│   │   ├── disk.nix             # 挂载（fileSystems，跟盘走；故意不含 swapDevices）
│   │   ├── swap.nix             # swap 策略（zram 独占，不写移动盘）
│   │   ├── users.nix            # 用户点名单（chen）
│   │   └── virtualisation.nix   # podman
│   └── msi-wd/                  # 员工机（独立安装）
│       ├── default.nix          # 接线点（imports = machines/employee-3600/）
│       ├── disk.nix             # ⚠️ 模板（内盘 UUID，装机时生成后填入）
│       └── users.nix            # 点名单（bumooby + mubimuba）
└── shared/                      # 系统领域（各安装共用的机级服务）
    ├── boot.nix                 # systemd-boot + 内核
    ├── networking.nix           # NetworkManager
    ├── ssh.nix                  # SSH 远程访问（局域网内 sshd，两 host 共用）
    ├── nix.nix                  # 缓存源 / flakes / nh / allowUnfree
    ├── locale.nix               # 时区 / locale / fcitx5 / 字体
    ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire
    ├── printing.nix             # CUPS + 标签打印机（容错 + 定时重试）
    ├── flatpak.nix              # Flatpak 共享应用（Vivaldi/微信，系统级）
    └── packages.nix             # 系统级基础软件（含 vim —— root/救援也要用）
```

另有一个不在 `shared/` 里的脚本（被上面两个"认机器"模块调用，也可手动跑）：

```
scripts/detect-machine.sh        # 认机器：读 DMI/CPU 指纹查 machines/machine-keys.txt
```

## 机器 ↔ 硬件映射

映射的**唯一权威来源是代码**：`machines/<机器>/`（一个目录 = `hardware-configuration.nix`（生成，勿改）+ `default.nix`（手写尾巴）），`specialisation` 按机器名选择。

## 常用命令

```bash
# 本机应用配置（系统 + home-manager 一起生效；按 hostname 自动取对应 host）
nh os switch

# 指定主机（员工机）
nh os switch --flake .#msi-wd

# 便携盘：机器变体自动选 —— 部署期认本机指纹，把默认启动条目指向本机变体，
# 所以 `nh os switch` 后直接重启就是本机桌面（开机零选择，菜单 5 秒内仍可手动选）
nh os switch

# 认机器 / 手动指定变体（一般用不到）
scripts/detect-machine.sh            # 打印本机对应的变体名
scripts/detect-machine.sh --probes   # 打印本机指纹（给 machine-keys.txt 加新机器时用）
nh os switch -s chen-laptop-intel    # 手动把「运行中的系统」切到指定变体
nh os switch -S                      # 忽略变体，回到基础系统

# 注意：plain `nh os switch` 会让「运行中的系统」回到基础系统（基础不带硬件，没桌面）；
# 不想重启就切回本机变体：sudo systemctl restart auto-machine-specialisation

# 更新锁定输入
nix flake update

# 校验 flake（两主机 + 全部变体一起求值）
nix flake check
```

## 注意事项 / 踩坑记录

- **维度判据**：机器硬件 → `machines/<机器>/`（`hardware-configuration.nix` 生成 + `default.nix` 手写尾巴）；
  一份 OS 的身份 + 盘 → `os-disk/<name>/`；机级服务（各安装共用）→ `shared/`；人 → `users/`。
  `os-disk/<name>/default.nix` 只做接线：把 machines / disk / shared / users 拼起来。
  跨机器**可变**的硬件差异（GPU/CPU）走 `specialisation`，不新增目录。
- **应用放哪，判据是"机器要"还是"人要"**：
  - 机器要（root/sudo、救援 TTY 也要能用的，如 `vim`）→ `shared/packages.nix`；
  - 某个人自己的 → `users/<name>/`：Nix 包放 `apps.nix`，Flatpak 放 `flatpak.nix`
    （经 nix-flatpak 的 home-manager 模块以 `--user` 安装，跟人走，别的机器拿不到）；
  - `os-disk/<name>/default.nix` **只做接线，不放任何应用**。
- **生成与手写分离**：`nixos-generate-config --no-filesystems` 的产物**原样**放
  `machines/<机器>/hardware-configuration.nix`（勿手改，重生成即覆盖）；生成器不产出的
  NVIDIA 驱动 / 固件 / 图形 / 蓝牙，写进 `machines/<机器>/default.nix`（imports 上面）。
  挂载行（fileSystems/swapDevices）跟盘走，放 `os-disk/<name>/disk.nix`。
  `--no-filesystems` 是省事关键：产物天然不含 fileSystems/swap，无需手工"砍"。
- **便携盘用 specialisation，不用多 host**：`os-disk/portable-chen` 的基础系统只带盘挂载、
  不带机器硬件（它的 initrd 里**没有 USB 读盘模块** → 基础条目在这块盘上挂不上根，起不来）；
  `chen-desktop` / `chen-laptop-amd` / `chen-laptop-intel` 是**开机菜单里的机器变体**，换机器零命令。
  ⚠️ 代价：每个变体多出一份系统闭包（共享的包不重复，额外≈差异部分）。
- **机器变体自动选（2026-09-14）**：菜单"选哪条"是 bootloader 的事，系统里改不了 →
  两段式，都靠 `machines/machine-keys.txt`（指纹表）+ `scripts/detect-machine.sh` 认机器：
  - **部署期** `os-disk/portable-chen/boot-machine.nix`：`nh os switch` 装完 bootloader 之后
    （`extraInstallCommands`）读本机 DMI/CPU，把 `loader.conf` 的 `default` 指向**本机变体**条目
    → 开机倒计时（`boot.loader.timeout`，默认 5s）结束直接进本机。**不做这一步默认条目就是基础系统，
    而基础系统挂不上盘** —— 这就是"每次开机都得手选"的根源。
  - **运行期** `os-disk/portable-chen/auto-machine.nix`：把盘插到**没 rebuild 过**的机器上时，
    默认条目是上一个机器的变体；开机后一个 oneshot 服务
    调它继承来的 `.../specialisation/<机器>/bin/switch-to-configuration test` 切到对的那台
    （`test` 只激活，不重写 /boot、不动 profile；已在正确变体里时是空操作），切完把
    `display-manager` 重启一次。⚠️ 故意不与 `display-manager` 建顺序关系（`switch-to-configuration`
    自己会 start/restart 它，排前/排后都会形成环），所以这一路径上桌面会闪一下。
    ⚠️ 也只在**开机**路径上动手：激活会把「新增单元」拉起来，本单元第一次进新配置时正是被那次激活
    启动的 —— 里面再切一次就是并发切换（实测会让 `nh os switch` 报 `auto-machine-specialisation.service`
    failed、退出码 4）。所以脚本先扫 `/proc/*/exe`：有进程的可执行文件是 `switch-to-configuration`
    （即激活在跑）就退出 —— 不用 `pgrep -f`，它匹配整条命令行，会被"命令行里恰好含这串字"的
    无关进程误命中（实测在 shell 里跑诊断命令就会误判）。
  - 指纹表里台式机 / Intel 笔电两行是按硬件表**推测**的 CPU 型号，到机后用
    `scripts/detect-machine.sh --probes` 核实；认不出只打日志，退化成手动菜单，不会卡启动。
  - ⚠️ **新增文件必须先 `git add`**：flake 是 git 输入，未跟踪文件对 Nix 不可见
    （`nix eval` 会直接报 "is not tracked by Git"）。
- **便携盘不做磁盘 swap**：swap 与 `/` 在同一块 USB SSD、同一条 uas 队列，且换页 I/O 出错是
  **内核级**的（进程 SIGBUS、D 状态任务杀不掉），写量还叠加在同一块盘上而 USB 桥挡 SMART →
  改用 zram（`os-disk/portable-chen/swap.nix`：zstd / 50% 内存 / prio 100，`swappiness=100`、
  `page-cluster=0`），`disk.nix` 不再声明 `swapDevices`（盘上分区保留，应急可手工 `swapon`）。
  代价：没有磁盘兜底（极端压力靠 OOM killer），且**不能休眠** —— 3 台机器共用一份 `/`，
  在 A 机写下的内存镜像到 B 机 resume 会错乱，所以永远不要配 `boot.resumeDevice`。
- **内核**：用发行版默认 `pkgs.linuxPackages`（6.18.x）。曾钉 7.1 是为了避开 7.2
  与 nvidia-open 595.71.05 的编译不兼容（`os-interface.c strncpy`），但 7.1 已 EOL，
  nixpkgs 对它直接 throw，会让**所有 host 无法重建**。换回 `linuxPackages_latest`
  的条件：nvidia 驱动支持 7.2 之后（细节见 `shared/boot.nix` 注释）。
- **缓存源**：USTC 镜像 2026-08 验证可用；SJTU 对新路径同步不及时，如遇
  HTTP/2 流中断报错可临时移除 SJTU 源。
- **Go 依赖（reasonix）**：`llm-agents` 的 reasonix 走 `buildGoModule`，默认从
  `proxy.golang.org` 拉取 Go 模块，国内直连超时（IPv6 i/o timeout）。已在
  `users/modules/llm.nix` 用 `overrideModAttrs` 把 `GOPROXY` 换成 `goproxy.cn`，
  并同时把 GOPROXY 从 `impureEnvVars` 移除——否则固定输出推导会以 nix-daemon
  环境（未设置 GOPROXY）的空串覆盖它，又退回默认代理。
- 仓库锁定的 nixpkgs 分支为 `nixos-26.05`，home-manager 为 `release-26.05`，
  两者需保持大版本一致。

## 依赖输入

| 输入 | 用途 |
|------|------|
| nixpkgs | 主包源（NJU 镜像，26.05） |
| nix-flatpak | flatpak 声明式安装模块（系统级 + home-manager 用户级） |
| home-manager | 用户环境管理 |
| llm-agents | dsh / reasonix 等 LLM 工具包（仅作者机 chen 使用） |
