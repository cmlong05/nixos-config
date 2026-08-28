{ pkgs, ... }:
let
  # flathub 的 GPG 签名公钥（镜像与官方字节一致，sha256 相同）。
  flathubGpg = pkgs.fetchurl {
    url = "https://mirror.sjtu.edu.cn/flathub/flathub.gpg";
    sha256 = "8bdc20abc4e19c0796460beb5bfe0e7aa4138716999e19c6f2dbdd78cc41aeaa";
  };
in
{
  services.flatpak = {
    enable = true;
    packages = [
      "com.vivaldi.Vivaldi"
      # SafeEyes：flathub 的 3.5.0 构建打包的 pywayland 有缺陷（核心 wayland 协议被装成
      # 单个 wayland.py 模块而非 wayland/ 包目录），导致 smartpause 插件启动时
      # `from pywayland.protocol.wayland.wl_seat import WlSeat` 抛 ModuleNotFoundError，
      # plugins_manager.start() 先于 core.start() 崩溃 → 托盘一直显示“无可用的休息”，
      # 只有重新保存一次设置（走 restart，core 先启动）才恢复。
      # 已在 ~/.var/app/io.github.slgobinath.SafeEyes/config/safeeyes/safeeyes.json 中
      # 禁用 smartpause 绕过；不要重新启用该插件，直到 flathub 修复打包问题
      # （https://github.com/flathub/io.github.slgobinath.SafeEyes/issues）。
      "io.github.slgobinath.SafeEyes"
      "com.tencent.WeChat"
      # "com.spotify.Client"
    ];


    remotes = [
      {
        name = "flathub";
        location = "https://mirror.sjtu.edu.cn/flathub";
        gpg-import = "${flathubGpg}";
      }
    ];

    # 自动更新（nix-flatpak 官方机制）：
    update = {
      onActivation = true;
    };
  };
}
