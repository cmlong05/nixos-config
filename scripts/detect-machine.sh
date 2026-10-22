#!/usr/bin/env bash
# 认机器：按本机物理网卡 MAC 在机器表里精确查找 specialisation 名并打印。
# 认不出来就什么都不打印（退出码 0）—— 兜底行为由调用方决定。
#
# 只有 mac 参与认机器；model / board / cpu 只用于展示和排障。
# 一个 [机器名] 段可以写多个 mac（例如有线和无线网卡），任意一个命中即可。
#
# 机器表格式：
#   [chen-desktop]
#   model = 展示用整机型号
#   board = 展示用主板型号
#   cpu = 展示用 CPU 型号
#   mac = 3c:7c:3f:50:d8:3f
# 空行和以 # 开头的行忽略；其他不认识的字段会作为格式错误退出。
#
# 退出码：
#   0 = 找到机器，或正常执行但没有匹配（后者 stdout 为空）
#   1 = 表格式错误、读不到表、没读到 MAC，或多个机器同时命中
#   2 = 命令行参数错误
#
# 本脚本只读 /sys、/proc 和机器表，不会修改系统或网络配置。
#
# 用法：
#   scripts/detect-machine.sh                  默认读取 machines/machine-fingerprints.conf
#   scripts/detect-machine.sh --probes         打印展示特征和本机物理网卡 MAC
#   scripts/detect-machine.sh --describe NAME  展示该机器配置的特征和 MAC
#                                              （which-spec.sh 用来展示本机型号/主板/CPU）
#   scripts/detect-machine.sh --table PATH     指定机器表。Nix 会把脚本和表复制成两个
#                                              独立 store 路径，默认相对路径在那里不成立。
set -uo pipefail
# 这里故意不使用 set -e：很多 read 在文件末尾没有换行时会返回非 0，
# 但值已经读入变量；脚本对每个失败点显式判断，避免误吞有效硬件信息。

# —— 路径、运行模式和参数 ——
self="${BASH_SOURCE[0]}"
dir="${self%/*}"
[ "$dir" = "$self" ] && dir="."
# 直接从仓库运行时，机器表在脚本上一级目录；Nix 运行时由 --table 覆盖。
table="$dir/../machines/machine-fingerprints.conf"
# 默认 detector 的根目录。--sysfs-root 只是为离线测试保留的注入点。
sysfs_root="/sys"
mode="detect"
describe_name=""

# 参数顺序不限，后面的同名参数会覆盖前面的值。
while [ $# -gt 0 ]; do
  case "$1" in
    --table)
      table="${2:-}"
      shift 2
      ;;
    --probes)
      mode="probes"
      shift
      ;;
    --describe)
      mode="describe"
      describe_name="${2:-}"
      shift 2
      ;;
    --sysfs-root)
      # 仅供离线测试；正常调用不需要传。
      sysfs_root="${2:-}"
      shift 2
      ;;
    *)
      echo "detect-machine: 未知参数 $1" >&2
      exit 2
      ;;
  esac
done

# 去掉 sysfs/DMI 值首尾的空白和 CR，保留中间内容。
# 这样同一硬件即使内核输出带行尾空格，也不会制造不同身份。
trim_value() {
  local value="$1"
  value="${value%$'\r'}"
  while [[ "$value" == [[:space:]]* ]]; do
    value="${value#?}"
  done
  while [[ "$value" == *[[:space:]] ]]; do
    value="${value%?}"
  done
  printf '%s' "$value"
}

# 读取单行 sysfs/DMI 文件，结果通过全局 probe_value 返回。
# 不使用 cat，是为了让开机早期和干净 PATH 环境也不依赖外部命令。
read_probe() {
  local file="$1"
  local value=""
  probe_value=""
  [ -r "$file" ] || return 1
  IFS= read -r value < "$file" 2> /dev/null || true
  value="$(trim_value "$value")"
  [ -n "$value" ] || return 1
  probe_value="$value"
}

# 只接受标准的 6 字节冒号分隔 MAC，并转小写后比较。
# 全零和全 FF 是无效/广播占位值，不能作为机器身份。
valid_mac() {
  case "${1,,}" in
    [0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f])
      ;;
    *)
      return 1
      ;;
  esac
  case "${1,,}" in
    00:00:00:00:00:00 | ff:ff:ff:ff:ff:ff)
      return 1
      ;;
  esac
  return 0
}

# machine_spe.nix 中的 specialisation 名。限制字符集，避免段头注入
# 或生成后续无法对应的 profile 名。
valid_machine_name() {
  case "$1" in
    '' | *[!A-Za-z0-9._-]*)
      return 1
      ;;
  esac
  return 0
}

