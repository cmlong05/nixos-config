# 用户账户定义。
# 用户级应用包已迁移到 home/modules/（apps.nix、llm.nix），这里只保留账户属性。
{ ... }:

{
  users.users."chen" = {
    isNormalUser = true;
    description = "chen";
    linger = true;  # Quadlet 用户容器服务开机自启
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
