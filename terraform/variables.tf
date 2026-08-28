variable "region" {
  description = "AWS region to use to create the resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "ARM based instance type"
  type        = string
  default     = "t4g.micro"
}

variable "wg_password_hash" {
  description = "Bcrypt hash of the wg-easy web panel password. Generate with: docker run --rm -it ghcr.io/wg-easy/wg-easy wgpw YOUR_PASSWORD"
  type        = string
  sensitive   = true
}
