# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# 本文件只是模块入口：按领域拆分的配置见 ./modules/，
# 硬件相关见 ./hardware-configuration.nix（生成文件，勿改），
# 用户级配置见 ./home/。
{ ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # 领域模块
      ./modules/boot.nix
      ./modules/networking.nix
      ./modules/bluetooth.nix
      ./modules/nix.nix
      ./modules/locale.nix
      ./modules/desktop.nix
      ./modules/virtualisation.nix
      ./modules/gpu.nix
      ./modules/flatpak.nix
      ./modules/packages.nix
      # 用户账户
      ./modules/users.nix
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
