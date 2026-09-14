我先做了一轮只读勘察（lsblk / sysfs / fstab / 仓库配置），没有执行任何变更。你的盘实际几何如下，后面的步骤全部基于这些精确数字。
一、现状快照（512 字节扇区）
分区	起点扇区	大小扇区	结束扇区	内容
sda1	4,096	2,097,152	2,101,247	vfat ESP，UUID 534A-47F7，挂 /boot（保持不动）
sda2	2,101,248	979,658,952	981,760,199	btrfs label root，UUID 086bf1f6-…，挂 /（subvolid 5）+ /home + /nix
sda3	981,760,200	18,454,944	1,000,215,143	swap，UUID 30cce407-…（要删）

    磁盘 /dev/sda 总扇区 1,000,215,216，GPT 最后可用扇区 1,000,215,182（by-id：usb-IM2P33F8_-512GD_T060_27030001005F-0:0，USB 3.0 移动盘）。
    目标新 sda2：起点 2101248，末扇区 1000215182，大小 998,113,935 扇区（≈475.94 GiB，净增 8.80 GiB）。
    两个关键事实（会影响步骤顺序）：
        当前跑的系统 fstab 里还有 swap（/dev/disk/by-uuid/30cce407-…），而仓库 git log 里已有 commit change swap to zram，os-disk/portable-chen/disk.nix 已无 swapDevices、zramSwap 已配 50% 内存 —— 配置已改但还没部署（zramctl 为空，systemctl list-units 'systemd-zram*' 无单元）。所以应先部署，再删分区。
        swap 里已用 1.9 GB，swapoff 要把它换回内存（RAM 15G / 可用约 10G，够，但先关掉 Firefox 之类更稳）。

二、执行顺序
步骤 1：先把 zram 部署上去（关键前置）
复制

nh os switch          # 你仓库的日常维护命令；等价于 sudo nixos-rebuild switch --flake /etc/nixos#portable-chen

验证（三条都应通过）：
复制

zramctl                                  # 应出现 /dev/zram0，约 7.5G，算法 zstd
swapon --show                            # 应出现 /dev/zram0，PRIO 100
grep -i swap /etc/fstab                  # 应无输出（只剩注释头）

    此时旧的磁盘 swap 仍处于激活状态（部署不会自动 swapoff），下一步显式关掉。这样做的好处：万一后面 swapoff 或分区操作出问题，系统已经不再依赖 sda3，重启也不会去激活一个已不存在的分区。

步骤 2：关掉 sda3 的 swap
复制

sudo swapoff /dev/sda3
swapon --show        # 只应剩 /dev/zram0
free -h              # 交换一行应只剩 zram

若报 Cannot allocate memory：说明要把 1.9G 换回内存，先关掉占内存的程序再重试（不要用 swapoff -a 去硬碰）。
步骤 3：备份分区表（30 秒，强烈建议）
复制

sudo sfdisk -d /dev/sda | sudo tee /root/sda-gpt-$(date +%F).dump

回滚用的就是它：sudo sfdisk /dev/sda < /root/sda-gpt-*.dump。
步骤 4：gdisk 删 sda3 + 右扩 sda2

gdisk 当前没装（sgdisk/parted/partprobe 也没装），用一次性环境跑：
复制

nix shell nixpkgs#gdisk
sudo env PATH="$PATH" gdisk /dev/sda

    没网装不了 gdisk 的话，可用已安装的 sudo fdisk /dev/sda（d/d/n 数字同上，类型选 L 列表里的 "Linux filesystem"），或见文末 sfdisk 脚本方案。

gdisk 内按键序列（★ 是必须手输、不能回车的地方）：
复制

p          # 核对：总扇区 1000215216；sda1 4096–2101247；sda2 2101248–981760199；sda3 981760200–1000215143
d
3          # 删掉 swap 分区
d
2          # 删掉 btrfs 分区（只删 GPT 表项，扇区里的数据一点没动）
n
2          # 分区号仍用 2
2101248    # ★ 起始扇区：必须手输 = 原 sda2 起点。绝对不能让 gdisk 自己挑
           # 结束扇区：直接回车（默认即 1000215182 = 最大可用）
8300       # ★ 类型码显式输入 Linux filesystem（不要回车碰运气）
p          # ★ 再核对一遍：sda1 完全没变；sda2 = 2101248–1000215182
w          # 写入，问 "Do you want to proceed?" 时输入 Y

