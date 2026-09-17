# 员工机（msi-wd）日常维护 / 更新

系统装好之后的**所有**日常操作都在本文件。
**全新安装**（会抹盘的一次性流程）看 [`DEPLOY-INSTALL.md`](./DEPLOY-INSTALL.md)。

适用机器：`msi-wd`（员工机，内盘独立安装）。作者机的规则基本一致，
差别只在于仓库路径（作者机 `/etc/nixos` 是指向 `~/nixos-config` 的软链）与 ssh 端口（作者机 555），
外加一处**必须**知道的差别：机器变体（`specialisation`）与 `-s` / `-S` —— 见第 5 节。

---

## 1. 一页速查

| 想干什么 | 谁来做 | 命令（在 msi-wd 上） |
|---|---|---|
| **把系统更新到仓库当前状态**（最常做） | 管理员 `bumooby` | `sudo git -C /etc/nixos pull --ff-only` → `nh os switch -H msi-wd` |
| 只构建不激活（先看看） | 管理员 | `nh os build` 或 `nh os switch -H msi-wd -n` |
| 更新自己的家目录 / dotfiles / 用户级应用 | **每个用户自己** | `nh home switch`（**不要** sudo） |
| 看 / 回滚系统世代 | 管理员 | `nh os info` / `nh os rollback` |
| 看 / 回滚家目录世代 | 每个用户自己 | `home-manager generations` / `home-manager --rollback` |
| 升级 nixpkgs 等输入 | **只在作者机做** | `nix flake update` → commit → push |
| 清 nix 垃圾 | 自动（每周） | 手动：`sudo nh clean all` |
| Flatpak 应用 | 系统 switch 时自动 | 失败重试：`sudo systemctl start flatpak-managed-install.service` |

一条命令记住：**系统级要管理员（在 `wheel`），但 `nh` 命令前不要加 sudo —— `nh` 自己会提权；用户级各人自己跑。**

---

## 2. 两层构建，别搞混

| 层 | 入口 | 需要 sudo? | 管什么 |
|---|---|---|---|
| 系统级 | `nh os switch` | **否**（`nh` 内部 sudo 提权） | 机器 / 盘 / 服务 / 账户 / `shared/packages.nix` |
| 用户级 | `nh home switch` | **否** | 家目录：dotfiles、用户服务、用户应用 |

- 系统侧**不激活任何家目录**（home-manager 只以 `homeConfigurations` 存在），
  所以 `nh os switch` 不会动用户家目录，也不会被用户级改动影响。
- `mubimuba` 不在 `wheel`：他能 `nh home switch`，**不能** `nh os switch`。
- 两个入口都用**位置参数**（nh 4.x **没有** `--flake` 这个选项）：
  `programs.nh.flake = "/etc/nixos"`（`shared/nix.nix`）把 `NH_FLAKE` 设成 `/etc/nixos`。
  - `nh home switch` 按 `$USER@$(hostname)` 自动选家目录配置。
  - `nh os switch` 按**本机运行中的 hostname** 把属性名补成
    `<flake>#nixosConfigurations.<hostname>`。本机 hostname 还不是 `msi-wd` 时（刚装好、
    或机器改过名）它会去找一个不存在的属性，报
    `error: flake ... does not provide attribute 'nixosConfigurations.<本机 hostname>'`
    → 用 `nh os switch -H msi-wd` 显式指定主机
    （等价写法：`cd /etc/nixos && nh os switch .#msi-wd`）。
- **不要**在 `nh` 前面加 `sudo`：`nh os switch` / `nh os rollback` 自己会 sudo 提权，
  以 root 直接跑会被拒绝（`Don't run nh os as root`）。带 sudo 的只有 `git`、`systemctl`
  这类命令。
- `-H` / `-s` / `-S` 都是「**选哪份配置**」的选项，不是"更彻底的 switch"：
  员工机没有变体，`-s` / `-S` 用不到；便携盘的三种写法见第 5 节。

---

## 3. 员工机上的仓库长什么样

- 位置 **`/etc/nixos`**，**root 所有**（装机时由 `DEPLOY-INSTALL.md` 第 4 步拷进去的
  git 工作树，`origin` = `git@github.com:cmlong05/nixos-config.git`）。
