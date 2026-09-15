# NixOS 配置
使用 flakes + home-manager 的 NixOS 配置仓库。

**两层构建、两个入口**：

| 层 | 入口 | 需要 sudo? | 管什么 |
|---|---|---|---|
| 系统级 | `nh os switch` | 是 | 机器 / 盘 / 服务 / 账户 / `shared/packages.nix` |
| 用户级 | `nh home switch` | **否** | 家目录：dotfiles、用户服务、用户应用 |

系统侧**不再激活任何家目录**（home-manager 不是 NixOS 模块，只以 `homeConfigurations`
存在）。因此：用户级改动不会被系统 switch 覆盖，也不需要为了装一个包去重启或切回 specialisation；
代价是**装机后每个用户要自己跑一次 `nh home switch`**（见"用户级构建"一节）。

| os+disk | 用途 | 用户 | 说明 |
|------|------|------|------|
| `portable-chen` | **便携盘系统**（chen 的多台机器共用同一块移动硬盘） | chen | 全功能：蓝牙 / podman / dsh；**基础只带盘、不带硬件**，机器变体按硬件指纹**自动选**（菜单里也照旧可选） |
| `msi-wd` | 员工机（同款硬件，内盘独立安装） | mubimuba（员工）+ bumooby（管理员） | 精简：无蓝牙 / podman / dsh；mubimuba 无 sudo（但**能**自己 `nh home switch`，用户级构建不需要提权） |

> chen 的硬件差异**不用多个 host**，而用 `specialisation`：基础系统只带盘挂载、不带硬件兜底，
> 每台机器对应菜单里的一条 `chen-desktop` / `chen-laptop-amd` / `chen-laptop-intel`。
> 选哪条由硬件指纹自动决定（部署期把默认条目指向本机 + 运行期兜底，见 `os-disk/portable-chen/boot-machine.nix`
> 与 `auto-machine.nix`），换机器**零命令**；菜单里手动选也照旧可用。默认条目写两个地方：
> **本机 NVRAM 的 EFI 变量 `LoaderEntryDefault`**（跟机器走 → 每台机器各自记住自己的变体）+
> 盘上 `loader.conf` 的 `default`（跟盘走 → 兜底）。

## 目录结构

```
nixos-config/
├── flake.nix                    # 入口：inputs + 两主机 nixosConfigurations + 三份 homeConfigurations
├── users/                       # 用户维度：账户（系统侧）+ home（用户侧）+ 用户域共享模块
│   ├── chen/                    # 作者
│   │   ├── default.nix          # 账户属性（系统侧，无 home-manager 绑定）
│   │   ├── home.nix             # home 入口（shell + apps + llm + 远程桌面 + 个人应用）
│   │   ├── apps.nix             # 仅 chen 的 Nix 应用（li-ri）
│   │   └── flatpak.nix          # 仅 chen 的 Flatpak（QQ / tuxmath，--user 安装）
│   ├── mubimuba/                # 员工
│   │   ├── default.nix          # 账户属性（系统侧）
│   │   ├── home.nix             # home 入口（shell + apps，无 llm）
│   │   └── apps.nix             # 仅 mubimuba 的 Nix 应用（gimp）
│   ├── bumooby/                 # 管理员
│   │   ├── default.nix          # 账户属性（系统侧）
│   │   └── home.nix             # home 入口（shell + apps，与 mubimuba 同基线）
│   └── modules/                 # 用户域共享 home 模块（每个用户的 home.nix 都 import）
│       ├── shell.nix            # bash + direnv
│       ├── apps.nix             # 用户级共享应用包 = "每个用户都要的基础软件"的统一位置
│       ├── llm.nix              # llm-agents 工具（dsh / reasonix，仅 chen）
│       └── remote-desktop.nix   # KDE 远程桌面（KRDP/RDP）用户级：krdpserverrc + 用户服务
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
│   │   ├── disk.nix             # 盘：挂载 + 读盘 initrd 模块（跟盘走；故意不含 swapDevices）
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
    ├── remote-desktop.nix       # KDE 远程桌面（KRDP/RDP）系统侧：防火墙放行（包由 plasma6 自带）
    ├── nix.nix                  # 缓存源 / flakes / nh / allowUnfree
    ├── locale.nix               # 时区 / locale / fcitx5 / 字体
    ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire
    ├── printing.nix             # CUPS + 标签打印机（容错 + 定时重试）
    ├── flatpak.nix              # Flatpak 共享应用（Vivaldi/微信，系统级）
    └── packages.nix             # 系统级基础软件（含 vim —— root/救援也要用）
```

