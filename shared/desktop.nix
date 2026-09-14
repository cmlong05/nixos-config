# 桌面环境：SDDM + Plasma 6、浏览器、声音（PipeWire）
{ ... }:

{
  imports = [ ./printing.nix ];

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

  # 浏览器：Chromium（经 home-manager 安装，见 users/modules/apps.nix）
  # 重启后恢复上次会话
  environment.etc."chromium/policies/recommended/restore-session.json".text = ''
    { "RestoreOnStartup": 1 }
  '';

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
