# 系统级软件包（各主机共享的机级基础软件）
#
# 判据：这里只放「**机器**需要」而不是「某个人需要」的东西 —— 尤其是 root/sudo
# 也要能用、或救援 TTY / 登录前就要有的工具。
#
# 个人应用放用户维度（users/）。放这里会渗到员工机，因为 shared/ 是所有 host 都导入。
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim                # root/sudo 改配置、救援 TTY 都要用
    git                # root 维护仓库也要用
    python3            # 不少系统工具/脚本依赖它在 PATH
    wireguard-tools    # wg-quick 需要 root 配置网络
    wget
    btop
  ];
}
