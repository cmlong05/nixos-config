# 员工机：AMD 3600 + NVIDIA 3060（无蓝牙）
{ ... }:

{
  imports = [
    ../hardware/probe-msi-wd.nix          # 探测（内盘，固定 AMD）
    ../hardware/common.nix
    ../hardware/cpu-amd.nix
    ../hardware/gpu-nvidia.nix
  ];
}
