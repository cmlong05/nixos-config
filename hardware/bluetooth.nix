# 蓝牙：硬件能力开关（hardware.bluetooth）
#
# 想开蓝牙的安装 import 本文件即可（便携盘要、员工机不要）。
{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # 如果你需要图形化蓝牙管理工具
  # services.blueman.enable = true;
}
