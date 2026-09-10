#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
arch=${1:-}

case "$arch" in
  amd64|arm64) ;;
  *)
    echo "Usage : $0 amd64|arm64" >&2
    exit 2
    ;;
esac

source_ova="$root/output-$arch/log100-network-lab-vm-$arch.ova"
release_dir="$root/release"
asset="$release_dir/log100-network-lab-vm-$arch.ova.gz"
checksum="$asset.sha256"
max_asset_bytes=2147483648

human_size() {
  local bytes=$1
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$bytes"
  else
    awk -v bytes="$bytes" 'BEGIN {printf "%.2f Gio", bytes / 1073741824}'
  fi
}

if [[ ! -f "$source_ova" ]]; then
  echo "ERREUR : appliance absente : $source_ova" >&2
  exit 1
fi

mkdir -p "$release_dir"
rm -f "$asset" "$checksum"

ova_size=$(wc -c < "$source_ova" | tr -d '[:space:]')
echo "INFO : taille de l'OVA source : $(human_size "$ova_size")"
echo "INFO : compression de $arch"
gzip -9 -n -c "$source_ova" > "$asset"

size=$(wc -c < "$asset" | tr -d '[:space:]')
echo "INFO : taille de l'asset compressé : $(human_size "$size")"
if (( size >= max_asset_bytes )); then
  cat >&2 <<EOF_ERROR
ERREUR : l'asset compressé atteint 2 Gio ou plus et ne peut pas être publié sur GitHub Releases.
ERREUR : package.sh ne peut pas compacter un disque déjà exporté dans l'OVA.
ERREUR : reconstruisez l'appliance avec ./scripts/build.sh $arch afin d'appliquer le nettoyage invité et TRIM avant l'export.
EOF_ERROR
  exit 1
fi

(
  cd "$release_dir"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$(basename "$asset")" > "$(basename "$checksum")"
  else
    shasum -a 256 "$(basename "$asset")" > "$(basename "$checksum")"
  fi
)

echo "OK : $asset"
echo "OK : $checksum"
