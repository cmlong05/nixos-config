# 仅 chen 个人的 Flatpak 应用（以 --user 安装，跟人走；员工机拿不到）
#
# 用 nix-flatpak 的 home-manager 模块（installation = "user"），与系统级的
# shared/flatpak.nix（Vivaldi / 微信，两台机器都要）分开。
{ pkgs, inputs, ... }:

let
  # 与 shared/flatpak.nix 相同的 flathub 镜像与公钥（镜像与官方字节一致）。
  flathubGpg = pkgs.fetchurl {
    url = "https://mirror.sjtu.edu.cn/flathub/flathub.gpg";
    sha256 = "8bdc20abc4e19c0796460beb5bfe0e7aa4138716999e19c6f2dbdd78cc41aeaa";
  };
in
{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = {
    packages = [
      "com.tux4kids.tuxmath"
      "com.qq.QQ"
    ];

    remotes = [
      {
        name = "flathub";
        location = "https://mirror.sjtu.edu.cn/flathub";
        gpg-import = "${flathubGpg}";
      }
    ];
  };
}
