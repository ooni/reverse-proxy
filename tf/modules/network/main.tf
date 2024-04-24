locals {
  private_net_offset  = 100
  cloudhsm_net_offset = 200
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_main_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  assign_generated_ipv6_cidr_block = true

  tags = var.tags
}

resource "aws_subnet" "public" {
  count = var.az_count

  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  assign_ipv6_address_on_creation = true

  availability_zone       = element(var.aws_availability_zones_available.names, count.index)
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ooni-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = var.az_count

  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, local.private_net_offset + count.index)

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, local.private_net_offset + count.index)
  assign_ipv6_address_on_creation = true

  availability_zone       = element(var.aws_availability_zones_available.names, count.index)
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false

  depends_on = [aws_internet_gateway.gw]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ooni-private-subnet-${count.index}"
  }
}


resource "aws_eip" "nat" {
  count      = var.az_count
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat_gw" {
  count = var.az_count

  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "ooni-nat-gw"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ooni-internet-gw"
  }
}

resource "aws_egress_only_internet_gateway" "egress_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ooni-egressonly-gw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_gw.id
  }

  tags = {
    Name = "ooni-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw[*].id, count.index)
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_gw.id
  }

  tags = {
    Name = "ooni-private-route-table-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "cloudhsm" {
  count      = var.enable_codesign_network ? 1 : 0
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, local.cloudhsm_net_offset)

  availability_zone       = var.aws_availability_zones_available.names[0]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false

  depends_on = [aws_internet_gateway.gw]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ooni-cloudhsm-subnet-0"
  }
}

resource "aws_route_table" "cloudhsm" {
  count = var.enable_codesign_network ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "ooni-cloudhsm-route-table"
  }
}

resource "aws_route_table_association" "cloudhsm" {
  count          = var.enable_codesign_network ? 1 : 0
  subnet_id      = element(aws_subnet.cloudhsm[*].id, count.index)
  route_table_id = aws_route_table.cloudhsm[count.index].id
}
