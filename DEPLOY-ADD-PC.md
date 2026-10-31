# 增加一台 PC：复用 portable-chen 移动盘

这份步骤适用于：新 PC **不单独安装系统**，而是启动现有的 `portable-chen`
移动盘，并与已有机器共用系统、用户和家目录。

如果新 PC 使用自己的内盘、需要全新安装，请走
[`DEPLOY-INSTALL.md`](./DEPLOY-INSTALL.md)。

## 1. 在新 PC 上采集机器信息
```bash

cd /etc/nixos
hostname
scripts/detect-machine.sh --probes

```
## 2. 生成新 PC 的硬件文件

```bash
MACHINE=new_PC
sudo nixos-generate-config --no-filesystems --dir /tmp/hw
sudo install -d /etc/nixos/machines/"$MACHINE"
sudo cp /tmp/hw/hardware-configuration.nix \
  /etc/nixos/machines/"$MACHINE"/hardware-configuration.nix
```

## 3. 写机器入口和硬件尾巴

复制最接近的一台机器的
`default.nix` 到 `machines/$MACHINE"/default.nix`。只保留适用于新 PC 的显卡、固件、蓝牙配置。


## 4. 注册 specialisation 和网卡 MAC
在 `os-disk/portable-chen/machine_spe.nix` 的 `config` 中增加：

```nix
specialisation.$MACHINE".configuration = {
  imports = [ ../../machines/new_PC ];
  my.portableChen.wifiOnBoot = false; # 台式机用 false；笔记本用 true
};
```
再把 `scripts/detect-machine.sh --probes` 输出的 MAC 加入
`machines/machine-fingerprints.conf`。展示特征可以一并记录.

一台机器可以写多个固定 MAC（例如有线和无线网卡），任意一个命中即可

## 5. 构建并激活
```bash
# 新机如果无wifi网络驱动，考虑在旧机器上完成构建
nh os switch
scripts/which-spec.sh
```

便携盘的 `nh` 包装器 (os-disk/portable-chen/nh-auto-specialisation.nix <--scripts/nh-local-wrapper.sh ) 会按刚加入的 MAC 自动选择新机器的 specialisation，
因此不需要手动追加 `-s <机器名>`；显式传入 `-s`、`-S` 或 `-H` 时包装器不会覆盖。
