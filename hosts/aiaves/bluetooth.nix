# 蓝牙配置（主机 aiaves）
{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # 如果你需要图形化蓝牙管理工具
  # services.blueman.enable = true;
}
