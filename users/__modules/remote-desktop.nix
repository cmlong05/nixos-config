# KDE 远程桌面（KRDP / RDP）—— 用户侧（home-manager）
#
# 服务本体 krdpserver 跑在**用户会话**里（Plasma 6 自带，图形入口是「系统设置 → 远程桌面」，
# 即 kcm_krdpserver），所以整套东西在这里：配置文件 + systemd 用户服务 + 开机自启。
# 系统侧只有一个防火墙放行（shared/remote-desktop.nix）；krdp 包本身由 plasma6 模块自带。启用方式（端口同 ssh：默认
# 3389，各人/各机自己覆盖）：
#     my.remoteDesktop = { enable = true; port = 59599; };
# 默认 enable = false：只有显式打开的用户才跑这个服务。
#
# 三个坑，实现里都绕过了：
#
#   1) 配置文件必须是**可写的真实文件**，不能让 home-manager 直接 symlink 进 store。
#      KConfig 保存是"原地写、跟随符号链接"（实测：kwriteconfig6 对指向只读文件的
#      符号链接报错、且不替换链接），所以 store 符号链接会让 KCM 里任何"保存/开关"
#      都失败。这里用 home.activation 把内容 install 成 ~/.config/krdpserverrc。
#      代价：KCM 里改的设置会在下一次 `nh home switch` 被声明值覆盖 —— 端口、认证方式
#      这类该走声明式的设置就改 nix 文件；KWallet 里的连接密码不受影响（不在这个文件里）。
#
#   2) 证书必须**先存在**：Server::start() 在证书文件缺失时直接
#      "A valid TLS certificate ... is required for the server to run!" 拒绝启动
#      （不是 README 说的"缺了就临时自签"）。而 KCM 生成证书用的是 `openssl req -days 1`
#      ——本机 8/29 生成的那份 8/30 就过期了。所以由 ExecStartPre 自己签一份 10 年的：
#      文件缺失、为空、或剩下不到一天就重签（位置与 KCM 一致，KCM 会沿用同一份）。
#
#   3) 无人值守：portal（xdg-desktop-portal-kde 的 RemoteDesktop 接口）默认会在**本机屏幕**
#      上弹授权框，人不在机器前就白连。KCM 打开开关时做的正是往 portal 权限库写一条预授权
#      （等价于 README 的 `flatpak permission-set kde-authorized remote-desktop
#      org.kde.krdpserver yes`，表名 kde-authorized 是 xdg-desktop-portal 认的 KDE 后端表）。
#      这里用一个 oneshot 服务在 krdpserver 之前做同样的事；失败不影响服务启动（ExecStart
#      前缀 `-`），最坏就是第一次连接要在本机屏幕上点一下授权。
#
# 认证方式：SystemUserEnabled=true → 走 PAM（/etc/pam.d/login，即**系统账号密码**，
# NixOS 已由 security.pam 提供），不需要往 KWallet 里存密码，也不需要 root。
# 客户端填 chen + 系统密码即可（用户名大小写敏感；Windows 的 mstsc / xfreerdp 都行）。
#
# ⚠️ 服务开启 = 这台机器**物理上无人时也能被别人远程接管桌面**（而且远程登录时本机屏幕
#    也是解锁状态的）。端口、防火墙、密码强度都按"局域网内可信"来写，别把 59599 映射到公网。
{ config, lib, pkgs, ... }:

