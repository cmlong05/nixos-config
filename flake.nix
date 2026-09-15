{
  description = "NixOS configuration (portable-chen: 便携盘 + specialisation / msi-wd: 员工机)";

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
      # 与系统 26.05 隔离；系统模块与 home-manager 模块都能拿到。
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # 系统侧模块：只叠加 nix-flatpak。
      #
      # ⚠️ home-manager 故意**不再**作为 NixOS 模块挂载：家目录由各用户
      # 自己 `nh home switch` 激活（见下面 homeConfigurations），因此
      #  - 不存在"系统 switch 把用户的 home 改回去"的第二个激活者；
      #  - 用户级改动不需要 sudo、不触发系统 switch（也就不会把运行中的
      #    系统打回 specialisation 基础系统）；
      #  - 代价：系统不再替用户激活家目录，装机后每个用户要自己跑一次。
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
      # （`nh home switch` / `home-manager switch --flake /etc/nixos#<name>`）。
      #
      # 所有用户共用的用户级基线在 users/modules/（apps.nix、shell.nix）——
      # 改一处、各人在自己家目录里生效；要"保证所有用户都有、用户改不掉"的
      # 东西请放系统级（shared/packages.nix）。
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
          # standalone 模式适配（PATH 等），详见该文件注释
          ./users/modules/standalone.nix
          {
            home.username = user;
            home.homeDirectory = "/home/${user}";
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
