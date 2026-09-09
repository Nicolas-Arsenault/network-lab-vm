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

for command_name in packer VBoxManage; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERREUR : commande requise absente : $command_name" >&2
    exit 1
  fi
done

host_arch=$(uname -m)
case "$host_arch" in
  x86_64|amd64) detected=amd64 ;;
  arm64|aarch64) detected=arm64 ;;
  *)
    echo "ERREUR : architecture de construction non supportée : $host_arch" >&2
    exit 1
    ;;
esac

if [[ "$detected" != "$arch" ]]; then
  echo "ERREUR : l'appliance $arch doit être construite sur un hôte $arch." >&2
  exit 1
fi

version=$(tr -d '[:space:]' < "$root/VERSION")
var_file="$root/packer/${arch}.pkrvars.hcl"

rm -rf "$root/output-$arch"

cd "$root"
echo "INFO : initialisation de Packer"
packer init packer

echo "INFO : validation de la configuration $arch"
packer validate -var-file="$var_file" -var "vm_version=$version" packer

echo "INFO : construction de l'appliance $arch"
packer build -var-file="$var_file" -var "vm_version=$version" packer

echo "OK : output-$arch/log100-network-lab-vm-$arch.ova"
