# 引导与内核
{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 内核：钉在 7.1 系列（7.1.9），不要用 latest（7.2）。
  # 原因：nvidia-open 595.71.05 与内核 7.2 不兼容（os-interface.c strncpy 隐式声明编译错误）。
  # 等 nvidia 驱动支持 7.2 后可改回 pkgs.linuxPackages_latest。
  boot.kernelPackages = pkgs.linuxPackages_7_1;
  #boot.kernelPackages = pkgs.linuxPackages_latest;

}
