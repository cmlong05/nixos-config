# chen 台式机：AMD 3900XT + NVIDIA 3060（无核显）
#
# 组合入口 = 生成器产物（./hardware-configuration.nix，勿改）
#          + 生成器不产出的手写尾巴（NVIDIA / 固件 / 图形 / 蓝牙）。
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # —— 手写尾巴：nixos-generate-config 不产出，必须手工维护 ——
  # 固件 + 图形底座
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # NVIDIA 独显
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  # 蓝牙
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
