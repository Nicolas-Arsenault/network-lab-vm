#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for script in "$root"/scripts/*.sh "$root"/packer/scripts/*.sh; do
  bash -n "$script"
done

python3 -m unittest discover -s "$root/tests" -v

echo "OK : validation du dépôt terminée."
