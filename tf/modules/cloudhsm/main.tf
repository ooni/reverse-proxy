resource "aws_cloudhsm_v2_cluster" "hsm" {
  hsm_type   = "hsm1.medium"
  subnet_ids = [var.subnet_id]

  tags = var.tags
}

resource "aws_security_group" "hsm" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2223 # Port for CloudHSM
    to_port     = 2225
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_instance" "codesign_box" {
  ami = data.aws_ami.amazon_linux.id

  key_name      = var.key_name
  instance_type = "t3.micro"

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.hsm.id]

  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y amazon-cloudhsm-cli
                sudo amazon-linux-extras install -y epel
                sudo yum install -y openssl
                sudo yum install -y engine_pkcs11 opensc
                EOF

  tags = merge(var.tags, { Name = "codesign-box" })
}
