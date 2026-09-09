#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  dnsutils \
  fuse-overlayfs \
  git \
  iproute2 \
  iputils-ping \
  jq \
  less \
  netcat-openbsd \
  openssh-server \
  passt \
  podman \
  slirp4netns \
  tcpdump \
  traceroute \
  uidmap \
  unzip \
  vim-tiny

if ! id log100 >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash --groups sudo log100
fi

echo 'log100:log100' | chpasswd

if ! grep -q '^log100:' /etc/subuid; then
  echo 'log100:200000:65536' >> /etc/subuid
fi
if ! grep -q '^log100:' /etc/subgid; then
  echo 'log100:200000:65536' >> /etc/subgid
fi

install -d -m 0755 /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/60-log100.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication yes
KbdInteractiveAuthentication no
AllowUsers log100 packer
EOF

systemctl enable ssh

cat > /etc/sysctl.d/60-log100-rootless.conf <<'EOF'
kernel.apparmor_restrict_unprivileged_userns=0
EOF
sysctl --system >/dev/null

install -d -o log100 -g log100 -m 0755 /home/log100/.config/containers
cat > /home/log100/README.txt <<'EOF'
LOG100 - Machine virtuelle pour les laboratoires de réseautique

Connexion depuis le système hôte :
  ssh -p 2222 log100@localhost

Mot de passe initial : log100
Il est recommandé de le modifier avec : passwd

Après avoir obtenu l'accès GitHub au laboratoire :
  git clone <adresse-du-depot>
  cd <depot>
  ./labctl doctor
  ./labctl up
EOF
chown log100:log100 /home/log100/README.txt

cat > /etc/motd <<'EOF'
LOG100 - Environnement des laboratoires de réseautique
Consultez ~/README.txt pour les commandes de départ.
EOF

install -d -m 0755 /var/lib/log100
: > /var/lib/log100/first-boot.pending

cat > /usr/local/sbin/log100-first-boot <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
marker=/var/lib/log100/first-boot.pending
if [[ ! -f "$marker" ]]; then
  exit 0
fi
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A
rm -f "$marker"
EOF
chmod 0755 /usr/local/sbin/log100-first-boot

cat > /etc/systemd/system/log100-first-boot.service <<'EOF'
[Unit]
Description=Initialiser la VM LOG100 après importation
After=network.target
Before=ssh.service
ConditionPathExists=/var/lib/log100/first-boot.pending

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/log100-first-boot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable log100-first-boot.service

cat > /usr/local/sbin/log100-finalize-build <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
passwd -l packer || true
rm -rf /home/packer/.ssh
apt-get clean
rm -rf /var/lib/apt/lists/*
sync
shutdown -P now
EOF
chmod 0755 /usr/local/sbin/log100-finalize-build

podman --version
git --version
sshd -t
