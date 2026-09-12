# 显卡：各主机共有的通用部分（不含任何厂商专属驱动）
#
# 用法：主机先导入本文件，再按自己实际的显卡叠加 gpu-nvidia.nix 或 gpu-intel.nix。
#   - 有 NVIDIA 独显 → gpu-common + gpu-nvidia（hosts/nixos、hosts/mubimuba）
#   - 只有 Intel 内显 → gpu-common + gpu-intel（hosts/aiaves）
#
# 待办（见 PORTABLE.md）：CPU 微码双开（#2）、固件开关显式化（#7）也可以收进这里，
# 因为它们同样与具体显卡无关、且各机器一致。
{ ... }:

{
  # 启用图形加速（Mesa / OpenGL / Vulkan 用户态）
  hardware.graphics.enable = true;
}
