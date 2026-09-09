# Installation de la machine virtuelle LOG100

## Prérequis

- Oracle VirtualBox 7.2 ou plus récent;
- une connexion Internet;
- environ 4 Go de mémoire disponible pour la VM;
- suffisamment d'espace disque pour l'appliance et les images de conteneurs.

L'installation n'exige pas de connaître l'adresse IP de la VM. SSH est redirigé vers `localhost:2222`.

## Linux ou macOS

Exécuter :

```bash
chmod +x setup-vm.sh
./setup-vm.sh
```

Le script choisit automatiquement l'appliance `amd64` ou `arm64` selon l'architecture du poste.

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

## Windows

Dans PowerShell :

```powershell
PowerShell -ExecutionPolicy Bypass -File .\setup-vm.ps1
```

Puis :

```powershell
ssh -p 2222 log100@localhost
```

Le mot de passe initial est `log100`.

## Premier laboratoire

Après avoir obtenu l'accès GitHub au dépôt du laboratoire :

```bash
git clone https://github.com/ets-log100/network-lab1-foundations-a2026.git
cd network-lab1-foundations-a2026
./labctl doctor
./labctl up
```

Les autres laboratoires utilisent le même flux.

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

Une nouvelle appliance peut avoir une nouvelle clé SSH. Les scripts d'installation retirent normalement l'ancienne entrée. Au besoin :

```bash
ssh-keygen -R "[localhost]:2222"
```

## Remarque sur Wireshark

Il n'est pas nécessaire d'installer l'interface graphique de Wireshark dans la VM. Les fichiers de capture produits par les laboratoires peuvent être ouverts avec Wireshark sur le système hôte.
