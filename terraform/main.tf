resource "aws_spot_instance_request" "this" {
  ami           = data.aws_ami.this.id
  instance_type = var.instance_type

  spot_type              = "one-time"
  wait_for_fulfillment   = true
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = file("${path.module}/template/user_data.sh")

  tags = {
    Name = "Wireguard"
  }
}

resource "null_resource" "tag_spot_instance" {
  depends_on = [aws_spot_instance_request.this]

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resource ${aws_spot_instance_request.this.spot_instance_id} --tags Key=Name,Value=Wireguard --region ${var.region}"
  }
}

resource "aws_security_group" "this" {
  name = "wireguard-sg"
}

resource "aws_vpc_security_group_ingress_rule" "wireguard" {
  security_group_id = aws_security_group.this.id
  description       = "WireGuard tunnel"
  from_port         = 51820
  to_port           = 51820
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "wireguard_ipv6" {
  security_group_id = aws_security_group.this.id
  description       = "WireGuard tunnel (IPv6)"
  from_port         = 51820
  to_port           = 51820
  ip_protocol       = "udp"
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

### IAM — SSM access
resource "aws_iam_role" "this" {
  name = "wireguard-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "wireguard-ssm-profile"
  role = aws_iam_role.this.name
}
