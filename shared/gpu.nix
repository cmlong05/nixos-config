{ config, pkgs, ... }:

{
  # ========== 显卡驱动配置 ==========
  
  # 启用图形加速
  hardware.graphics.enable = true;

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

  # Wayland 环境变量优化
  environment.sessionVariables = {
    WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
    # 如果遇到画面撕裂，取消注释下面这行
    # KWIN_DRM_NO_AMS = "1";
  };
}
