# 时区、locale、输入法、字体
{ config, pkgs, ... }:

let
  kwinrcFormat = pkgs.formats.ini { };
in

{
  # Set your time zone.
  time.timeZone = "Asia/Shanghai";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-nord
      qt6Packages.fcitx5-chinese-addons
    ];

    # 中文输入
    fcitx5.settings.inputMethod = {
      "Groups/0" = {
        Name = "默认";
        "Default Layout" = "us";
        DefaultIM = "pinyin";
      };
      "Groups/0/Items/0".Name = "keyboard-us";
      "Groups/0/Items/1".Name = "pinyin";
      "GroupOrder"."0" = "默认";
    };
  };

  environment.etc."xdg/kwinrc".source =
    let
      launcher = "${config.i18n.inputMethod.package}/share/applications/fcitx5-wayland-launcher.desktop";
    in
    kwinrcFormat.generate "kwinrc" {
      Wayland = {
        InputMethod = launcher;
        VirtualKeyboardEnabled = true;
      };
    };

  # 中文字体
  fonts.packages = with pkgs; [ noto-fonts-cjk-sans noto-fonts-cjk-serif dejavu_fonts ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
    serif = [ "Noto Serif" "Noto Serif CJK SC" ];
    monospace = [ "Hack" "Noto Sans Mono" "Noto Sans Mono CJK SC" ];
  };
}
