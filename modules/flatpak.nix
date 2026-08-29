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
      "com.tencent.WeChat"
      "com.tux4kids.tuxmath"
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
