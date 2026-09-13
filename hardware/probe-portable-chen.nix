# 便携盘安装（os-disk/portable-chen）的硬件探测 —— **必须与具体机器无关**
#
# 这块盘要在多台机器上启动，所以这里不能出现任何机器专属的东西：
#   - 不写死 kvm-amd / kvm-intel：KVM 模块会按需自动加载
#   - 微码不在这里：在 cpu-amd.nix / cpu-intel.nix（兜底 base 两个都 import）
# 机器专属的驱动差异放 specialisation（见 os-disk/portable-chen/default.nix），
# 或另开独立安装（os-disk/<name>/ + hardware/<name>.nix）。
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
