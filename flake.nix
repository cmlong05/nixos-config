{
  description = "NixOS configuration (nixos: portable disk + specialisation / mubimuba: 员工机)";

  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
    # 供个别需要新版本的包使用（如 safeeyes 3.5），不整体升级系统
    nixpkgs-unstable.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs@{ nixpkgs, nixpkgs-unstable, nix-flatpak, llm-agents, home-manager, ... }:
    let
      system = "x86_64-linux";
      # unstable 的包集合：供个别需要新版本的包使用（如 safeeyes），
      # 与系统 26.05 隔离；NixOS 模块与 home-manager 模块都能拿到。
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # 每台主机都要叠加的 NixOS 模块：nix-flatpak 与 home-manager
      sharedModules = [
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
        }
      ];

      mkHost = hostDir:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            hostDir
          ] ++ sharedModules;
        };
    in
    {
      nixosConfigurations = {
        # 便携盘系统（AMD+NVIDIA 台式机 / Intel 笔电 共用，硬件差异走 specialisation）
        nixos = mkHost ./hosts/nixos/default.nix;
        # 员工机（hostname: mubimuba，同款硬件）
        mubimuba = mkHost ./hosts/mubimuba/default.nix;
      };
    };
}