另有两个不在 `shared/` 里的脚本（被上面两个"认机器"模块调用，也可手动跑）：

```
scripts/detect-machine.sh        # 认机器：读 DMI/CPU 指纹查 machines/machine-keys.txt
scripts/set-default-entry.sh     # 把本机变体写成开机默认条目：本机 NVRAM 的 EFI 变量
                                 # LoaderEntryDefault + 盘上 loader.conf 的 default（幂等、永不失败）
```

## 机器 ↔ 硬件映射

映射的**唯一权威来源是代码**：`machines/<机器>/`（一个目录 = `hardware-configuration.nix`（生成，勿改）+ `default.nix`（手写尾巴）），`specialisation` 按机器名选择。

## 常用命令

```bash
# 系统级：机器 / 盘 / 服务 / 账户（按 hostname 自动取对应 host）
nh os switch

# 指定主机（员工机）
nh os switch --flake .#msi-wd

# 便携盘：机器变体自动选 —— 部署期认本机指纹，把默认启动条目写成「本机变体」：
# 一份进本机 NVRAM 的 EFI 变量 LoaderEntryDefault（跟机器走 → 每台机器各自记住自己，
# 来回换机器不用再手选，别的机器上 rebuild 也改不到它），一份进盘上的 loader.conf（兜底）。
# 所以 `nh os switch` 后直接重启就是本机桌面（开机零选择，菜单 5 秒内仍可手动选）
nh os switch

# 认机器 / 手动指定变体（一般用不到）
scripts/detect-machine.sh            # 打印本机对应的变体名
scripts/detect-machine.sh --probes   # 打印本机指纹（给 machine-keys.txt 加新机器时用）
nh os switch -s chen-laptop-intel    # 手动把「运行中的系统」切到指定变体
nh os switch -S                      # 忽略变体，回到基础系统（控制台救援入口）

# 注意：plain `nh os switch` 会让「运行中的系统」回到基础系统（只有控制台，没桌面）；
# 不想重启就切回本机变体：sudo systemctl restart auto-machine-specialisation

# 更新锁定输入
nix flake update

# 校验 flake（两主机 + 全部变体一起求值）
nix flake check
```

## 用户级构建（每个用户自己）

家目录由**用户自己**负责，不需要 sudo，也不会被系统 switch 覆盖。

```bash
# 激活/更新自己的家目录（自动按 $USER@$(hostname) 找 homeConfigurations，
# 找不到再退到 $USER；flake 取自 programs.nh.flake = /etc/nixos）
nh home switch

# 只构建不激活（想先看看会怎样）
nh home build
nh home switch --dry

# 显式指定（在别的目录/别的 checkout 里跑）
nh home switch --flake ~/nixos-config#mubimuba

# 世代与回滚（home-manager CLI 由 programs.home-manager.enable 装进用户环境）
home-manager generations
home-manager --rollback
```

几个要知道的点：

- **首次必须自己跑一次**：系统不再有 `home-manager-<user>.service`，装机后到跑
  `nh home switch` 之前，家目录里没有这套 dotfiles/用户服务（系统级包仍然可用，
  `nh` 本身在 `/run/current-system/sw/bin`，所以引导没问题）。
  管理员可代跑：`sudo -u mubimuba -i nh home switch`。
- **"每个用户都要的软件"放哪**：`users/modules/apps.nix`（+ `shell.nix`）—— 一份代码、
  各自 import，改一处所有人下次 `nh home switch` 生效；要"保证所有用户都有、用户改不掉"
  的放系统级 `shared/packages.nix`。
- **一个家目录只能有一个激活者**：不要为了"双保险"同时再挂 `home-manager.users.<user>`
  （NixOS 模块）—— 那会变成两个激活者抢同一批文件，用户 switch 的结果会被系统 switch
  或开机服务悄悄盖回去。要回到系统托管，就把 `homeConfigurations.<user>` 和
  `users/<user>/home.nix` 一起挪回 NixOS 模块。
