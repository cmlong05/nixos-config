# flathub 镜像清单 —— 唯一权威来源。
#
# 用法（这不是 NixOS/HM 模块，只是个函数）：
#   let flathub = import ../lib/flatpak-mirror.nix { inherit pkgs; }; in ...

{ pkgs }:
rec {
  # 顺序即优先级：第一个是主，后面的是备
  mirrors = [
    "https://mirror.sjtu.edu.cn/flathub"
    "https://mirrors.ustc.edu.cn/flathub"
  ];

  primaryMirror = builtins.head mirrors;

  # flathub 的 GPG 签名公钥（各镜像与官方字节一致，sha256 相同）
  flathubGpg = pkgs.fetchurl {
    url = "${primaryMirror}/flathub.gpg";
    sha256 = "8bdc20abc4e19c0796460beb5bfe0e7aa4138716999e19c6f2dbdd78cc41aeaa";
  };
}
