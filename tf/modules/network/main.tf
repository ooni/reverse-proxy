
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

  tags = {
    Name = "ooni-public-subnet-${count.index}"
  }
}

moved {
  from = aws_subnet.main
  to   = aws_subnet.public
}

resource "aws_subnet" "private" {
  count = var.az_count

  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, var.az_count + count.index)
  assign_ipv6_address_on_creation = true

  availability_zone       = element(var.aws_availability_zones_available.names, var.az_count + count.index)
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = false

  depends_on = [aws_internet_gateway.gw]

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

moved {
  from = aws_egress_only_internet_gateway.gw
  to   = aws_egress_only_internet_gateway.egress_gw
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
}