let
  cfg = config.my.remoteDesktop;

  # 证书目录/文件名与 KCM 一致：$XDG_DATA_HOME/krdpserver/krdp.{crt,key}
  certDir = "${config.xdg.dataHome}/krdpserver";

  # ~/.config/krdpserverrc（KConfig；组 General）。 ListenPort 必须与系统侧
  # shared/remote-desktop.nix 的防火墙放行端口一致。
  krdpserverrc = pkgs.writeText "krdpserverrc" ''
    [General]
    ListenPort=${toString cfg.port}
    AutogenerateCertificates=true
    Certificate=${certDir}/krdp.crt
    CertificateKey=${certDir}/krdp.key
    SystemUserEnabled=true
    Autostart=true
  '';

  # 启动前保证有一份**没过期**的证书（原因见文件头第 2 条）
  ensureCertificate = pkgs.writeShellScript "krdp-ensure-certificate" ''
    set -eu
    dir=${lib.escapeShellArg certDir}
    crt="$dir/krdp.crt"
    key="$dir/krdp.key"

    need=yes
    if [ -s "$crt" ] && [ -s "$key" ] \
       && ${pkgs.openssl}/bin/openssl x509 -in "$crt" -noout -checkend 86400 >/dev/null 2>&1
    then
      need=no
    fi

    if [ "$need" = yes ]; then
      echo "krdp: 生成自签证书到 $dir（有效期 10 年）"
      umask 077
      ${pkgs.coreutils}/bin/mkdir -p "$dir"
      ${pkgs.openssl}/bin/openssl req -nodes -new -x509 -batch \
        -subj "/CN=krdp" -days 3650 \
        -keyout "$key" -out "$crt"
    fi
  '';
in

{
  options.my.remoteDesktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "是否启用 KDE 远程桌面（KRDP/RDP）的用户级服务：登录自启 + 写 krdpserverrc";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3389;
      description = "krdpserver 监听端口；须与系统侧 shared/remote-desktop.nix 的 my.remoteDesktop.port 一致";
    };
  };

  config = lib.mkIf cfg.enable {
    # 真实文件（不是 store 符号链接）：KCM 要能就地保存，见文件头第 1 条
    home.activation.krdpserverrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/install -D -m 600 ${krdpserverrc} "$HOME/.config/krdpserverrc"
    '';

    systemd.user.services = {
      # 单元名必须与上游一字不差（app-org.kde.krdpserver.service）：
      #   - portal 靠 systemd 单元的 `app-` 前缀识别调用者 id（org.kde.krdpserver），
      #     名字一变，下面 krdp-portal-authorize 写的预授权就对不上了；
      #   - KCM 是按这个单元名经 systemd D-Bus 开关服务/查询状态的。
      # 上游单元被 KDE 自己的 preset 钉成永不默认启用（server/00-krdp.preset:
      # "disable app-org.kde.krdpserver.service"），而用户级 ~/.config/systemd/user
      # 优先级高于系统单元目录，所以在这里写同名单元 + want 链接即可"默认开启"。
      # Unit/Service 各字段照抄上游单元（app-org.kde.krdpserver.service.in），
      # 只多一条 ExecStartPre 保证证书存在。
      "app-org.kde.krdpserver" = {
        Unit = {
          Description = "KRDP Server";
          After = [ "plasma-core.target" "plasma-xdg-desktop-portal-kde.service" ];
        };
        Service = {
          Type = "exec";
          ExecStartPre = "${ensureCertificate}";
          ExecStart = "${pkgs.kdePackages.krdp}/bin/krdpserver";
          Restart = "on-abnormal";
        };
        Install.WantedBy = [ "plasma-workspace.target" ];
      };

      # portal 预授权（见文件头第 3 条）。类型 oneshot：每次登录跑一次即可；
      # Before= 只排顺序、不被依赖，所以这条失败不会拦住 krdpserver。
      krdp-portal-authorize = {
        Unit = {
          Description = "Pre-authorize KRDP for the RemoteDesktop portal";
          Before = [ "app-org.kde.krdpserver.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          # 开头的 `-` = 失败也不算单元失败（权限库不可用时只是弹授权框而已）
          # （写成一行：systemd 虽然认行尾反斜杠续行，但没必要让 unit 文件依赖它）
          ExecStart = "-${pkgs.dbus}/bin/dbus-send --session --type=method_call --dest=org.freedesktop.impl.portal.PermissionStore /org/freedesktop/impl/portal/PermissionStore org.freedesktop.impl.portal.PermissionStore.SetPermission string:kde-authorized boolean:true string:remote-desktop string:org.kde.krdpserver array:string:yes";
        };
        Install.WantedBy = [ "plasma-workspace.target" ];
      };
    };
  };
}
