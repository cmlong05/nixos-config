#!/usr/bin/env bash
# Add the detected machine specialisation to a local `nh os switch`.
#
# Usage: nh-local-wrapper.sh <real-nh> <detector> <fingerprints> [NH ARGS...]
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "nh-local-wrapper: expected real nh, detector, and fingerprint paths" >&2
  exit 2
fi

real_nh="$1"
detect="$2"
fingerprints="$3"
shift 3

args=("$@")
if [ "${args[0]:-}" = "os" ] && [ "${args[1]:-}" = "switch" ]; then
  explicit_target=0
  for arg in "${args[@]}"; do
    case "$arg" in
      -s | --specialisation | -s=* | --specialisation=* | \
        -S | --no-specialisation | \
        -H | --hostname | -H=* | --hostname=* | \
        --target-host | --target-host=* | --)
        explicit_target=1
        break
        ;;
    esac
  done

  if [ "$explicit_target" = 0 ]; then
    machine="$("$detect" --table "$fingerprints")" || {
      echo "nh-local-wrapper: 无法确定本机 specialisation；未执行 nh。若确实要基础系统，请显式使用 -S。" >&2
      exit 1
    }
    if [ -z "$machine" ]; then
      echo "nh-local-wrapper: 未识别到本机 specialisation；未执行 nh。若确实要基础系统，请显式使用 -S。" >&2
      exit 1
    fi
    args=("${args[@]:0:2}" "--specialisation" "$machine" "${args[@]:2}")
  fi
fi

exec "$real_nh" "${args[@]}"