- **PATH**：standalone 的世代落在 `~/.local/state/nix/profiles/home-manager`（`nh` 的约定），
  那个目录不在 NixOS 的 PATH 里；真正把包送进 PATH 的是 home-manager 自己的激活步骤
  `installPackages` —— 它把本代 `home.path`（`home.packages` 合并出来的 `home-manager-path`）
  用 `nix-env -i` 装进 **Nix 的命令式 profile** `~/.nix-profile`
  （`~/.nix-profile` → `~/.local/state/nix/profiles/profile` → `profile-N-link`）。
  于是 NixOS 已有的 `$HOME/.nix-profile/bin`（登录 shell、图形会话、systemd 用户服务全覆盖）
  自然就有这批包，而且每次 `nh home switch` 自动更新，`nix-env` 自己装的包也并存。
  ⚠️ **不要**为了"更快见效"手动把 `~/.nix-profile` 指到本代 `home-path`（含 `bin/` 的那份）：
  那是 `/nix/store` 里的只读目录，链接一旦指过去，**下一次**激活就会死在 `nix-env` 开锁文件上
  （`error: opening lock file ".../profiles/home-manager/home-path.lock": Read-only file system`，
  `nh home switch` 报 "Activation failed"），而且 `nix-env` / `nix profile install` 也一起失效。
  中招的判据与修法见下面「踩坑记录」。
- **配置的写权限**：员工机上仓库在 `/etc/nixos`（root 所有）→ 普通用户能 `nh home switch`
  激活，但改不了配置；要自助声明新包就在自己家目录 clone 一份仓库
  （`nh home switch --flake ~/nixos-config#<user>`），或请管理员改 `users/<user>/apps.nix`。

## 注意事项 / 踩坑记录

- **维度判据**：机器硬件 → `machines/<机器>/`（`hardware-configuration.nix` 生成 + `default.nix` 手写尾巴）；
  一份 OS 的身份 + 盘 → `os-disk/<name>/`；机级服务（各安装共用）→ `shared/`；人 → `users/`。
  `os-disk/<name>/default.nix` 只做接线：把 machines / disk / shared / users 拼起来。
  跨机器**可变**的硬件差异（GPU/CPU）走 `specialisation`，不新增目录。
- **应用放哪，判据是"机器要"还是"人要"**：
  - 机器要（root/sudo、救援 TTY 也要能用的，如 `vim`）→ `shared/packages.nix`（系统级，
    `nh os switch` 生效，对所有用户可用、用户改不掉）；
  - **每个用户都要的桌面/终端应用** → `users/modules/apps.nix`（+ `shell.nix`）：
    一份代码，各人 `home.nix` import，改一处、各人 `nh home switch` 后生效；
  - 某个人自己的 → `users/<name>/`：Nix 包放 `apps.nix`，Flatpak 放 `flatpak.nix`
    （经 nix-flatpak 的 home-manager 模块以 `--user` 安装，跟人走，别的机器拿不到）；
  - `os-disk/<name>/default.nix` **只做接线，不放任何应用**。
- **用户级构建（2026-09-15）**：home-manager 从 "NixOS 模块" 改为 **standalone
  `homeConfigurations`**（`flake.nix` 的 `mkHome`，每人 `"<user>@<host>"` 与 `"<user>"` 两个名字），
  系统侧删掉全部 `home-manager.users.*` 与 `useGlobalPkgs/useUserPackages`。动机：用户级改动
  不必 sudo、不触发系统 switch（也就不会把运行中的系统打回 specialisation 基础系统），
  且用户自己掌握家目录世代与回滚。代价：装机后各人自跑一次 `nh home switch`；
  PATH 由 home-manager 激活步骤把本代 `home-path` 装进 `~/.nix-profile` 兜（详见"用户级构建"一节）。
- **standalone 下 `~/.nix-profile` 指到本代 home-path 会让激活永久失败（2026-09-15 修）**：
  早期 `users/modules/standalone.nix` 为了复用 NixOS 的 `$HOME/.nix-profile/bin`，在激活末尾
  执行 `ln -sfn <本代>/home-path ~/.nix-profile`。第一次 `nh home switch` 会成功（那时
  `~/.nix-profile` 还不存在，Nix 用它自己的默认 profile 装完包之后才被这行覆盖），但从
  **第二次**起必然失败：
  ```
  installing 'home-manager-path'
  error: opening lock file "/home/chen/.local/state/nix/profiles/home-manager/home-path.lock": Read-only file system
  ```
  原因：`~/.nix-profile` → `.../profiles/home-manager/home-path`，而 `home-manager` 是指向
  `/nix/store/*-home-manager-generation` 的符号链接 —— 链接穿过它落进**只读**的 `/nix/store`；
  激活的 `installPackages` 步骤跑 `nix-env -i`，它会按当前 profile 路径开 `<profile>.lock`
  并创建 `<profile>-N-link`，于是 EROFS。
  该模块已删除（PATH 由 home-manager 自己装进命令式 profile，见「用户级构建 → PATH」）。
  已中招的机器修一次即可（别的用户只要 `readlink ~/.nix-profile` 不含 `home-path` 就不用管）：
  ```
  readlink ~/.nix-profile        # 含 home-path 才是中招
  ln -sfn ~/.local/state/nix/profiles/profile ~/.nix-profile
  nh home switch
  ```
