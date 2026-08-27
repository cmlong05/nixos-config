# 桌面环境：SDDM + Plasma 6、浏览器、声音（PipeWire）、打印（CUPS）
{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # 浏览器：Firefox（经 programs 模块启用）
  programs.firefox = {
    enable = true;
    policies.Homepage.StartPage = "previous-session";
  };

  # 浏览器：Chromium（经 home-manager 安装，见 home/modules/apps.nix）
  # 重启后恢复上次会话
  environment.etc."chromium/policies/recommended/restore-session.json".text = ''
    { "RestoreOnStartup": 1 }
  '';

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # 标签打印机：经局域网 CUPS 服务器 (10.10.10.9) 共享的 Xprinter XP-470E。
  # 远端支持 IPP Everywhere，本地用内置 everywhere 驱动自动探测生成 PPD，
  # 无需安装厂商驱动。尺寸等选项在打印对话框中选择（如 2x4in / 4x6in）。
  hardware.printers = {
    # 如需设为默认打印机，取消下行注释：
    # ensureDefaultPrinter = "Xprinter_XP-470E";
    ensurePrinters = [
      {
        name = "Xprinter_XP-470E";
        description = "Xprinter XP-470E 标签打印机 (10.10.10.9)";
        location = "office";
        deviceUri = "ipp://10.10.10.9:631/printers/Xprinter_XP-470E";
        model = "everywhere";
      }
    ];
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}
