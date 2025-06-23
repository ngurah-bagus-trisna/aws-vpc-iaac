resource "aws_vpc" "nb-chatgpt-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "nb-chatgpt-vpc"
  }
}

resource "aws_subnet" "nb-subnet" {
  depends_on = [ aws_vpc.nb-chatgpt-vpc ]
  vpc_id   = aws_vpc.nb-chatgpt-vpc.id
  for_each = var.subnet

  cidr_block        = each.value.subnet_range
  availability_zone = each.value.availability_zone
  tags = {
    "Name" = each.key
    "Type" = each.value.type
  }
}

resource "aws_internet_gateway" "nb-inet-gw" {
  depends_on = [ aws_vpc.nb-chatgpt-vpc ]
  vpc_id = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "nb-inet-gw"
  }
}

resource "aws_eip" "nb-eip-nat-gw" {
  depends_on = [ aws_internet_gateway.nb-inet-gw ]
  tags = {
    "Name" = "nb-eip-nat-gw"
  }
}

locals {
  public_subnet_ids = [
    for key, subnet in var.subnet : aws_subnet.nb-subnet[key].id
    if subnet.type == "public"
  ]
  private_subnet_ids = [
    for key, subnet in var.subnet : aws_subnet.nb-subnet[key].id
    if subnet.type == "private"
  ]
}

resource "aws_nat_gateway" "nb-nat-gw" {
  depends_on        = [aws_eip.nb-eip-nat-gw]
  allocation_id     = aws_eip.nb-eip-nat-gw.id
  subnet_id         = aws_subnet.nb-subnet["private-net"].id
  connectivity_type = "public"
  tags = {
    "Name" : var.natgw_name
  }
}

resource "aws_route_table" "net-public" {
  for_each = var.route_tables
  vpc_id   = aws_vpc.nb-chatgpt-vpc.id

  route {
    cidr_block     = each.value.cidr_source
    gateway_id     = each.value.route_destination == "igw" ? aws_internet_gateway.nb-inet-gw.id : null
    nat_gateway_id = each.value.route_destination == "nat" ? aws_nat_gateway.nb-nat-gw.id : null
  }
}

resource "aws_route_table_association" "public" {
  depends_on     = [aws_route_table.net-public]
  subnet_id      = aws_subnet.nb-subnet["public-net"].id
  route_table_id = aws_route_table.net-public["public"].id
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_route_table.net-public]
  subnet_id      = aws_subnet.nb-subnet["private-net"].id
  route_table_id = aws_route_table.net-public["private"].id
}

resource "aws_db_subnet_group" "nb-db-subnet" {
  depends_on = [ aws_subnet.nb-subnet ]
  name       = "nb-db-subnet"
  subnet_ids = local.private_subnet_ids

  tags = {
    "Name" = "Private DB Subnet Group"
  }
}


resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Security group to allow access rds-subnet from private subnets"
  vpc_id      = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-access-rds" {
  depends_on        = [aws_security_group.rds-sg]
  security_group_id = aws_security_group.rds-sg.id
  cidr_ipv4         = aws_subnet.nb-subnet["private-net"].cidr_block
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
}


resource "aws_db_instance" "nb-db" {
  depends_on             = [aws_security_group.rds-sg, aws_vpc_security_group_ingress_rule.allow-access-rds]
  allocated_storage      = 10
  db_name                = "nb-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = var.db_credentials.username
  password               = var.db_credentials.password
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}




output "vpc_id" {
  value = aws_vpc.nb-chatgpt-vpc.id
}

output "public_subnet_id" {
  value = local.public_subnet_ids
}

output "private_subnet_id" {
  value = local.private_subnet_ids
}

output "nat_gateway_public_ip" {
  value = aws_nat_gateway.nb-nat-gw.public_ip
}
