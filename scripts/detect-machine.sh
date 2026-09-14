#!/usr/bin/env bash
# 认机器：按本机硬件指纹在「指纹表」里找机器名（= specialisation 名）并打印。
# 认不出来就什么都不打印（退出码 0）—— 兜底行为由调用方决定。
#
# 只用 bash 内建 + /sys + /proc（不依赖 PATH 里的 cat/sed），因为它在两个
# 「环境很干净」的地方被调用：开机早期的 systemd 服务、bootloader 安装脚本。
#
# 用法：
#   scripts/detect-machine.sh                  默认指纹表 = 仓库内 machines/machine-keys.txt
#   scripts/detect-machine.sh --table PATH     指定指纹表（Nix 侧从 store 里传进来）
#   scripts/detect-machine.sh --probes         只打印本机指纹，便于往指纹表里加行
set -uo pipefail

self="${BASH_SOURCE[0]}"
dir="${self%/*}"
[ "$dir" = "$self" ] && dir="."
table="$dir/../machines/machine-keys.txt"

probes_only=""
while [ $# -gt 0 ]; do
  case "$1" in
    --table) table="${2:-}"; shift 2 ;;
    --probes) probes_only=1; shift ;;
    *) echo "detect-machine: 未知参数 $1" >&2; exit 2 ;;
  esac
done

# —— 本机指纹（DMI 整机 / 主板 / CPU 型号）——
probes=""
for f in /sys/class/dmi/id/product_name /sys/class/dmi/id/board_name; do
  line=""
  IFS= read -r line < "$f" 2>/dev/null || true   # 末尾无换行时 read 返回非 0，但值已读进 line
  [ -n "$line" ] && probes="$probes$line"$'\n'
done
while IFS= read -r line; do
  case "$line" in
    "model name"*)
      probes="$probes${line#*: }"$'\n'
      break
      ;;
  esac
done < /proc/cpuinfo

if [ -n "$probes_only" ]; then
  printf '%s' "$probes"
  exit 0
fi

if [ ! -r "$table" ]; then
  echo "detect-machine: 读不到指纹表 ${table}" >&2
  exit 1
fi

# —— 子串匹配：指纹表里第一行命中的机器胜出 ——
while IFS='|' read -r key machine; do
  case "$key" in ''|'#'*) continue ;; esac
  [ -n "$machine" ] || continue
  case "$probes" in
    *"$key"*) printf '%s\n' "$machine"; exit 0 ;;
  esac
done < "$table"

exit 0
