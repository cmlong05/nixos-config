# NixOS 配置

单机 NixOS 配置仓库，使用 flakes + home-manager。主机名 `nixos`，用户 `chen`。

## 目录结构

```
nixos-config/
├── flake.nix                    # 入口：inputs + outputs
├── configuration.nix            # 模块入口：imports + stateVersion
├── hardware-configuration.nix   # 硬件扫描生成文件，勿改
├── modules/                     # 系统级模块（按领域拆分）
│   ├── boot.nix                 # systemd-boot + 内核钉版
│   ├── networking.nix           # 主机名 + NetworkManager
│   ├── bluetooth.nix            # 蓝牙
│   ├── nix.nix                  # 缓存源 / flakes / nh 清理 / allowUnfree
│   ├── locale.nix               # 时区 / locale / fcitx5 / 字体
│   ├── desktop.nix              # SDDM + Plasma 6 / Firefox / PipeWire / CUPS
│   ├── virtualisation.nix       # Podman
│   ├── gpu.nix                  # NVIDIA 驱动
│   ├── flatpak.nix              # Flatpak 及声明式应用
│   ├── packages.nix             # 系统级软件包
│   └── users.nix                # 用户账户定义
├── home/                        # home-manager 配置（用户 chen）
│   ├── home.nix                 # 入口
│   └── modules/
│       ├── shell.nix            # bash + direnv
│       ├── apps.nix             # 用户级应用包
│       └── llm.nix              # llm-agents 工具（dsh / reasonix）
```

## 常用命令

```bash
# 应用系统配置（推荐，含自动清理）
nh os switch

# 仅 home-manager
home-manager switch --flake .#chen

# 更新锁定输入
nix flake update

# 校验 flake（本仓库所有模块求值）
nix flake check
```

## 注意事项 / 踩坑记录

- **内核钉版 7.1**：nvidia-open 595.71.05 与内核 7.2 不兼容，等驱动支持后再改回
  `linuxPackages_latest`（见 `modules/boot.nix` 注释）。
- **缓存源**：USTC 镜像 2026-08 验证可用；SJTU 对新路径同步不及时（narinfo 已同步
  但 nar 文件缺失），如遇 HTTP/2 流中断报错可临时移除 SJTU 源。
- **hardware-configuration.nix** 由 `nixos-generate-config` 生成，改动会被覆盖。
- 仓库锁定的 nixpkgs 分支为 `nixos-26.05`，home-manager 为 `release-26.05`，
  两者需保持大版本一致。

## 依赖输入

| 输入 | 用途 |
|------|------|
| nixpkgs | 主包源（NJU 镜像，26.05） |
| nix-flatpak | flatpak 声明式安装模块 |
| home-manager | 用户环境管理 |
| llm-agents | dsh / reasonix 等 LLM 工具包 |
