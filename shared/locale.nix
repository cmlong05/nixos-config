# 时区、locale、输入法、字体
{ config, pkgs, ... }:

let
  # KDE Wayland 下输入法由合成器（KWin）拉起，KWin 的命令行来自 kwinrc 的
  # [Wayland] InputMethod（见 kwin 的 src/inputmethod.cpp：startInputMethod()
  # 把该值当命令 split 后 exec）。NixOS 不设这项，所以新账户上它是空的：
  #   - KWin 无法用 Wayland input-method 协议拉起 fcitx5，即使 fcitx5 正跑着，
  #     也没有 input-method socket，Wayland 应用里根本打不出中文；
  #   - KWin 于是每次都弹「Fcitx 在 KDE Wayland 应由 KWin 启动…」的提示。
  # 系统设置（系统设置 → 虚拟键盘）只是把下面这个值写进用户 ~/.config/kwinrc，
  # 所以这里声明成系统默认值就够了（KConfig 先读 $XDG_CONFIG_HOME，再回落到
  # $XDG_CONFIG_DIRS = /etc/xdg，用户自己的值仍然优先）。
  kwinrcFormat = pkgs.formats.ini { };
in

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

  # KWin（KDE Wayland）的系统默认输入法：开机即用，不需要再进系统设置点一次。
  #
  # 值必须是**可执行命令**（不是 .desktop 名）：上游 kcm 存的是 desktop 文件的
  # 绝对路径，KWin 拿它当命令直接 exec —— 这个 launcher 会带上 Wayland
  # input-method socket 启动 fcitx5（fcitx5-wayland-launcher --reopen）。
  #
  # 用 pkgs.formats.ini 拼文件，而不是 environment.etc 的 text 模板：源串里的
  # ${...} 会被 Nix 当插值解析，配 .desktop 路径很容易踩坑。
  environment.etc."xdg/kwinrc".source =
    let
      # 包的宿主是 i18n.inputMethod.package（fcitx5 子模块只放 addons 等选项），
      # 即上面的 fcitx5-with-addons；用写死的 /run/current-system/sw/... 也行，
      # 但那样每次 fcitx5 升级都会留下一个失效的绝对路径。
      launcher = "${config.i18n.inputMethod.package}/share/applications/fcitx5-wayland-launcher.desktop";
    in
    kwinrcFormat.generate "kwinrc" {
      Wayland = {
        InputMethod = launcher;
        # KWin 只在「已启用」时才启用输入法（inputmethod.cpp 构造里读同一组），
        # 桌面环境下默认就是 true，这里显式写上，免得被改坏时静默失效。
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
