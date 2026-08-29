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
