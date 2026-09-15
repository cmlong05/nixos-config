# KDE 远程桌面（KRDP / RDP）—— 系统侧
#
# 机级服务，两个 host 共用，约定与 shared/ssh.nix 一致：端口属于机器差异，模块只定义
# 选项 + 默认值，各机在 os-disk/<host>/default.nix 里按需覆盖：
#     my.remoteDesktop = { enable = true; port = 59599; };
# 默认 enable = false：员工机（msi-wd）不受影响，要开就在各自的 host 里显式打开。
#
# 为什么远程桌面还要一个"系统模块"？因为服务本体是**用户级**的（krdpserver 跑在
# 用户会话里，见 users/modules/remote-desktop.nix），系统侧就只剩一件事：
#
#   防火墙放行。NixOS 默认**开着**防火墙（networking.firewall.enable 默认 true），
#   本仓库没有关掉它；不放行的话局域网根本连不上，改端口也白改。
#
# krdp 包**不在这里装**：services.desktopManager.plasma6.enable 已经带了它 ——
# nixpkgs 的 plasma6 模块把 krdp 列在 optionalPackages 里（→ environment.systemPackages，
# 见 nixos/modules/services/desktop-managers/plasma6.nix），krdpserver、kcm_krdpserver
# 和上游 systemd 单元都出自那一个包。用户侧的单元 ExecStart 又直接引用
# `pkgs.kdePackages.krdp` 的 store 路径，所以服务不依赖"系统里装没装"。
# 唯一例外是 KCM 那一页（System Settings → 远程桌面）：它由系统包提供，若哪天把 krdp
# 写进 `environment.plasma6.excludePackages`，这页会消失（服务照跑）；真要留着 KCM，
# 就在这里补回 `environment.systemPackages = [ pkgs.kdePackages.krdp ];`。
#
# ⚠️ 端口在这个仓库里是**两处**：
#     系统侧 = 本文件的 my.remoteDesktop.port（只影响防火墙放行）
#     用户侧 = users/modules/remote-desktop.nix 的 my.remoteDesktop.port（真的监听端口）
#   sshd 是系统服务，端口只有系统侧一处；krdpserver 是用户服务，防火墙与配置天然分属
#   两层，改端口时两边都要改，否则出现"服务在听 59599、防火墙只放 3389"这种连不上的状态。
{ config, lib, ... }:

let
  cfg = config.my.remoteDesktop;
in

{
  options.my.remoteDesktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "是否打开 KDE 远程桌面（KRDP/RDP）的系统侧支持（防火墙放行）";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3389;
      description = "krdpserver 监听端口（仅用于防火墙放行）；各机在 os-disk/<host>/default.nix 里按需覆盖";
    };
  };

  config = lib.mkIf cfg.enable {
    # 只放行 TCP：KRDP 是纯 RDP（TLS over TCP），没有需要额外放行的 UDP 端口
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
