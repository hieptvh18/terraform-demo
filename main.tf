data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(data.aws_availability_zones.available.names)
}

// create vpc
resource "aws_vpc" "this"  {
  cidr_block = var.cidr_block
  tags = merge({
    "Name" = "vpchihi"
  }, var.default_tags)
}

// define subnets
resource "aws_subnet" "public_subnet" {
  depends_on = [ aws_vpc.this ]
  count = local.azs
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.this.id
  tags = merge({
    public-aws_subnet = "true"
    "Name" = "public-subnet-${count.index}"
  }, var.default_tags)
}

resource "aws_subnet" "private_subnet" {
  depends_on = [ aws_vpc.this ]
  count = local.azs
  cidr_block = cidrsubnet(var.cidr_block, 8, local.azs + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.this.id
  tags = merge({
    public-aws_subnet = "false",
    "Name" = "private-subnet-${count.index}"
  }, var.default_tags)
}

resource "aws_internet_gateway" "igw" {
  depends_on = [ aws_vpc.this ]
  vpc_id = aws_vpc.this.id
  tags = merge({
    "Name" = "igw"
  }, var.default_tags)
}

resource "aws_route" "public_route" {
  depends_on = [ aws_internet_gateway.igw, aws_vpc.this ]
  route_table_id = aws_vpc.this.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public-route-association" {
  depends_on = [ aws_vpc.this ]
  count = local.azs
  subnet_id = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_vpc.this.main_route_table_id
}


// NATGateway

// moi nat gateway se co the su dung 1 public subnet de tao ra 1 elastic ip de su dung cho nat gateway
resource "aws_eip" "private-eip" {
  depends_on = [ aws_vpc.this ]
  count = local.azs
  tags = merge({
    "Name" = "private-eip-${count.index}"
  }, var.default_tags)
}

resource "aws_nat_gateway" "private-natgw" {
  depends_on = [ aws_vpc.this ]
  count = local.azs
  subnet_id = element(aws_subnet.public_subnet.*.id, count.index)
  allocation_id = element(aws_eip.private-eip.*.id, count.index)
  tags = merge({
    "Name" = "private-natgw-${count.index}"
  }, var.default_tags)
}

resource "aws_route_table" "private-route-table" {
  depends_on = [ aws_vpc.this, aws_nat_gateway.private-natgw ]
  count  = local.azs
  vpc_id = aws_vpc.this.id
  tags = merge({
    "Name" = "private-route-table-${count.index}"
  }, var.default_tags)

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.private-natgw.*.id, count.index)
  }

}

resource "aws_route_table_association" "private-route-association" {
  depends_on = [ aws_vpc.this ]
  count = local.azs
  subnet_id = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private-route-table.*.id, count.index)
}