#!/usr/bin/env bash
# Exercise the portable-chen nh wrapper with real argv at the boundary.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wrapper="$repo/scripts/nh-local-wrapper.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fake_detect="$tmp/detect-machine"
fake_nh="$tmp/nh"
argv_file="$tmp/argv"
keys="$tmp/machine-fingerprints.conf"

printf '' > "$keys"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "${WRAPPER_TEST_DETECT_MODE:-found}" in' \
  '  found) printf "%s\n" dell-intel ;;' \
  '  empty) exit 0 ;;' \
  '  error) printf "%s\n" "ambiguous" >&2; exit 3 ;;' \
  'esac' > "$fake_detect"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$@" > "$WRAPPER_TEST_ARGV"' > "$fake_nh"
chmod +x "$fake_detect" "$fake_nh"

run_wrapper() {
  WRAPPER_TEST_ARGV="$argv_file" \
    bash "$wrapper" "$fake_nh" "$fake_detect" "$keys" "$@"
}

assert_argv() {
  local expected="$1"
  local actual
  actual="$(cat "$argv_file")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'expected argv:\n%s\nactual argv:\n%s\n' "$expected" "$actual" >&2
    return 1
  fi
}

run_wrapper os switch
assert_argv $'os\nswitch\n--specialisation\ndell-intel'

run_wrapper os switch -s chen-desktop -n
assert_argv $'os\nswitch\n-s\nchen-desktop\n-n'

run_wrapper os switch -S
assert_argv $'os\nswitch\n-S'

run_wrapper os switch --specialisation=chen-desktop -n
assert_argv $'os\nswitch\n--specialisation=chen-desktop\n-n'

run_wrapper os switch -H msi-wd
assert_argv $'os\nswitch\n-H\nmsi-wd'

run_wrapper os switch --hostname=msi-wd
assert_argv $'os\nswitch\n--hostname=msi-wd'

run_wrapper os switch --target-host root@example
assert_argv $'os\nswitch\n--target-host\nroot@example'

run_wrapper os switch -- --option foo bar
assert_argv $'os\nswitch\n--\n--option\nfoo\nbar'

run_wrapper home switch
assert_argv $'home\nswitch'

expect_detection_failure() {
  local mode="$1"
  local output
  rm -f "$argv_file"
  if output="$(
    WRAPPER_TEST_DETECT_MODE="$mode" \
      WRAPPER_TEST_ARGV="$argv_file" \
      bash "$wrapper" "$fake_nh" "$fake_detect" "$keys" os switch 2>&1
  )"; then
    echo "expected detection mode '$mode' to fail" >&2
    return 1
  fi
  if [ -e "$argv_file" ]; then
    echo "detection failure still invoked nh for mode '$mode'" >&2
    return 1
  fi
  case "$output" in
    *'-S'*) ;;
    *)
      echo "detection failure did not suggest -S for mode '$mode'" >&2
      return 1
      ;;
  esac
}

expect_detection_failure empty
expect_detection_failure error

printf 'nh-local-wrapper tests passed\n'
