#!/usr/bin/env bash
# Read-only Android diagnostics. Requires adb; never invokes root, flash, or writes.
set -euo pipefail
command -v adb >/dev/null || { echo "adb not found" >&2; exit 2; }
if [[ "$(adb devices | awk 'NR>1 && $2=="device" {n++} END {print n+0}')" != 1 ]]; then
  echo "Connect and authorize exactly one Android device." >&2; exit 2
fi
printf '%s\n' '# Samsung A56 read-only compatibility report'
for key in ro.product.model ro.product.device ro.build.display.id ro.build.version.release ro.build.version.security_patch ro.bootimage.build.fingerprint ro.boot.flash.locked ro.boot.verifiedbootstate ro.boot.vbmeta.device_state; do
  value="$(adb shell getprop "$key" | tr -d '\r' | head -c 512)"
  printf '%s=%s\n' "$key" "$value"
done
printf 'kernel=%s\n' "$(adb shell uname -r | tr -d '\r')"
printf '%s\n' 'Note: missing properties are unknown, not false. No modifications performed.'
