
# Local variable definitions
locals {
  environment      = "production"
  ecs_cluster_name = "ooni-ecs-cluster"
  dns_zone_ooni_nu = "Z035992527R8VEIX2UVO0" # ooni.nu hosted zone
  dns_zone_ooni_io = "Z02418652BOD91LFA5S9X" # ooni.io hosted zone
}

locals {
  clickhouse_hostname    = "clickhouse.tier1.prod.ooni.nu"
  clickhouse_device_name = "/dev/sdf"

  name = "ooni-clickhouse-tier1-${local.environment}"

  tags = {
    Name       = local.name
    Repository = "https://github.com/ooni/devops"
  }
}

data "aws_ami" "debian_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"] # Debian's official AWS account ID
}

resource "aws_instance" "clickhouse_server_prod_tier1" {
  ami           = data.aws_ami.debian_ami.id
  instance_type = "r5.xlarge"
  key_name      = var.key_name

  associate_public_ip_address = true

  subnet_id              = var.aws_subnet_id
  vpc_security_group_ids = [aws_security_group.clickhouse_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
  }

  user_data = templatefile("${path.module}/templates/clickhouse-setup.sh", {
    hostname        = local.clickhouse_hostname,
    device_name     = local.clickhouse_device_name
  })

  tags = merge(
    local.tags,
    {
      Name = "clickhouse-${local.tags["Name"]}"
    }
  )
}

# We care to ensure this data volume is not destroyed across re-applies. To do
# that you can either run first an apply with this commented out and then
# specify the data volume below. You can also just create a data volume with the
# appropriate tag manually and then edit the section below to indicate the name.
# If you do that, you will then have to manually also run:
# $ terraform state rm aws_ebs_volume.clickhouse_data_volume
#resource "aws_ebs_volume" "clickhouse_data_volume" {
#  availability_zone = aws_instance.clickhouse_server_prod_tier1.availability_zone
#  size              = 1024  # 1 TB
#  type              = "gp3" # SSD-based volume type, provides up to 16,000 IOPS and 1,000 MiB/s throughput
#  tags = merge(local.tags, {
#    Name = "ooni-tier1-prod-clickhouse-vol1"
#  })
#
#  lifecycle {
#    prevent_destroy = true
#  }
#}

data "aws_ebs_volume" "clickhouse_data_volume" {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["ooni-tier1-prod-clickhouse-vol1"]
  }

  filter {
    name   = "availability-zone"
    values = [aws_instance.clickhouse_server_prod_tier1.availability_zone]
  }
}

resource "aws_volume_attachment" "clickhouse_data_volume_attachment" {
  device_name  = local.clickhouse_device_name
  volume_id    = data.aws_ebs_volume.clickhouse_data_volume.id
  instance_id  = aws_instance.clickhouse_server_prod_tier1.id
  force_detach = true
}

resource "aws_eip" "clickhouse_ip" {
  instance = aws_instance.clickhouse_server_prod_tier1.id

  tags = local.tags
}

resource "aws_security_group" "clickhouse_sg" {
  name        = "clickhouse_sg"
  description = "Allow Clickhouse traffic"

  vpc_id = var.aws_vpc_id


  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      var.admin_cidr_ingress,
    ]
  }

  ingress {
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = ["93.65.174.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_route53_record" "clickhouse_dns" {
  zone_id = local.dns_zone_ooni_nu
  name    = local.clickhouse_hostname
  type    = "A"
  ttl     = "300"
  records = [aws_eip.clickhouse_ip.public_ip]
}
