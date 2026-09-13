# chen Intel 笔记本：Intel Core Ultra 9 285H（仅内显 Arc）
{ ... }:

{
  imports = [
    ../hardware/storage-usb.nix
    ../hardware/storage-nvme.nix
    ../hardware/common.nix
    ../hardware/cpu-intel.nix
    ../hardware/gpu-intel.nix
    ../hardware/bluetooth.nix
    ../hardware/wifi.nix
  ];
}
