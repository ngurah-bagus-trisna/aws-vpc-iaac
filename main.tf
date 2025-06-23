resource "aws_vpc" "nb-chatgpt-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "nb-chatgpt-vpc"
  }
}

resource "aws_subnet" "nb-subnet" {
  depends_on = [aws_vpc.nb-chatgpt-vpc]
  vpc_id     = aws_vpc.nb-chatgpt-vpc.id
  for_each   = var.subnet

  cidr_block              = each.value.subnet_range
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.key == "public-net" ? true : false
  tags = {
    "Name" = each.key
    "Type" = each.value.type
  }
}

resource "aws_internet_gateway" "nb-inet-gw" {
  depends_on = [aws_vpc.nb-chatgpt-vpc]
  vpc_id     = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "nb-inet-gw"
  }
}

resource "aws_eip" "nb-eip-nat-gw" {
  depends_on = [aws_internet_gateway.nb-inet-gw]
  tags = {
    "Name" = "nb-eip-nat-gw"
  }
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
  depends_on = [ aws_vpc.nb-chatgpt-vpc, aws_subnet.nb-subnet ]
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
  depends_on = [aws_subnet.nb-subnet]
  name       = "nb-db-subnet"
  subnet_ids = [aws_subnet.nb-subnet["private-net"].id]

  tags = {
    "Name" = "Private DB Subnet Group"
  }
}


resource "aws_security_group" "rds-sg" {
  depends_on  = [aws_subnet.nb-subnet]
  name        = "rds-sg"
  description = "Security group to allow access rds-subnet from private subnets"
  vpc_id      = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    Name = "rds-server-sg"
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

resource "aws_security_group" "web-sg" {
  depends_on = [aws_subnet.nb-subnet]

  name        = "web-sg"
  description = "Security group to allow access port 22"
  vpc_id      = aws_vpc.nb-chatgpt-vpc.id

  tags = {
    "Name" : "web-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-access-ssh" {
  depends_on = [aws_security_group.web-sg]

  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  to_port           = 22
  from_port         = 22
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

# Begin create instance

resource "aws_network_interface" "instance-interface" {
  depends_on      = [aws_subnet.nb-subnet]
  for_each        = var.instance
  subnet_id       = aws_subnet.nb-subnet[each.value.subnet].id
  security_groups = [aws_security_group.web-sg.id]

  tags = {
    "Name" = "interface ${each.key}"
  }
}

resource "aws_instance" "nb-instance" {
  for_each   = var.instance
  depends_on = [aws_network_interface.instance-interface]

  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = "nb-keys"

  network_interface {
    network_interface_id = aws_network_interface.instance-interface[each.key].id
    device_index         = 0
  }

  tags = {
    "Name" = "Instance - ${each.key}"
  }
}


output "vpc_id" {
  value = aws_vpc.nb-chatgpt-vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.nb-subnet["public-net"].id
}

output "private_subnet_id" {
  value = aws_subnet.nb-subnet["private-net"].id
}


output "nat_gateway_public_ip" {
  value = aws_nat_gateway.nb-nat-gw.public_ip
}