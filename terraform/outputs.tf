output "public_ip" {
  description = "Public IP of the EC2 instance running Wireguard"
  value       = aws_spot_instance_request.this.public_ip
}
