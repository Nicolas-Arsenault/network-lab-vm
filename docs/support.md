# Plateformes supportées

La machine virtuelle LOG100 vise à fournir un environnement Ubuntu et Podman uniforme sans imposer l'installation de Podman directement sur le poste de l'étudiant.

## Supportées

| Système hôte | Architecture | Appliance |
| --- | --- | --- |
| Windows 10/11 | Intel/AMD x86_64 | `amd64` |
| Ubuntu récent | x86_64 | `amd64` |
| macOS | Intel x86_64 | `amd64` |
| macOS | Apple Silicon ARM64 | `arm64` |

## Meilleur effort

| Système hôte | Architecture | Appliance |
| --- | --- | --- |
| Windows 11 | ARM64 | `arm64` |

Le support de VirtualBox sur Windows 11 ARM est considéré expérimental par Oracle. Ce cas ne doit donc pas être présenté comme une plateforme de référence du cours.

## Non supportées

- Linux sur ARM;
- VMware, Parallels, Hyper-V, QEMU ou d'autres hyperviseurs;
- les architectures autres que x86_64 et ARM64;
- l'émulation d'une architecture différente de celle du système hôte.

## Environnement de référence

Les postes de laboratoire de l'ÉTS demeurent l'environnement de référence. La VM est une solution de repli pour le travail sur un ordinateur personnel.

Une appliance ARM64 et une appliance AMD64 sont publiées pour une même version. Elles doivent offrir le même environnement fonctionnel et exécuter les mêmes images de conteneurs multi-architectures.
