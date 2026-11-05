#!/usr/bin/env bash
# Everything on the validator except the installer and its keys. Safe to re-run.
# scp validator/*.sh root@<ip>:/root/ && ssh root@<ip> bash /root/setup.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get -qq update
apt-get -yqq -o Dpkg::Options::=--force-confold full-upgrade >/dev/null
apt-get -yqq install unattended-upgrades jq lz4 sudo curl age ufw >/dev/null

# Installing a fix patches nothing until it boots: the fleet's lesson.
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'C'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
C
cat > /etc/apt/apt.conf.d/52validator <<'C'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
C

cat > /etc/ssh/sshd_config.d/10-validator.conf <<'C'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
C
sshd -t && systemctl reload ssh

# Vultr's Debian image ships ufw allowing only SSH, on top of its cloud firewall.
for port in 22 80 443 26656; do ufw allow "$port/tcp" >/dev/null; done

mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=500M\nMaxRetentionSec=3day\n' > /etc/systemd/journald.conf.d/10-short.conf
systemctl restart systemd-journald

id svote >/dev/null 2>&1 || useradd -m -s /bin/bash svote
install -d -m 700 -o svote -g svote /home/svote/.ssh
install -m 600 -o svote -g svote /root/.ssh/authorized_keys /home/svote/.ssh/authorized_keys

unit=/etc/systemd/system/svoted.service
if [ -d /home/svote/.svoted ]; then
  rm -f /etc/sudoers.d/90-svote-install
  # join.sh's SERVICE_PATH is overwritten by the library it sources, so the
  # unit it writes on Linux has the unit's own path as PATH and cannot start.
  if grep -q '"PATH=/etc/systemd/system/svoted.service"' "$unit"; then
    sed -i 's|"PATH=/etc/systemd/system/svoted.service"|"PATH=/home/svote/.local/bin:/usr/local/bin:/usr/bin:/bin"|' "$unit"
    systemctl daemon-reload
    systemctl restart svoted
  fi
else
  # The installer needs this once; the branch above takes it away afterwards.
  echo 'svote ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-svote-install
  chmod 440 /etc/sudoers.d/90-svote-install
fi

install -m 755 "$(dirname "$0")/heartbeat.sh" /usr/local/bin/validator-heartbeat
cat > /etc/systemd/system/validator-heartbeat.service <<'C'
[Unit]
Description=Signed status for infra.cypherpunk.com
[Service]
Type=oneshot
ExecStart=/usr/local/bin/validator-heartbeat
C
cat > /etc/systemd/system/validator-heartbeat.timer <<'C'
[Unit]
Description=Signed status for infra.cypherpunk.com
[Timer]
OnCalendar=minutely
[Install]
WantedBy=timers.target
C
systemctl daemon-reload
systemctl enable --now validator-heartbeat.timer
