#!/usr/bin/env bash
set -euo pipefail

repo="ets-log100/network-lab-vm"
vm_name="LOG100 Network Labs"
ssh_port=2222
work_dir="${TMPDIR:-/tmp}/log100-network-lab-vm"

fail() {
  echo "ERREUR : $*" >&2
  exit 1
}

command -v VBoxManage >/dev/null 2>&1 || fail "VirtualBox n'est pas installé ou VBoxManage n'est pas dans PATH."
command -v curl >/dev/null 2>&1 || fail "curl est requis."
command -v gzip >/dev/null 2>&1 || fail "gzip est requis."

host_arch=$(uname -m)
case "$host_arch" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) fail "architecture non supportée : $host_arch" ;;
esac

vbox_version=$(VBoxManage --version | sed -E 's/^([0-9]+\.[0-9]+).*/\1/')
major=${vbox_version%%.*}
minor=${vbox_version#*.}
if (( major < 7 || (major == 7 && minor < 2) )); then
  fail "VirtualBox 7.2 ou plus récent est requis. Version détectée : $vbox_version"
fi

if VBoxManage showvminfo "$vm_name" >/dev/null 2>&1; then
  fail "une VM nommée '$vm_name' existe déjà. Supprimez-la ou renommez-la avant de continuer."
fi

asset="log100-network-lab-vm-$arch.ova.gz"
base_url="https://github.com/$repo/releases/latest/download"
mkdir -p "$work_dir"
archive="$work_dir/$asset"
checksum="$archive.sha256"
ova="$work_dir/log100-network-lab-vm-$arch.ova"

echo "INFO : téléchargement de l'appliance $arch"
curl -fL --retry 3 -o "$archive" "$base_url/$asset"
curl -fL --retry 3 -o "$checksum" "$base_url/$asset.sha256"

expected=$(awk '{print $1}' "$checksum")
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$archive" | awk '{print $1}')
else
  actual=$(shasum -a 256 "$archive" | awk '{print $1}')
fi
[[ "$actual" == "$expected" ]] || fail "le SHA-256 de l'appliance est invalide."

echo "INFO : décompression"
gzip -dc "$archive" > "$ova"

echo "INFO : importation dans VirtualBox"
VBoxManage import "$ova" --vsys 0 --vmname "$vm_name"

VBoxManage modifyvm "$vm_name" --nat-pf1 delete ssh >/dev/null 2>&1 || true
VBoxManage modifyvm "$vm_name" --nat-pf1 "ssh,tcp,127.0.0.1,$ssh_port,,22"

if command -v ssh-keygen >/dev/null 2>&1; then
  ssh-keygen -R "[localhost]:$ssh_port" >/dev/null 2>&1 || true
fi

echo "INFO : démarrage de la VM"
VBoxManage startvm "$vm_name" --type headless

cat <<EOF

OK : la VM LOG100 est démarrée.

Connexion :
  ssh -p $ssh_port log100@localhost

Mot de passe initial : log100
La première disponibilité de SSH peut prendre quelques dizaines de secondes.
EOF
