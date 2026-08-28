# wireguard

## Description
On-demand personal VPN using:
- **WireGuard** via [wg-easy](https://github.com/wg-easy/wg-easy) (Docker)
- **AWS** as cloud provider (spot instance for cost savings)
- **Terraform** for infrastructure
- **AWS SSM Session Manager** for secure panel access (no SSH, no open port 22)

## Architecture

![Architecture](docs/architecture.png)

A small ARM EC2 spot instance runs wg-easy in Docker. The WireGuard tunnel (port 51820/UDP) is the only port open to the internet. The wg-easy web panel (port 51821) is bound to localhost and accessed exclusively via SSM port forwarding — no SSH keys or bastion required.

## How to Run

### Prerequisites
- Terraform
- AWS CLI configured
- [AWS Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

### 1) Clone this repo
```sh
git clone https://github.com/felipelaptrin/wireguard.git
cd wireguard
```

### 2) Generate the wg-easy password hash
wg-easy requires a bcrypt hash. Generate one with:
```sh
docker run --rm -it ghcr.io/wg-easy/wg-easy wgpw YOUR_PASSWORD
```
Copy the output hash — you'll need it in the next step.

### 3) Create the infrastructure
```sh
cd terraform
terraform init
terraform apply
```

You will be prompted for `wg_password_hash` (the bcrypt hash from step 2).

Wait ~2 minutes for the instance to boot and Docker to start.

### 4) Open the wg-easy panel
Use SSM port forwarding to access the web UI securely:
```sh
bash scripts/tunnel.sh <INSTANCE_ID>
```
The instance ID is printed by `terraform output instance_id`. Then open **http://localhost:51821** in your browser.

### 5) Add clients
From the wg-easy panel:
- Click **+ Add Client**
- **Mobile (Android/iOS):** scan the QR code with the WireGuard app
- **Desktop:** download the `.conf` file and import it into the WireGuard client

### 6) Destroy when done
```sh
cd terraform
terraform destroy
```
