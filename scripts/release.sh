#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=$(tr -d '[:space:]' < "$root/VERSION")
tag="v$version"
release_dir="$root/release"
prerelease=false
notes_file="$root/release-notes/$tag.md"

usage() {
  cat <<'USAGE'
Usage : release.sh [--prerelease] [--notes <chemin>]

Options :
  --prerelease       Publier une préversion AMD64 seulement.
                     ARM64 n'est pas exigée et la release n'est pas marquée comme latest.
  --notes <chemin>   Utiliser ce fichier Markdown comme notes de release.
                     Par défaut : release-notes/v<version>.md.
  -h, --help         Afficher cette aide.

Sans --prerelease, la publication stable exige AMD64 et ARM64 ainsi que
LOG100_ARM64_VALIDATED=1.
USAGE
}

while (( $# > 0 )); do
  case "$1" in
    --prerelease)
      prerelease=true
      shift
      ;;
    --notes)
      if (( $# < 2 )); then
        echo "ERREUR : --notes exige un chemin de fichier." >&2
        exit 1
      fi
      if [[ "$2" = /* ]]; then
        notes_file="$2"
      else
        notes_file="$root/$2"
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERREUR : option inconnue : $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$prerelease" == false && "${LOG100_ARM64_VALIDATED:-}" != "1" ]]; then
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

if [[ "$prerelease" == true ]]; then
  architectures=(amd64)
else
  architectures=(amd64 arm64)
fi

assets=()
for arch in "${architectures[@]}"; do
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

if [[ ! -f "$notes_file" ]]; then
  echo "ERREUR : fichier de notes de release absent : $notes_file" >&2
  exit 1
fi

if [[ "$prerelease" == true ]]; then
  title="network-lab-vm $version - préversion AMD64"
else
  title="network-lab-vm $version"
fi

release_args=(
  "$tag"
  "${assets[@]}"
  --title "$title"
  --notes-file "$notes_file"
  --verify-tag
)

if [[ "$prerelease" == true ]]; then
  release_args+=(--prerelease --latest=false)
fi

gh release create "${release_args[@]}"

if [[ "$prerelease" == true ]]; then
  echo "OK : préversion AMD64 $tag publiée."
else
  echo "OK : release stable $tag publiée."
fi
