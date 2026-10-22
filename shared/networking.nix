# 网络：NetworkManager
# 注意：hostName 属于机器差异，在各主机配置里设置（os-disk/<name>/default.nix）
{ config, lib, pkgs, ... }:

{
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # mDNS/DNS-SD 局域网服务发现（打印机、设备等）。
  # 不启用 nssmdns4：它依赖 system.nssModules，而下面为关闭 nscd 已强制清空该列表。
  services.avahi = {
    enable = true;
    openFirewall = true;
  };

  # 关掉 nscd（NixOS 默认开，实现是 Rust 写的 nsncd）：
  # 开关 WiFi 时「整机卡住几秒」的元凶就是它，链路如下 ——
  #   1) 网络状态一变（开关 WiFi、DHCP 续租、改 DNS），NetworkManager 就重写 resolv.conf；
  #      而 NixOS 在生成的 /etc/resolvconf.conf 里塞了
  #        libc_restart='... systemctl try-restart --no-block nscd.service'
  #      （nixos/modules/config/resolvconf.nix：只有 services.nscd.enable 为真才写这行）
  #      → 每次网络变化都当场重启 nscd。
  #   2) 切换瞬间的 DNS 查询会卡住。本机 resolv.conf 只有 `options edns0`，即 glibc 默认
  #      timeout:5 attempts:2 = 10 秒；nsncd 又只有 8 个 worker，被占满后 accept 线程在
  #      handoff 超时上放弃，整个守护进程退出重启（单元里写死 NSNCD_HANDOFF_TIMEOUT=10、
  #      worker_count=8，见 nixos/modules/services/system/nscd.nix）。
  #   这期间任何进程调 getpwnam/getgrgid/getaddrinfo 都要先连 /var/run/nscd/socket，
  #   glibc 客户端的 poll 超时是 5 秒 —— 开终端、sudo、ps、Plasma 托盘这些跟网络无关的
  #   操作一起卡住，表现为「整机卡顿」而不是「网络慢」。
  #
  # 实测（2026-10-01，portable-chen）：
  #   10:47:44 / 10:55:19 / 11:11:39 / 11:13:15 / 12:16:03 每次 `rfkill: WLAN soft blocked`
  #   之后**正好 10.0 秒**出现
  #     nsncd: ERRO timed out waiting for an available worker, thread: accept
  #     nsncd: INFO shutting down
  #   9/25 以来 nscd 被停止 402 次，其中 13 次是上面这种 worker 超时自杀（其余多为开机/关机
  #   与上面那个 resolv.conf 钩子触发的重启）。同一个 bug 上游仍开着：
  #     https://github.com/NixOS/nixpkgs/issues/402693
  #     https://github.com/twosigma/nsncd/issues/158
  #
  # 关掉后由各进程自己做 NSS 查询：某次 DNS 卡住只卡那个进程，不再牵连全系统，上面那个
  # 「改 resolv.conf 就重启」的钩子也随之消失。代价只是没有 passwd/group/hosts 的共享缓存，
  # 单用户笔记本可忽略。
  # 若日后确实需要缓存，可改成 `services.nscd.enableNsncd = false;`（换回 glibc 自带 nscd，
  # 上游反馈退化到 ~1.4 秒而不是 5 秒+，但**仍会卡**）。
  services.nscd.enable = false;

  # ⚠️ 关掉 nscd 必须把 system.nssModules 一起清空，否则 NixOS 直接断言失败：
  #     "Loading NSS modules from system.nssModules (...), requires services.nscd.enable
  #      being set to true.  If disabling nscd is really necessary, it is possible to
  #      disable loading NSS modules by setting `system.nssModules = lib.mkForce [];`"
  #   （断言在 nixos/modules/config/nsswitch.nix:134，报错本身就是这么建议的。）
  #
  # 这个列表的用途只有一个（nsswitch.nix 里的原话："NSS modules. Hacky! Only works with
  # nscd!"）：给 nscd / sshd / dbus-broker / timesyncd 等进程加 LD_LIBRARY_PATH，让它们能
  # dlopen 到 systemd 自带的 libnss_systemd / libnss_mymachines / libnss_myhostname
  # （值来自 systemd.nix 的 `system.nssModules = [ cfg.package.out ]`）。没有 nscd 这个
  # 中转进程，它就只是白挂着 —— 普通进程本来就拿不到这个 LD_LIBRARY_PATH。
  #
  # 代价（本机可接受，2026-10-01 核对过）：
  #   - /etc/nsswitch.conf 里仍会留 `systemd` / `mymachines` / `myhostname` 条目，glibc 找不到
  #     对应模块时按「不可用」跳过，不会卡；passwd/group/shadow 照走 files，hosts 走
  #     files + dns（/etc/hosts 里已有 localhost 与 portable-chen）。
  #   - 失去的只是 userdb 那类查询：本机没有 DynamicUser 单元、不用 systemd-nspawn/homed，
  #     也没有开 samba/sssd/avahi 的 nssmdns/libvirtd-nss 任何一个（它们才会往这个列表里加东西）。
  # 若哪天真的需要 nss-systemd（例如用 homed / nspawn），就把上面 nscd 那两行换成
  # `services.nscd.enableNsncd = false;`（保留 glibc nscd，卡顿只会退化到 ~1.4s 而不是消失）。
  system.nssModules = lib.mkForce [ ];
}
