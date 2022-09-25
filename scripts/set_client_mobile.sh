#!/bin/bash
set -e


## INPUTS
api_key=$1
vpn_public_ip=$2


################ SCRIPT ######################
echo "[INFO] Updading apt packages..."
apt-get update
echo "[INFO] Installing Wireguard..."
apt install wireguard -y

echo "[INFO] Removing old files if exist..."
cd /tmp
rm -f publickey privatekey wg0.conf

echo "[INFO] Creating public and private key..."
wg genkey | tee privatekey | wg pubkey > publickey
chmod 600 privatekey publickey
private_key=$(cat privatekey)
public_key=$(cat publickey)

echo "[INFO] Requesting VPN to add you as a new user..."
response=$(curl -X POST $vpn_public_ip:8000/user --header "Authorization: Bearer $api_key" -H "Content-Type: application/json" -d '{"public_key":"'"$public_key"'"}')
vpn_public_key=$(jq -r .public_key <<<$response)
private_ip=$(jq -r .private_ip <<<$response)


cat > wg0.conf <<EOF
[Interface]
Address = $private_ip
PrivateKey = $private_key

[Peer]
PublicKey = $vpn_public_key
Endpoint = $vpn_public_ip:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 30
EOF

qrencode -t png -o wireguard_qrcode.png -r wg0.conf

echo "[Info] QR Code stored in path /tmp/wireguard_qrcode.png"
echo "[DONE] You are good to go. Feel free to connect to the VPN at any time."
