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

if [[ ! -f "$source_ova" ]]; then
  echo "ERREUR : appliance absente : $source_ova" >&2
  exit 1
fi

mkdir -p "$release_dir"
rm -f "$asset" "$checksum"

echo "INFO : compression de $arch"
gzip -9 -n -c "$source_ova" > "$asset"

size=$(wc -c < "$asset" | tr -d '[:space:]')
if (( size >= 2147483648 )); then
  echo "ERREUR : l'asset compressé atteint 2 Gio ou plus et ne peut pas être publié sur GitHub Releases." >&2
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
