# 已装机器：日常维护

命令以员工机 `msi-wd` 为例，换机器把 `msi-wd` 换成对应 `<HOST>` 即可。


## 2. 一页速查

| 想干什么 | 谁 | 命令 |
|---|---|---|
| 更新系统 | 管理员 | `nh os switch -H msi-wd` |
| 只构建 / 只打印 | 管理员 | `nh os build` / `nh os switch -H msi-wd -n` |
| 更新自己的家目录 | 用户 |`nh home switch` |
| 看 / 回滚系统世代 | 管理员 | `nh os info` / `nh os rollback` |
| 看 / 回滚家目录世代 | 用户 | `home-manager generations` / `home-manager --rollback` |
| 升级输入（nixpkgs 等） | **只在作者机** | `nix flake update` → commit → push（§8） |
| 清 nix 垃圾 | 自动（每周） | 手动 `sudo nh clean all` |

## 3. 命令约定

- `nh os switch` 按**本机运行中的 hostname** 补属性名；不是 `msi-wd` 时报
  `does not provide attribute 'nixosConfigurations.<本机 hostname>'` → 用 `-H msi-wd` 显式指定。
- `nh` 前**不要**加 sudo（会被拒绝 `Don't run nh os as root`）；`nh` 自己提权。
- `nh home switch` 按 `$USER@$(hostname)` 选，找不到退到 `$USER`；显式用 `-c <user>@<host>`。
- `-s` / `-S` 是"选哪份配置"（specialisation），员工机没有变体、**用不到**；便携盘见 §7。

## 4. 仓库与同步（`/etc/nixos`）

root 所有的 git 工作树。**纪律：改动只在作者机做，这里只 pull、不手改**；新文件要
`sudo git -C /etc/nixos add -A` 才对 flake 可见。

```bash
# 方式 A（需网络）：root 没有 GitHub 密钥，直接用 https
sudo git -C /etc/nixos pull --ff-only https://github.com/cmlong05/nixos-config.git main

# 方式 B（没网络）：从作者的移动盘取
sudo git -C /etc/nixos fetch /run/media/<你>/<卷标>/nixos-config main
sudo git -C /etc/nixos merge --ff-only FETCH_HEAD
```

⚠️ **不要 `git checkout -- .` / `reset --hard`**：会连本机 `disk.nix`、`hardware-configuration.nix`
一起还原成占位值（重启可能挂不上盘）。这两处是装机时按本机硬件改的，属正常现象；pull 被它们挡住时：

```bash
sudo cp -a /etc/nixos/os-disk/msi-wd/disk.nix /tmp/d.bak            # 留底
sudo cp -a /etc/nixos/machines/employee-3600/hardware-configuration.nix /tmp/h.bak
sudo git -C /etc/nixos stash push -- os-disk/msi-wd/disk.nix machines/employee-3600/hardware-configuration.nix
sudo git -C /etc/nixos pull --ff-only https://github.com/cmlong05/nixos-config.git main
sudo cp -a /tmp/d.bak /etc/nixos/os-disk/msi-wd/disk.nix            # 放回本机版本
sudo cp -a /tmp/h.bak /etc/nixos/machines/employee-3600/hardware-configuration.nix
sudo git -C /etc/nixos add -A
```

## 5. 更新系统

以 `mubimuba` 登录，先按 §4 拉改动，然后：

```bash
# 清除并重建为bumooby的登录环境。如果不加”-“，将任然不吃mubimuba的部分登陆环境，导致$XDG_CACHE_HOME任然为mubimuba的
su - bumooby
nh os switch
```

- **改了内核 / NVIDIA 驱动 / initrd** → `sudo reboot`（内核只有 `nix flake update` 后才变）。
- 只改服务、包、用户 → 一般不用重启。
- 第一次拉进新 `flake.lock` 要下载不少；缓存源 SJTU 报 HTTP/2 流中断可临时去掉。

## 6. 用户级（各人自己）

```bash
nh home switch            # 每个用户在自己的账号下跑；管理员可代跑 sudo -u <user> -i nh home switch
nh home build             # 只构建；nh home switch -c mubimuba@msi-wd 显式指定
```

## 7. 便携盘 `portable-chen`

| 命令 | 作用 |
|---|---|
| `nh os switch` | 日常就这一条：激活基础系统 + 装 bootloader，并把本机变体写成开机默认条目 |
| `nh os switch -s <变体>` | 只把运行中的系统切到该变体，不重启 |
| `nh os switch -S` | 不要变体 → 落在基础系统（控制台救援入口） |

无参数 `nh os switch` 后运行中的是基础系统（没桌面），**重启一次**就进本机变体；不想重启用
`scripts/detect-machine.sh` 查变体名后 `-s <变体>`，或 `sudo systemctl restart auto-machine-specialisation`。
原理见 README §6。

## 8. `nix flake update` 只在作者机做

员工机上各自 update 会导致两台机器版本漂移。正确姿势：作者机 `nix flake update` → 构建验证 →
commit `flake.lock` → push，员工机只 pull。
升级内核 / NVIDIA 后按 §5 重启。

## 9. 改配置速查

| 改什么 | 改哪里（作者机） | 生效 |
|---|---|---|
| 系统级包（root / 救援也要） | `shared/packages.nix` | `nh os switch -H msi-wd` |
| 机级服务（ssh / 桌面 / 打印 / flatpak…） | `shared/*.nix` | 同上 |
| 账户（组、描述、是否 `wheel`） | `users/<name>/default.nix` | 同上 |
| 机器硬件（显卡 / 固件尾巴） | `machines/employee-3600/default.nix` | 同上 |
| 硬件探测（**生成物，勿手改**） | `machines/employee-3600/hardware-configuration.nix` | 重生成后同上 |
| 挂载 / swap（跟盘走） | `os-disk/msi-wd/disk.nix` | 同上（`/boot` 改动要重启） |
| 人人要的桌面 / 终端应用 | `users/modules/apps.nix` | 各人 `nh home switch` |
| 某个人的 Nix 应用 | `users/<name>/apps.nix` | 该用户 `nh home switch` |
| office 网络文件夹链接 | `users/mubimuba/desktop.nix` | mubimuba `nh home switch`；首次双击输一次密码并勾「记住密码」 |
| 登录界面列哪些用户 | `os-disk/msi-wd/default.nix`（`hiddenUsers`） | `nh os switch -H msi-wd` |
| 时区 / 硬件时钟(RTC 走本地时间) / locale / 字体 / 输入法 | `shared/locale.nix` | 同上；RTC 本身可用一次 `sudo hwclock --systohc` 立即改成本地时间 |

## 10. 回滚

```bash
nh os info / nh os rollback        # 系统级（-n 只打印，-a 先问）；也能在开机菜单里选旧世代
home-manager generations / home-manager --rollback   # 用户级
```

`nh os info` 提示 `Profile is out of sync with /run/current-system` = 上次 switch 激活失败 → 重跑 switch 或 rollback。

## 11. 清理与 Flatpak

- `nh-clean.timer` 每周跑 `nh clean all --keep-since 7d --keep 5`（回滚窗口就这么大）；手动 `sudo nh clean all`。
  空间不足先清，再 `nix-collect-garbage -d`；查看用 `df -h /nix`。
- Flatpak 系统级应用由 `flatpak-managed-install.service` 在激活时安装，`nh os switch` 会顺带更新；
  失败重试 `sudo systemctl start flatpak-managed-install.service`，`journalctl -u flatpak-managed-install -n 100`。
  用户级 flatpak 改完跑 `nh home switch`。
