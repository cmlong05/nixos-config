#!/usr/bin/env bash
# 现在跑在哪个「系统变体」里？—— 只读诊断，不改任何东西，**不需要 root**。
#
# 背景见 os-disk/portable-chen/{machine_spe,boot-machine,auto-machine}.nix：
# 一块盘装了 3 个机器变体（specialisation）。开机菜单选哪条是 bootloader 定的、系统里
# 无法预知，所以事后判断「我到底落在哪」有三个独立证据（本脚本三个都查）：
#
#   A. 跑的是哪个变体    /run/current-system 指向哪个 store ↔ profile 里的变体符号链接
#                        注意：变体自己的 store 里 specialisation/ 是空的 ——
#                        变体符号链接只存在于「基础系统」那一代，所以基准目录要用
#                        /nix/var/nix/profiles/system/specialisation/。
#   B. 开机菜单选了哪条  EFI 变量 LoaderEntrySelected（systemd-boot 自己写的，最权威）
#   C. 是不是运行时切换  /run/booted-system（内核/initrd 真正从哪起）≠ /run/current-system
#                        就是 auto-machine 在开机后切过来的：配置换了，内核没换
#
# 用法：scripts/which-spec.sh
# 退出码：0 = 在正确的变体里；1 = 不在变体里 / 变体与本机指纹不符。
set -uo pipefail

self="${BASH_SOURCE[0]}"
dir="${self%/*}"
[ "$dir" = "$self" ] && dir="."
detect="$dir/detect-machine.sh"
keys="$dir/../machines/machine-keys.txt"

cur="$(readlink -f /run/current-system 2> /dev/null || true)"
booted="$(readlink -f /run/booted-system 2> /dev/null || true)"
profile="$(readlink -f /nix/var/nix/profiles/system 2> /dev/null || true)"
spe_dir="/nix/var/nix/profiles/system/specialisation"

# 读 EFI 变量：efivarfs 上是「4 字节属性 + UTF-16LE 值」。这些 Loader* 变量的值都是
# ASCII，UTF-16LE 里就是「字符, 00」交替 —— 所以取偶数位字节即可。
# 这么做绕开了 NUL：bash 的字符串存不住 NUL，直接 cat 一个 efivarfs 文件既会丢字节
# 又会往 stderr 打 warning。跟 scripts/set-default-entry.sh 的读法等价（那边只比较
# 是否等于目标，这里要把名字原样打出来，所以老老实实解码）。
efi_hex() { # $1 = 变量名（不带 GUID）→ 输出「属性之后的字节」的十六进制
  local f
  for f in "/sys/firmware/efi/efivars/$1-"*; do
    [ -e "$f" ] || return 0
    od -An -v -tx1 "$f" 2> /dev/null | tr -d ' \n' | tail -c +9
    return 0
  done
}

efi_str() { # $1 = 变量名 → ASCII 字符串（UTF-16LE 的偶数位字节），读到"字符 00 00"为止
  local hex out="" pair
  hex="$(efi_hex "$1")"
  while [ ${#hex} -ge 4 ]; do
    pair="${hex:0:2}"
    [ "$pair" = "00" ] && break                # 字符 00 之后的 00 = 收尾
    out="$out$(printf "\\x$pair")"
    hex="${hex:4}"                             # 每字符 2 字节
  done
  printf '%s' "$out"
}

efi_dec() { # $1 = 变量名 → 值是十进制字符串（LoaderTime* 系列，如 "22166567"）时转成整数
  local s v
  s="$(efi_str "$1")"
  case "$s" in
    '' | *[!0-9]*) return 0 ;;
  esac
  while [ -n "$s" ]; do                           # 逐位转，避免依赖 10# 之外的算术细节
    v=$(( ${v:-0} * 10 + ${s:0:1} ))
    s="${s:1}"
  done
  printf '%d' "$v"
}

# —— A. 现在跑的是哪个变体 ——
variant=""
if [ -d "$spe_dir" ]; then
  for child in "$spe_dir"/*; do
    [ -e "$child" ] || continue
    if [ "$(readlink -f "$child" 2> /dev/null || true)" = "$cur" ]; then
      variant="${child##*/}"
      break
    fi
  done
fi

if [ -n "$variant" ]; then
  running="变体 $variant"
elif [ "$cur" = "$profile" ]; then
  running="基础系统 base（救援/控制台入口：无机器硬件、无显卡驱动 → 没有桌面）"
