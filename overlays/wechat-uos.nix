# WeChat (微信) UOS 版下载源修复
#
# nixpkgs 的 wechat-uos（UOS 商店 deb 版）下载地址
#   https://pro-store-packages.uniontech.com/appstore/pool/.../com.tencent.wechat_4.1.1.4_amd64.deb
# 会 307 跳转到 app-store-files.uniontech.com，该 CDN 做了防盗链校验，
# 必须带 Referer: https://pro-store-packages.uniontech.com/ 才能下载，
# 否则返回 403（nixpkgs 只带 -A apt，见 NixOS/nixpkgs#458010）。
#
# 修复方式：原样复用 nixpkgs 的 wechat-uos package.nix（保持其文件布局与
# 运行时依赖不变），仅把 fetchurl 包装一层，在 curlOpts 里追加 Referer。
# 版本/哈希仍由 nixpkgs 的 sources.nix（当前 4.1.1.4）决定。
#
# 用法：flake.nix 中 outputs.overlays.wechatUos 暴露，nixosConfigurations 经
# nixpkgs.overlays 引用（见 flake.nix）。
final: prev: {
  wechat-uos = prev.callPackage "${prev.path}/pkgs/by-name/we/wechat-uos/package.nix" {
    fetchurl = args: prev.fetchurl (args // {
      curlOpts = (args.curlOpts or "") + " -e https://pro-store-packages.uniontech.com/";
    });
  };
}
