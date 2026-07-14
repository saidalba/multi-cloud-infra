#!/usr/bin/env bash
# Quick manual setup for a fresh Ubuntu server -- paste-and-run over SSH when
# you don't have Terraform/Ansible handy. Covers similar baseline hardening
# to ansible/roles/ubuntu_minimal, but is a standalone script meant to be
# run once, by hand, on a box you're already SSH'd into as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [ "$EUID" -ne 0 ]; then echo "Error: Must run as root"; exit 1; fi

echo "--> Updating system..."
apt-get update && apt-get upgrade -y
apt-get autoremove -y

echo "--> Installing utilities (fail2ban, monitoring, tools)..."
apt-get install -y ufw fail2ban unattended-upgrades htop ncdu iotop nethogs tmux git micro cron mailutils

# 1. Automate security & maintenance updates
dpkg-reconfigure -f noninteractive unattended-upgrades
cat << 'EOF' > /etc/apt/apt.conf.d/52unattended-upgrades-custom
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

# 2. Configure the installed tools (mouse/scrollback for tmux, sane defaults
# for git, a usable editor config for micro). htop/ncdu/iotop/nethogs are
# ad-hoc diagnostic tools with no persistent config worth setting here.
cat << 'EOF' > /etc/tmux.conf
set -g mouse on
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g escape-time 10
EOF

git config --system init.defaultBranch main
git config --system pull.rebase false
git config --system core.editor micro
# NOTE: relaxes git's "dubious ownership" check (safe.directory) repo-wide.
# That check exists to stop one user's repo from executing config-driven
# git hooks/commands as another user; on a single-admin box run as root it's
# mostly noise, but remove this line if multiple people will use this server.
git config --system safe.directory '*'

mkdir -p /root/.config/micro
cat << 'EOF' > /root/.config/micro/settings.json
{
    "tabsize": 4,
    "tabstospaces": true,
    "mouse": true,
    "softwrap": true
}
EOF

# 3. SSH hardening (disable password auth, enforce keys)
# NOTE: PermitRootLogin is "prohibit-password", not "no". "no" would block
# root over SSH entirely -- including the key-based session you're using to
# run this script right now -- and this script does not create a fallback
# sudo user. If you want root SSH disabled completely, create and test a
# separate sudo user with your key authorized first, then change this to "no".
# X11Forwarding is intentionally left unset (Ubuntu's default is "yes") and
# the Kex/Cipher/MAC list below only restricts transport-layer crypto to
# modern algorithms -- it does not affect which key types can authenticate,
# so existing SSH private keys keep working unchanged.
cat << 'EOF' > /etc/ssh/sshd_config.d/99-hardening.conf
PasswordAuthentication no
PermitRootLogin prohibit-password
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp521
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF
sshd -t
systemctl restart ssh

# 4. Minimal UFW firewall (SSH only). X11 forwarding and any ssh -L/-D
# port forwarding tunnel through the SSH connection itself, so a
# deny-by-default firewall that only allows SSH does not affect them --
# nothing extra to open for those to keep working.
ufw allow OpenSSH
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# 5. Fail2ban tuning
cat << 'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
EOF
systemctl restart fail2ban

# 6. Limit journald logs (prevents disk fill-up)
mkdir -p /etc/systemd/journald.conf.d/
cat << 'EOF' > /etc/systemd/journald.conf.d/00-journal-size.conf
[Journal]
SystemMaxUse=1G
RuntimeMaxUse=200M
MaxRetentionSec=30day
EOF
systemctl restart systemd-journald

# 7. Prometheus node_exporter (optional monitoring). Stays unreachable from
# the internet by default -- UFW only allows SSH, same as everything else.
# Open 9100 yourself, restricted to your monitoring server's IP, to scrape it.
apt-get install -y prometheus-node-exporter
systemctl enable --now prometheus-node-exporter

# 8. Basic disk/memory health-check, mailed to ALERT_EMAIL (defaults to the
# local root mailbox, readable on-box via `mail`). For alerts to leave the
# server you need a real mail transport (e.g. msmtp) configured separately --
# this only wires up the local script + schedule.
cat << EOF > /usr/local/bin/health-check.sh
#!/bin/bash
df -h | awk 'NR>1 && \$5+0 > 80 {print "DISK ALERT: " \$0}' | mail -s "Disk Alert: \$(hostname)" "${ALERT_EMAIL:-root}"
FREE=\$(free | awk '/Mem/{printf "%.0f", \$4/\$2*100}')
[ "\$FREE" -lt 10 ] && echo "Low memory: \${FREE}% free" | mail -s "Memory Alert: \$(hostname)" "${ALERT_EMAIL:-root}"
EOF
chmod +x /usr/local/bin/health-check.sh
echo "*/15 * * * * root /usr/local/bin/health-check.sh" > /etc/cron.d/health-check

echo "--> Setup complete. Keep this terminal open and test SSH in a NEW terminal before closing it."