else
  running="未知（$cur 既不是基础系统也不是本代任何变体）"
fi

# —— B. 本机应该是哪个变体 ——
expected="$(bash "$detect" --table "$keys" 2> /dev/null || true)"

# —— C. systemd-boot 实际启动的条目（最权威的「开机菜单选了哪条」）——
# 条目名形如 nixos-generation-86-specialisation-chen-desktop.conf：直接读出变体名。
selected="$(efi_str LoaderEntrySelected)"
default_entry="$(efi_str LoaderEntryDefault)"
# LoaderTime* 是 systemd-boot 的单调计时检查点，不是各自的耗时：
#   Init = 初始化完成，Menu = 进入菜单，Exec = 离开菜单、开始启动所选条目。
# 所以菜单实际停留时间是 Exec - Menu；直接打印 Menu 会得到自开机以来约十几秒的累计值。
menu_start_us="$(efi_dec LoaderTimeMenuUSec)"
menu_end_us="$(efi_dec LoaderTimeExecUSec)"
booted_variant=""
entry_spe="${selected#*specialisation-}"
if [ "$entry_spe" != "$selected" ]; then
  booted_variant="${entry_spe%.conf}"
fi

# 盘上那份 loader.conf：/boot 是 0700，非 root 读不到 —— 那不是错误，只说明要看就得 sudo
disk_default=""
if [ -r /boot/loader/loader.conf ]; then
  while IFS= read -r line; do
    case "$line" in
      default\ *) disk_default="${line#default }" ;;
    esac
  done < /boot/loader/loader.conf
  disk_default="${disk_default%% *}"
elif [ -d /boot ]; then
  disk_default="(读不到：/boot 是 0700 —— sudo grep '^default' /boot/loader/loader.conf)"
else
  disk_default="(没有 /boot)"
fi

# —— 报告 ——
printf '当前运行   : %s\n' "$running"
printf '             /run/current-system = %s\n' "$cur"
if [ "$cur" = "$booted" ]; then
  printf '             /run/booted-system  = 同一个 store（开机就落在这里，内核与配置匹配）\n'
else
  printf '             /run/booted-system  = %s\n' "$booted"
  printf '             ⚠ 两者不同：运行时被切换过（auto-machine），内核/initrd 仍是开机那个\n'
fi
printf '本机指纹   : %s\n' "${expected:-（认不出：scripts/detect-machine.sh --probes 看指纹，再往 machines/machine-keys.txt 加行）}"
printf '菜单默认   : NVRAM(LoaderEntryDefault) = %s\n' "${default_entry:-（读不到/没种过）}"
printf '             盘上(loader.conf)         = %s\n' "$disk_default"
printf '实际启动   : NVRAM(LoaderEntrySelected) = %s\n' "${selected:-（读不到）}"
if [ -n "$menu_start_us" ] && [ -n "$menu_end_us" ] &&
  [ "$menu_end_us" -ge "$menu_start_us" ] 2> /dev/null; then
  menu_us=$((menu_end_us - menu_start_us))
  printf '             菜单停留 = %s ms（LoaderTimeExecUSec - LoaderTimeMenuUSec）\n' \
    "$((menu_us / 1000))"
fi
if [ -n "$booted_variant" ] && [ -n "$variant" ] && [ "$booted_variant" != "$variant" ]; then
  printf '             ⚠ 菜单起的是 %s，现在是 %s → auto-machine 在本开机里切过一次\n' "$booted_variant" "$variant"
fi

# —— 结论 ——
status=0
if [ -z "$variant" ]; then
  printf '结论       : ⚠ 不在任何机器变体里 —— 没有显卡驱动、进不了桌面（菜单里手选变体条目）\n'
  status=1
elif [ -n "$expected" ] && [ "$variant" != "$expected" ]; then
  printf '结论       : ⚠ 跑的是 %s，本机指纹是 %s —— 重启，或 sudo systemctl restart auto-machine-specialisation\n' "$variant" "$expected"
  status=1
elif [ -n "$expected" ]; then
  printf '结论       : ✓ 正确：%s 跑在 %s 上\n' "$variant" "$expected"
else
  printf '结论       : 变体 %s 在跑，但认不出本机 → 无法判断对错（看上面指纹，往 machines/machine-keys.txt 加行）\n' "$variant"
fi
exit "$status"
