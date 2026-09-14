# 非本机生成 —— 由旧组件（storage-usb + storage-nvme + cpu-intel + gpu-intel）
# 拼装的占位，到 chen-laptop-intel 后重跑覆盖：
#   sudo nixos-generate-config --no-filesystems --root /tmp/hw
# 生成结果勿手改（与另两台同规）。
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];   # 推测：对应另两台的 kvm-amd，到机核实
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
