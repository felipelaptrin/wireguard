output "public_ip" {
  description = "Public IP of the EC2 instance running WireGuard"
  value       = aws_spot_instance_request.this.public_ip
}

output "instance_id" {
  description = "EC2 instance ID (needed for SSM port forwarding)"
  value       = aws_spot_instance_request.this.spot_instance_id
}

output "ssm_tunnel_command" {
  description = "SSM port forwarding command to access the wg-easy panel at http://localhost:51821"
  value       = "aws ssm start-session --target ${aws_spot_instance_request.this.spot_instance_id} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"51821\"],\"localPortNumber\":[\"51821\"]}' --region ${var.region}"
}
