# 用户级 Flatpak 的公共底座

{ pkgs, inputs, ... }:

let
  flathub = import ../../lib/flatpak-mirror.nix { inherit pkgs; };
in
{
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = flathub.primaryMirror;
        gpg-import = "${flathub.flathubGpg}";
      }
    ];
  };
}
