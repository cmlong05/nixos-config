# chen 笔记本：AMD 4800H + NVIDIA 3060（移动版 / Max-Q）
#
# 组合入口 = 生成器产物（./hardware-configuration.nix，本机实测生成，勿改）
#          + 手写尾巴（NVIDIA / 固件 / 图形 / 蓝牙）。
# 注：4800H 的 Vega 核显未在 lspci 出现（BIOS/MUX 禁用），无需配置。
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
