# WeChat (微信) 下载源修复
#
# nixpkgs 中 wechat 的 Linux AppImage 只从 web.archive.org 获取
# （主源已失效，见 nixpkgs pkgs/by-name/we/wechat/package.nix 的注释），
# archive.org 对国内 IP 限流（HTTP 429），导致 `nh os switch` 构建失败。
#
# 修复方式：按 nixpkgs linux.nix 的同等逻辑重建该包，把下载源改为
# 腾讯官方 CDN 直连，并跟随官方当前版本（4.1.1.8，2026-07 构建）。
# nixpkgs 仍锁定 2026-03 存档的 4.1.1.4，官方已更新，无需回退旧版。
# 4.1.1.8 已不再链接 libtiff，因此省略 nixpkgs 里的 libtiff patchelf 步骤。
#
# 注意：官方 AppImage 链接是“浮动”的（总是指向最新版）。
# 若腾讯更新版本导致哈希不匹配，构建会报错并给出新哈希，更新 hash 和 version 即可。
#
# 用法：flake.nix 中 outputs.overlays.wechat 暴露，nixosConfigurations 经
# nixpkgs.overlays 引用（见 flake.nix）。
final: prev: {
  wechat =
    let
      version = "4.1.1.8"; # 2026-07 官方当前版本（从 AppImage 内二进制版本号确认）
      appimageContents = final.appimageTools.extract {
        pname = "wechat";
        inherit version;
        src = final.fetchurl {
          url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
          hash = "sha256-RX26ArkbAxzdRBLu4HT7v/udnQax5Q/Bgi00hw4RSZA=";
        };
      };
    in
    final.appimageTools.wrapAppImage {
      pname = "wechat";
      inherit version;
      meta = prev.wechat.meta;
      src = appimageContents;
      extraInstallCommands = ''
        mkdir -p $out/share/applications
        cp ${appimageContents}/wechat.desktop $out/share/applications/
        mkdir -p $out/share/icons/hicolor/256x256/apps
        cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/

        substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat
      '';
    };
}
