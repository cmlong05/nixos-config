
## 员工机（msi-wd）部署清单

在**同款硬件**（AMD CPU + NVIDIA 3060）的新电脑上装 NixOS。以下流程为
**全新装机的一次性操作**，系统装好后日常只靠 `nh os switch` 维护。

> **第 0 步：选择引导介质（二选一，仅用于启动安装环境，系统本身不写入介质）**
>
> - **方式 A：NixOS 安装 U 盘** —— 官网 ISO 写入 U 盘，从 U 盘启动。
> - **方式 B：作者的移动硬盘系统** —— 把跑着本仓库系统的 USB 移动硬盘
>   （作者机本体）插到员工机上并从它启动，即可当作现成安装环境（工具齐全）。
>
> 两种方式进入的环境相同，后续步骤完全一致。**注意：给员工机分区前务必
> `lsblk` 分清楚目标盘**，目标必须是员工机内置硬盘，避免误抹引导介质本身。


1. 
1.1 创建/mnt目录
sudo mkdir -p /mnt
1.2 对**员工机内置硬盘**分区和格式化（EFI + btrfs，可照抄本机布局）与 挂载
1.2.1分区
1.2.2 格式化目标盘
###一定二次确认目标盘
sudo mkfs.fat -F 32 /dev/nvme0n1p1xx
sudo mkfs.btrfs -f /dev/nvme0n1p2xx
sudo mkswap /dev/nvme0n1p3
1.2.3 建子卷布局（照抄作者机：root 顶层 + home/nix 子卷）
sudo mount /dev/nvme0n1p2 /mnt
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo umount /mnt
1.2.4 挂载到 /mnt
sudo mount -o subvol=home /dev/nvme0n1p2 /mnt/home
sudo mount -o subvol=nix /dev/nvme0n1p2 /mnt/nix
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot

1.2.5 验证挂载
lsblk

1.3 关掉移动硬盘的swap 并启用目标盘的（防止污染生成的hardware-configuration）
sudo swapoff /dev/sda3
sudo swapon /dev/nvme0n1p3**
swapon --show
1.4 生成该机专属`hardware-configuration.nix`（磁盘 UUID 每台不同，勿用仓库里的模板）。
sudo nixos-generate-config --root /mnt
1.5 查看生成的硬件配置交给AI核对
cat /mnt/etc/nixos/hardware-configuration.nix

2. 
# 确认仓库在移动硬盘上
ls ~/nixos-config/flake.nix && echo OK

# 备份刚生成的硬件配置
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/hw-chen-generated.nix

# 把本仓库复制到 `/mnt/etc/nixos/`
sudo rm -rf /mnt/etc/nixos
sudo mkdir -p /mnt/etc/nixos
sudo cp -a ~/nixos-config/. /mnt/etc/nixos/
# 把生成的硬件配置拆成两部分：
#   - 挂载行（fileSystems + swapDevices）→ 覆盖 os-disk/msi-wd/disk.nix
#   - 其余硬件探测（availableKernelModules / 微码 / hostPlatform / not-detected）
#     → 覆盖 machines/employee-3600/hardware-configuration.nix
# 建议把 /tmp/hw-chen-generated.nix 交给 AI，让它按上述覆盖。

# 确认 flake 结构与拆分结果
ls /mnt/etc/nixos/flake.nix /mnt/etc/nixos/os-disk/msi-wd/default.nix /mnt/etc/nixos/machines/employee-3600/hardware-configuration.nix /mnt/etc/nixos/os-disk/msi-wd/disk.nix

3. `nixos-install --flake /mnt/etc/nixos#msi-wd`。
   安装过程中会交互式设置用户密码，请照做（不要用 `--no-root-passwd` 会导致没有密码无法进入系统）。
4. reboot
注意：flatpak 应用是"首次启动时由系统服务安装"
员工机刚装好，很可能首次启动时这个服务失败/没跑成功（安装时无网络、或 SJTU flatpak 镜像拉不动


5. 员工机上 mubimuba **没有 wheel（无 sudo）**；如需提权，把 `wheel`
   加回 `users/mubimuba/default.nix` 的 mubimuba extraGroups。
6. 员工机上需要哪些用户级应用，改 `users/mubimuba/home.nix`。
