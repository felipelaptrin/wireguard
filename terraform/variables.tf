variable "region" {
  description = "AWS region to use to create the resources"
  type        = string
  default     = "us-east-1"
}

variable "ssh_key" {
  description = "SSH key to use to connect to the EC2 running the Wireguard"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "ARM based instance type"
  type        = string
  default     = "t4g.nano"
}

variable "api_key" {
  description = "API key used to Auth when requesting to the API"
  type        = string
  sensitive   = true
}
