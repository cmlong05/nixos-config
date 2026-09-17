# 员工机安装（msi-wd）—— 固定硬件，见 machines/employee-3600/
{ ... }:

{
  imports = [
    ../../machines/employee-3600            # 机器（生成硬件 + 手写尾巴）
    # 挂载（跟盘走；员工机内盘）
    ./disk.nix
    # 系统领域（各安装共用）
    ../../shared/boot.nix
    ../../shared/networking.nix
    ../../shared/ssh.nix
    # 远程桌面（KRDP/RDP）：只提供选项，员工机默认不开（enable 默认 false）
    ../../shared/remote-desktop.nix
    ../../shared/nix.nix
    ../../shared/locale.nix
    ../../shared/desktop.nix
    ../../shared/flatpak.nix
    ../../shared/packages.nix
    # 用户点名单（bumooby 管理员 + mubimuba 员工）
    ./users.nix
  ];

  networking.hostName = "msi-wd";

  # 登录界面只列 mubimuba：管理员 bumooby 不用这台机的图形界面（维护走 ssh，
  # 见 DEPLOY-MAINT.md），留他在登录界面上只会让员工看混。
  #
  # 作用范围 = SDDM 生成的 sddm.conf 里的 [Users] HideUsers=（只过滤用户列表），
  # 不动账户本身：bumooby 照样能 ssh 登录（默认 22），也能在文本控制台
  # （Ctrl+Alt+F2…）登录。代价是 Breeze 主题"只要有用户可选就显示用户列表、
  # 不显示用户名输入框"，所以图形界面里也选不到 bumooby —— 哪天需要图形界面
  # 登管理员，临时注释掉这行再 switch，或从文本控制台登录。
  #
  # 该选项默认值是 [ "nobody" ]，普通 list 赋值会整体替换它，这里显式写回。
  services.displayManager.hiddenUsers = [ "nobody" "bumooby" ];

  system.stateVersion = "26.05";
}
