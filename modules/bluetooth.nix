# 蓝牙配置
{ config, pkgs, ... }:

{
  # 蓝牙配置
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # 如果你需要图形化蓝牙管理工具
  # services.blueman.enable = true;

}
