# 员工机：AMD 3600 + NVIDIA 3060（无蓝牙）
{ ... }:

{
  imports = [
    ../hardware/storage-nvme.nix          # 读盘（内盘 NVMe）
    ../hardware/common.nix
    ../hardware/cpu-amd.nix
    ../hardware/gpu-nvidia.nix
  ];
}
