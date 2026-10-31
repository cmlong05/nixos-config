# 已装机器：日常维护
命令以员工机 `msi-wd` 为例

## 2. 一页速查

| 目标 | 谁 | 命令 |
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
- `nh home switch` 按 `$USER@$(hostname)` 选，找不到退到 `$USER`；显式用 `-c <user>@<host>`。
- `-s` / `-S` 是"选哪份配置"（specialisation），员工机没有变体、**用不到**；便携盘见 §7。
- 便携盘上的 `nh os switch` 会自动按物理网卡 MAC 选出本机变体并补 `-s`；
  显式 `-s`、`-S`、`-H` 和 `--target-host` 不会被覆盖，其他 nh 子命令保持原样。

## 4. 仓库与同步（`/etc/nixos`）

```bash
# 直接即可
git pull
# 方式 A（网络）：root 没有 GitHub 密钥，直接用 https
sudo git -C /etc/nixos pull --ff-only https://github.com/cmlong05/nixos-config.git main
# 方式 B（没网络）：从作者的移动盘取
sudo git -C /etc/nixos fetch /run/media/<你>/<卷标>/nixos-config main
sudo git -C /etc/nixos merge --ff-only FETCH_HEAD
```

## 5. 更新系统

```bash
# 如果是用户 mubimuba 需要清除并重建为bumooby的登录环境，
# 需加”-“ 以切换 $XDG_CACHE_HOME 到 bumooby 的
su - bumooby
nh os switch
```
- **改了内核 / NVIDIA 驱动 / initrd** → `sudo reboot`（内核只有 `nix flake update` 后才变）。
- 只改服务、包、用户 → 一般不用重启。

## 6. 用户级（各人自己）

```bash
# 每个用户在自己的账号下跑；
nh home switch
# 管理员可代跑
sudo -u <user> -i nh home switch
```

## 7. 便携盘 `portable-chen`

把一台新 PC 加入便携盘（不重装系统）见
[`DEPLOY-ADD-PC.md`](./DEPLOY-ADD-PC.md)。

| 命令 | 作用 |
|---|---|
| `nh os switch` | 自动选本机变体，激活 + 装 bootloader，并把本机变体写成开机默认条目 |
| `nh os switch -s <变体>` | 只把运行中的系统切到该变体，不重启 |
| `nh os switch -S` | 不要变体 → 落在基础系统（控制台救援入口） |

便携盘的 `nh` 包装器 (os-disk/portable-chen/nh-auto-specialisation.nix <--scripts/nh-local-wrapper.sh ) 在 `portable-chen` 上自动执行 `scripts/detect-machine.sh`；确认当前变体可运行 `scripts/which-spec.sh`。认不出机器或 MAC 冲突时包装器会拒绝执行，避免误切基础系统；确实需要控制台救援入口时显式运行 `nh os switch -S`。原理见 README §6。

## 8. `nix flake update` 只在作者机做

员工机上各自 update 会导致两台机器版本漂移。正确姿势：作者机 `nix flake update` → 构建验证 →
commit `flake.lock` → push，员工机只 pull。
升级内核 / NVIDIA 后需重启。

## 9. 改配置速查

| 改什么 | 改哪里（作者机） | 生效 |
|---|---|---|
| 系统级包（root / 救援也要） | `shared/packages.nix` | `nh os switch -H msi-wd` |
| 机级服务（ssh / 桌面 / 打印 / flatpak…） | `shared/*.nix` | 同上 |
| 账户（组、描述、是否 `wheel`） | `users/<name>/default.nix` | 同上 |
| 机器硬件（显卡 / 固件尾巴） | `machines/employee-3600/default.nix` | 同上 |
| 硬件探测（**生成物，勿手改**） | `machines/employee-3600/hardware-configuration.nix` | 重生成后同上 |
| 挂载 / swap（跟盘走） | `os-disk/msi-wd/disk.nix` | 同上（`/boot` 改动要重启） |
| 人人要的桌面 / 终端应用 | `users/__modules/apps.nix` | 各人 `nh home switch` |
| 某个人的 Nix 应用 | `users/<name>/apps.nix` | 该用户 `nh home switch` |
| office 网络文件夹链接 | `users/mubimuba/desktop.nix` | mubimuba `nh home switch`；首次双击输一次密码并勾「记住密码」 |
| 登录界面列哪些用户 | `os-disk/msi-wd/default.nix`（`hiddenUsers`） | `nh os switch -H msi-wd` |
| 时区 / 硬件时钟存 UTC / locale / 字体 / 输入法 | `shared/locale.nix` | 同上

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
