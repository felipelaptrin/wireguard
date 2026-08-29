#!/bin/bash
set -e

### SYSTEM UPDATE & PREREQUISITES
apt-get update
apt-get install -y ca-certificates curl gnupg ufw unattended-upgrades

### SSM AGENT INSTAL
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

### DOCKER INSTAL
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: arm64
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl status docker
systemctl enable docker
systemctl start docker
systemctl status docker

### FIREWALL (UFW)
ufw default deny incoming
ufw default allow outgoing
ufw allow 51820/udp comment "WireGuard"
# Port 22 (SSH) and 51821 (wg-easy panel) are intentionally NOT opened.
# Use AWS SSM Session Manager for instance access and panel port forwarding.
ufw --force enable

### AUTOMATIC SECURITY UPDATES
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'UPGRADES'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
UPGRADES

### WG-EASY
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

mkdir -p /root/.wg-easy

# WG_HOST is only known at boot time (fetched from IMDS), so it's written to
# .env dynamically. Everything else static lives in docker-compose.yml directly.
# NOTE: wg-easy v15 has no PASSWORD_HASH env var (v14-only, removed). The admin
# account (username + password) is created through the panel's first-run setup
# wizard instead — see README.
printf 'WG_HOST=%s\n' "$PUBLIC_IP" > /root/.env

cat > /root/docker-compose.yml <<'COMPOSE'
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:15.4.0
    container_name: wg-easy
    restart: unless-stopped
    env_file: .env
    environment:
      - LANG=en
      - PORT=51821
      - INSECURE=true
      - EXPERIMENTAL_AWG=true
      - OVERRIDE_AUTO_AWG=awg
    volumes:
      - /root/.wg-easy:/etc/wireguard
      # Bind-mount the host's kernel modules so ip6tables can load ip6_tables.ko.
      # Without this, the container's own (Alpine) /lib/modules is empty, IPv6
      # firewall rules fail, and wg-quick/awg-quick aborts entirely — the only
      # workaround then is DISABLE_IPV6=true, which leaks IPv6 traffic around
      # the tunnel on any dual-stack client network. Mounting real modules in
      # makes the server correctly dual-stack capable (verified: instance-level
      # curl -6/ping6 work, NAT/forwarding rules are populated, peer configs
      # include a valid IPv6 address). End-to-end client connectivity still
      # depends on the client app, though — the "Amnezia VPN" iOS/macOS app has
      # open bugs mishandling dual-stack Address fields (e.g. amnezia-vpn/
      # amnezia-client#1630, #2539)
      - /lib/modules:/lib/modules:ro
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - "51820:51820/udp"
      - "127.0.0.1:51821:51821/tcp"
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv4.ip_forward=1
COMPOSE

docker compose -f /root/docker-compose.yml up -d
