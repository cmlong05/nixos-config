# 虚拟化：Podman
{ config, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;   # 可选：保留 docker/podman compose 兼容
  };
}
