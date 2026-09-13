# 用户 chen（作者）—— 账户属性 + home-manager 绑定
# 账户属性是 chen 的唯一权威来源；home 配置见 ./home.nix。
# 本文件经 host-disk/nixos/users.nix（点名单）import 后，同时注入
# users.users.chen 与 home-manager.users.chen。
{ ... }:

{
  users.users.chen = {
    isNormalUser = true;
    description = "chen";
    linger = true;  # 保持用户实例在未登录时运行（dsh-web 等用户服务自启需要）
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.chen = {
    imports = [ ./home.nix ];
  };
}
