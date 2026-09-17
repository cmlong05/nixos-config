# 员工机（msi-wd）mubimuba 桌面上的 office 网络文件夹链接
#
# KDE 里的「桌面文件夹链接」就是一个 .desktop（Type=Link + URL=smb://…）：双击交给
# KIO 的 smb worker 打开，**不挂载、不占挂载点**，跟 Windows 的"映射网络驱动器"不是
# 一回事（也就不需要 sudo / fileSystems）。作者机桌面上那份是手工建的，这里把同一份
# 东西**声明式**化：由 home-manager 的 home.file 生成，字段与原文件一致，只是 URL
# 指到办公室共享里的具体目录。
#
# 密码**不写进 URL**：那样会明文进世界可读的 /nix/store（同机别的账户能读，且
# nh home switch 的每个旧世代都留一份副本，回滚也删不掉）。改成走 KDE 自己的 KWallet：
#   - 这里只声明到用户名 `smb://operation@…`。kio-extras 的 checkPassword() 会把 URL 里
#     的用户名预填进认证框，并把 keepPassword 置真（= 认证框上的「记住密码」勾选框）；
#   - 员工机上**首次双击**输一次密码 + 勾「记住密码」，密码存进他自己的
#     ~/.local/share/kwalletd/kdewallet.kwl（0600，只有他自己读得到）；
#   - 之后 checkCachedAuthentication() 直接命中 KWallet，不再弹框（key 按
#     主机 + 共享 + 用户名 匹配，所以桌面链接里写不写 /Product 子路径都一样命中）。
# 代价有二：① 每台机 / 每个账户要手工输这一次（写在 DEPLOY-INSTALL 第 6 节）；
# ② KWallet 若用**空口令**（自动登录的机器常见），加密形同虚设 —— 它防的是"同机别的
# 账户 / 仓库泄漏"，不防 mubimuba 自己的进程。
#
# 另一条备选（想彻底不手工）：用 sops-nix/agenix 把密码加密进仓库，再让 home.activation
# 在激活时拼出一份 0600 的**真实** .desktop（不能走 home.file，那还是 store 里的明文）。
# 现在没上，是因为为这一条链接引入 age 密钥分发不划算。
#

{ ... }:

let
  # XDG 桌面目录名：系统 locale 固定 zh_CN（shared/locale.nix），xdg-user-dirs 首次登录
  # 生成的就是「桌面」（plasma6 模块自带该包，见 nixpkgs plasma6.nix）。home.file 会自己
  # 把父目录建出来，所以不依赖 xdg-user-dirs-update 是否已经跑过。万一哪天这台机的桌面
  # 叫 Desktop，改这一个串即可。
  desktopDir = "桌面";

  # 办公室文件服务器 10.10.10.9 上的 \\Operation\Product
  # 只带用户名不带密码：密码交给 KWallet（见文件头）
  shareUrl = "smb://operation@10.10.10.9/Operation/Product/";
in
{
  home.file."${desktopDir}/office.desktop".text = ''
    [Desktop Entry]
    Icon=network-workgroup
    Name=office
    Type=Link
    URL[$e]=${shareUrl}
  '';
}