# —— 本机展示特征和物理网卡 MAC ——
probe_model=""
probe_board=""
probe_cpu=""
# 多个 MAC 用换行分隔，既方便逐行输出，也避免依赖关联数组。
probe_macs=""
# mac_details 只服务于 --probes 的人读输出，不参与匹配。
mac_details=""

# DMI 型号可读性较好，但可能被多台机器共用，因此只作为展示信息。
if read_probe "$sysfs_root/class/dmi/id/product_name"; then
  probe_model="$probe_value"
fi
if read_probe "$sysfs_root/class/dmi/id/board_name"; then
  probe_board="$probe_value"
fi
# CPU 型号来自 /proc/cpuinfo，同样只用于 --probes / --describe 展示。
while IFS= read -r line; do
  case "$line" in
    "model name"*)
      probe_cpu="$(trim_value "${line#*:}")"
      break
      ;;
  esac
done < /proc/cpuinfo

# 遍历每个网络接口的 sysfs 地址。只保留物理以太网/Wi-Fi 设备：
#   - /device 存在：排除 bridge、veth、tun 等虚拟接口；
#   - type=1：以太网接口类型（Wi-Fi 也属于该类）；
#   - addr_assign_type=0/3/空：硬件或固件设置的地址，而非临时随机地址。
for address_file in "$sysfs_root"/class/net/*/address; do
  [ -r "$address_file" ] || continue
  netdev="${address_file%/address}"
  [ -e "$netdev/device" ] || continue   # 排除 bridge、veth、tun 等虚拟接口

  interface_type=""
  addr_assign_type=""
  IFS= read -r interface_type < "$netdev/type" 2> /dev/null || true
  IFS= read -r addr_assign_type < "$netdev/addr_assign_type" 2> /dev/null || true
  [ "$interface_type" = "1" ] || continue

  # Linux addr_assign_type:
  #   0 = 硬件永久地址；3 = 固件/驱动设置的物理设备地址；
  #   1/2 等可能是软件随机或借用地址，不能作为跨次启动的身份。
  case "$addr_assign_type" in
    0 | 3 | '') ;;
    *) continue ;;
  esac

  IFS= read -r mac < "$address_file" 2> /dev/null || true
  mac="${mac%$'\r'}"
  valid_mac "$mac" || continue
  # 配置文件中统一用小写，避免大小写差异造成同一网卡匹配失败。
  mac="${mac,,}"
  interface="${netdev##*/}"
  # 某些驱动会给多个接口报告同一 MAC；这里去重，避免 --probes 重复输出。
  case $'\n'"$probe_macs"$'\n' in
    *$'\n'"$mac"$'\n'*) ;;
    *)
      probe_macs="${probe_macs:+$probe_macs$'\n'}$mac"
      mac_details="${mac_details:+$mac_details$'\n'}$interface (addr_assign_type=${addr_assign_type:-未知})"
      ;;
  esac
done

# --probes 不读机器表，只打印“可以复制进表”的展示字段和 MAC。
# 注意这里会输出原始 MAC；这不是安全凭据，也不应被当作密钥使用。
if [ "$mode" = "probes" ]; then
  printf '%s\n' '# 展示特征：只用于人工核对，不参与认机器。'
  [ -n "$probe_model" ] && printf 'model = %s\n' "$probe_model"
  [ -n "$probe_board" ] && printf 'board = %s\n' "$probe_board"
  [ -n "$probe_cpu" ] && printf 'cpu = %s\n' "$probe_cpu"

  printf '%s\n' '' '# 识别 MAC：复制到对应 [机器名] 段。'
  if [ -n "$probe_macs" ]; then
    while IFS= read -r mac; do
      printf 'mac = %s\n' "$mac"
    done <<< "$probe_macs"
    while IFS= read -r detail; do
      printf '# 上面的 MAC 之一：%s\n' "$detail"
    done <<< "$mac_details"
  else
    echo "detect-machine: 没有读到可用的物理网卡 MAC" >&2
    exit 1
  fi
  exit 0
fi

if [ ! -r "$table" ]; then
  echo "detect-machine: 读不到机器表 ${table}" >&2
  exit 1
fi

