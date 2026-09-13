# 读盘：USB 存储（从 USB 盘读系统所需的 initrd 模块）
{ ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "usb_storage" "usbhid" "uas" "sd_mod" ];
}
