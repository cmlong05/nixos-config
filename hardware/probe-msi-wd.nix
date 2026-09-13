# 员工机安装（os-disk/msi-wd）的硬件探测 —— 固定 AMD 机器，可写死
#
# ⚠️ 装机时重新生成后覆盖（见 DEPLOY.md / os-disk/msi-wd/disk.nix 顶部注释）。
{ lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "usbhid" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];   # 固定 AMD 机，可直接写死（不写也会按需自加载）
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # 微码不在这里：intel/amd 双微码已在 hardware/common.nix 统一开。
}
