#!/bin/bash

apt-get update
apt install python3-pip wireguard -y

### WIREGUARD
cd /etc/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
chmod 600 privatekey
chmod 777 publickey

network_interface=$(find /sys/class/net -mindepth 1 -maxdepth 1 -lname '*virtual*' -prune -o -printf '%f\n')
privatekey=$(cat privatekey)
cat > wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $network_interface -j MASQUERADE;
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $network_interface -j MASQUERADE;
ListenPort = 51820
PrivateKey = $privatekey
EOF

wg-quick up wg0
sysctl -w net.ipv4.ip_forward=1
sysctl --system

### API
cd ~
git clone https://github.com/felipelaptrin/wireguard.git
cd wireguard

pip3 install -r api/requirements.txt
export API_KEY=${api_key}
python3 api/main.py