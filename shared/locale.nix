# 时区、locale、输入法、字体
{ config, pkgs, ... }:

{
  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

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

    # 中文输入法本身也声明式配置好，而不是装完再去 fcitx5-configtool 里手动加。
    #
    # settings.inputMethod 会生成 /etc/xdg/fcitx5/profile（fcitx5 的输入法组定义）。
    # fcitx5 启动时按 XDG 规范在 $XDG_CONFIG_DIRS 里找 profile，而 NixOS 的
    # XDG_CONFIG_DIRS 本来就含 /etc/xdg（与本文件无关，见 /etc/set-environment），
    # 所以**新账户首次登录、没跑过 nh home switch** 也能直接用拼音：
    # 用户 ~/.config/fcitx5/profile 不存在时读系统这份，之后用户自己改了
    # （fcitx5-configtool 保存）就写进家目录、覆盖系统这份 —— 系统这份只当初始值。
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

  # 中文字体
  fonts.packages = with pkgs; [ noto-fonts-cjk-sans noto-fonts-cjk-serif dejavu_fonts ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" "Noto Sans CJK SC" ];
    serif = [ "Noto Serif" "Noto Serif CJK SC" ];
    monospace = [ "Hack" "Noto Sans Mono" "Noto Sans Mono CJK SC" ];
  };
}