要点：

    删 sda2 后立刻重建、起点必须一字不差；起点一变，btrfs 全部元数据错位 = 数据报废。
    只在同一块盘上操作。全程不要碰 nvme0n1（Windows 盘）。
    w 之后 gdisk 会提示 “The kernel is still using the old partition table. The new table will be used at the next reboot or after you run partprobe(8)/partx(8).” —— 这是正常的，见下一步。
    新 sda2 会拿到新的 PARTUUID，无所谓：你的 fstab 用的是文件系统 UUID（086bf1f6-…），btrfs UUID 不变。被删掉的 swap 那行 fstab 已在步骤 1 消失。
    老的 swap 签名还留在旧偏移处，纯属残留，对 btrfs 无影响（想清理见收尾）。

步骤 5：让内核看到新的分区表（二选一）

A. 重启（推荐，最稳）：sync && sudo reboot 重启后确认：
复制

lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL
# sda2 应显示 ~476G，sda3 消失；/、/home、/nix、/boot 正常挂上

B. 不重启（partprobe 没装，用 partx）：
复制

sudo partx -u /dev/sda
blockdev --getsize64 /dev/sda2       # ★ 应变成 511034334720；若仍是旧值 501583544320 就别继续，说明没生效，改用 A

只有上面这个数字确实变大，才能做下一步；否则 btrfs resize max 会报 "no change" 或按旧大小处理。USB 桥有时不刷新，那就老老实实重启。
步骤 6：扩 btrfs（在线，瞬时，不搬数据）
复制

sudo btrfs filesystem resize max /

预期输出：Resize device id 1 (/dev/sda2) from 467.14GiB to 475.94GiB。（/ 就是顶层 subvol，/home、/nix 是它的子卷，共享同一个 btrfs，一次即可，不需要对子卷单独 resize，也不需要 balance。）
步骤 7：验证
复制

lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT /dev/sda
df -h / /nix /home                  # 可用空间应比原来多 ~8.8G
sudo btrfs filesystem usage /       # Device size 475.94GiB；Device unallocated ≈ 194GiB
sudo btrfs filesystem show /        # devid 1 size 475.94GiB（非 root 跑会显示 size 0/MISSING，是权限假象）
sudo btrfs filesystem df /

这一轮不需要 rebuild（这次没改任何 fileSystems/swapDevices；UUID 和挂载参数都没变）。下次 nh os switch 顺手确认一次 git status 干净即可。

收尾（可选，纯为干净）：旧 swap 签名残留检查——
复制

sudo wipefs -n -o 502661222400 /dev/sda          # -n = 只看不写；981760200×512
# 若确实报出 swap 签名且你想抹掉：
sudo wipefs -o 502661222400 -t swap /dev/sda

三、备用方案：不用 gdisk（util-linux 已装，离线可用）

先 dry-run，看清输出无误再去掉 --no-act：
复制

sudo sfdisk --no-act /dev/sda <<'EOF'
label: gpt
start=4096,     size=2097152,   type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, name=EFI
start=2101248,  size=998113935, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF

去掉 --no-act 执行同一条即可（等价于上面 gdisk 的全部动作）；之后照步骤 5、6 走。
四、风险清单 / 不要做的事

    不要改 sda2 起点（2101248），不要 mkfs，不要 wipefs -a /dev/sda，不要 parted mkpart 之类重建分区表。
    不要在步骤 5 生效前就 btrfs resize max。
    不要删/动 sda1（ESP，/boot 全靠它）；不要碰 nvme0n1。
    操作前确认设备名没变：lsblk 里 sda 必须是那块 USB 盘（/dev/disk/by-id/usb-IM2P33F8_-512GD_T060_27030001005F-0:0）。换 USB 口后仍按 lsblk 结果确认，别信记忆。
    删掉磁盘 swap 后永久不能用休眠（boot.resumeDevice）—— 这条你仓库 os-disk/portable-chen/swap.nix 里已经写明“三机共用一份 / 与 swap，永远不要配休眠”，只是现在物理上也没得用了。
    全程别在做大 nix 构建/GC 或大量写盘时进行；USB 盘上分区表变更用最保守的方式（重启而不是热更新）永远更划算。
    回滚路径：sudo sfdisk /dev/sda < /root/sda-gpt-*.dump 恢复旧表；若已 resize 过，先把 btrfs 缩回去（btrfs filesystem resize -8.8g /，需在表恢复前做）再恢复表。

要不要我把这套步骤连同你机器上这些精确扇区号写成一个 PORTABLE.md 的附录（只写文档、不动分区）？你说一声我再动笔。