# 显卡：Intel 内显（i915 / Arc）—— 只导入到只有核显、没有独显的机器
{ pkgs, ... }:

{
  # Intel 内显本身不需要额外驱动配置：
  # hardware.graphics.enable 已在 gpu-common.nix 打开，Mesa 会自动用 i915 + ANV。

  # Intel 内显 VA-API 硬解（见 PORTABLE.md 待办 #6）；需要时取消注释：
  # hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];
}
