# 开机后检测本机硬件，并切换到对应的机器变体。
# 同时将正确入口写入本机 NVRAM，让每台机器记住自己的变体。
# 基础系统和各变体都会运行；已在正确变体时安全退出。
# 切换前检查其他 switch-to-configuration 进程，避免并发切换。
# 只激活配置，不重写 /boot 条目或 system profile。
{ config, pkgs, ... }:

let
  detect = ../../scripts/detect-machine.sh;
  setDefault = ../../scripts/set-default-entry.sh;
  keys = ../../machines/machine-fingerprints.conf;

  # 启动条目和 loader.conf 写入 ESP（当前配置的 /boot）。
  bootMount = config.boot.loader.efi.efiSysMountPoint;
in
{
  systemd.services.auto-machine-specialisation = {
    description = "按硬件自动切到机器变体";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    # 不与 display-manager 排序，避免切换配置时形成依赖环；切换后单独重启它。
    path = with pkgs; [
      bash
      coreutils
      systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # 给配置切换留足时间，超时则明确失败。
      TimeoutStartSec = "3min";
      # 停止服务时一并终止内层的 switch-to-configuration。
      TimeoutStopSec = "30s";
    };
    script = ''
      # systemd 外壳自带 `set -e`，所有可能失败的步骤都要显式兜住。
      set -u

      # 激活过程可能启动本服务，检测到 switch-to-configuration 时跳过，避免并发切换。
      # 检查 /proc/<pid>/exe，避免 pgrep -f 因命令行包含相同文字而误判。
      activation_in_progress() {
        local pid exe
        for pid in /proc/[0-9]*; do
          exe="$(readlink "$pid/exe" 2> /dev/null || true)"
          case "$exe" in
            *switch-to-configuration*)
              return 0
              ;;
          esac
        done
        return 1
      }

      if activation_in_progress; then
        echo "auto-machine: 检测到激活正在进行，跳过（开机时才会自动切）"
        exit 0
      fi

      machine="$(bash ${detect} --table ${keys} || true)"
      if [ -z "$machine" ]; then
        echo "auto-machine: 认不出这台机器；留在当前系统（手动菜单照旧）"
        echo "auto-machine: 本机网卡 MAC 见 scripts/detect-machine.sh --probes，可往 machines/machine-fingerprints.conf 添加"
        exit 0
      fi

      # 幂等写入 NVRAM 的 LoaderEntryDefault（按机器记忆）和盘上的 loader.conf（兜底）。
      # 先写默认条目再切换，切换失败也不影响下次开机。
      bash ${setDefault} --machine "$machine" --boot ${bootMount} \
        --efi --bootctl ${pkgs.systemd}/bin/bootctl || true

      # 开机进入基础系统表示菜单手选了救援入口，此时只更新默认条目，不切换。
      # 若基础系统已经运行，则允许手动重启本服务，以便切回机器变体。
      if [ "$(readlink -f /run/current-system)" = "$(readlink -f /nix/var/nix/profiles/system)" ]; then
        state="$(systemctl is-system-running 2> /dev/null || true)"
        case "$state" in
          starting | initializing)
            echo "auto-machine: 菜单里手选了基础系统（救援入口），只改菜单默认条目，不切换"
            exit 0
            ;;
        esac
      fi

      target="/nix/var/nix/profiles/system/specialisation/$machine"
      if [ ! -x "$target/bin/switch-to-configuration" ]; then
        echo "auto-machine: 没有 $machine 这个变体（$target 不存在），留在当前系统"
        exit 0
      fi

      if [ "$(readlink -f /run/current-system)" = "$(readlink -f "$target")" ]; then
        echo "auto-machine: 已经在 $machine 里，无需切换"
        exit 0
      fi

      echo "auto-machine: 切到 $machine"
      if ! "$target/bin/switch-to-configuration" test; then
        echo "auto-machine: 切换失败（看 journalctl -u auto-machine-specialisation -b），保持当前系统" >&2
        exit 0
      fi

      # 桌面用新变体的配置重启一次（否则 SDDM/Plasma 还是旧变体启动的那个）
      systemctl restart display-manager.service && echo "auto-machine: 桌面已重启" || true
      exit 0
    '';
  };
}
