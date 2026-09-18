# Flatpak 基础：共享应用 + flathub 镜像（主 SJTU，备 USTC）
{ lib, pkgs, ... }:
let
  # 镜像清单 / 主备顺序 / 公钥的唯一权威来源，见 lib/flatpak-mirror.nix。
  flathub = import ../lib/flatpak-mirror.nix { inherit pkgs; };

  flatpakMirror = pkgs.writeShellScript "flatpak-mirror" ''
    set -u
    inst=$1                                   # --system 或 --user
    flatpak=${pkgs.flatpak}/bin/flatpak
    grep=${pkgs.gnugrep}/bin/grep
    curl=${pkgs.curl}/bin/curl

    # 1) 按优先级挑第一个 3 秒内应答的镜像当主镜像；都不行就沿用主镜像
    mirror=""
    for m in ${lib.concatStringsSep " " flathub.mirrors}; do
      if $curl -sf --max-time 3 -o /dev/null "$m/config" 2>/dev/null; then
        mirror=$m
        break
      fi
    done
    if [ -z "$mirror" ]; then
      mirror=${flathub.primaryMirror}
      echo "flatpak-mirror: 所有镜像都没在 3s 内应答，保持 ${flathub.primaryMirror}"
    else
      echo "flatpak-mirror: $inst flathub -> $mirror"
    fi

    # 2) remote 不存在就先建（顺带导入公钥）
    if ! $flatpak remotes $inst --columns=name 2>/dev/null | $grep -qx flathub; then
      $flatpak remote-add $inst --if-not-exists \
        --gpg-import=${flathub.flathubGpg} flathub "$mirror" || true
    fi

    # 3) 钉住 URL（见上面注释：不做这步会被 redirect-url 带回官方）
    $flatpak remote-modify $inst --gpg-import=${flathub.flathubGpg} \
      --url="$mirror" flathub || true
  '';
in
{
  services.flatpak = {
    enable = true;
    # 共用的应用（两台机器都要）
    packages = [
      "com.vivaldi.Vivaldi"
      "com.tencent.WeChat"
    ];

    remotes = [
      {
        name = "flathub";
        location = flathub.primaryMirror;
        gpg-import = "${flathub.flathubGpg}";
      }
    ];

    # 自动更新（nix-flatpak 官方机制）：
    update = {
      onActivation = true;
    };
  };

  # 系统级 installation（/var/lib/flatpak）的兜底：root 身份，在 nix-flatpak
  # 自己的安装服务之前跑，保证它拿到的就是镜像地址（新建的 remote 也一样）
  systemd.services.flatpak-mirror-system = {
    description = "把系统级 flathub remote 钉在 flathub 镜像上";
    wantedBy = [ "multi-user.target" ];
    before = [ "flatpak-managed-install.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${flatpakMirror} --system";
    };
  };

  # 用户级 installation（~/.local/share/flatpak）的兜底。
  systemd.user.services.flatpak-mirror = {
    description = "把用户级 flathub remote 钉在 flathub 镜像上";
    wantedBy = [ "default.target" ];
    before = [ "flatpak-managed-install.service" ];
    serviceConfig = {
      # 每次登录跑一遍就退出；失败不牵连会话（脚本内部已 || true）。
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${flatpakMirror} --user";
    };
  };
}
