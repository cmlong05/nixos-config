# 便携盘的机器变体：每台机器 = 一个开机菜单条目（specialisation）
#
# inheritParentConfig 默认 true = 基础系统（盘 + 服务 + 用户）+ 这里的机器组合
# （machines/<机器>/default.nix：生成硬件 + 手写尾巴）。换机器 = 开机菜单选一下，零命令。
#
# 这些 specialisation 共用便携盘上的 /var/lib/NetworkManager，所以 Wi-Fi 软件
# 开关状态也会跟着盘走。每台机器在这里显式声明开机目标，避免台式机的 off 串到笔记本。
{ config, lib, ... }:

{
  options.my.portableChen.wifiOnBoot = lib.mkOption {
    type = lib.types.nullOr lib.types.bool;
    default = null;
    description = ''
      Wi-Fi radio state to apply after NetworkManager starts on this machine.
      null preserves NetworkManager's existing state.
    '';
  };

  config = {
    systemd.services.wifi-boot-state = lib.mkIf (
      config.my.portableChen.wifiOnBoot != null
    ) {
      description = "Apply this portable-chen machine's default Wi-Fi state";
      wantedBy = [ "multi-user.target" ];
      requires = [ "NetworkManager.service" ];
      after = [ "NetworkManager.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${
          config.networking.networkmanager.package
        }/bin/nmcli radio wifi ${
          if config.my.portableChen.wifiOnBoot then "on" else "off"
        }";
      };
    };

    specialisation.chen-desktop.configuration = {
      imports = [ ../../machines/chen-desktop ];
      my.portableChen.wifiOnBoot = false;
    };

    specialisation.chen-laptop-amd.configuration = {
      imports = [ ../../machines/chen-laptop-amd ];
      my.portableChen.wifiOnBoot = true;
    };

    specialisation.chen-laptop-intel.configuration = {
      imports = [ ../../machines/chen-laptop-intel ];
      my.portableChen.wifiOnBoot = true;
    };

    specialisation.dell-intel.configuration = {
      imports = [ ../../machines/dell-intel ];
      my.portableChen.wifiOnBoot = true;
    };
  };
}
