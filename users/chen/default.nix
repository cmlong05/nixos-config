# 用户 chen（作者）—— 账户属性（系统侧）
#
# 账户属性是 chen 的唯一权威来源；home 配置见 ./home.nix，
# 由 flake.nix 的 homeConfigurations."chen@portable-chen" 挂载（同一份文件），
# 激活方式是用户自己跑 `nh home switch`（不需要 sudo）。
{ ... }:

{
  users.users.chen = {
    isNormalUser = true;
    description = "chen";

    # 保持用户实例在未登录时运行（dsh-web 等用户服务自启需要）
    linger = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