- **KDE 远程桌面（KRDP/RDP，2026-09-15）**：服务本体是**用户级**的 `krdpserver`（Plasma 6 自带，
  图形入口「系统设置 → 远程桌面」），所以整套在 `users/modules/remote-desktop.nix`：写
  `~/.config/krdpserverrc` + 在 `~/.config/systemd/user` 放同名单元
  `app-org.kde.krdpserver.service`（上游 krdp 仓库把它 preset 成永不默认启用，见其
  `server/00-krdp.preset`）
  + `plasma-workspace.target` 的 want 链接 = 登录自启。系统侧 `shared/remote-desktop.nix` 只做
  一件事：防火墙放行（krdp 包本身由 `services.desktopManager.plasma6.enable` 自带 —— 它在
  nixpkgs plasma6 模块的 `optionalPackages` 里，krdpserver / kcm_krdpserver / 上游单元都出自
  那一个包；用户侧 ExecStart 直接引用 store 路径，所以不靠系统包装没装）。
  **端口因此要写两处** —— `os-disk/portable-chen/default.nix`
  （系统侧，只影响防火墙）与 `users/chen/home.nix`（用户侧，真的监听），只改一处会出现
  "服务在听一个端口、防火墙只放另一个"。几个坑（文件注释里有展开）：
  - 单元名不能改：portal 靠 systemd 单元的 `app-` 前缀识别调用者 id `org.kde.krdpserver`，
    KCM 也按这个名字经 systemd D-Bus 开关服务；
  - `krdpserverrc` 必须是**可写真实文件**：KConfig 是"就地写、跟随符号链接"，store 符号链接会让
    KCM 保存失败 → 用 `home.activation` + `install` 写；代价是 KCM 里改的端口/设置会被下次
    `nh home switch` 覆盖回声明值；
  - 证书：`Server::start()` 在证书文件缺失时**直接拒绝启动**（不是文档说的"临时自签"），而 KCM
    生成用的是 `-days 1`（本机 8/29 那份 8/30 就过期了）→ ExecStartPre 自己签 10 年的（缺/过期才签）；
  - 无人值守：多一个 oneshot `krdp-portal-authorize`，在服务前把 `org.kde.krdpserver` 预授权给
    portal（等价 `flatpak permission-set kde-authorized remote-desktop org.kde.krdpserver yes`，
    也是 KCM 打开开关时做的事），否则第一次连接会在**本机屏幕**上弹授权框；
  - 认证走 PAM（`SystemUserEnabled=true` → `/etc/pam.d/login`，即系统账号密码），不往 KWallet 存密码；
  - ⚠️ 服务开着 = 物理无人时也能被远程接管桌面，而且远程登录时本机屏幕也是解锁的；按"局域网内
    可信 + 高位端口"来用，别把端口映射到公网。
- **ssh 端口与防火墙（2026-09-15 修）**：`shared/ssh.nix` 原来只写 `services.openssh.settings.Port`，
  而 sshd 的监听端口与防火墙放行都看 `services.openssh.ports`（默认 `[22]`）→ 现象是 sshd
  同时监听 555 **和** 22、防火墙只放 22，`ssh -p 555` 从别的机器连不上（`-p 22` 反而能连）。
  现在改成 `ports = [ cfg.port ]`（openFirewall 默认 true，自动带上放行）：**sshd 只监听 555、
  防火墙也只放 555**。⚠️ 22 从此不再监听也不再放行 —— 要回到标准端口就 `my.ssh.port = 22;`。
