# 员工机：AMD 3600 + NVIDIA 3060（无蓝牙）
#
# 组合入口 = 生成器产物（./hardware-configuration.nix，旧组件拼装、待重生成）
#          + 手写尾巴（NVIDIA / 固件 / 图形）。msi-wd 无蓝牙 / podman / dsh。
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
}
