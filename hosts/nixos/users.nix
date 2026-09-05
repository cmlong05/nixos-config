# 作者机用户账户（chen）
# 用户级应用包见 ../../home/（home.nix），这里只保留账户属性。
{ ... }:

{
  users.users."chen" = {
    isNormalUser = true;
    description = "chen";
    linger = true;  # 保持用户实例在未登录时运行（dsh-web 等用户服务自启需要）
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