- **生成与手写分离**：`nixos-generate-config --no-filesystems` 的产物**原样**放
  `machines/<机器>/hardware-configuration.nix`（勿手改，重生成即覆盖）；生成器不产出的
  NVIDIA 驱动 / 固件 / 图形 / 蓝牙，写进 `machines/<机器>/default.nix`（imports 上面）。
  挂载行（fileSystems/swapDevices）跟盘走，放 `os-disk/<name>/disk.nix`。
  `--no-filesystems` 是省事关键：产物天然不含 fileSystems/swap，无需手工"砍"。
- **便携盘用 specialisation，不用多 host**：`os-disk/portable-chen` 的基础系统只带盘
  （挂载 + 读盘 initrd 模块，见 `disk.nix`）、不带机器硬件 → **能引导，但只有控制台**
  （没有显卡驱动），所以它是**救援入口**（`nh os switch -S` 后重启，或菜单里手选基础条目）；
  `chen-desktop` / `chen-laptop-amd` / `chen-laptop-intel` 是**开机菜单里的机器变体**，换机器零命令。
  ⚠️ 代价：每个变体多出一份系统闭包（共享的包不重复，额外≈差异部分）。
  曾试过"多 host 共享一块盘"（两个 host 目录各导入同一份盘挂载），**已放弃**：换机器必须在
  **目标机上**跑 `nh os switch --flake .#<host>`，而且菜单里"另一台"的条目只是**最后一次激活时的
  过期快照** —— 菜单能让你回到过去，却切不到另一台的当前配置。若将来某台机器的差异超出
  "显卡变体"范围（例如要不同的用户/服务），那才该另开独立 host。
- **机器变体自动选（2026-09-14 两段式；2026-09-15 补运行期也改；2026-09-15 改存本机 NVRAM）**：
  菜单"选哪条"是 bootloader 的事、系统里改不了 → 两段式，都靠 `machines/machine-keys.txt`（指纹表）
  + `scripts/detect-machine.sh` 认机器，找条目/写默认条目的活儿在 `scripts/set-default-entry.sh`
  （A/B 共用同一份实现）。默认条目写**两个目的地**：
  - **本机 NVRAM**（主记忆）：EFI 变量 `LoaderEntryDefault`。systemd-boot 优先用它、覆盖
    `loader.conf`（`loader.conf(5)`：default 可以在菜单里改，改了就存成 EFI 变量，
    "overriding this option"）。它在**主板**上、跟机器走不跟盘走 → **每台机器各自记住自己的变体**：
    第一次在那台机器上开过机之后，来回换机器都不用再手选，在别的机器上 rebuild 也改不到它
    （盘上那份会被改）。⚠️ 第一次到某台机器（从没种过这个变量）仍需手选一次 —— 原理限制：
    菜单在任何系统代码之前就定了，那时读不到 DMI。
  - **盘上 `$BOOT/loader/loader.conf`**（兜底）：跟盘走。NixOS 的 builder 每次 rebuild 都会先把它
    重写成**基础系统**条目，所以 B/A 每次都得补写；没有 NVRAM（固件不给写变量 / NVRAM 被清）时
    全靠这一份。
  - **部署期** `os-disk/portable-chen/boot-machine.nix`：`nh os switch` 装完 bootloader 之后
    （`extraInstallCommands`，排在 builder 之后）读本机 DMI/CPU，把**本机变体**写成默认条目（两处）
    → 开机倒计时（`boot.loader.timeout`，默认 5s）结束直接进本机。**不做这一步默认条目就是基础系统：
    能进控制台，但没有显卡驱动（进不了桌面）**。
  - **运行期** `os-disk/portable-chen/auto-machine.nix`：把盘插到**没 rebuild 过**的机器上时，
    默认条目还是上一个机器的；开机后一个 oneshot 服务
    （1）先按本机指纹写默认条目（两个目的地，幂等）→ 那之后每次开机都零操作；
    （2）再调 `.../specialisation/<机器>/bin/switch-to-configuration test` 把**当前这次**也切到
    对的那台（`test` 只激活，不重写 /boot、不动 profile；已在正确变体里时是空操作），
    切完把 `display-manager` 重启一次。
    ⚠️ 故意不与 `display-manager` 建顺序关系（`switch-to-configuration` 自己会 start/restart 它，
    排前/排后都会形成环），所以这一路径上桌面会闪一下。
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
- **选错变体不会变砖**：Intel 机带着整套 nvidia 驱动也能正常进桌面，最坏是驱动加载失败
  + 日志噪音 + 性能退化；不要为了"怕选错"而给便携盘另开 host 或拆分目录。
