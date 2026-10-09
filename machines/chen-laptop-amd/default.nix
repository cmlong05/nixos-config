# chen 笔记本：AMD 4800H + NVIDIA 3060（移动版 / Max-Q）
#
# 组合入口 = 生成器产物（./hardware-configuration.nix，本机实测生成，勿改）
#          + 手写尾巴（NVIDIA / 固件 / 图形 / 蓝牙）。
# 注：本机有个固件级（EC / 热键，Linux 看不到也改不了）的 iGPU / dGPU 直连切换：
#   2026-10-01 实测 asus_wmi 虽会加载，但报 "ASUS Management GUID not found"（没有
#   asus-nb-wmi 的 gpu_mux_mode 之类接口），内核里也没有 mechrevo/tongfang/uniwill
#   的 WMI 驱动 —— 所以模式只能在固件层切，且切换后要重启才生效。
#   判断现在在哪个模式（哪个 GPU 的 eDP 是 connected，就是它在驱动内屏）：
#     for l in /sys/class/drm/card*-eDP-*/; do echo "$l $(cat $l/status)"; done
#   实测 hybrid = amdgpu 的 card2-eDP-2 connected、nvidia 的 card1-eDP-1 disconnected；
#   切到独显直连则反过来（核显可能整个不出现，旧注释记的就是那种状态）。
#   一份配置同时覆盖两种模式：nvidia-drm 的 modeset=1 两边都需要，下面那个 runtime D3
#   参数只在 hybrid 下有意义 —— 独显直连时 GPU 驱动着显示，按驱动文档不会进 runtime D3。
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;

    # ⚠️ 把 runtime D3 从默认的 0x03 压到 0x02 —— 否则 dGPU 会周期性「假死」
    moduleParams.nvidia.NVreg_DynamicPowerManagement = "0x02";
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
