data "aws_cloudhsm_v2_cluster" "hsm_cluster" {
  cluster_id = "cluster-qsvghm4oqok"
}

## Temporarily disabled, see: https://github.com/ooni/devops/issues/55
#resource "aws_cloudhsm_v2_hsm" "hsm" {
#  count      = length(var.subnet_ids)
#  subnet_id  = var.subnet_ids[count.index]
#  cluster_id = data.aws_cloudhsm_v2_cluster.hsm_cluster.cluster_id
#}

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
    cidr_blocks = var.subnet_cidr_blocks
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

  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.hsm.id]

  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                curl -o cloudhsm-cli.rpm https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Amzn2023/cloudhsm-cli-latest.amzn2023.x86_64.rpm
                sudo yum install -y ./cloudhsm-cli.rpm
                rm cloudhsm-cli.rpm

                curl -o  cloudhsm-pkcs11.rpm https://s3.amazonaws.com/cloudhsmv2-software/CloudHsmClient/Amzn2023/cloudhsm-pkcs11-latest.amzn2023.x86_64.rpm
                sudo yum install -y ./cloudhsm-pkcs11.rpm
                rm cloudhsm-pkcs11.rpm
                EOF

  tags = merge(var.tags, { Name = "codesign-box" })

  // NOTE: remove the ignore_changes rule to deploy 
  lifecycle {
    ignore_changes = all
  }
}
