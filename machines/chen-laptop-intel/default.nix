# chen Intel 笔记本：Intel Core Ultra 9 285H（仅内显 Arc）
#
# 组合入口 = 生成器产物（./hardware-configuration.nix，旧组件拼装、待重生成）
#          + 手写尾巴（固件 / 图形 / 蓝牙）。Intel 内显无需额外驱动（内核自动 + Mesa）。
{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
