# network-lab-vm

Ce dépôt contient les fichiers nécessaires pour construire et publier une machine virtuelle VirtualBox destinée aux laboratoires de réseautique de LOG100.

La machine virtuelle est une solution de repli pour les étudiants qui veulent exécuter les laboratoires sur leur ordinateur personnel sans installer et configurer Podman directement sur leur système hôte. Les postes de laboratoire de l'ÉTS demeurent l'environnement de référence.

## Environnement fourni

L'appliance contient notamment :

- Ubuntu Server 24.04 LTS;
- Podman en mode rootless;
- Git;
- OpenSSH;
- les outils réseau usuels nécessaires aux laboratoires;
- un compte utilisateur `log100`.

La VM utilise un adaptateur VirtualBox en mode NAT. Le port SSH du système invité est exposé uniquement sur la boucle locale du poste hôte :

```text
localhost:2222 -> VM:22
```

Après l'installation, l'étudiant se connecte avec :

```bash
ssh -p 2222 log100@localhost
```

Le mot de passe initial est `log100`. Il est recommandé de le modifier avec `passwd` après la première connexion.

## Plateformes

### Supportées

- Windows 10/11 sur Intel ou AMD;
- Ubuntu x86_64 récent;
- macOS sur Intel;
- macOS sur Apple Silicon.

### Meilleur effort

- Windows 11 sur ARM.

### Non supportées

- Linux sur ARM;
- les hyperviseurs autres que VirtualBox;
- les architectures inhabituelles.

VirtualBox 7.2 ou une version plus récente est recommandée. Les hôtes ARM utilisent l'appliance ARM64 et les hôtes Intel/AMD utilisent l'appliance AMD64.

## Prérequis avant une première release stable ARM64

L'appliance ARM64 ne doit être publiée comme cible supportée qu'après la publication et la validation des images OCI LOG100 en multi-architecture `linux/amd64` et `linux/arm64`. Les laboratoires doivent épingler les digests des index OCI multi-architectures avant la validation finale sur Apple Silicon.

## Distribution

Les appliances ne sont pas stockées dans Git. Elles sont publiées comme assets d'une GitHub Release du dépôt.

Chaque version stable contient :

```text
log100-network-lab-vm-amd64.ova.gz
log100-network-lab-vm-amd64.ova.gz.sha256
log100-network-lab-vm-arm64.ova.gz
log100-network-lab-vm-arm64.ova.gz.sha256
```

Les noms restent stables d'une version à l'autre afin que les scripts d'installation puissent utiliser la dernière release.

## Utilisation par un étudiant

### Linux ou macOS

Télécharger `scripts/setup-vm.sh`, puis :

```bash
chmod +x setup-vm.sh
./setup-vm.sh
```

### Windows PowerShell

Télécharger `scripts/setup-vm.ps1`, puis :

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup-vm.ps1
```

Les scripts :

1. vérifient VirtualBox;
2. détectent l'architecture du poste;
3. téléchargent l'appliance appropriée depuis la dernière release;
4. vérifient son SHA-256;
5. importent la VM;
6. configurent `127.0.0.1:2222 -> 22`;
7. démarrent la VM en mode sans interface graphique.

Voir [docs/student-setup.md](docs/student-setup.md) pour les détails.

## Construction

La construction se fait avec Packer et VirtualBox sur un hôte de la même architecture que l'appliance produite. Pendant la phase de stabilisation, la console VirtualBox reste visible afin de pouvoir diagnostiquer immédiatement un problème de démarrage ou d'autoinstallation.

```bash
./scripts/build.sh amd64
./scripts/package.sh amd64
```

Sur un Mac Apple Silicon :

```bash
./scripts/build.sh arm64
./scripts/package.sh arm64
```

Les deux assets doivent être validés avant de publier une release.

Voir [docs/build.md](docs/build.md).

## Publication d'une release

Après avoir regroupé les quatre fichiers dans `release/` et créé le tag correspondant à `VERSION` :

```bash
./scripts/release.sh
```

Le script utilise `gh` pour créer la GitHub Release et téléverser les assets.

## Validation

```bash
./scripts/validate.sh
```

Les fichiers Markdown sont en français. Les noms de dépôts, répertoires, scripts et identifiants techniques utilisent l'anglais.
