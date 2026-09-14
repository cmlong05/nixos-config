# chen 台式机：AMD 3900XT + NVIDIA 3060（无核显）
{ ... }:

{
  imports = [
    ../hardware/storage-usb.nix           # 读盘（USB 根盘）
    ../hardware/storage-nvme.nix          # 读盘（内盘 NVMe）
    ../hardware/common.nix                # 底座（图形 + 固件 + 架构）
    ../hardware/cpu-amd.nix               # 微码
    ../hardware/gpu-nvidia.nix            # NVIDIA 3060
    ../hardware/bluetooth.nix
    ../hardware/wifi.nix
  ];
}