- 因此：
  - 改配置、拉更新 → **只有管理员**（`sudo`）能做；
  - 普通用户能读它、能 `nh home switch`（求值只读），但改不了。
- **纪律：改动永远在作者机做**（`~/nixos-config` → commit → push），
  员工机上**只 pull、不手改**。手改 `/etc/nixos` 里的文件会让下一次 `git pull` 冲突。
- ⚠️ **flake 只把 git 索引里的文件当源码**：新加的文件必须 `git add`（在作者机提交即可），
  否则求值直接报 `... is not tracked by Git`。在员工机上临时手改了文件，也要
  `sudo git -C /etc/nixos add -A` 之后才可见。

---

## 4. 标准流程：怎么更新 msi-wd 的系统

前提：以 **`bumooby`**（在 `wheel`）登录，能 `sudo`。

### 4.1 把作者的改动带到员工机

**方式 A（常规，需网络）：git pull**

```bash
sudo git -C /etc/nixos status --short     # 先看有没有本地手改（理想是空的）
sudo git -C /etc/nixos remote -v          # origin 是 SSH（git@github.com:...）

# origin 走 SSH，但 root 通常没有 GitHub 密钥 → 公开仓库直接走 https 最省事：
sudo git -C /etc/nixos pull --ff-only https://github.com/cmlong05/nixos-config.git main
```

- `--ff-only`：只接受快进。若报 "not possible to fast-forward"，说明员工机上
  有人手改/本地提交过 → 先 `sudo git -C /etc/nixos status` 看清楚，
  必要时 `sudo git -C /etc/nixos stash` 或 `checkout -- .` 丢掉本地改动再拉。
- 若哪天仓库转私有，就得给 root 配部署密钥（或改用下面的方式 B）。

**方式 B（没网络 / 更习惯用盘）：从作者移动盘取改动**

作者机的 `~/nixos-config`（= 移动盘上那份系统里的仓库）与员工机的 `/etc/nixos`
同源，可以直接用 git 从本地路径拉：

```bash
# 把移动盘插上，找到它挂载点（KDE 自动挂载一般在 /run/media/<用户>/<卷标>）
sudo git -C /etc/nixos fetch /run/media/<你>/<卷标>/nixos-config main
sudo git -C /etc/nixos merge --ff-only FETCH_HEAD
```

实在不行就整份覆盖（注意 `cp -a` **不会删**上游已删掉的文件）：

```bash
sudo cp -a /run/media/<你>/<卷标>/nixos-config/. /etc/nixos/
sudo git -C /etc/nixos add -A     # 让所有文件进索引，新文件才对 flake 可见
```

### 4.2 系统 switch

```bash
nh os switch -H msi-wd        # 不要 sudo：nh 自己会提权
```

- `-H msi-wd` 显式指定 `nixosConfigurations.msi-wd`。不加 `-H` 时 nh 用**本机运行中的
  hostname** 去补属性名：本机 hostname 就是 `msi-wd` 时两者等价，不是 `msi-wd` 时会报
  `does not provide attribute 'nixosConfigurations.<本机 hostname>'`。
  等价写法：`cd /etc/nixos && nh os switch .#msi-wd`。
- 想先看会做什么、不激活：`nh os build`（只构建）或 `nh os switch -H msi-wd -n`（只打印）。
- 第一次拉进新 `flake.lock` 时可能要下载不少东西；缓存源配在 `shared/nix.nix`
  （USTC + SJTU），SJTU 对新路径同步不及时，遇 HTTP/2 流中断可临时去掉它。

### 4.3 什么时候要重启

- **改了内核 / NVIDIA 驱动 / initrd** → 必须重启：`sudo reboot`。
  （内核来自 nixpkgs，只有 `nix flake update` 之后才会变，见第 6 节。）
- 只改了服务、包、用户 → 一般不用重启；`nh os switch` 已经激活。
- 想让新系统成为**开机默认**：`nh os switch` 本来就会写入 boot 默认条目。

### 4.4 用户级（各人自己，不需要 sudo）

**只要动了用户级配置**（`users/modules/*`、`users/<name>/*`）才需要跑。
`nh os switch` **不会**替用户激活家目录。

