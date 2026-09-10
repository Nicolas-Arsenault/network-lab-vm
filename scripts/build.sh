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
host_os=$(uname -s)
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

if [[ "$arch" == "arm64" && "$host_os" != "Darwin" ]]; then
  echo "ERREUR : la construction ARM64 de référence doit être effectuée sur macOS Apple Silicon." >&2
  exit 1
fi

vbox_version=$(VBoxManage --version | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
if [[ ! "$vbox_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "ERREUR : impossible de déterminer la version de VirtualBox." >&2
  exit 1
fi
vbox_major=${vbox_version%%.*}
vbox_minor=${vbox_version#*.}
if (( vbox_major < 7 || (vbox_major == 7 && vbox_minor < 2) )); then
  echo "ERREUR : VirtualBox 7.2 ou plus récent est requis. Version détectée : $vbox_version" >&2
  exit 1
fi

if [[ "$arch" == "arm64" ]]; then
  echo "AVERTISSEMENT : la cible ARM64 reste expérimentale tant que les images OCI LOG100 ne sont pas multi-architectures et que les six laboratoires ne sont pas validés sur ARM64." >&2
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
