# 打印：CUPS + 标签打印机（经局域网 CUPS 服务器 10.10.10.9 共享的 Xprinter XP-470E）
{ config, pkgs, lib, ... }:

let
  # 与 nixpkgs `hardware/printers.nix` 的 ensurePrinters 生成逻辑保持一致，
  # 只是把「远端 CUPS 服务器不可达」从“服务失败”降级为“记日志 + 退出 0”，
  # 这样 `nh os test/switch` 的激活就不会再因打印服务器离线而以 exit 4 判失败。
  printers = config.hardware.printers.ensurePrinters;

  lpadminArgs = p:
    lib.cli.toCommandLineShellGNU { } (
      { p = p.name; v = p.deviceUri; m = p.model; }
      // lib.optionalAttrs (p.location != null) { L = p.location; }
      // lib.optionalAttrs (p.description != null) { D = p.description; }
      // lib.optionalAttrs (p.ppdOptions != { }) {
        o = lib.mapAttrsToList (name: value: "${name}=${value}") p.ppdOptions;
      }
    );

  ensurePrinterTolerant = p: ''
    if ${pkgs.cups}/bin/lpadmin ${lpadminArgs p} -E; then
      echo "ensure-printers: ensured printer '${p.name}'"
      changed=1
    else
      echo "ensure-printers: printer '${p.name}' unreachable (${p.deviceUri}); will retry later" >&2
    fi
  '';

  ensurePrintersScript = ''
    changed=0
    ${lib.concatMapStringsSep "\n" ensurePrinterTolerant printers}
    ${lib.optionalString (config.hardware.printers.ensureDefaultPrinter != null) ''
      if ${pkgs.cups}/bin/lpadmin -d '${config.hardware.printers.ensureDefaultPrinter}'; then
        changed=1
      fi
    ''}
    ${lib.optionalString (config.services.printing.startWhenNeeded && !config.services.printing.stateless) ''
      if [ "$changed" = 1 ]; then
        systemctl stop cups.service || true
      fi
    ''}
    exit 0
  '';
in

{
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # 标签打印机：经局域网 CUPS 服务器 (10.10.10.9) 共享的 Xprinter XP-470E。
  # 远端支持 IPP Everywhere，本地用内置 everywhere 驱动自动探测生成 PPD，
  # 无需安装厂商驱动。尺寸等选项在打印对话框中选择（如 2x4in / 4x6in）。
  hardware.printers = {
    # 如需设为默认打印机，取消下行注释：
    # ensureDefaultPrinter = "Xprinter_XP-470E";
    ensurePrinters = [
      {
        name = "Xprinter_XP-470E";
        description = "Xprinter XP-470E 标签打印机 (10.10.10.9)";
        location = "office";
        deviceUri = "ipp://10.10.10.9:631/printers/Xprinter_XP-470E";
        model = "everywhere";
      }
    ];
  };

  # ensure-printers 默认是开机一次性服务：若开机时远端 CUPS 服务器 (10.10.10.9)
  # 尚未就绪，lpadmin 连不上构建就会失败。原实现用 `set -e`，失败会让
  # `nh os test/switch` 的激活以非零退出（exit 4）判为失败。
  #
  # 这里覆盖 ExecStart 为容错版本：连不上远端时记日志但退出 0，激活不再失败；
  # 再由 timer 每 30 分钟重试，直到远端可连。
  systemd.services.ensure-printers = {
    script = lib.mkForce ensurePrintersScript;
    # 关闭 RemainAfterExit，timer 才能每次都真正重新执行 ExecStart。
    serviceConfig.RemainAfterExit = lib.mkForce false;
  };

  systemd.timers.ensure-printers = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
    };
  };
}
