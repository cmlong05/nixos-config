# LLM 相关工具（由 llm-agents 输入提供）
{ config, pkgs, inputs, ... }:

let
  lib = pkgs.lib;
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  # reasonix 的 Go 依赖默认从 proxy.golang.org 拉取，国内直连超时（IPv6 i/o timeout）。
  # go-modules 是固定输出推导：其 impureEnvVars 里的 GOPROXY 会被 nix-daemon 环境
  # （未设置 GOPROXY）以空串覆盖 env 中显式指定的值，导致回退到默认 proxy.golang.org。
  # 因此需在 env 里指定国内镜像，同时把 GOPROXY 从 impureEnvVars 中移除。
  # 模块版本内容不变，故 vendorHash 无需改动。
  reasonix = llmPackages.reasonix.overrideAttrs (finalAttrs: previousAttrs: {
    passthru = previousAttrs.passthru // {
      overrideModAttrs = lib.composeExtensions previousAttrs.passthru.overrideModAttrs (
        finalModAttrs: previousModAttrs: {
          env = (previousModAttrs.env or {}) // {
            GOPROXY = "https://goproxy.cn,direct";
          };
          impureEnvVars = builtins.filter (v: v != "GOPROXY") (previousModAttrs.impureEnvVars or []);
        }
      );
    };
  });
in {
  home.packages = [
    # DeepSeek Harness (dsh) — 与 nix run github:numtide/llm-agents.nix#dsh 同一来源
    llmPackages.dsh
    reasonix
  ];

  # dsh web 开机自启（用户级 systemd 服务）
  # - 用户 chen 已启用 linger（见 users/chen/default.nix），因此用户实例在开机时即启动，
  #   无需登录；本服务挂在 default.target 下随之自动运行。
  # - ExecStart 与手动执行的 `dsh web` 等价（dsh 的 bin 包装脚本即 node bin.js web）。
  # - 应用配置后请勿再手动 `dsh web`（会与 3080 端口冲突）：
  #     systemctl --user status dsh-web     # 查看状态
  #     systemctl --user restart dsh-web    # 重启
  #     journalctl --user -u dsh-web -f     # 查看日志
  systemd.user.services.dsh-web = {
    Unit = {
      Description = "DeepSeek Harness (dsh web)";
    };
    Service = {
      Type = "simple";
      # 用包内绝对路径，避免依赖服务环境的 PATH
      ExecStart = "${llmPackages.dsh}/bin/dsh web";
      # 服务环境补上系统与用户 profile，供 dsh 内部调用的 git/pnpm 等命令使用。
      # 用 home.path（本代包的合并目录）而不是 home.profileDirectory：
      # standalone 模式下 profileDirectory 只是声明值（~/.nix-profile），
      # home.path 才是这一代真实存在的包目录，两种激活方式下都成立。
      Environment = "PATH=/run/current-system/sw/bin:${config.home.path}/bin";
      # 开机后网络可能尚未就绪/偶发失败，自动重试
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