```bash
nh home switch            # 每个用户在自己的账号下跑一次
```

- 管理员可代跑：`sudo -u bumooby -i nh home switch`、`sudo -u mubimuba -i nh home switch`。
- 只构建不激活：`nh home build`；显式指定：`nh home switch ~/nixos-config#mubimuba`。
- `mubimuba` 想自助装包又改不了 `/etc/nixos`：在自己家目录 clone 一份仓库，
  然后 `nh home switch ~/nixos-config#mubimuba`。

---

## 5. 便携盘（portable-chen）：`nh os switch` 还是 `-s` / `-S`？

员工机 `msi-wd` 只有一个 `nixosConfigurations.msi-wd`、**没有机器变体**，
所以 `-s` / `-S` 在员工机上**永远用不到**。作者机（便携盘，hostname 就是
`portable-chen`，三台机器的硬件差异走 `specialisation`）要分清三种写法：

| 命令 | 作用 | 什么时候用 |
|---|---|---|
| `nh os switch` | 构建并激活**基础系统** + 装 bootloader；装完由 `os-disk/portable-chen/boot-machine.nix` 把**本机变体**写成开机默认条目 | **日常就这一条**（不要 sudo、不要 `-H`、不要 `-s`） |
| `nh os switch -s <变体>` | 只把**运行中**的系统切到指定变体，不重启 | 不想重启、现在就要进变体（显卡驱动 / 桌面） |
| `nh os switch -S` | 明确**不要**变体那一步 → 运行中的系统落在基础系统 | 救援入口（只有控制台，没显卡驱动） |

- 变体名 = 本机硬件指纹命中的目录名（`chen-desktop` / `chen-laptop-amd` /
  `chen-laptop-intel` 之一）：`scripts/detect-machine.sh` 直接打印本机该用哪个，
  `--probes` 打印指纹（往 `machines/machine-keys.txt` 加新机器时用）。
- `-s` / `-S` 是 **nh 自带**的 specialisation 选项（`nh os switch --help` 里的
  `-s, --specialisation` / `-S, --no-specialisation`），不是本仓库的约定。
  这里的 `-H` 同样不用加：本机 hostname 就是 `portable-chen`，nh 会自己补属性名。

⚠️ **plain `nh os switch` 之后「运行中的系统」是基础系统**（控制台那条，没显卡驱动），
但**开机默认条目**已经被 `boot-machine.nix` 指向本机变体 —— 所以**重启一次**
（菜单 5 秒倒计时后零操作）就进本机变体。不想重启就二选一：

```bash
scripts/detect-machine.sh                           # 先查本机变体（例如 chen-laptop-amd）
nh os switch -s chen-laptop-amd                     # 换成上一行打印的名字 → 不重启直接切
sudo systemctl restart auto-machine-specialisation  # 或：走运行期兜底（见 auto-machine.nix）
```

- 自检现在跑在哪一层：`readlink -f /run/current-system` 与
  `readlink -f /nix/var/nix/profiles/system` **相同 = 基础系统**；
  等于 `/nix/var/nix/profiles/system/specialisation/<变体>` 才是变体。
- 想**常驻**基础系统（而不只是让这次运行落进去）：重启时在菜单里手选基础条目 ——
  systemd-boot 会把这次选择存进本机 NVRAM 的 `LoaderEntryDefault`，
  `auto-machine-specialisation` 开机时会尊重这个手选、不再把人切走。
- 完整成因（两段式自动选机器，NVRAM 与盘上 `loader.conf` 两个目的地）见 README 的
  specialisation 一节与 `os-disk/portable-chen/{boot-machine,auto-machine}.nix`。

---

## 6. 什么时候该 `nix flake update`

`nix flake update` 升级的是**锁定的输入**（nixpkgs 26.05 分支、home-manager、
nix-flatpak、llm-agents），也就是"整个系统的软件版本"。**别在员工机上做**：

- 在员工机上各自 `update` → 两台机器版本漂移，出问题了也不知道是哪边；
- 正确姿势：**在作者机 `nix flake update` → 构建验证 → commit `flake.lock` → push**，
  员工机只 `git pull`（自然拿到同一份 `flake.lock`）→ `nh os switch -H msi-wd`。
