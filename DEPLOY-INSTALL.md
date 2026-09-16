# 员工机（msi-wd）全新安装

**一次性清单**：在同款硬件（AMD CPU + NVIDIA 3060）的新电脑上从零装 NixOS。

- 装完之后的日常操作（更新系统 / 改配置 / 回滚 / 清理 / 排障）看
  **[`DEPLOY-MAINT.md`](./DEPLOY-MAINT.md)**。本文件第 1 步会**抹盘**，
  系统装好之后**绝对不要**再照它跑。
- 目标机：hostname `msi-wd`，host 定义 `os-disk/msi-wd/`，机器目录 `machines/employee-3600/`。
- 系统装在**员工机内置硬盘**上（不是移动盘），宿主机与移动盘系统完全独立、互不影响。
- 两个用户：`bumooby`（管理员，在 `wheel`）+ `mubimuba`（员工，**不在 `wheel`**，不能 sudo）。

---

## 0. 引导介质（二选一，只用来启动安装环境）

> 介质本身**不写入任何东西** —— 装的是员工机的内置硬盘。

- **方式 A：NixOS 安装 U 盘** —— 官网 ISO 写入 U 盘，从 U 盘启动。
- **方式 B：作者的移动硬盘系统** —— 把跑着本仓库系统的 USB 移动硬盘（作者机本体）
  插到员工机上并从它启动，即现成的安装环境（工具齐全，且仓库 `~/nixos-config` 就在手边）。

两种方式进入的环境相同，后面的步骤完全一致。

> ⚠️ **动手分区前必须 `lsblk` 分清哪块是员工机内盘**。目标是**内置硬盘**，
> 别把正在当安装环境用的 U 盘/移动硬盘抹了。
>
> ```bash
> lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINTS
> ```

下文用四个变量代表目标盘与分区，**必须按 `lsblk` 的实际结果替换**（示例为 NVMe 内盘，
> 实际可能是 `sda`/`nvme1n1`，分区编号也按你分出来的填）：

```bash
DISK=/dev/nvme0n1      # 员工机内盘
EFI=${DISK}p1          # EFI 分区（vfat）
ROOT=${DISK}p2         # btrfs 根分区
SWAP=${DISK}p3         # swap 分区
```

---

## 1. 分区 / 格式化 / 子卷 / 挂载

### 1.1 建挂载点 / 1.2 分区

```bash
sudo mkdir -p /mnt
```

按作者机同款布局分三个区：**EFI + btrfs + swap**（`fdisk` / `parted` / `cfdisk` 均可）。
分完再 `lsblk` 复核一次编号。

### 1.3 格式化（**再确认一次目标盘**）

```bash
sudo mkfs.fat -F 32 "$EFI"
sudo mkfs.btrfs -f "$ROOT"
sudo mkswap "$SWAP"
```

### 1.4 建子卷 + 挂载（照抄作者机：`/` = btrfs 顶层 + `home` / `nix` 两个子卷）

```bash
# 顶层子卷（subvolid=5）就是将来的 /
sudo mount "$ROOT" /mnt
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix

# ⚠️ 不要在这里 umount：上面那份顶层挂载就是 /，后面所有写入都落在它上面
sudo mount -o subvol=home "$ROOT" /mnt/home
sudo mount -o subvol=nix  "$ROOT" /mnt/nix
sudo mkdir -p /mnt/boot
sudo mount "$EFI" /mnt/boot
```

> 说明：这条路径与 `os-disk/msi-wd/disk.nix` 一致 —— `/` 挂在 btrfs 顶层
> （所以那里没有 `subvol=` 选项），`/home`、`/nix` 各挂自己的子卷。
> 旧版清单在 `btrfs subvolume create` 之后多了一句 `umount /mnt`，
> 那会让 `/` 无处可挂、`/mnt/home` 也不存在 —— 已去掉。

### 1.5 验证挂载

```bash
findmnt -R /mnt
# 期望看到四条：/ （btrfs 顶层）、/home（subvol=home）、/nix（subvol=nix）、/boot（vfat）
lsblk
```

---

## 2. swap：关掉安装环境的，启用目标盘的

生成 `hardware-configuration.nix` 时，工具会把**当前处于激活状态的** swap 写进配置。
如果移动盘的 swap 还开着，生成的 `swapDevices` 就会指向**错误的设备**，所以先换过来：

```bash
swapon --show                            # 先看现在有哪些 swap
sudo swapoff /dev/<安装环境的 swap>       # 例如作者移动盘的 /dev/sda3；没有就跳过
sudo swapon "$SWAP"
swapon --show                            # 只应剩员工机内盘的 swap
```

---

## 3. 生成该机专属的 `hardware-configuration.nix`

磁盘 UUID 每台机器不同，**不要**用仓库里那份模板。

```bash
sudo nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix   # 交给 AI 核对
```

---

## 4. 把仓库放进 `/mnt/etc/nixos`

