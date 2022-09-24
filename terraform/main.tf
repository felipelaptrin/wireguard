resource "aws_spot_instance_request" "this" {
  depends_on = [archive_file.zip]

  ami           = "ami-0f69dd1d0d03ad669" // Ubuntu ARM us-east-1
  instance_type = var.instance_type

  block_duration_minutes = 0
  wait_for_fulfillment   = true
  key_name               = var.ssh_key
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = data.template_file.user_data.rendered
}

resource "null_resource" "tag_spot_instance" {
  depends_on = [aws_spot_instance_request.this]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resource ${aws_spot_instance_request.this.spot_instance_id} --tags Key=Name,Value=Wireguard"
  }
}

resource "aws_security_group" "this" {
  name = "wireguard-sg"

  dynamic "ingress" {
    for_each = var.ssh_key != null ? range(1) : []

    content {
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = "Allow SSH connection"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
    }
  }

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Default Wireguard port"
    from_port        = 51820
    to_port          = 51820
    protocol         = "udp"
  }

  ingress {
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Default Wireguard port"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
