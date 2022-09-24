import subprocess


def get_vpn_public_key() -> str:
    with open('/etc/wireguard/publickey') as f:
        content = f.read().splitlines()[0]
    return content


def add_user_to_vpn(user_public_key: str, user_private_ip: str):
    command = f"wg set wg0 peer {user_public_key} allowed-ips {user_private_ip}"
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
