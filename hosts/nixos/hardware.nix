# 主机 nixos 的硬件探测（机级，不随盘走）
# 与 disks/portable-ssd.nix 分开：这里只放"跟机器走"的行。
# 本文件由 nixos-generate-config 生成的 hardware-configuration.nix 拆分而来，
# 重新生成后需手工再拆一次（挂载行 → disks/，探测行 → 本文件）。
{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
