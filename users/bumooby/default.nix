# 用户 bumooby（管理员）—— 仅账户属性，无 home 配置（维护用系统账户）
{ ... }:

{
  users.users.bumooby = {
    isNormalUser = true;
    description = "bumooby (admin)";
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
