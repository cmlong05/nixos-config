# SSH 远程访问（sshd）—— 局域网内
#
# 机级服务，两个 host（portable-chen / msi-wd）共用。
# 目前仅面向局域网：保留密码登录、未配防火墙。若将来要从公网连入，请：
#   1) 改走 WireGuard（shared/packages.nix 已带 wireguard-tools），或
#   2) 至少：PasswordAuthentication = false（仅密钥）+ 关 root + 开启防火墙并放行。
{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      # 默认端口从 22 改为 555（连接时需 ssh -p 555 user@host）
      Port = 555;
      # 禁止 root 直接登录（局域网内也建议，root 走 sudo）
      PermitRootLogin = "no";
      # 局域网内保留密码登录；若要公网暴露请改成 false
      PasswordAuthentication = true;
    };
  };
}
