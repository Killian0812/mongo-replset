# 3 public subnets across AZs, no NAT - IGW route gives every node a public IP directly.
resource "aws_vpc" "mongo" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "mongo-cluster" }
}

resource "aws_subnet" "mongo" {
  for_each                = var.subnet_cidrs
  vpc_id                  = aws_vpc.mongo.id
  cidr_block              = each.value
  availability_zone       = "${var.region}${each.key}"
  map_public_ip_on_launch = true # no NAT, use IGW
  tags                    = { Name = "mongo-subnet-${each.key}" }
}

resource "aws_internet_gateway" "mongo" {
  vpc_id = aws_vpc.mongo.id
  tags   = { Name = "mongo-igw" }
}

resource "aws_route_table" "mongo" {
  vpc_id = aws_vpc.mongo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mongo.id
  }

  tags = { Name = "mongo-rt" }
}

resource "aws_route_table_association" "mongo" {
  for_each       = aws_subnet.mongo
  subnet_id      = each.value.id
  route_table_id = aws_route_table.mongo.id
}
