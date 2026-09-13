# 硬件底座：所有机器共有、与厂商无关
#
# 图形加速 + 非自由固件（含 wifi / 音频等固件，linux-firmware 全量）。
# CPU 微码不在这里，见 cpu-amd.nix / cpu-intel.nix。
{ ... }:

{
  # 图形加速（Mesa / OpenGL / Vulkan 用户态）
  hardware.graphics.enable = true;

  # 显式声明固件，不再依赖 generate-config 产物里的 mkDefault 传递 —— PORTABLE #7
  hardware.enableRedistributableFirmware = true;
}
