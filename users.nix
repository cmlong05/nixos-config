# Define a user account. Don't forget to set a password with ‘passwd’.

{ config, pkgs, inputs, ... }:

let
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  users.users."chen" = {
    isNormalUser = true;
    description = "chen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      chromium
      kdePackages.kate
      kdePackages.fcitx5-configtool
      vscodium
      wechat
      karere # whatsapp
    ] ++ (with llmPackages; [
        reasonix
    ]);
  };
}
