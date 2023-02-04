locals {
  environment_name = "${terraform.workspace}" 
}

#availability-zones

data "aws_availability_zones" "vpc" {
  state = "available"
}

#vpc
resource "aws_vpc" "main" {
  cidr_block       = var.mvpc_cidr
  instance_tenancy = var.mvpc_instance_tenancy

  tags = {
    Name = "${local.environment_name}-vpc"
  }
}

#public-subnets

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  count = length(var.mpublic_cidr)
  cidr_block = element(var.mpublic_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.vpc.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.environment_name}-public-${count.index+1}"
  }
}
#private-subnets

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  count = length(var.mprivate_cidr)
  cidr_block = element(var.mprivate_cidr, count.index)
  availability_zone =element(data.aws_availability_zones.vpc.names, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.environment_name}-private-${count.index+1}"
  }
}

#igw

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.environment_name}-igw"
  }
}

#EIP

resource "aws_eip" "eip" {
  vpc = true
  tags = {
    Name = "${local.environment_name}-eip"
  }
}

#nat-gw

resource "aws_nat_gateway" "natgw" {
  depends_on = [
    aws_eip.eip
  ]
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.environment_name}-natgw"
  }
}

# Route table: attach Internet Gateway 

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.environment_name}-publicRouteTable"
  }
}

# Route table: attach Nat-Gateway 
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "${local.environment_name}-privateRouteTable"
  }
}

# Route table association with public subnets
resource "aws_route_table_association" "public" {
  count = length(var.mpublic_cidr)
  subnet_id      = element(aws_subnet.public.*.id,count.index)
  route_table_id = aws_route_table.public_rt.id
}

# Route table association with private subnets
resource "aws_route_table_association" "private" {
  count = length(var.mprivate_cidr)
  subnet_id      = element(aws_subnet.private.*.id,count.index)
  route_table_id = aws_route_table.private_rt.id
}