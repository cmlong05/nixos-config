# 显卡：NVIDIA 独显 —— 只导入到确实有 N 卡的机器
{ config, ... }:

{
  # 指定 NVIDIA 驱动
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA 驱动详细配置
  hardware.nvidia = {
    # 使用官方开源内核模块（适用于 RTX 3060）
    open = true;

    # Wayland 必需
    modesetting.enable = true;

    # 电源管理
    powerManagement.enable = true;

    # 安装 nvidia-settings 工具
    nvidiaSettings = true;
  };

  # 混合显卡 (PRIME) - 笔记本专用
  # hardware.nvidia.prime = {
    # sync.enable = true;
    # 从 lspci 获取的 Bus ID
    # nvidiaBusId = "PCI:1:0:0";
  # };

  # 注意：原 shared/gpu.nix 里有一行
  #   environment.sessionVariables.WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
  # 已删除 —— KWin 不读 WLR_ 前缀（那是 wlroots 的变量），该行从未生效。
  # 确实需要固定 GPU 顺序时，改用 KWin 认的变量，且只能放本文件：
  #   environment.sessionVariables.KWIN_DRM_DEVICES = "card1:card0";
}
