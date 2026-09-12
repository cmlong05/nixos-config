# Shell 与 direnv
{ config, pkgs, ... }:

{
  # direnv + nix-direnv：进项目目录自动加载 devShell
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # bash：让 direnv 的 shell hook 注入到 ~/.bashrc（必须启用，否则 direnv allow 不生效）
  programs.bash = {
    enable = true;
  };
}
