# chen Dell Vostro 5471 / i5-8250U / UHD 620 笔记本
# 组合入口 = 生成器产物（./hardware-configuration.nix，nixos-generate-config
#          --no-filesystems 生成）
#          + 手写尾巴（固件 / 图形 / 蓝牙）
{ pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # Kaby Lake-R（UHD 620）的 VA-API 驱动。
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];

  services.thermald.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