# —— --describe：解析机器表并打印请求段，供 which-spec 展示 ——
# 格式与正式匹配相同；这里只收集展示字段，不比较本机 MAC。
if [ "$mode" = "describe" ]; then
  if [ -z "$describe_name" ]; then
    echo "detect-machine: --describe 后缺少机器名" >&2
    exit 2
  fi

  current=""
  describe_found=""
  model=""
  board=""
  cpu=""
  macs=""
  line_no=0

  # 读到下一个 [段] 或 EOF 时，打印上一段；因此无须把整张表存入数组。
  finish_description() {
    local first_mac=1
    [ "$current" = "$describe_name" ] || return 0
    describe_found=1
    printf '整机型号   : %s\n' "${model:-（未记录）}"
    printf '主板型号   : %s\n' "${board:-（未记录）}"
    printf 'CPU        : %s\n' "${cpu:-（未记录）}"
    if [ -z "$macs" ]; then
      printf '识别 MAC   : （未配置：运行时不会认出这台机器）\n'
      return 0
    fi
    while IFS= read -r machine_mac; do
      if [ "$first_mac" = 1 ]; then
        printf '识别 MAC   : %s\n' "$machine_mac"
        first_mac=0
      else
        printf '             %s\n' "$machine_mac"
      fi
    done <<< "$macs"
  }

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    case "$line" in
      '' | '#'*) continue ;;
      '['*']')
        # 先结束上一段，再重置本段收集到的展示字段。
        finish_description
        current="${line#\[}"
        current="${current%\]}"
        if ! valid_machine_name "$current"; then
          echo "detect-machine: ${table}:${line_no}: 机器名格式错误" >&2
          exit 1
        fi
        model=""
        board=""
        cpu=""
        macs=""
        ;;
      'model = '*)
        model="${line#model = }"
        ;;
      'board = '*)
        board="${line#board = }"
        ;;
      'cpu = '*)
        cpu="${line#cpu = }"
        ;;
      'mac = '*)
        # --describe 也校验格式；坏配置应尽早暴露，而不是等开机切换时才发现。
        value="${line#mac = }"
        valid_mac "$value" || {
          echo "detect-machine: ${table}:${line_no}: MAC 格式错误：${value}" >&2
          exit 1
        }
        macs="${macs:+$macs$'\n'}${value,,}"
        ;;
      *)
        echo "detect-machine: ${table}:${line_no}: 无法识别的行：${line}" >&2
        exit 1
        ;;
    esac
  done < "$table"
  finish_description

  if [ -z "$describe_found" ]; then
    echo "detect-machine: 机器表里没有 [${describe_name}]" >&2
    exit 1
  fi
  exit 0
fi

# —— 精确匹配：某个 mac 命中，就选中该段；多个机器冲突时不猜 ——
# current     = 当前 [机器名]
# mac_hit     = 当前段是否命中任一 MAC
# matches     = 所有命中的机器名，用空格分隔
current=""
mac_hit=""
matches=""
line_no=0

# 一段可能写多个 MAC，因此在一段结束时只记录一次机器名。
# 用空格分隔是安全的：valid_machine_name 已禁止空格。
finish_machine() {
  [ -n "$mac_hit" ] || return 0
  case " $matches " in
    *" $mac_hit "*) ;;
    *) matches="${matches:+$matches }$mac_hit" ;;
  esac
  mac_hit=""
}

while IFS= read -r line || [ -n "$line" ]; do
  line_no=$((line_no + 1))
  case "$line" in
    '' | '#'*) continue ;;
    '['*']')
      # 进入新段前提交上一段的匹配结果。
      finish_machine
      current="${line#\[}"
      current="${current%\]}"
      if ! valid_machine_name "$current"; then
        echo "detect-machine: ${table}:${line_no}: 机器名格式错误" >&2
        exit 1
      fi
      ;;
    'model = '* | 'board = '* | 'cpu = '*)
      # 展示特征不参与匹配；即使型号/CPU 完全相同，也不能据此选变体。
      ;;
    'mac = '*)
      if [ -z "$current" ]; then
        echo "detect-machine: ${table}:${line_no}: mac 前缺少 [机器名]" >&2
        exit 1
      fi
      value="${line#mac = }"
      valid_mac "$value" || {
        echo "detect-machine: ${table}:${line_no}: MAC 格式错误：${value}" >&2
        exit 1
      }
      # 本机 MAC 也已在收集阶段统一为小写，因此这里是大小写无关的精确匹配。
      case $'\n'"$probe_macs"$'\n' in
        *$'\n'"${value,,}"$'\n'*) mac_hit="$current" ;;
      esac
      ;;
    *)
      echo "detect-machine: ${table}:${line_no}: 无法识别的行：${line}" >&2
      exit 1
      ;;
  esac
done < "$table"
finish_machine

# 没有命中时保持旧的“静默退出”契约；命中多个机器时宁可失败也不猜测。
case "$matches" in
  '') exit 0 ;;
  *' '*)
    echo "detect-machine: 本机 MAC 同时匹配多台机器：${matches}；拒绝猜测" >&2
    exit 1
    ;;
  *)
    printf '%s\n' "$matches"
    exit 0
    ;;
esac