### 4.1 备份刚生成的完整硬件配置 + 拷仓库

```bash
# 确认仓库在（方式 B 时它就在移动盘上）
ls ~/nixos-config/flake.nix && echo OK

# 备份刚生成的硬件配置（后面取挂载行用）
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hw-chen-generated.nix

# 把本仓库复制到 /mnt/etc/nixos/
sudo rm -rf /mnt/etc/nixos
sudo mkdir -p /mnt/etc/nixos
sudo cp -a ~/nixos-config/. /mnt/etc/nixos/
```

### 4.2 覆盖 `os-disk/msi-wd/disk.nix` 的挂载行

挂载行（`fileSystems` + `swapDevices`）跟盘走。把 `/tmp/hw-chen-generated.nix` 里
这两段**原样**替换进 `os-disk/msi-wd/disk.nix` 的同名内容（UUID 以生成结果为准；
模板里 `/boot` 的 `fmask=0077` / `dmask=0077` 之类可选项想保留就手动带上）。

### 4.3 覆盖 `machines/employee-3600/hardware-configuration.nix`

硬件探测部分用 `--no-filesystems` 直接生成（工具自行省略挂载，**勿手改**）：

```bash
sudo nixos-generate-config --no-filesystems --root /mnt
# 生成物是 /mnt/etc/nixos/hardware-configuration.nix —— 搬进仓库的机器目录：
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos/machines/employee-3600/hardware-configuration.nix
# 顺手删掉仓库根目录下那份多余的：
sudo rm /mnt/etc/nixos/hardware-configuration.nix
```

### 4.4 核对落盘结果

```bash
ls /mnt/etc/nixos/flake.nix \
   /mnt/etc/nixos/os-disk/msi-wd/default.nix \
   /mnt/etc/nixos/os-disk/msi-wd/disk.nix \
   /mnt/etc/nixos/machines/employee-3600/hardware-configuration.nix

# flake 只把 git 索引里的文件当源码：新增文件必须先 add，否则求值报 "is not tracked by Git"
sudo git -C /mnt/etc/nixos add -A
sudo git -C /mnt/etc/nixos status --short
```

> 这两处覆盖最容易出错，建议把 `disk.nix`、`hardware-configuration.nix`
> 和 `/tmp/hw-chen-generated.nix` 一起交给 AI 复核一遍再装。

---

## 5. 安装

```bash
sudo nixos-install --flake /mnt/etc/nixos#msi-wd
```

- 安装过程会**交互式要求设置 root 密码**，请照做；**不要**用 `--no-root-passwd`
  （装完就没有可用的提权入口）。
- 仓库里**没有**为 `bumooby` / `mubimuba` 写 `initialPassword`，
  所以装完第一次开机要先用 root 在 TTY 上给两个用户设密码：
  `passwd bumooby`、`passwd mubimuba`。不设的话 SDDM 里这两个账号登不进去。

```bash
sudo reboot
```
重启前记得**拔掉安装介质**（或确认启动顺序指向内盘）。

---

## 6. 第一次开机后

1. **Flatpak 应用是「首次启动时由系统服务安装」**（`flatpak-managed-install.service`）。
   员工机刚装好时这个服务很可能失败/没跑成功（安装时无网络、或 SJTU flatpak 镜像拉不动）。
   失败它会每 60s 自己重试；想立刻重试：
   ```bash
   sudo systemctl start flatpak-managed-install.service
   sudo journalctl -u flatpak-managed-install -n 50
   ```
2. **每个用户在自己的账号下跑一次家目录激活**（系统不再代劳，详见 README「用户级构建」）：
   ```bash
   nh home switch          # 不要 sudo
   ```
   管理员可代跑：`sudo -u bumooby -i nh home switch`、`sudo -u mubimuba -i nh home switch`。
   跑之前家目录里还没有这套 dotfiles 与用户级应用（系统级包不受影响，
   `nh` 本身在 `/run/current-system/sw/bin`，所以引导没问题）。
3. `mubimuba` **没有 wheel（无 sudo）**；真要给他提权，把 `wheel`
   加回 `users/mubimuba/default.nix` 的 `extraGroups`（然后系统级 switch 一次）。
4. 员工机上需要哪些用户级应用：改 `users/mubimuba/home.nix`（人人都要的改
   `users/modules/apps.nix`）。

---

## 7. 装机后自检

```bash
hostname                       # msi-wd
nh os info | head              # 有系统世代
sudo systemctl --failed        # 无 failed（flatpak 那条见第 6 节）
nh os switch -H msi-wd         # 不要 sudo；-H 显式指定主机（幂等：再 switch 一次应无改动）
nh home switch                 # 各用户各自跑
flatpak list                   # Vivaldi / WeChat 是否装上
lsblk                          # 确认 /、/home、/nix、/boot 都来自内盘
```

之后一律走 **[`DEPLOY-MAINT.md`](./DEPLOY-MAINT.md)**。
