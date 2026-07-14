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

echo "--> Installing utilities (fail2ban, monitoring, tools)..."
apt-get install -y fail2ban unattended-upgrades htop ncdu iotop nethogs tmux git micro

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
cat << 'EOF' > /etc/ssh/sshd_config.d/99-hardening.conf
PasswordAuthentication no
PermitRootLogin prohibit-password
MaxAuthTries 3
X11Forwarding no
EOF
sshd -t
systemctl restart ssh

# 4. Fail2ban tuning
cat << 'EOF' > /etc/fail2ban/jail.local
[sshd]
enabled = true
bantime = 1h
maxretry = 5
EOF
systemctl restart fail2ban

# 5. Limit journald logs (prevents disk fill-up)
mkdir -p /etc/systemd/journald.conf.d/
printf '[Journal]\nSystemMaxUse=1G\n' > /etc/systemd/journald.conf.d/00-journal-size.conf
systemctl restart systemd-journald

echo "--> Setup complete. Keep this terminal open and test SSH in a NEW terminal before closing it."
