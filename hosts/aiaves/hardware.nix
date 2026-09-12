# 主机 aiaves 的硬件探测（机级，不随盘走）
# 本机实测：Intel Core Ultra 9 285H + 内显 i915（无独立显卡），从 USB 移动硬盘启动。
# 注意与 host nixos 的区别：kvm-intel（不是 kvm-amd）、intel 微码（不是 amd）。
{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
