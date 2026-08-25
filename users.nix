# Define a user account. Don't forget to set a password with ‘passwd’.

{ config, pkgs, inputs, ... }:

let
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  users.users."chen" = {
    isNormalUser = true;
    description = "chen";
    linger = true;  # Quadlet 用户容器服务开机自启
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      chromium
      kdePackages.kate
      kdePackages.fcitx5-configtool
      vscodium
      wechat-uos # 微信（UOS 商店版 4.x，替代原 AppImage 版 wechat）
      karere # whatsapp
    ] ++ (with llmPackages; [
        reasonix
    ]);
  };
}
