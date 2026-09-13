# 便携盘的硬件探测（**必须与具体机器无关**）
#
# 这块盘要在多台机器上启动，所以这里不能出现任何机器专属的东西：
#   - 不写死 kvm-amd / kvm-intel：KVM 模块会按需自动加载
#   - 微码不在这里：intel / amd 两个都在 shared/hardware-common.nix 同时开
# 机器专属的驱动/固件调整请放 specialisation，或另开独立 host。
{ lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # 从 USB 移动硬盘启动所需的最小集合
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