- 升级内核/NVIDIA 之后按第 4.3 节重启，并留意 `shared/boot.nix` 里关于内核版本的注释。

---

## 7. 改配置速查：改什么 → 哪个文件 → 谁跑什么

| 想改的东西 | 改哪里（作者机） | 生效方式 |
|---|---|---|
| 系统级包（root/救援也要用） | `shared/packages.nix` | `nh os switch -H msi-wd` |
| 机级服务（ssh / 桌面 / 打印 / flatpak…） | `shared/*.nix` | `nh os switch -H msi-wd` |
| 用户账户（组、描述、是否 wheel） | `users/<name>/default.nix` | `nh os switch -H msi-wd` |
| 机器硬件（显卡/固件尾巴） | `machines/employee-3600/default.nix`（手写） | `nh os switch -H msi-wd` |
| 硬件探测（**生成物，勿手改**） | `machines/employee-3600/hardware-configuration.nix` | 重生成后 `nh os switch -H msi-wd` |
| 挂载 / swap（跟盘走） | `os-disk/msi-wd/disk.nix` | `nh os switch -H msi-wd`（`/boot` 之类改动要重启） |
| 所有用户都要的桌面/终端应用 | `users/modules/apps.nix` | 各人 `nh home switch` |
| 某个人自己的 Nix 应用 | `users/<name>/apps.nix` | 该用户 `nh home switch` |
| 员工桌面上的 office 网络文件夹链接（smb://10.10.10.9/Operation/Product/） | `users/mubimuba/desktop.nix` | mubimuba 跑 `nh home switch`；**首次双击输一次密码并勾「记住密码」**（存 KWallet，之后不再弹框） |
| 员工机装哪些用户 | `os-disk/msi-wd/users.nix` | `nh os switch -H msi-wd` |
| 登录界面列哪些用户（msi-wd 只列 mubimuba） | `os-disk/msi-wd/default.nix`（`services.displayManager.hiddenUsers`） | `nh os switch -H msi-wd` |
| 时区 / locale / 字体 / 输入法 | `shared/locale.nix` | `nh os switch -H msi-wd` |

⚠️ 别把硬件探测写进 `machines/<机器>/hardware-configuration.nix` 手改 ——
在员工机上重生成（`sudo nixos-generate-config --no-filesystems --root /`，产物手动摘到该文件）
或按 `DEPLOY-INSTALL.md` 第 4.3 节的做法。

---

## 8. 回滚

**系统级**

```bash
nh os info              # 列世代（含时间、内核、闭包大小）
nh os rollback          # 回滚到上一个世代（-n 只打印，-a 先问）；不要 sudo
sudo reboot             # 需要的话
```

也可以在开机菜单（systemd-boot）里直接选旧世代。
另：`nh os info` 若提示 `Profile is out of sync with /run/current-system`，
说明上一次 switch 激活阶段失败过 → 重跑 `nh os switch -H msi-wd` 或直接 rollback。

**用户级**

```bash
home-manager generations
home-manager --rollback
```

---

## 9. 磁盘与清理

- 自动清理已开：`programs.nh.clean`（`shared/nix.nix`）→ `nh-clean.timer` **每周**跑
  `nh clean all --keep-since 7d --keep 5`。手动跑：`sudo nh clean all`。
- 世代保留策略同上（7 天 / 最近 5 代）→ 回滚窗口就这么大，出问题当天回滚最稳。
- `/nix` 在自己的 btrfs 子卷上；空间不足时先 `nh clean all`，再 `nix-collect-garbage -d`。
- 查看占用：`df -h /nix`、`du -sh /nix/store`。

---

## 10. Flatpak

- 系统级应用（`shared/flatpak.nix`：Vivaldi、微信）由 **`flatpak-managed-install.service`**
  在激活时安装；`update.onActivation = true`，所以 `nh os switch` 会顺带更新它们。
- 失败的典型原因：没网 / SJTU 镜像拉不动（remotes 指向 `https://mirror.sjtu.edu.cn/flathub`）。
  该单元 `Restart=on-failure`、60s 重试；手动重试与看日志：

  ```bash
  sudo systemctl start flatpak-managed-install.service
  sudo journalctl -u flatpak-managed-install -n 100
  flatpak list                       # 装上了什么
  flatpak remote-ls --updates        # 有没有可更新的
  ```

