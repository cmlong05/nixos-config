{ config, pkgs, inputs, ... }:

let
  llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  users.users."chen" = {
    isNormalUser = true;
    description = "chen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.fcitx5-configtool
      vscodium
      wechat
    ] ++ (with llmPackages; [

    ]);
  };
}