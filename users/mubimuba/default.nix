# 用户 mubimuba（一般用户）—— 账户属性 + home-manager 绑定
{ ... }:

{
  users.users.mubimuba = {
    isNormalUser = true;
    description = "mubimuba - employee";
    extraGroups = [ "networkmanager" ];
  };

  home-manager.users.mubimuba = {
    imports = [ ./home.nix ];
  };
}
