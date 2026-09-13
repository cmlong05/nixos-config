# 硬件底座：各主机共有、且**与具体厂商无关**的部分
#
# 这里放的东西必须"插到任何一台机器上都成立"——便携盘会在多台机器间换，
# 所以 CPU 微码两个都要开、固件要显式声明。
#
# 厂商专属的图形驱动不放这里，按机器叠加：
#   - NVIDIA 独显 → shared/gpu-nvidia.nix（mubimuba；便携盘上作为 specialisation.nvidia）
#   - Intel 内显 → shared/gpu-intel.nix （便携盘上作为 specialisation.intel）
{ ... }:

{
  # 图形加速（Mesa / OpenGL / Vulkan 用户态）
  hardware.graphics.enable = true;

  # 显式声明，不再依赖 nixos-generate-config 产物里的 mkDefault 传递
  # （重新生成硬件配置就可能变）—— PORTABLE.md #7
  hardware.enableRedistributableFirmware = true;

  # 两个 CPU 微码都开：各 CPU 只吃自己那份，代价仅是 initrd 大几 MB。
  # 便携盘会在 Intel / AMD 机器上启动，无法只选一个 —— PORTABLE.md #2
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
}
