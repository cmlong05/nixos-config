# 新增一台机器：全新安装（通用清单）

## 1. 装机前把新机器加进仓库

- `machines/<MACHINE>/`
  `hardware-configuration.nix` 先占位（参考 `machines/employee-3600/`），第 5 步在目标机上重生成；
  `default.nix` = `imports = [ ./hardware-configuration.nix ];` + 手写尾巴（显卡驱动 / 固件 / 蓝牙，照抄同类机器）。
- `os-disk/<HOST>/`：参考 `os-disk/msi-wd/` 下的文件
  `default.nix`改 `networking.hostName`、`my.ssh.port` 等机器差异；
  `users.nix`
  `disk.nix` 先留空（第 5 步填挂载行）
- `users/<name>/`（新用户）：
  `default.nix` 写账户（管理员加 `wheel`，**不写** `initialPassword`）
  `home.nix` 参考同级

- `flake.nix`：
  `nixosConfigurations.<HOST> = mkHost ./os-disk/<HOST>/default.nix;`
  新用户在 `homeConfigurations`加 `"<USER>@<HOST>"` 与 `"<USER>"`。

## 2. 引导介质（只用来启动安装环境）

现成的 NixOS 系统盘（如作者的移动盘）。

⚠️ 分区前先 `lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINTS` 分清哪块是**目标机内盘**，别抹了介质。

## 3. 分区 / 格式化 / 子卷 / 挂载

布局：EFI(vfat) + btrfs + swap；`/` 用 btrfs 顶层，`/home`、`/nix` 各一个子卷。

```bash
DISK=/dev/nvme0n1; EFI=${DISK}p1; ROOT=${DISK}p2; SWAP=${DISK}p3   # 按 lsblk 改
sudo mkdir -p /mnt
# 分区（fdisk / parted / cfdisk 均可）后：
sudo mkfs.fat -F 32 "$EFI"; sudo mkfs.btrfs -f "$ROOT"; sudo mkswap "$SWAP"

sudo mount "$ROOT" /mnt                     # 顶层子卷就是将来的 /
sudo btrfs subvolume create /mnt/home; sudo btrfs subvolume create /mnt/nix
# ⚠️ 不要在这里 umount
sudo mount -o subvol=home "$ROOT" /mnt/home; sudo mount -o subvol=nix "$ROOT" /mnt/nix
sudo mkdir -p /mnt/boot; sudo mount "$EFI" /mnt/boot
findmnt -R /mnt                             # 期望四条：/、/home、/nix、/boot
```

## 4. swap：先换成本机的

生成配置时会把**当前激活的** swap 写进 `swapDevices`，所以先关掉安装环境的：

```bash
swapon --show
sudo swapoff /dev/<安装环境的 swap>          # 没有就跳过
sudo swapon "$SWAP"
swapon --show          # 只应剩目标机内盘的
```

## 5. 生成两份"跟机器走"的文件，并把仓库放进 `/mnt/etc/nixos`

```bash
# 5.1 完整生成（含 fileSystems + swapDevices），备份后要用
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hw-full.nix

# 5.2 放入仓库：本地拷（无网络也行）或 clone
sudo rm -rf /mnt/etc/nixos && sudo mkdir -p /mnt/etc/nixos
sudo cp -a <REPO>/. /mnt/etc/nixos/                              # 连 .git 一起
# 或：sudo git clone https://github.com/cmlong05/nixos-config.git /mnt/etc/nixos

# 5.3 把 /tmp/hw-full.nix 的 fileSystems + swapDevices 原样填进 disk.nix，再核对
sudoedit /mnt/etc/nixos/os-disk/<HOST>/disk.nix
grep -n by-uuid /mnt/etc/nixos/os-disk/<HOST>/disk.nix /tmp/hw-full.nix

# 5.4 硬件探测部分（勿手改）：生成到临时 root，避免往仓库里丢 configuration.nix
sudo nixos-generate-config --no-filesystems --root /tmp/hw
sudo cp /tmp/hw/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos/machines/<MACHINE>/hardware-configuration.nix

# 5.5 进 git 索引（否则求值报 is not tracked by Git）
sudo git -C /mnt/etc/nixos add -A && sudo git -C /mnt/etc/nixos status --short
```

> 别在目标机 `git commit`：`disk.nix` / `hardware-configuration.nix` 是这台机器特有的，留在工作区即可
> （pull 冲突的处理见 [`DEPLOY-MAINT.md`](./DEPLOY-MAINT.md) §4）。装前建议把这两份和 `/tmp/hw-full.nix` 一起复核一遍。

## 6. 安装

```bash
sudo nixos-install --flake /mnt/etc/nixos#<HOST>
sudo reboot          # 重启前拔掉介质
```

- 会交互式要求设 root 密码；**不要** `--no-root-passwd`。
- 仓库没写 `initialPassword` → 第一次开机用 root 在 TTY 上给各用户 `passwd`；
  安装环境有 `nixos-enter` 也可现在设：`sudo nixos-enter --root /mnt -c 'passwd <USER>'`。

## 7. 第一次开机后

1. Flatpak（若该 host 用了 `shared/flatpak.nix`）：失败就 `sudo systemctl start flatpak-managed-install.service`。
2. 每个用户自己跑 `nh home switch`（管理员可代跑 `sudo -u <USER> -i nh home switch`）。
3. `<USER>` 刻意不在 `wheel`；要提权就改 `users/<USER>/default.nix` 的 `extraGroups` 再 switch 一次。

## 8. 自检

```bash
hostname; nh os info | head; sudo systemctl --failed
nh os switch -H <HOST>       # 幂等：再跑一次应无改动
nh home switch               # 各用户
flatpak list; lsblk; findmnt -R /
```
