# SSH 远程访问（sshd）—— 局域网内
#
# 机级服务，两个 host（portable-chen / msi-wd）共用。
#
# 端口属于机器差异，所以本模块只定义选项 + 默认值，各机在
# os-disk/<host>/default.nix 里覆盖（与 shared/networking.nix 的 hostName 同一约定）：
#     my.ssh.port = 555;
# 默认取 22：别人 clone 这份配置后拿到的是标准端口，不会被动跟着本机改。
# 注意 flake 是纯求值，且只把 git 索引里的文件当源码 —— 想让改动生效，
# 新文件必须先 `git add`（未 add 的文件对求值不可见）。
#
# ⚠️ 端口要写进 `services.openssh.ports`，**不是** `settings.Port`：
#   NixOS 是拿 `ports` 同时干两件事（sshd.nix）——生成 sshd 的 `Port` 行
#   （extraConfig: `Port ${toString port}`）和防火墙放行
#   （`networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall cfg.ports`，
#   `openFirewall` 默认 true）。而 NixOS 默认**开着**防火墙
#   （`networking.firewall.enable` 默认 true），所以只写 settings.Port 的结果是：
#   sshd 多听一个端口、防火墙却仍只放 22 —— 现象就是 `ssh -p 555` 从别的机器连不上、
#   `-p 22` 反而能连（2026-09-15 修；那时 sshd_config 里 `Port 555` 与 `Port 22` 并存）。
#
# 目前仅面向局域网：保留密码登录。若将来要从公网连入，请：
#   1) 改走 WireGuard（shared/packages.nix 已带 wireguard-tools），或
#   2) 至少：PasswordAuthentication = false（仅密钥）+ PermitRootLogin = "no"。
#      端口放行已由上面的 ports 自动带上（openFirewall 默认 true），不用另写。
{ config, lib, ... }:

let
  cfg = config.my.ssh;
in

{
  options.my.ssh.port = lib.mkOption {
    type = lib.types.port;
    default = 22;
    description = "sshd 监听端口；各机在 os-disk/<host>/default.nix 里按需覆盖";
  };

  config.services.openssh = {
    enable = true;

    # 监听端口与防火墙放行都看它（连接时 ssh -p <port> user@host）
    ports = [ cfg.port ];

    settings = {
      # 禁止 root 直接登录（局域网内也建议，root 走 sudo）
      PermitRootLogin = "no";
      # 局域网内保留密码登录；若要公网暴露请改成 false
      PasswordAuthentication = true;
    };
  };
}
