# LLM 相关工具（由 llm-agents 输入提供）
{ config, pkgs, inputs, ... }:

let
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = [
    # DeepSeek Harness (dsh) — 与 nix run github:numtide/llm-agents.nix#dsh 同一来源
    llmPackages.dsh
    llmPackages.reasonix
  ];

  # dsh web 开机自启（用户级 systemd 服务）
  # - 用户 chen 已启用 linger（见 modules/users.nix），因此用户实例在开机时即启动，
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
      # 服务环境补上系统与用户 profile，供 dsh 内部调用的 git/pnpm 等命令使用
      Environment = "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/chen/bin";
      # 开机后网络可能尚未就绪/偶发失败，自动重试
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
