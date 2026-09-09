# Construction et publication

Ce document s'adresse aux responsables du cours.

## Principes

- Une appliance est construite sur un hôte de la même architecture.
- L'appliance AMD64 peut être construite sur Ubuntu x86_64, Windows x86_64 avec un environnement Bash approprié, ou macOS Intel.
- L'appliance ARM64 doit être construite et validée sur macOS Apple Silicon. Windows 11 ARM demeure une cible de meilleur effort pour l'exécution, pas une plateforme de construction de référence.
- Les images OVA ne sont jamais commitées dans Git.
- Les appliances sont compressées avant leur téléversement dans une GitHub Release.
- Les deux architectures doivent être validées avant une release stable.
- Une release ARM64 stable exige des images OCI LOG100 multi-architectures et une validation des six laboratoires sur Apple Silicon.

## Outils de construction

- VirtualBox 7.2 ou plus récent;
- Packer 1.14 ou plus récent;
- le plugin Packer VirtualBox 1.1.5;
- Bash;
- gzip;
- GitHub CLI `gh` uniquement pour la publication.

Le support ARMv8 du plugin VirtualBox est récent. Une nouvelle version de VirtualBox ou du plugin Packer doit toujours être validée avec les six laboratoires avant d'être adoptée.

## Initialiser Packer

```bash
packer init packer
```

## Comportement du démarrage

La configuration Packer applique explicitement les paramètres suivants pour fiabiliser le démarrage de l'installateur Ubuntu :

- le lecteur DVD est le premier périphérique de démarrage;
- le disque virtuel est le second;
- Packer attend 15 secondes avant d'envoyer les commandes au menu de démarrage;
- les groupes de touches sont espacés de 200 ms;
- la console VirtualBox est visible pendant la construction;
- le menu GRUB est utilisé pour démarrer Ubuntu en mode `autoinstall`.

La console visible est intentionnelle pendant la phase de stabilisation. Elle permet de distinguer un problème de démarrage, un échec de récupération de la configuration NoCloud et un simple délai avant la disponibilité de SSH. Une fois les builds AMD64 et ARM64 régulièrement validés, `headless` pourra être remis à `true`.

## Construire AMD64

Sur un hôte x86_64 :

```bash
./scripts/build.sh amd64
```

Le résultat attendu est :

```text
output-amd64/log100-network-lab-vm-amd64.ova
```

## Construire ARM64

Sur un Mac Apple Silicon :

```bash
./scripts/build.sh arm64
```

Le résultat attendu est :

```text
output-arm64/log100-network-lab-vm-arm64.ova
```

## Diagnostic d'un build bloqué

Si Packer reste sur `Waiting for SSH to become available...`, observer d'abord la console VirtualBox.

- Si l'installateur Ubuntu ne démarre pas, vérifier que l'ISO est accessible et que le DVD est bien le premier périphérique de démarrage.
- Si l'installateur interactif apparaît, la commande de démarrage automatique n'a pas été reçue correctement.
- Si l'installateur indique qu'il ne peut pas joindre la source NoCloud, vérifier l'accès à `10.0.2.2` depuis le réseau NAT de VirtualBox.
- Si l'écran de connexion Ubuntu apparaît, l'installation est terminée et le diagnostic doit se concentrer sur SSH et la redirection NAT temporaire créée par Packer.

Le délai `ssh_timeout` reste volontairement fixé à 45 minutes afin de ne pas interrompre une installation légitimement lente.

## Paqueter

Pour chaque architecture :

```bash
./scripts/package.sh amd64
./scripts/package.sh arm64
```

Les fichiers sont placés dans `release/`.

## Validation fonctionnelle

Avant une release stable, importer chaque appliance sur une plateforme représentative et vérifier au minimum :

```bash
ssh -p 2222 log100@localhost
podman info
git --version
```

Puis exécuter les six laboratoires avec leurs images de conteneurs publiées :

```bash
./labctl doctor
./labctl up
./labctl status
./labctl down
```

Le laboratoire 6 doit aussi confirmer le fonctionnement de FRRouting et d'OSPF.

## Publication

1. Mettre `VERSION` à jour.
2. Valider le dépôt :

```bash
./scripts/validate.sh
```

3. Construire et paqueter les deux architectures.
4. Copier les quatre assets dans `release/` sur le poste qui publiera la release.
5. Créer et pousser un tag annoté :

```bash
git tag -a "v$(cat VERSION)" -m "Version $(cat VERSION)"
git push origin "v$(cat VERSION)"
```

6. Publier :

```bash
./scripts/release.sh
```

Le script refuse une release incomplète ou un asset de 2 Gio ou plus.

## Politique de versions

Le dépôt suit SemVer.

- PATCH : correction de construction, de documentation ou de compatibilité sans changement important de l'environnement étudiant.
- MINOR : ajout ou modification compatible de l'environnement de la VM.
- MAJOR : changement incompatible du flux d'installation, de l'OS invité ou des exigences principales.

La version des appliances est indépendante de la version des laboratoires et des images de conteneurs.
