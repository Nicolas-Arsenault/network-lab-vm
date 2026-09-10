# Installation de la machine virtuelle LOG100

## Avant de commencer

La VM est une solution de repli. Les postes de laboratoire de l'ÉTS demeurent l'environnement de référence.

La cible AMD64 est la première cible en cours de stabilisation. Une appliance ARM64 ne doit être utilisée que lorsqu'une release indique explicitement que la validation ARM64 des six laboratoires est terminée.

## Prérequis

- Oracle VirtualBox 7.2 ou plus récent;
- une connexion Internet;
- environ 4 Go de mémoire disponible pour la VM;
- suffisamment d'espace disque pour l'appliance et les images de conteneurs.

L'installation n'exige pas de connaître l'adresse IP de la VM. SSH est redirigé vers `localhost:2222`.

## Linux x86_64 ou macOS Intel

Exécuter :

```bash
chmod +x setup-vm.sh
./setup-vm.sh
```

## Windows Intel ou AMD

Dans PowerShell :

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup-vm.ps1
```

## Hôtes ARM64

Le dépôt contient une cible de construction ARM64, mais son utilisation étudiante dépend encore de la publication d'images OCI multi-architectures et de la validation des six laboratoires sur ARM64.

Ne pas utiliser l'appliance ARM64 tant que la release ne confirme pas cette validation. Windows 11 sur ARM restera une cible de meilleur effort même après cette validation.

## Connexion

Une fois la VM démarrée :

```bash
ssh -p 2222 log100@localhost
```

Mot de passe initial :

```text
log100
```

Il est recommandé de le modifier :

```bash
passwd
```

## Premier laboratoire

Après avoir obtenu l'accès GitHub au dépôt du laboratoire :

```bash
git clone https://github.com/ets-log100/network-lab1-foundations-a2026.git
cd network-lab1-foundations-a2026
./labctl doctor
./labctl up
./labctl check
./labctl submit
./labctl down
```

Les autres laboratoires utilisent le même flux.

Les images de conteneurs ne sont pas préinstallées dans la VM. `./labctl up` les récupère depuis GHCR selon les références définies par le laboratoire.

La VM fournit aussi Nano, `vim-tiny`, Python 3, `pip`, `venv`, `requests`, PyYAML et plusieurs outils de diagnostic réseau, dont `tcpdump` et `tshark`. Les dépendances propres à un laboratoire demeurent toutefois définies par ce laboratoire et ses images de conteneurs.

## Arrêter et redémarrer la VM

Arrêt propre depuis la VM :

```bash
sudo poweroff
```

Redémarrage depuis le système hôte :

```bash
VBoxManage startvm "LOG100 Network Labs" --type headless
```

## Problème avec la clé SSH après une mise à jour

Une nouvelle appliance génère une nouvelle clé SSH au premier démarrage. Les scripts d'installation retirent normalement l'ancienne entrée. Au besoin :

```bash
ssh-keygen -R "[localhost]:2222"
```

## Remarque sur Wireshark

Il n'est pas nécessaire d'installer l'interface graphique de Wireshark dans la VM. `tshark` est disponible pour l'analyse en ligne de commande. Les fichiers de capture produits par les laboratoires peuvent aussi être ouverts avec Wireshark sur le système hôte.
