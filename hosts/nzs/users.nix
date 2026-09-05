# 员工机用户账户
# - chen：管理员（wheel 用于维护）
# - mubimuba：员工（无 wheel = 无 sudo，只有 networkmanager）
{ ... }:

{
  users.users."chen" = {
    isNormalUser = true;
    description = "chen (admin)";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  users.users."mubimuba" = {
    isNormalUser = true;
    description = "mubimuba (employee)";
    extraGroups = [ "networkmanager" ];
  };
}
