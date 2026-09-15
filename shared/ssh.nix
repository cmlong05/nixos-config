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
# 目前仅面向局域网：保留密码登录、未配防火墙（将来若开防火墙，记得放行
# cfg.port）。若将来要从公网连入，请：
#   1) 改走 WireGuard（shared/packages.nix 已带 wireguard-tools），或
#   2) 至少：PasswordAuthentication = false（仅密钥）+ 关 root + 开启防火墙并放行。
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
    settings = {
      # 端口取自 my.ssh.port（默认 22）；连接时 ssh -p <port> user@host
      Port = cfg.port;
      # 禁止 root 直接登录（局域网内也建议，root 走 sudo）
      PermitRootLogin = "no";
      # 局域网内保留密码登录；若要公网暴露请改成 false
      PasswordAuthentication = true;
    };
  };
}