- 用户级 flatpak（`--user`）只属于各自的 home 配置，改完跑 `nh home switch`。

---

## 11. 排障速查

| 现象 | 原因 | 处理 |
|---|---|---|
| `error: ... is not tracked by Git` | 新文件没进 git 索引 | 作者机 `git add` 后 push；员工机 `sudo git -C /etc/nixos add -A` |
| `git pull` 报 not possible to fast-forward | `/etc/nixos` 有本地手改/提交 | `sudo git -C /etc/nixos status` → `stash` 或 `checkout -- .` 后重拉 |
| 改了用户级配置但桌面/终端没变 | 家目录没激活 | 该用户跑 `nh home switch` |
| `nh home switch` 报 `Read-only file system ... home-path.lock` | `~/.nix-profile` 被手动指到了本代 `home-path` | `readlink ~/.nix-profile` 确认后 `ln -sfn ~/.local/state/nix/profiles/profile ~/.nix-profile` 再 switch |
| 家目录激活报 `Activation failed` | 同上，或上一次激活半途失败 | 看报错最后一段；上面这条 + 重跑 |
| 普通用户求值 `/etc/nixos` 报 git 所有权/权限错 | 仓库是 root 所有 | 改用自家 clone：`nh home switch ~/nixos-config#mubimuba` |
| Flatpak 应用没出现 | 首次安装服务失败 | 见第 10 节 |
| `ssh` 连不上 | msi-wd 用**默认 22**（作者机才是 555） | `ssh bumooby@<msi-wd-ip>`；端口在 `os-disk/<host>/default.nix` 的 `my.ssh.port` |
| 系统 switch 后桌面没了 / 只有控制台 | 只可能发生在便携盘（specialisation），员工机没有变体 | 员工机不会出现；便携盘见第 5 节（重启一次，或 `nh os switch -s <变体>`） |
| `nh os info` 提示 profile 与 `/run/current-system` 不同步 | 上次 switch 激活失败 | 重跑 `nh os switch -H msi-wd`，或 `nh os rollback` |
| `error: ... does not provide attribute 'nixosConfigurations.<名字>'`（名字不是 `msi-wd`） | plain `nh os switch` 是按**本机运行中的 hostname** 补属性名的，而本机 hostname 还不是 `msi-wd`（刚装好/改过名） | 用 `nh os switch -H msi-wd` 显式指定；顺便 `hostname` 确认一下 |
| `Don't run nh os as root` | `nh` 命令前加了 `sudo` | 去掉 sudo：`nh os switch -H msi-wd`（`nh` 自己会提权） |
| 远程桌面连不上 | 员工机**默认不开** KDE 远程桌面 | 要开就在 `os-disk/msi-wd/default.nix` 设 `my.remoteDesktop.enable = true;`（+ 用户级配置），再 switch |
| 员工机登录界面里看不到 bumooby | 设计如此：`hiddenUsers` 只把他从**用户列表**里滤掉，账户没被禁用 | 管理员照旧 `ssh bumooby@<msi-wd-ip>` 或 Ctrl+Alt+F2 文本控制台登录；非要在图形界面登，临时注释掉 `os-disk/msi-wd/default.nix` 里那行再 switch |

---

## 12. 不要做的事

1. **不要在员工机上跑 `DEPLOY-INSTALL.md` 的分区/格式化步骤** —— 会抹掉内盘。
2. **不要直接手改 `/etc/nixos` 里的文件**（除非临时应急并当场 `git add`）——
   作者机才是唯一权威副本。
3. **不要在员工机上 `nix flake update`** —— 版本漂移由作者机统一升级（第 6 节）。
4. **不要手动把 `~/.nix-profile` 指到本代 `home-path`** —— 会让下一次 `nh home switch`
   永久失败（README「用户级构建」有完整成因）。
5. **不要为双系统去改 BIOS 的 Secure Boot / TPM / 启动顺序** —— 内盘 Windows 是
   BitLocker 加密的，会索要恢复密钥。
6. **`mubimuba` 不要试图 `sudo` / `nh os switch`** —— 他不在 `wheel`，也不需要；
   系统级的事找 `bumooby`。
