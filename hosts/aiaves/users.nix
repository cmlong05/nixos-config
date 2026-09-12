# 主机 aiaves 的用户点名单：只声明"这台机上有哪些用户"，不写账户属性。
# 账户属性 + home 配置的唯一权威来源在 ../../users/<name>/default.nix。
{ ... }:

{
  imports = [
    ../../users/chen
  ];
}
