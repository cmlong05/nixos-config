# standalone home-manager 模式（非 NixOS 模块）的共享适配。
# 由 flake.nix 的 mkHome 自动注入到每个 homeConfigurations，不需要各人手动 import。
#
# 为什么需要这个文件：
#   NixOS 的 PATH（/etc/set-environment）里只有两个用户相关的目录
#     - $HOME/.nix-profile/bin
#     - /etc/profiles/per-user/$USER/bin        （那是 home-manager.useUserPackages 的产物）
#   而 standalone home-manager 把这一代装到
#     - ~/.local/state/nix/profiles/home-manager          （用户态 profile 目录已存在时）
#     - /nix/var/nix/profiles/per-user/$USER/home-manager （否则）
#   两处都不在 PATH 里 —— 不处理的话，`nh home switch` 装的应用敲不出来
#   （.desktop 文件仍能用，因为 Exec 是 store 绝对路径）。
#
# 做法：把 $HOME/.nix-profile 指向本代的 home-path（home.packages 合并出来的目录）。
#   - NixOS 原有的 PATH 条目 $HOME/.nix-profile/bin 立刻生效，登录 shell、
#     图形会话、systemd 用户服务等一切继承会话 PATH 的消费者都覆盖到；
#   - $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh 也在 home-path 里，
#     所以 home-manager 手册里那句 `. ~/.nix-profile/etc/profile.d/hm-session-vars.sh` 同样成立；
#   - 不写死 XDG_STATE_HOME：两个候选位置里谁存在用谁（与 home-manager 自身的
#     profile 选择逻辑一致）。
{ config, lib, ... }:
{
  home.activation.linkNixProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for profile in \
      "${config.xdg.stateHome}/nix/profiles/home-manager" \
      "/nix/var/nix/profiles/per-user/$(id -un)/home-manager"
    do
      if [[ -e "$profile/home-path" ]]; then
        run ln -sfn "$profile/home-path" "$HOME/.nix-profile"
        break
      fi
    done
  '';
}
