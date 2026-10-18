# LLM 相关工具（dsh 由 llm-agents 输入提供；codex 由 nixpkgs-unstable 提供）
{ config, pkgs, pkgs-unstable, inputs, ... }:

let
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = [
    llmPackages.dsh
    pkgs-unstable.codex
  ];

  # dsh web 开机自启（用户级 systemd 服务）
  systemd.user.services.dsh-web = {
    Unit = {
      Description = "DeepSeek Harness (dsh web)";
    };
    Service = {
      Type = "simple";
      # 用包内绝对路径，避免依赖服务环境的 PATH
      ExecStart = "${llmPackages.dsh}/bin/dsh web";
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
