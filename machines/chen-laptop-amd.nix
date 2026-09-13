# chen 笔记本：AMD 4800H + NVIDIA 3060（另有 Vega 核显）
{ ... }:

{
  imports = [
    ../hardware/probe-portable-chen.nix
    ../hardware/common.nix
    ../hardware/cpu-amd.nix
    ../hardware/gpu-amd-vega.nix          # 核显（内核自动驱动，留档）
    ../hardware/gpu-nvidia.nix
    ../hardware/bluetooth.nix
    ../hardware/wifi.nix
  ];
}
