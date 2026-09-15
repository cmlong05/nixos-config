# 用户 mubimuba（一般用户）—— 账户属性（系统侧）
#
# 账户属性是 mubimuba 的唯一权威来源；home 配置见 ./home.nix，
# 由 flake.nix 的 homeConfigurations."mubimuba@msi-wd" 挂载（同一份文件）。
# mubimuba 没有 wheel，但 standalone home-manager 不需要提权，
# 所以他能自己跑 `nh home switch` 激活/更新自己的家目录。
{ ... }:

{
  users.users.mubimuba = {
    isNormalUser = true;
    description = "mubimuba - employee";
    extraGroups = [ "networkmanager" ];
  };
}
