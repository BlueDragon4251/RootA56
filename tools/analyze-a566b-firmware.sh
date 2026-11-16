#!/usr/bin/env bash
# Offline firmware inventory helper. It performs no device interaction.
set -euo pipefail

usage() {
  printf 'Usage: %s <parts-directory> <output-directory>\n' "$0" >&2
  exit 64
}

[[ $# -eq 2 ]] || usage
parts_dir=$1
output_dir=$2
prefix='SAMFW.COM_SM-A566B_MOB_A566BXXUEDZJ1_fac.zip'
archive="$output_dir/$prefix"

for command in sha256sum unzip tar lz4 gzip grep dd; do
  command -v "$command" >/dev/null || {
    printf 'Missing required command: %s\n' "$command" >&2
    exit 69
  }
done

mkdir -p "$output_dir/images"

parts=()
for number in $(seq 1 11); do
  printf -v index '%03d' "$number"
  part="$parts_dir/$prefix.$index"
  [[ -s $part ]] || {
    printf 'Missing or empty firmware part: %s\n' "$part" >&2
    exit 66
  }
  parts+=("$part")
done

sha256sum "${parts[@]}" > "$output_dir/parts.sha256"
cat "${parts[@]}" > "$archive"
sha256sum "$archive" > "$output_dir/archive.sha256"
unzip -t "$archive"

mkdir -p "$output_dir/extracted"
unzip -qo "$archive" -d "$output_dir/extracted"
sha256sum "$output_dir"/extracted/*.tar.md5 > "$output_dir/firmware-files.sha256"

ap=$(find "$output_dir/extracted" -maxdepth 1 -type f -name 'AP_A566BXXUEDZJ1_*.tar.md5' -print -quit)
[[ -n $ap ]] || { printf 'AP package not found\n' >&2; exit 65; }

tar -xf "$ap" -C "$output_dir/images" \
  boot.img.lz4 init_boot.img.lz4 vendor_boot.img.lz4 dtbo.img.lz4 \
  vbmeta.img.lz4 vbmeta_system.img.lz4

for compressed in "$output_dir"/images/*.lz4; do
  lz4 -d -f "$compressed" "${compressed%.lz4}"
done
sha256sum "$output_dir"/images/* > "$output_dir/images/images.sha256"

# The kernel's compressed IKCONFIG is bounded by these sentinel strings.
start=$(LC_ALL=C grep -abo 'IKCFG_ST' "$output_dir/images/boot.img" | head -1 | cut -d: -f1)
end=$(LC_ALL=C grep -abo 'IKCFG_ED' "$output_dir/images/boot.img" | head -1 | cut -d: -f1)
[[ -n $start && -n $end && $end -gt $start ]] || {
  printf 'Embedded kernel configuration was not found\n' >&2
  exit 65
}
payload_start=$((start + 8))
payload_size=$((end - payload_start))
dd if="$output_dir/images/boot.img" of="$output_dir/images/kernel.config.gz" \
  iflag=skip_bytes,count_bytes skip="$payload_start" count="$payload_size" status=none
gzip -t "$output_dir/images/kernel.config.gz"
gzip -dc "$output_dir/images/kernel.config.gz" > "$output_dir/images/kernel.config"
sha256sum "$output_dir"/images/* > "$output_dir/images/images.sha256"

printf 'Analysis complete. Results: %s\n' "$output_dir"
