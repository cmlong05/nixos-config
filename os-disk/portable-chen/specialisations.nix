# 便携盘的机器变体：每台机器 = 一个开机菜单条目（specialisation）
#
# inheritParentConfig 默认 true = 基础系统 + 这里的机器组件组合。
# 换机器 = 开机菜单选一下，零命令。
{ ... }:

{
  specialisation.chen-desktop.configuration.imports      = [ ../../machines/chen-desktop.nix ];
  specialisation.chen-laptop-amd.configuration.imports   = [ ../../machines/chen-laptop-amd.nix ];
  specialisation.chen-laptop-intel.configuration.imports = [ ../../machines/chen-laptop-intel.nix ];
}
