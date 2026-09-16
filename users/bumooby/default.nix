# 用户 bumooby（管理员）—— 账户属性（系统侧）
#
# 管理员用系统账户。home 配置见 ./home.nix（与 mubimuba 共用同一套用户级基线），
# 由 flake.nix 的 homeConfigurations."bumooby@msi-wd" 挂载。
{ ... }:

{
  users.users.bumooby = {
    isNormalUser = true;
    description = "";
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
