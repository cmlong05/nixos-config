# chen 台式机：AMD 3900X + NVIDIA 3060（无核显）
{ ... }:

{
  imports = [
    ../hardware/probe-portable-chen.nix   # 探测（便携盘，硬件无关）
    ../hardware/common.nix                # 底座（图形 + 固件）
    ../hardware/cpu-amd.nix               # 微码
    ../hardware/gpu-nvidia.nix            # NVIDIA 3060
    ../hardware/bluetooth.nix
    ../hardware/wifi.nix
  ];
}
