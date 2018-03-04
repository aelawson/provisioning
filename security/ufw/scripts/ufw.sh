# !/bin/bash
set -e

ufw --force reset

ufw allow in on ${private_interface} to any port ${vpn_port}
ufw allow in on ${vpn_interface}
ufw allow in on ${kubernetes_interface}

ufw allow 6443
ufw allow ssh
ufw allow http
ufw allow https
ufw default deny incoming

ufw --force enable
ufw status update