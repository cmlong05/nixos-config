# 便携盘的机器变体：每台机器 = 一个开机菜单条目（specialisation）
#
# inheritParentConfig 默认 true = 基础系统（盘 + 服务 + 用户）+ 这里的机器组合
# （machines/<机器>/default.nix：生成硬件 + 手写尾巴）。换机器 = 开机菜单选一下，零命令。
{ ... }:

{
  specialisation.chen-desktop.configuration.imports      = [ ../../machines/chen-desktop ];
  specialisation.chen-laptop-amd.configuration.imports   = [ ../../machines/chen-laptop-amd ];
  specialisation.chen-laptop-intel.configuration.imports = [ ../../machines/chen-laptop-intel ];
}
