#!/usr/bin/env bash
# 把「本机变体」写成开机菜单的默认条目 —— 两个目的地，同一份实现：
#   1) 本机 NVRAM：EFI 变量 LoaderEntryDefault（主记忆）。systemd-boot 优先用它、覆盖
#      loader.conf（loader.conf(5)：default 可以在菜单里改，改了就以 EFI 变量存下来，
#      "overriding this option"）。
#   2) 盘上：$BOOT/loader/loader.conf 的 default（兜底）。NixOS 的 builder 每次 rebuild
#      都会把它重写成**基础系统**条目，所以我们每次部署/开机都补写一次。
#
# 为什么要写两个：**盘是移动的，机器是固定的**。
#   - loader.conf 跟盘走 → "上次是在别的机器上 rebuild 的"会把盘上那份改到别的机器；
#     换机器后的第一次开机必然预选错（菜单在任何系统代码之前就定了，认不出机器）。
#   - EFI 变量在主板 NVRAM 上、跟机器走 → 每台机器各自记住自己的变体：第一次在那台
#     机器上开过机之后，来回换机器都不用再手选，rebuild 也覆盖不到它。
# 变量是主记忆，盘上那份是「固件不给写变量 / NVRAM 被清」时的兜底，两者互为保险。
#
# 谁在用（两个调用点，同一份实现）：
#   - os-disk/portable-chen/boot-machine.nix  部署期：nh os switch 装完 bootloader 后（B）
#   - os-disk/portable-chen/auto-machine.nix  开机后：换到没部署过的机器时（A）
#
# 约定：**永不失败**（调用方一个是 set -euo pipefail 的 bootloader 安装脚本，一个是 systemd
# unit）。出错只打日志 + exit 0 —— 两个目的地任一个成功就算成功。幂等：已经是目标条目就
# 什么都不写（EFI 变量也先读后写，不白写闪存）。
#
# 不依赖 PATH：找条目、改 loader.conf、读 efivarfs 全用 bash 内建（不用 sed/ls/sort/cat）——
# 安装脚本里 PATH 不可靠。读 EFI 变量利用「bash 会丢掉 NUL」：efivarfs 上的文件是 4 字节
# 属性 + UTF-16LE 的值，于是只剩属性字节（如 0x06）粘在开头，剥掉即可。
#
# 用法：set-default-entry.sh --machine <变体名> [--boot <$BOOT 挂载点>] [--efi] [--bootctl <路径>]
#   $BOOT 默认 /boot（条目在 <$BOOT>/loader/entries/，配置在 <$BOOT>/loader/loader.conf）
#   --efi     同时写本机 EFI 变量 LoaderEntryDefault（要 root）
#   --bootctl 指定 bootctl 可执行文件（默认从 PATH 找；安装脚本里传绝对路径）
set -uo pipefail

machine=""
boot="/boot"
efi=""
bootctl="bootctl"

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
    --efi)
      efi=1
      shift
      ;;
    --bootctl)
      bootctl="${2:-}"
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
# efivarfs 上的固定文件名：GUID 4a67b082-... 就是 systemd 的 loader 命名空间
efi_file="/sys/firmware/efi/efivars/LoaderEntryDefault-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f"

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
  echo "set-default-entry: 没找到 $machine 的启动条目（$entries），两个目的地都不动" >&2
  exit 0
fi

# —— 2) 盘上那份：$BOOT/loader/loader.conf ——
# 读不到就只跳过这一半（EFI 变量那半照旧要写），所以这里**不** exit。
if [ ! -f "$loader" ]; then
  echo "set-default-entry: 读不到 $loader，跳过盘上那份" >&2
else
  current=""
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "default "*) current="${line#default }" ;;
    esac
  done < "$loader"

  if [ "$current" = "$best" ]; then
    echo "set-default-entry: 盘上默认条目已经是 $best，无需改"
  else
    # 原样重写，只换 default 那一行（同目录 rename，跟 NixOS builder 一个套路）
    tmp="$loader.tmp.$$"
    if ! : > "$tmp"; then
      echo "set-default-entry: 写不了 $tmp（$boot 只读？），盘上默认条目保持 $current" >&2
    else
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
        echo "set-default-entry: 盘上默认条目 $current → $best（本机 = $machine）"
      else
        rm -f "$tmp"
        echo "set-default-entry: 改写 $loader 失败，盘上默认条目保持 $current" >&2
      fi
    fi
  fi
fi

# —— 3) 本机 NVRAM：EFI 变量 LoaderEntryDefault（优先级高于 loader.conf）——
if [ -n "$efi" ]; then
  current_efi=""
  if [ -r "$efi_file" ]; then
    # 前 4 字节是属性、后面是 UTF-16LE；bash 丢 NUL 后只剩属性字节粘在开头，剥掉第一个
    # 'n' 之前的前缀即可。变量不存在（第一次到这台机器）时保持空串。
    IFS= read -r current_efi < "$efi_file" 2> /dev/null || true
    current_efi="${current_efi#"${current_efi%%n*}"}"
  fi

  if [ "$current_efi" = "$best" ]; then
    echo "set-default-entry: EFI 变量已经是 $best，无需改"
  elif err="$("$bootctl" set-default "$best" 2>&1)"; then
    echo "set-default-entry: EFI 变量 ${current_efi:-（未设置）} → $best（本机 = $machine）"
  else
    echo "set-default-entry: 写 EFI 变量失败（固件不给写 / efivarfs 只读？）：${err:-无输出}" >&2
    echo "set-default-entry: 本机仍靠盘上的 loader.conf 兜底" >&2
  fi
fi

exit 0
