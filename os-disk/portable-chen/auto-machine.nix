# 方案 A（运行期兜底）：开机后按本机硬件，把自己「换成」对应的机器变体。
#
# 为什么需要它：开机菜单里选哪条由 bootloader 决定，系统里改不了。
# boot-machine.nix 在部署时把默认条目指向本机变体；但把盘插到「还没在这台机器上
# rebuild 过」的机器时，默认条目仍是**上一个机器**的变体条目 —— 这个 oneshot 就负责
# 从那个变体里切到对的那台。
#
# 它同时把本机变体写进**本机 NVRAM** 的 EFI 变量 LoaderEntryDefault（见下面 setDefault
# 那段注释）：那才是「每台机器各自记住自己」的主记忆 —— loader.conf 在盘上，会被别的机器
# 上跑的 rebuild 改走；NVRAM 跟机器走，改不动。变量在某台机器上种过之后，再回到那台机器
# （哪怕中间在别的机器上 rebuild 过）第一次开机就直接落在本机变体上。
#
# 它在两个地方都会跑：基础系统（控制台救援入口，读盘模块见 ./disk.nix）和每个变体
# （specialisation 的 inheritParentConfig 默认 true 会继承）。所以「已经在正确变体里」
# 时必须是安全的空操作 —— 见下面 readlink 比对；从基础系统里跑也能救回桌面。
#
# 切法就是 NixOS 官方给 specialisation 的用法：
#     <变体>/bin/switch-to-configuration test
# 用 test（不是 switch）：只激活配置，不重写 /boot 条目、不动 system profile。
#
# 它会被每个变体继承（specialisation 的 inheritParentConfig 默认 true），
# 所以「已经在正确变体里」时必须是安全的空操作 —— 见下面 readlink 比对。
#
# ⚠️ 只在开机路径上动手：激活会把「新增单元」拉起来，本单元第一次进入新配置时
# 正是被那次激活启动的 —— 那里面再切一次就是并发切换（实测让激活报 failed）。
# 所以脚本第一件事是检查有没有别的 switch-to-configuration 在跑，有就退出。
{ config, pkgs, ... }:

let
  detect = ../../scripts/detect-machine.sh;
  setDefault = ../../scripts/set-default-entry.sh;
  keys = ../../machines/machine-keys.txt;

  # 条目和 loader.conf 写在 $BOOT：配了 XBOOTLDR 分区就是它，否则是 ESP
  # （boot-machine.nix 里有一份同样的算法：那处是同一份 config，只是部署期跑）
  bootMount =
    if config.boot.loader.systemd-boot.xbootldrMountPoint != null then
      config.boot.loader.systemd-boot.xbootldrMountPoint
    else
      config.boot.loader.efi.efiSysMountPoint;
in
{
  systemd.services.auto-machine-specialisation = {
    description = "按硬件自动切到 portable-chen 的机器变体";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    # ⚠️ 故意**不**和 display-manager 建立顺序关系（不加 before/after）：
    # switch-to-configuration 自己会 start/restart 一批单元，其中包括 display-manager ——
    # 若我们被排在它前面，就会形成「我们等它、它等我们」的环；排在它后面则它的 restart
    # 又要先停我们。所以：不排序，切完自己把桌面重启一次（见脚本末尾）。
    path = with pkgs; [
      bash
      coreutils
      systemd
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # switch-to-configuration 要停/起一批单元，给足时间；但也别无限等，坏事时 fail 掉更清楚
      TimeoutStartSec = "3min";
      # 卡住时能停得干净（默认 KillMode=control-group 会连内层 switch-to-configuration 一起收）
      TimeoutStopSec = "30s";
    };
    script = ''
      # 注意：systemd 生成的脚本外壳自带 `set -e`（失败会让单元变 failed、
      # 并把 `nh os switch` 的激活判为失败），所以每个可能失败的步骤都要显式兜住。
      set -u

      # ⚠️ 只在「真正的开机」路径上动手。
      # 激活（nh os switch / nixos-rebuild）会启动「新增单元」，所以本单元第一次出现在
      # 新配置里时，是被那次激活自己拉起来的；此时里面再跑一次 switch-to-configuration
      # 就是两次切换并发 —— 实测会让激活报 "auto-machine-specialisation.service failed"
      # （unit 脚本带 set -e，内层返回 4 直接终止脚本）。
      # 判据：有没有进程的**可执行文件**就是 switch-to-configuration。
      # 看 /proc/<pid>/exe，而不是 `pgrep -f`（后者匹配整条命令行，会被任何「命令行里
      # 恰好含这串字」的无关进程误命中 —— 实测在 shell 里跑诊断命令就会误判）。
      # 服务以 root 跑，所以对所有进程的 /proc/<pid>/exe 都可读。
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
        echo "auto-machine: 本机指纹见 scripts/detect-machine.sh --probes，可往 machines/machine-keys.txt 加行"
        exit 0
      fi

      # 顺手把**菜单默认条目**认对，两个目的地一起写（细节见 scripts/set-default-entry.sh）：
      #   - 本机 NVRAM 的 EFI 变量 LoaderEntryDefault：跟机器走，且 systemd-boot 优先用它
      #     → 每台机器各自记住自己的变体。第一次在那台机器开过机之后，来回换机器都不用
      #     再手选；别的机器上 rebuild 也覆盖不到它（loader.conf 会 —— 它在盘上）。
      #   - 盘上的 $BOOT/loader/loader.conf：跟盘走，是没有 NVRAM 时的兜底。
      # 幂等：已经是目标就什么都不写。放在切换之前：即使下面的切换失败，下一次开机也已经
      # 落在对的机器上。
      bash ${setDefault} --machine "$machine" --boot ${bootMount} \
        --efi --bootctl ${pkgs.systemd}/bin/bootctl || true

      # 尊重"菜单里手选"：基础系统是救援入口（默认条目是变体，只有手选才进得来），
      # 开机阶段跑在基础系统里 → 只改菜单默认条目，不把当前系统切走。
      # 例外：plain `nh os switch` 也会让"运行中的系统"变成基础系统，那时系统已经 running ——
      # 按文档 `systemctl restart auto-machine-specialisation` 是要切回变体的，所以放行。
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
