resource "aws_vpc" "vpc_aws_sandbox_ced_poc_sel" {
  cidr_block = "172.32.4.0/22"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "SEL - VPC"
  }
}


resource "aws_subnet" "sel_public" {
  vpc_id                  = aws_vpc.vpc_aws_sandbox_ced_poc_sel.id
  cidr_block              = "172.32.4.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SEL - Public Subnet ${var.region}a"
  }
}

resource "aws_internet_gateway" "sel_vpc_igw" {
  vpc_id = aws_vpc.vpc_aws_sandbox_ced_poc_sel.id

  tags = {
    Name = "SEL - VPC - Internet Gateway"
  }
}

resource "aws_route_table" "sel_vpc_public" {
  vpc_id = aws_vpc.vpc_aws_sandbox_ced_poc_sel.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sel_vpc_igw.id
  }

  tags = {
    Name = "SEL - Public Subnets Route Table for SEL VPC"
  }
}

resource "aws_route_table_association" "sel_vpc_public" {
  subnet_id      = aws_subnet.sel_public.id
  route_table_id = aws_route_table.sel_vpc_public.id
}
