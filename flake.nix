{
  description = "NixOS configuration (portable-chen: 便携盘 + specialisation / msi-wd)";

  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-26.05&shallow=1";
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
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # 系统侧模块：只叠加 nix-flatpak。
      # home-manager 不再作为 NixOS 模块挂载
      sharedModules = [
        nix-flatpak.nixosModules.nix-flatpak
      ];

      mkHost = hostDir:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            hostDir
          ] ++ sharedModules;
        };

      # 用户侧：standalone home-manager 配置，由用户自己激活

      # 所有用户共用的用户级基线在 users/modules/（apps.nix、shell.nix）
      mkHome = { user, modules }: home-manager.lib.homeManagerConfiguration {
        # standalone 没有 useGlobalPkgs，必须自己构造 pkgs；与系统保持一致：
        # 镜像 shared/nix.nix 的 nixpkgs.config.allowUnfree。
        # nixpkgs 与 home-manager 同源（flake.lock 里 home-manager.inputs.nixpkgs
        # follows = "nixpkgs"），所以和系统侧拿到的是同一批 store path。
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit inputs pkgs-unstable; };
        modules = modules ++ [
          {
            home.username = user;
            home.homeDirectory = "/home/${user}";
            # 各用户共用的首次安装版本（跟 home-manager 的 release-26.05 对应）；
            # 正常永不改，升级只动 flake.lock。
            home.stateVersion = "26.05";
          }
        ];
      };

      chenHome = mkHome {
        user = "chen";
        modules = [ ./users/chen/home.nix ];
      };
      bumoobyHome = mkHome {
        user = "bumooby";
        modules = [ ./users/bumooby/home.nix ];
      };
      mubimubaHome = mkHome {
        user = "mubimuba";
        modules = [ ./users/mubimuba/home.nix ];
      };
    in
    {
      nixosConfigurations = {
        # 便携盘系统（AMD+NVIDIA 台式机 / Intel 笔电 共用，硬件差异走 specialisation）
        portable-chen = mkHost ./os-disk/portable-chen/default.nix;
        # 员工机（hostname: msi-wd，同款硬件）
        msi-wd = mkHost ./os-disk/msi-wd/default.nix;
      };

      # 每人两个名字指向同一份求值结果：
      # `nh home switch` 缺省先找 `<user>@<hostname>`、再退到 `<user>`，
      # 两个都提供就不必记 hostname；同一个值不会重复构建。
      homeConfigurations = {
        "chen@portable-chen" = chenHome;
        chen = chenHome;
        "bumooby@msi-wd" = bumoobyHome;
        bumooby = bumoobyHome;
        "mubimuba@msi-wd" = mubimubaHome;
        mubimuba = mubimubaHome;
      };
    };
}
