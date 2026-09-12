# 引导与内核
{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 内核：用本发行版默认（linuxPackages = 6.18.x）。
  #
  # 历史：这里曾钉在 7.1，为的是避开 7.2 与 nvidia-open 595.71.05 的不兼容
  # （os-interface.c strncpy 隐式声明编译错误）。但 7.1 现已 EOL，nixpkgs 对它
  # 直接 throw（`linux 7.1 was removed because it has reached its end of life upstream`），
  # 导致所有 host 都无法重建。
  # 现改为发行版默认内核：仍在支持期内，也是 nixpkgs 与 nvidia 驱动配套的组合。
  #
  # 换回 latest（7.2+）的条件：nvidia 驱动版本更新到支持该内核之后。
  boot.kernelPackages = pkgs.linuxPackages;

}
