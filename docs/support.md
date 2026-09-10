# Plateformes supportées

La machine virtuelle LOG100 vise à fournir un environnement Ubuntu et Podman uniforme sans imposer l'installation de Podman directement sur le poste de l'étudiant. Les postes de laboratoire de l'ÉTS demeurent l'environnement de référence.

## État actuel

La cible AMD64 est la cible en cours de stabilisation pour la première appliance utilisable.

La cible ARM64 existe dans les fichiers Packer, mais elle ne doit pas encore être présentée comme une cible étudiante disponible. Avant cette annonce, `network-lab-image` doit publier des images OCI pour `linux/amd64` et `linux/arm64`, puis les six laboratoires doivent être validés sur ARM64. Le laboratoire 6 doit notamment confirmer FRRouting et OSPF.

## Politique visée après validation ARM64

### Supportées

| Système hôte | Architecture | Appliance |
| --- | --- | --- |
| Windows 10/11 | Intel/AMD x86_64 | `amd64` |
| Ubuntu récent | x86_64 | `amd64` |
| macOS | Intel x86_64 | `amd64` |
| macOS | Apple Silicon ARM64 | `arm64` |

### Meilleur effort

| Système hôte | Architecture | Appliance |
| --- | --- | --- |
| Windows 11 | ARM64 | `arm64` |

Windows 11 sur ARM demeure une cible de meilleur effort. Elle ne constitue pas une plateforme de référence du cours.

### Non supportées

- Linux sur ARM;
- VMware, Parallels, Hyper-V, QEMU ou d'autres hyperviseurs;
- les architectures autres que x86_64 et ARM64;
- l'émulation d'une architecture différente de celle du système hôte.

## Règle de publication ARM64

Une release qui annonce ARM64 comme utilisable doit avoir passé les validations suivantes :

- construction de l'appliance sur macOS Apple Silicon;
- importation et démarrage dans VirtualBox;
- connexion SSH par `localhost:2222`;
- validation de Podman rootless;
- exécution des six laboratoires avec leurs images OCI multi-architectures;
- validation spécifique de FRRouting et OSPF dans le laboratoire 6.
