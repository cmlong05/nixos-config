# 让本机上的无参数 `nh os switch` 自动选择当前硬件的 specialisation。
#
# nh 只会在未指定 -H 时默认选择本机 hostname（这里是 portable-chen），
# 但没有“默认 specialisation”选项。包装器只拦截本机的 os switch；
# 显式 -s/-S/-H/--target-host 仍由用户控制，其他 nh 子命令原样透传。
{ lib, pkgs, ... }:

let
  realNh = pkgs.nh;
in
{
  programs.nh.package = pkgs.writeShellApplication {
    name = "nh";
    text = ''
      exec ${pkgs.bash}/bin/bash ${../../scripts/nh-local-wrapper.sh} \
        ${lib.getExe realNh} \
        ${../../scripts/detect-machine.sh} \
        ${../../machines/machine-fingerprints.conf} \
        "$@"
    '';
  };
}
