#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=$(tr -d '[:space:]' < "$root/VERSION")
tag="v$version"
release_dir="$root/release"

if [[ "${LOG100_ARM64_VALIDATED:-}" != "1" ]]; then
  echo "ERREUR : définissez LOG100_ARM64_VALIDATED=1 uniquement après la validation ARM64 complète des images OCI et des six laboratoires." >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERREUR : GitHub CLI (gh) est requis pour publier la release." >&2
  exit 1
fi

if ! git -C "$root" diff --quiet || ! git -C "$root" diff --cached --quiet; then
  echo "ERREUR : le dépôt contient des modifications non commitées." >&2
  exit 1
fi

if ! git -C "$root" rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "ERREUR : le tag $tag n'existe pas. Créez et poussez d'abord le tag annoté." >&2
  exit 1
fi

assets=()
for arch in amd64 arm64; do
  asset="$release_dir/log100-network-lab-vm-$arch.ova.gz"
  checksum="$asset.sha256"
  for file in "$asset" "$checksum"; do
    if [[ ! -f "$file" ]]; then
      echo "ERREUR : asset de release absent : $file" >&2
      exit 1
    fi
    assets+=("$file")
  done
  size=$(wc -c < "$asset" | tr -d '[:space:]')
  if (( size >= 2147483648 )); then
    echo "ERREUR : $(basename "$asset") atteint 2 Gio ou plus." >&2
    exit 1
  fi
done

if gh release view "$tag" >/dev/null 2>&1; then
  echo "ERREUR : la release $tag existe déjà." >&2
  exit 1
fi

notes=$(mktemp)
trap 'rm -f "$notes"' EXIT
cat > "$notes" <<EOF
Machine virtuelle LOG100 $version pour VirtualBox.

Assets :
- AMD64 : Windows 10/11 Intel/AMD, Ubuntu x86_64 et macOS Intel;
- ARM64 : macOS Apple Silicon; Windows 11 ARM en meilleur effort.

Connexion SSH après installation :

\`\`\`text
ssh -p 2222 log100@localhost
\`\`\`

Mot de passe initial : \`log100\`.
EOF

gh release create "$tag" "${assets[@]}" \
  --title "network-lab-vm $version" \
  --notes-file "$notes" \
  --verify-tag

echo "OK : release $tag publiée."