- **不要给不同变体配不同内核**：变体共用同一份内核闭包，各自钉不同版本就得编译两份内核。
- **BitLocker**：内盘 Windows 已加密，不要为了双系统去改 BIOS 的 Secure Boot / TPM / 启动顺序，
  否则会索要恢复密钥。
- 仓库锁定的 nixpkgs 分支为 `nixos-26.05`，home-manager 为 `release-26.05`，
  两者需保持大版本一致。standalone 的 `mkHome` 用 `import nixpkgs { config.allowUnfree = true; }`
  构造 pkgs —— **`shared/nix.nix` 里的 nixpkgs 配置若有变动（overlay / config），
  这里要同步改**，否则系统侧与用户侧会漂移成两份不同的包。

## 待办（未决 / 未验证）

- **时间策略未定**：用 `time.hardwareClockInLocalTime`，还是 Windows 侧改（双系统 RTC 差 8 小时）。
  仓库目前**两处都没设** —— 定下来之前别只改一半。
- **Intel 内显无 VA-API 硬解**：`/run/opengl-driver/lib` 里没有 `iHD` / `vpl`，视频解码全走 CPU。
  修法（取消一行注释即可）写在 `machines/chen-laptop-intel/default.nix`。
- **只做了构建/脚本验证，没做真机重启验证**：
  1. 基础系统当救援入口（`nh os switch -S` 后重启，或在菜单里手选基础条目，确认能挂盘、能重建）；
  2. 运行期写默认条目：**"写"这半步已实测**（2026-09-15 18:56 那次开机，journal 里
     `set-default-entry: 盘上默认条目 nixos-generation-79-specialisation-chen-desktop.conf
     → ...-laptop-amd.conf`）；**"下一次开机不碰菜单真的按它预选"还没验**（要一次不碰键的重启）。
  3. EFI 变量 `LoaderEntryDefault`（本机 NVRAM）：脚本层面已沙箱验证（首次写 / 幂等 / 固件拒绝 /
     `bootctl` 不存在 都不影响退出码），**还没在这台固件上真写过**，也没验过 systemd-boot 是否吃它
     （`bootctl status` 报 `Default entry control ✓`，但只有重启才算数）。
  4. 悬空变量：EFI 变量钉的是带代数的条目 id。若那台机器长期不回去、那一代又被 `nh clean` 删掉，
     那次开机会退化成 systemd-boot 自己的排序结果（**未实测**，可能落到没显卡驱动的基础系统）；
     下次在那台机器开机时 A 会按"存在的最大代"重写变量自愈。
  5. ⚠️ 开机菜单里按 `d` 会把当前高亮那条写成 `LoaderEntryDefault`（写在本机 NVRAM 上，换机器也带着）。
     两个方向都成立：它覆盖我们写的值；下次开机 A 又会按本机指纹把它改回本机变体。
     想长期钉住别的条目，得先停掉这个服务：`sudo systemctl disable --now auto-machine-specialisation`。
- **RDP 只做了构建/脚本验证，没做真机连通验证（2026-09-15）**：已验证的是求值 + 构建
  （`nix build .#homeConfigurations.chen.activationPackage`；`nix eval` 两个 host 的
  `networking.firewall.allowedTCPPorts` = portable-chen `[22 59599]` / msi-wd `[22]`；
  证书脚本在 /tmp 下试过"缺证书 / 有效证书 / 只剩不到一天"三条路径）。真正要验的是拿另一台
  机器 `xfreerdp /v:<ip>:59599 /u:chen` 或 Windows 的 mstsc 连一次，确认三件事：防火墙放行
  生效、PAM 认证能过、连接时本机屏幕不弹授权框。另注意 `nh home switch` 会重写
  `~/.config/krdpserverrc`，所以端口/认证方式请在 nix 里改。

## 依赖输入

| 输入 | 用途 |
|------|------|
| nixpkgs | 主包源（NJU 镜像，26.05） |
| nix-flatpak | flatpak 声明式安装模块（系统级 + home-manager 用户级） |
| home-manager | 用户环境管理（standalone `homeConfigurations`，由各用户自己 `nh home switch` 激活） |
| llm-agents | dsh / reasonix 等 LLM 工具包（仅作者机 chen 使用） |
