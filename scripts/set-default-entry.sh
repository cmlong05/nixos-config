#!/usr/bin/env bash
# 把 $BOOT/loader/loader.conf 的 default 指向「本机变体」的启动条目。
#
# 谁在用（两个调用点，同一份实现）：
#   - os-disk/portable-chen/boot-machine.nix  部署期：nh os switch 装完 bootloader 后（B）
#   - os-disk/portable-chen/auto-machine.nix  开机后：换到没部署过的机器时（A）
# 这样"插到新机器上第一次开机"就能自动把菜单默认条目认对，下一次开机零操作。
#
# 约定：**永不失败**（调用方一个是 set -euo pipefail 的 bootloader 安装脚本，一个是 systemd
# unit）。出错只打日志 + exit 0。幂等：已经是目标条目就什么都不写。
#
# 只用 bash 内建（不用 sed/ls/sort），所以不依赖 PATH —— 安装脚本里 PATH 不可靠。
#
# 用法：set-default-entry.sh --machine <变体名> [--boot <$BOOT 挂载点>]
#   $BOOT 默认 /boot（条目在 <$BOOT>/loader/entries/，配置在 <$BOOT>/loader/loader.conf）
set -uo pipefail

machine=""
boot="/boot"

while [ $# -gt 0 ]; do
  case "$1" in
    --machine)
      machine="${2:-}"
      shift 2
      ;;
    --boot)
      boot="${2:-}"
      shift 2
      ;;
    *)
      echo "set-default-entry: 忽略未知参数 $1" >&2
      shift
      ;;
  esac
done

if [ -z "$machine" ]; then
  echo "set-default-entry: 没给 --machine，什么都不做" >&2
  exit 0
fi

entries="$boot/loader/entries"
loader="$boot/loader/loader.conf"

# —— 1) 找这台机器「代号最大」的变体条目（= 最近一次构建出来的那代）——
best=""
best_gen=-1
for f in "$entries"/*-specialisation-"$machine".conf; do
  [ -e "$f" ] || continue
  name="${f##*/}"
  name="${name%.conf}"
  rest="${name#*-generation-}"
  gen="${rest%%-*}"
  case "$gen" in
    '' | *[!0-9]*) continue ;;
  esac
  if [ "$gen" -gt "$best_gen" ]; then
    best_gen="$gen"
    best="$name.conf"
  fi
done

if [ -z "$best" ]; then
  echo "set-default-entry: 没找到 $machine 的启动条目（$entries），不动 loader.conf" >&2
  exit 0
fi

if [ ! -f "$loader" ]; then
  echo "set-default-entry: 读不到 $loader，不动" >&2
  exit 0
fi

# —— 2) 幂等：读现有 default ——
current=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "default "*) current="${line#default }" ;;
  esac
done < "$loader"

if [ "$current" = "$best" ]; then
  echo "set-default-entry: 默认条目已经是 $best，无需改"
  exit 0
fi

# —— 3) 原样重写，只换 default 那一行（同目录 rename，跟 NixOS builder 一个套路）——
tmp="$loader.tmp.$$"
if ! : > "$tmp"; then
  echo "set-default-entry: 写不了 $tmp（$boot 只读？），默认条目保持 $current" >&2
  exit 0
fi

replaced=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "default "*)
      printf 'default %s\n' "$best" >> "$tmp"
      replaced=1
      ;;
    *) printf '%s\n' "$line" >> "$tmp" ;;
  esac
done < "$loader"

# loader.conf 里原本没有 default 行 → 补一行
[ -n "$replaced" ] || printf 'default %s\n' "$best" >> "$tmp"

if mv "$tmp" "$loader"; then
  echo "set-default-entry: 默认启动条目 $current → $best（本机 = $machine）"
else
  rm -f "$tmp"
  echo "set-default-entry: 改写 $loader 失败，默认条目保持 $current" >&2
fi

exit 0
