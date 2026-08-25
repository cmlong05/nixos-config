{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs@{ nixpkgs, nix-flatpak, llm-agents, home-manager, ... }:
    let
      system = "x86_64-linux";
      wechatOverlay = import ./overlays/wechat.nix;
    in
    {
      # 包覆盖：wechat 下载源修复（见 overlays/wechat.nix 顶部注释）
      overlays.wechat = wechatOverlay;

      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            nix-flatpak.nixosModules.nix-flatpak
            home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = [ wechatOverlay ];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.chen = ./home/home.nix;
            }
          ];
        };
      };
    };
}
