# 非本机生成 —— 由旧组件（storage-nvme + cpu-amd + common）拼装的占位，
# 到员工机后重跑覆盖：
#   sudo nixos-generate-config --no-filesystems --root /tmp/hw
# 生成结果勿手改（与 chen 机器同规）。
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
