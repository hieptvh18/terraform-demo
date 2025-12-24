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

// NATGateway
# resource "aws_nat_gateway" "ngw" {
#   depends_on = [ aws_vpc.this ]
#   count = local.azs
#   subnet_id = element(aws_subnet.public_subnet.*.id, count.index)
# }